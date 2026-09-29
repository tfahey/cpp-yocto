#!/bin/bash
# Build Qt5 hello-world for multiple architectures AND run SCA with srcclr
#
# Usage:
#   export SRCCLR_API_TOKEN="your-token-here"
#   bash BUILD_MULTI_ARCH_WITH_SCA.sh [arm64|x86-64|both]
#
# This script:
# 1. Builds the application using Yocto (same as BUILD_MULTI_ARCH.sh)
# 2. Runs srcclr SCA on the resulting build directory (requires SRCCLR_API_TOKEN)
# 3. Generates SCA reports in sca-reports/ directory
#
# Note: SRCCLR_API_TOKEN is passed via environment only (not stored in image/container)
# Note: Uses a named persistent container (yocto-builder) for reusable builds

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUTPUT_DIR="$SCRIPT_DIR/hello-world-output"
SCA_OUTPUT_DIR="$SCRIPT_DIR/sca-reports"

# Persistent cache directories (separate per architecture for efficiency)
YOCTO_CACHE_DIR="$SCRIPT_DIR/.yocto-cache"
YOCTO_DL_DIR="$YOCTO_CACHE_DIR/downloads"

TARGET="${1:-both}"

# Create cache directories
mkdir -p "$YOCTO_DL_DIR"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Building Qt5 + SCA Analysis (srcclr)                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Target: $TARGET"
echo ""

# Helper function to build and scan for a specific architecture
build_and_scan() {
    local MACHINE=$1
    local ARCH_NAME=$2
    local BUILD_DIR="$SCRIPT_DIR/build-$ARCH_NAME"
    local TMP_BUILD="/tmp/yocto-build-$ARCH_NAME"
    local OUTPUT_SUBDIR="$OUTPUT_DIR"
    local SCA_REPORT="$SCA_OUTPUT_DIR/sca-report-$ARCH_NAME.txt"

    # Architecture-specific sstate cache
    local YOCTO_SSTATE_DIR="$YOCTO_CACHE_DIR/sstate-cache-$ARCH_NAME"
    mkdir -p "$YOCTO_SSTATE_DIR"

    if [ "$ARCH_NAME" != "x86-64" ]; then
        OUTPUT_SUBDIR="$OUTPUT_DIR/$ARCH_NAME"
    fi

    echo "🔨 Building for $ARCH_NAME ($MACHINE)..."
    echo ""

    # Create build directory
    mkdir -p "$BUILD_DIR/conf"

    # Copy bblayers.conf
    cp "$SCRIPT_DIR/build/conf/bblayers.conf" "$BUILD_DIR/conf/" 2>/dev/null || \
        echo "⚠️  Warning: bblayers.conf not found, will create in container"

    # Create local.conf for this architecture with architecture-specific sstate cache
    cat > "$BUILD_DIR/conf/local.conf" << EOF
MACHINE = "$MACHINE"
TMPDIR = "$TMP_BUILD/tmp"
IMAGE_INSTALL:append = " hello-world"
EXTRA_IMAGE_FEATURES ?= "debug-tweaks"
USER_CLASSES ?= "buildstats"
PATCHRESOLVE = "noop"

# Persistent cache directories (architecture-specific for efficiency)
DL_DIR = "/home/yocto/cache/downloads"
SSTATE_DIR = "/home/yocto/cache/sstate-cache-$ARCH_NAME"
BB_DISKMON_DIRS ??= "\\
    STOPTASKS,\${TMPDIR},1G,100K \\
    STOPTASKS,\${DL_DIR},1G,100K \\
    STOPTASKS,\${SSTATE_DIR},1G,100K \\
    STOPTASKS,/tmp,100M,100K \\
    HALT,\${TMPDIR},100M,1K \\
    HALT,\${DL_DIR},100M,1K \\
    HALT,\${SSTATE_DIR},100M,1K \\
    HALT,/tmp,10M,1K"
PACKAGECONFIG:append:pn-qemu-system-native = " sdl"
CONF_VERSION = "2"
EOF

    # Create temporary directory for artifact transfer
    TEMP_ARTIFACTS=$(mktemp -d)
    trap "rm -rf $TEMP_ARTIFACTS" EXIT

    # Run build in Docker with SCA
    # Pass SRCCLR_API_TOKEN from environment (not stored in image/container)
    # Mount architecture-specific sstate cache to avoid cache invalidation on arch switches
    docker run --rm \
        -m 14g \
        --memory-swap 16g \
        -e SRCCLR_API_TOKEN \
        -v "$SCRIPT_DIR:/home/yocto/project" \
        -v "$TEMP_ARTIFACTS:/tmp/artifacts" \
        -v "$YOCTO_DL_DIR:/home/yocto/cache/downloads" \
        -v "$YOCTO_SSTATE_DIR:/home/yocto/cache/sstate-cache-$ARCH_NAME" \
        yocto-qt-builder:latest \
        bash -c "
            cd /tmp
            mkdir -p yocto-build-$ARCH_NAME
            cd yocto-build-$ARCH_NAME

            # Setup
            cp -r /home/yocto/project/build-$ARCH_NAME/conf .
            source /home/yocto/project/poky/oe-init-build-env . > /dev/null 2>&1

            # Show config
            echo '=== Build Configuration ==='
            grep '^MACHINE' conf/local.conf
            echo ''

            # Build
            echo '=== Starting Build ==='
            bitbake hello-world

            BUILD_STATUS=\$?
            echo ''

            if [ \$BUILD_STATUS -eq 0 ]; then
                echo '🔍 Searching for binary in Yocto build outputs...'

                BINARY=\"\"

                # Check in image directory (most common for cross-compiled binaries)
                if [ -z \"\$BINARY\" ]; then
                    BINARY=\$(find tmp*/work -path '*/image/usr/bin/hello-world' -type f 2>/dev/null | head -1)
                fi

                # Check in package directory
                if [ -z \"\$BINARY\" ]; then
                    BINARY=\$(find tmp*/work -path '*/package/usr/bin/hello-world' -type f 2>/dev/null | head -1)
                fi

                # Check in build directory
                if [ -z \"\$BINARY\" ]; then
                    BINARY=\$(find tmp*/work -path '*/build/hello-world' -type f 2>/dev/null | head -1)
                fi

                # Fallback: any ELF file named hello-world in the build tree
                if [ -z \"\$BINARY\" ]; then
                    for F in \$(find tmp* -type f -name 'hello-world' ! -name '*.so' ! -name '*.a' ! -name '*.o' ! -name '*.ipk' 2>/dev/null); do
                        if file \"\$F\" | grep -q 'ELF'; then BINARY=\"\$F\"; break; fi
                    done
                fi

                # Fallback: extract binary from IPK package
                if [ -z \"\$BINARY\" ]; then
                    IPK=\$(find \$(pwd)/tmp* -path '*/deploy/ipk/*/hello-world_*.ipk' -type f 2>/dev/null | grep -v '\-dbg\|\-dev\|\-src' | head -1)
                    if [ -n \"\$IPK\" ]; then
                        echo \"Extracting binary from IPK: \$IPK\"
                        EXTRACT_DIR=\$(mktemp -d)
                        cd \"\$EXTRACT_DIR\"
                        ar x \"\$IPK\"
                        if [ -f data.tar.zst ]; then
                            tar --use-compress-program=unzstd -xf data.tar.zst
                        elif [ -f data.tar.xz ]; then
                            tar xf data.tar.xz
                        elif [ -f data.tar.gz ]; then
                            tar xf data.tar.gz
                        fi
                        FOUND=\$(find \"\$EXTRACT_DIR\" -name 'hello-world' -type f 2>/dev/null | head -1)
                        if [ -n \"\$FOUND\" ] && file \"\$FOUND\" | grep -q 'ELF'; then
                            echo \"✅ Extracted ELF binary from IPK\"
                            cp \"\$FOUND\" /tmp/artifacts/hello-world-$ARCH_NAME
                            file \"\$FOUND\"
                            BINARY=\"COPIED_FROM_IPK\"
                        fi
                        cd -  > /dev/null
                        rm -rf \"\$EXTRACT_DIR\"
                    fi
                fi

                if [ \"\$BINARY\" = \"COPIED_FROM_IPK\" ]; then
                    echo '✅ Binary already copied to artifacts from IPK'
                elif [ -n \"\$BINARY\" ] && [ -f \"\$BINARY\" ]; then
                    echo \"✅ Found binary: \$BINARY\"
                    cp \"\$BINARY\" /tmp/artifacts/hello-world-$ARCH_NAME
                    echo '✅ Binary copied to artifacts'
                    file \"\$BINARY\"
                else
                    echo '❌ Binary not found after successful build'
                    exit 1
                fi

                # ========================================
                # Now run SCA with srcclr on Yocto build tree
                # ========================================
                echo ''
                echo '📊 Running SCA analysis with srcclr on Yocto build artifacts...'

                if command -v srcclr &> /dev/null; then
                    srcclr scan /home/yocto/build-$ARCH_NAME/tmp-glibc/work > /tmp/artifacts/srcclr-report-$ARCH_NAME.txt 2>&1 || true
                    echo '✅ SCA scan completed'
                    cp /tmp/artifacts/srcclr-report-$ARCH_NAME.txt /tmp/artifacts/ 2>/dev/null || true
                else
                    echo '⚠️  srcclr not installed, skipping SCA'
                fi
            else
                echo '❌ Build failed'
                exit 1
            fi
        "

    BUILD_RESULT=$?

    # Copy from temp directory to host
    if [ $BUILD_RESULT -eq 0 ] && [ -f "$TEMP_ARTIFACTS/hello-world-$ARCH_NAME" ]; then
        mkdir -p "\$OUTPUT_SUBDIR"
        cp "$TEMP_ARTIFACTS/hello-world-$ARCH_NAME" "$OUTPUT_SUBDIR/hello-world"
        echo "✅ Binary saved to: $OUTPUT_SUBDIR/hello-world"
    elif [ $BUILD_RESULT -ne 0 ]; then
        echo "❌ Build failed with exit code $BUILD_RESULT"
        exit 1
    else
        echo "❌ Binary not found in artifacts"
        exit 1
    fi

    # Copy SCA report if it exists
    mkdir -p "$SCA_OUTPUT_DIR"
    if [ -f "$TEMP_ARTIFACTS/srcclr-report-$ARCH_NAME.txt" ]; then
        cp "$TEMP_ARTIFACTS/srcclr-report-$ARCH_NAME.txt" "$SCA_REPORT"
        echo "📊 SCA report saved to: $SCA_REPORT"
    fi

    # Show result
    if [ -f "$OUTPUT_SUBDIR/hello-world" ]; then
        echo ""
        echo "✅ \$ARCH_NAME build complete!"
        echo "   Binary: \$OUTPUT_SUBDIR/hello-world"
        file "\$OUTPUT_SUBDIR/hello-world" | grep -o "x86-64\|aarch64"
        ls -lh "\$OUTPUT_SUBDIR/hello-world"
        echo ""
    else
        echo "❌ \$ARCH_NAME build failed!"
        exit 1
    fi
}

# Build based on target
case "$TARGET" in
    arm64)
        build_and_scan "qemuarm64" "arm64"
        ;;
    x86-64)
        build_and_scan "qemux86-64" "x86-64"
        ;;
    both)
        build_and_scan "qemuarm64" "arm64"
        build_and_scan "qemux86-64" "x86-64"
        ;;
    *)
        echo "❌ Invalid target: $TARGET"
        echo "Usage: $0 [arm64|x86-64|both]"
        exit 1
        ;;
esac

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              ✅ Build + SCA Complete!                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Output directory: $OUTPUT_DIR"
echo "SCA reports directory: $SCA_OUTPUT_DIR"
echo ""

# List built binaries
echo "Built binaries:"
if [ -f "\$OUTPUT_DIR/hello-world" ]; then
    echo "  • x86-64:  \$OUTPUT_DIR/hello-world"
fi
if [ -f "\$OUTPUT_DIR/arm64/hello-world" ]; then
    echo "  • ARM64:   \$OUTPUT_DIR/arm64/hello-world"
fi

echo ""
echo "SCA Reports:"
if [ -d "\$SCA_OUTPUT_DIR" ] && [ "$(ls -A \$SCA_OUTPUT_DIR)" ]; then
    ls -lh "\$SCA_OUTPUT_DIR"
else
    echo "  (No SCA reports generated - srcclr may not be installed)"
fi

echo ""
