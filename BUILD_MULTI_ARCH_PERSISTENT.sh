#!/bin/bash
# Build Qt5 hello-world for multiple architectures (ARM64 + x86-64)
# This version uses persistent containers to reliably extract artifacts
#
# Usage:
#   bash BUILD_MULTI_ARCH_PERSISTENT.sh [arm64|x86-64|both]
#
# Default: build both

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUTPUT_DIR="$SCRIPT_DIR/hello-world-output"

TARGET="${1:-both}"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Building Qt5 Hello World for Multiple Architectures      ║"
echo "║   (Persistent Container - Reliable Binary Extraction)      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Target: $TARGET"
echo ""

# Helper function to build for a specific architecture
build_architecture() {
    local MACHINE=$1
    local ARCH_NAME=$2
    local BUILD_DIR="$SCRIPT_DIR/build-$ARCH_NAME"
    local OUTPUT_SUBDIR="$OUTPUT_DIR"

    if [ "$ARCH_NAME" != "x86-64" ]; then
        OUTPUT_SUBDIR="$OUTPUT_DIR/$ARCH_NAME"
    fi

    echo "🔨 Building for $ARCH_NAME ($MACHINE)..."
    echo ""

    # Create build directory
    mkdir -p "$BUILD_DIR/conf"

    # Copy bblayers.conf
    cp "$SCRIPT_DIR/build/conf/bblayers.conf" "$BUILD_DIR/conf/" 2>/dev/null || true

    # Create local.conf for this architecture
    cat > "$BUILD_DIR/conf/local.conf" << EOF
MACHINE = "$MACHINE"
TMPDIR = "/tmp/yocto-build-$ARCH_NAME/tmp"
IMAGE_INSTALL:append = " hello-world"
EXTRA_IMAGE_FEATURES ?= "debug-tweaks"
USER_CLASSES ?= "buildstats"
PATCHRESOLVE = "noop"
CONF_VERSION = "2"
EOF

    # Create temporary directory for artifacts
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" RETURN

    echo "Starting build in persistent Docker container..."

    # Run build in persistent container (NO --rm flag)
    CONTAINER_ID=$(docker run -d \
        -v "$SCRIPT_DIR:/home/yocto/project" \
        -v "$TEMP_DIR:/tmp/extract" \
        yocto-qt-builder:latest \
        sleep 999)

    # Run the build commands
    docker exec -u yocto "$CONTAINER_ID" bash -c "
        set -e
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

        echo ''
        echo '✅ Build completed successfully!'
    "

    BUILD_STATUS=$?

    if [ $BUILD_STATUS -ne 0 ]; then
        echo "❌ Build failed"
        docker rm -f "$CONTAINER_ID" > /dev/null 2>&1
        exit 1
    fi

    echo ""
    echo "📦 Extracting binary from container..."

    # Find the binary in the container
    BINARY=$(docker exec "$CONTAINER_ID" bash -c "
        cd /tmp/yocto-build-$ARCH_NAME
        find tmp/work -name 'hello-world' -type f ! -name '*.so' ! -name '*.a' 2>/dev/null | head -1
    ")

    if [ -z "$BINARY" ]; then
        echo "❌ Binary not found after build"
        docker rm -f "$CONTAINER_ID" > /dev/null 2>&1
        exit 1
    fi

    echo "✅ Found: $BINARY"

    # Copy binary to temp mount point
    docker exec "$CONTAINER_ID" bash -c "
        cp /tmp/yocto-build-$ARCH_NAME/$BINARY /tmp/extract/hello-world
    "

    # Copy from temp to Mac
    if [ -f "$TEMP_DIR/hello-world" ]; then
        mkdir -p "$OUTPUT_SUBDIR"
        cp "$TEMP_DIR/hello-world" "$OUTPUT_SUBDIR/hello-world"
        chmod +x "$OUTPUT_SUBDIR/hello-world"
        echo "✅ Binary transferred to Mac"
        echo ""
        echo "File: $OUTPUT_SUBDIR/hello-world"
        file "$OUTPUT_SUBDIR/hello-world"
        ls -lh "$OUTPUT_SUBDIR/hello-world"
        echo ""
    else
        echo "❌ Failed to copy binary"
        docker rm -f "$CONTAINER_ID" > /dev/null 2>&1
        exit 1
    fi

    # Cleanup
    docker rm -f "$CONTAINER_ID" > /dev/null 2>&1
    echo "✅ Container cleaned up"
    echo ""
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
echo "║              ✅ All Builds Complete!                       ║"
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
echo "✅ Ready to test on Mac Docker or deploy to Linux!"
echo ""
