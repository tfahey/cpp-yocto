#!/bin/bash
# Build Qt5 hello-world for multiple architectures (ARM64 + x86-64)
#
# Usage:
#   bash BUILD_MULTI_ARCH.sh [arm64|x86-64|both]
#
# Default: build both

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUTPUT_DIR="$SCRIPT_DIR/hello-world-output"

TARGET="${1:-both}"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Building Qt5 Hello World for Multiple Architectures      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Target: $TARGET"
echo ""

# Helper function to build for a specific architecture
build_architecture() {
    local MACHINE=$1
    local ARCH_NAME=$2
    local BUILD_DIR="$SCRIPT_DIR/build-$ARCH_NAME"
    local TMP_BUILD="/tmp/yocto-build-$ARCH_NAME"
    local OUTPUT_SUBDIR="$OUTPUT_DIR"

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

    # Create local.conf for this architecture
    cat > "$BUILD_DIR/conf/local.conf" << EOF
MACHINE = "$MACHINE"
TMPDIR = "$TMP_BUILD/tmp"
IMAGE_INSTALL:append = " hello-world"
EXTRA_IMAGE_FEATURES ?= "debug-tweaks"
USER_CLASSES ?= "buildstats"
PATCHRESOLVE = "noop"
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

    # Run build in Docker (WITHOUT --rm so we can extract artifacts)
    CONTAINER_ID=$(docker run -d \
        -v "$SCRIPT_DIR:/home/yocto/project" \
        -v "$TEMP_ARTIFACTS:/tmp/artifacts" \
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
                echo '🔍 Searching for binary...'

                # Try multiple locations where binary might be
                BINARY=\"\"

                # Check in image directory (most common)
                if [ -f \"tmp/work/*/hello-world/0.1/image/usr/bin/hello-world\" ]; then
                    BINARY=\$(find tmp/work -path '*/hello-world/0.1/image/usr/bin/hello-world' -type f | head -1)
                fi

                # Check in recipe-sysroot
                if [ -z \"\$BINARY\" ] && [ -f \"tmp/work/*/hello-world/0.1/recipe-sysroot/usr/bin/hello-world\" ]; then
                    BINARY=\$(find tmp/work -path '*/hello-world/0.1/recipe-sysroot/usr/bin/hello-world' -type f | head -1)
                fi

                # Fallback: search everywhere
                if [ -z \"\$BINARY\" ]; then
                    BINARY=\$(find tmp/work -name 'hello-world' -type f ! -name '*.so' ! -name '*.a' 2>/dev/null | grep -v '\.ipk' | head -1)
                fi

                if [ -n \"\$BINARY\" ] && [ -f \"\$BINARY\" ]; then
                    echo \"Found: \$BINARY\"
                    cp \"\$BINARY\" /tmp/artifacts/hello-world-$ARCH_NAME
                    echo '✅ Binary copied to Mac'
                    file \"\$BINARY\"
                else
                    echo '❌ Binary not found. Searching...'
                    find tmp/work -name 'hello-world' -type f ! -name '*.a' 2>/dev/null | head -10
                    exit 1
                fi
            else
                echo '❌ Build failed'
                exit 1
            fi
        "

    BUILD_RESULT=$?

    # Copy from temp directory to Mac
    if [ $BUILD_RESULT -eq 0 ] && [ -f "$TEMP_ARTIFACTS/hello-world-$ARCH_NAME" ]; then
        mkdir -p "$OUTPUT_SUBDIR"
        cp "$TEMP_ARTIFACTS/hello-world-$ARCH_NAME" "$OUTPUT_SUBDIR/hello-world"
        echo "✅ Binary saved to Mac: $OUTPUT_SUBDIR/hello-world"
    elif [ $BUILD_RESULT -ne 0 ]; then
        echo "❌ Build failed with exit code $BUILD_RESULT"
        exit 1
    else
        echo "❌ Binary not found in artifacts"
        exit 1
    fi

    # Show result
    if [ -f "$OUTPUT_SUBDIR/hello-world" ]; then
        echo ""
        echo "✅ $ARCH_NAME build complete!"
        echo "   Binary: $OUTPUT_SUBDIR/hello-world"
        file "$OUTPUT_SUBDIR/hello-world" | grep -o "x86-64\|aarch64"
        ls -lh "$OUTPUT_SUBDIR/hello-world"
        echo ""
    else
        echo "❌ $ARCH_NAME build failed!"
        exit 1
    fi
}

# Build based on target
case "$TARGET" in
    arm64)
        build_architecture "qemuarm64" "arm64"
        ;;
    x86-64)
        build_architecture "qemux86-64" "x86-64"
        ;;
    both)
        build_architecture "qemuarm64" "arm64"
        build_architecture "qemux86-64" "x86-64"
        ;;
    *)
        echo "❌ Invalid target: $TARGET"
        echo "Usage: $0 [arm64|x86-64|both]"
        exit 1
        ;;
esac

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              ✅ Build Complete!                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Output directory: $OUTPUT_DIR"
echo ""

# List built binaries
echo "Built binaries:"
if [ -f "$OUTPUT_DIR/hello-world" ]; then
    echo "  • x86-64:  $OUTPUT_DIR/hello-world"
fi
if [ -f "$OUTPUT_DIR/arm64/hello-world" ]; then
    echo "  • ARM64:   $OUTPUT_DIR/arm64/hello-world"
fi

echo ""
echo "To test:"
echo "  ARM64 on Mac Docker:"
echo "    docker run --rm -v $OUTPUT_DIR/arm64:/app --platform linux/arm64 ubuntu:20.04"
echo ""
echo "  x86-64 on Linux:"
echo "    scp $OUTPUT_DIR/hello-world user@linux-vm:"
echo "    ssh user@linux-vm ./hello-world"
echo ""
