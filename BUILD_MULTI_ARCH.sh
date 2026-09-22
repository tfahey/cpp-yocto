#!/bin/bash
# Build Qt5 hello-world for multiple architectures (ARM64 + x86-64)
#
# Usage:
#   bash BUILD_MULTI_ARCH.sh [arm64|x86-64|both]
#
# Default: build both

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUTPUT_DIR="$SCRIPT_DIR/hello-world-output"

# Persistent cache directories on the host (survive across builds)
YOCTO_DL_DIR="$SCRIPT_DIR/.yocto-cache/downloads"
YOCTO_SSTATE_DIR="$SCRIPT_DIR/.yocto-cache/sstate-cache"

mkdir -p "$YOCTO_DL_DIR" "$YOCTO_SSTATE_DIR"

TARGET="${1:-both}"

# Track timing - BEFORE set -e so we can always print this
START_TIME=$(date +%s)
START_DISPLAY=$(date "+%Y-%m-%d %H:%M:%S")

# Set error flag after capturing start time, so we still exit on errors
set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Building Qt5 Hello World for Multiple Architectures      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Target: $TARGET"
echo "Start time: $START_DISPLAY"
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

    local ARCH_START_TIME=$(date +%s)
    local ARCH_START_DISPLAY=$(date "+%H:%M:%S")

    echo "🔨 Building for $ARCH_NAME ($MACHINE)..."
    echo "   Start: $ARCH_START_DISPLAY"
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

# Persistent cache directories (mounted from host)
DL_DIR = "/home/yocto/cache/downloads"
SSTATE_DIR = "/home/yocto/cache/sstate-cache"

# Memory optimization for Docker builds
# Limit parallel jobs to prevent OOM during GCC compilation
BB_NUMBER_THREADS = "2"
PARALLEL_MAKE = "-j 2"

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

    # Run build in Docker (interactive mode to see output, wait for completion)
    # Allocate 7GB memory and 2GB swap to prevent OOM kills during GCC compilation
    # Mount persistent cache volumes to speed up subsequent builds
    docker run --rm \
        -m 7g \
        --memory-swap 9g \
        -v "$SCRIPT_DIR:/home/yocto/project" \
        -v "$TEMP_ARTIFACTS:/tmp/artifacts" \
        -v "$YOCTO_DL_DIR:/home/yocto/cache/downloads" \
        -v "$YOCTO_SSTATE_DIR:/home/yocto/cache/sstate-cache" \
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
                echo \"Build directory: \$(pwd)\"

                # Yocto may append libc name to TMPDIR (e.g. tmp-glibc instead of tmp)
                # Search all tmp* directories, filter for ELF binaries (not text files)
                BINARY=\"\"

                # Check in image directory (installed binary)
                if [ -z \"\$BINARY\" ]; then
                    for F in \$(find tmp*/work -path '*/image/usr/bin/hello-world' -type f 2>/dev/null); do
                        if file \"\$F\" | grep -q 'ELF'; then BINARY=\"\$F\"; break; fi
                    done
                fi

                # Check in package directory
                if [ -z \"\$BINARY\" ]; then
                    for F in \$(find tmp*/work -path '*/package/usr/bin/hello-world' -type f 2>/dev/null); do
                        if file \"\$F\" | grep -q 'ELF'; then BINARY=\"\$F\"; break; fi
                    done
                fi

                # Check in build directory
                if [ -z \"\$BINARY\" ]; then
                    for F in \$(find tmp*/work -path '*/build/hello-world' -type f 2>/dev/null); do
                        if file \"\$F\" | grep -q 'ELF'; then BINARY=\"\$F\"; break; fi
                    done
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
                        # IPK data archive can be .tar.gz, .tar.xz, or .tar.zst
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

                    # Generate preprocessed source files for Veracode analysis
                    echo ''
                    echo '🔨 Generating preprocessed source files (.i)...'

                    # Find Qt5 include path from the Yocto build sysroot
                    QT_INC=\"\"
                    for CANDIDATE in \$(find tmp* -path '*/recipe-sysroot/usr/include/qt5' -type d 2>/dev/null) \
                                     \$(find tmp* -path '*/sysroots/*/usr/include/qt5' -type d 2>/dev/null) \
                                     \$(find tmp* -path '*/include/qt5' -type d 2>/dev/null); do
                        if [ -f \"\$CANDIDATE/QtCore/QObject\" ] || [ -f \"\$CANDIDATE/QtCore/qobject.h\" ]; then
                            QT_INC=\"\$CANDIDATE\"
                            break
                        fi
                    done

                    cd /home/yocto/project/preprocessed-src/sources

                    if [ -n \"\$QT_INC\" ]; then
                        echo \"Using Qt5 headers from: \$QT_INC\"

                        g++ -E -I. \
                            -I\$QT_INC \
                            -I\$QT_INC/QtCore \
                            -I\$QT_INC/QtGui \
                            -I\$QT_INC/QtWidgets \
                            -dD main.cpp > main.i 2>/dev/null && echo '✅ Generated main.i' || echo '⚠️  Failed to preprocess main.cpp'

                        g++ -E -I. \
                            -I\$QT_INC \
                            -I\$QT_INC/QtCore \
                            -I\$QT_INC/QtGui \
                            -I\$QT_INC/QtWidgets \
                            -dD mainwindow.cpp > mainwindow.i 2>/dev/null && echo '✅ Generated mainwindow.i' || echo '⚠️  Failed to preprocess mainwindow.cpp'
                    else
                        echo '⚠️  Qt5 headers not found in Yocto sysroot'
                        echo '    Installing Qt5 dev headers...'
                        sudo apt-get update -qq && sudo apt-get install -y -qq qtbase5-dev > /dev/null 2>&1

                        g++ -E -I. \
                            -I/usr/include/x86_64-linux-gnu/qt5 \
                            -I/usr/include/x86_64-linux-gnu/qt5/QtCore \
                            -I/usr/include/x86_64-linux-gnu/qt5/QtGui \
                            -I/usr/include/x86_64-linux-gnu/qt5/QtWidgets \
                            -dD main.cpp > main.i 2>/dev/null && echo '✅ Generated main.i' || echo '⚠️  Failed to preprocess main.cpp'

                        g++ -E -I. \
                            -I/usr/include/x86_64-linux-gnu/qt5 \
                            -I/usr/include/x86_64-linux-gnu/qt5/QtCore \
                            -I/usr/include/x86_64-linux-gnu/qt5/QtGui \
                            -I/usr/include/x86_64-linux-gnu/qt5/QtWidgets \
                            -dD mainwindow.cpp > mainwindow.i 2>/dev/null && echo '✅ Generated mainwindow.i' || echo '⚠️  Failed to preprocess mainwindow.cpp'
                    fi

                    ls -lh *.i 2>/dev/null
                    echo '✅ Preprocessed files ready for Veracode'
                else
                    echo '❌ Binary not found after successful build'
                    echo \"\"
                    echo \"Listing all tmp* directories:\"
                    ls -d tmp* 2>/dev/null

                    echo \"\"
                    echo \"All hello-world files in build tree:\"
                    find tmp* -name '*hello-world*' -type f 2>/dev/null | head -30

                    echo \"\"
                    echo \"Recipe work directories:\"
                    find tmp* -type d -name 'hello-world*' 2>/dev/null

                    echo \"\"
                    echo \"IPK packages:\"
                    find tmp* -name 'hello-world*.ipk' 2>/dev/null

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

    # Show result with timing
    local ARCH_END_TIME=$(date +%s)
    local ARCH_END_DISPLAY=$(date "+%H:%M:%S")
    local ARCH_DURATION=$((ARCH_END_TIME - ARCH_START_TIME))
    local ARCH_MINUTES=$((ARCH_DURATION / 60))
    local ARCH_SECONDS=$((ARCH_DURATION % 60))

    if [ -f "$OUTPUT_SUBDIR/hello-world" ]; then
        echo ""
        echo "✅ $ARCH_NAME build complete!"
        echo "   Binary: $OUTPUT_SUBDIR/hello-world"
        echo "   End: $ARCH_END_DISPLAY"
        echo "   Duration: ${ARCH_MINUTES}m ${ARCH_SECONDS}s"
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

set +e  # Disable error exit so we can always print summary

echo ""

# Calculate total elapsed time
END_TIME=$(date +%s)
END_DISPLAY=$(date "+%Y-%m-%d %H:%M:%S")
TOTAL_DURATION=$((END_TIME - START_TIME))
TOTAL_MINUTES=$((TOTAL_DURATION / 60))
TOTAL_SECONDS=$((TOTAL_DURATION % 60))

# Check if build succeeded
BUILD_SUCCESS=0
if [ -f "$OUTPUT_DIR/hello-world" ] || [ -f "$OUTPUT_DIR/arm64/hello-world" ]; then
    BUILD_SUCCESS=1
fi

if [ $BUILD_SUCCESS -eq 1 ]; then
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              ✅ Build Complete!                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
else
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              ❌ Build Failed                               ║"
    echo "╚════════════════════════════════════════════════════════════╝"
fi

echo ""
echo "Timeline:"
echo "  Start:    $START_DISPLAY"
echo "  End:      $END_DISPLAY"
echo "  Duration: ${TOTAL_MINUTES}m ${TOTAL_SECONDS}s"
echo ""
echo "Output directory: $OUTPUT_DIR"
echo ""

# List built binaries
if [ $BUILD_SUCCESS -eq 1 ]; then
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
else
    echo "No binaries found in output directory."
    echo "Check the build log above for errors."
    echo ""
fi
