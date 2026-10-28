#!/bin/bash
# Build Qt5 hello-world for multiple architectures (ARM64 + x86-64)
#
# Usage:
#   bash BUILD_MULTI_ARCH.sh [arm64|x86-64|both]
#
# Optional environment variables:
#   USE_PERSISTENT_CONTAINER - Set to 1 to use persistent CONTAINER_MANAGER containers
#
# Default: build both architectures, using ephemeral containers

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUTPUT_DIR="$SCRIPT_DIR/hello-world-output"

# Persistent cache directories (separate per architecture for efficiency)
YOCTO_CACHE_DIR="$SCRIPT_DIR/.yocto-cache"
YOCTO_DL_DIR="$YOCTO_CACHE_DIR/downloads"

TARGET="${1:-both}"

# Persistent container mode (optional, default is ephemeral)
USE_PERSISTENT_CONTAINER="${USE_PERSISTENT_CONTAINER:-0}"

# Create cache and output directories
mkdir -p "$YOCTO_DL_DIR" "$OUTPUT_DIR"

# Pre-create architecture-specific cache directories
for arch in arm64 x86-64; do
    mkdir -p "$YOCTO_CACHE_DIR/sstate-cache-$arch"
done

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Building Qt5 Hello World for Multiple Architectures      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Target: $TARGET"
if [ "$USE_PERSISTENT_CONTAINER" = "1" ]; then
    echo "Mode: Persistent containers (via CONTAINER_MANAGER)"
else
    echo "Mode: Ephemeral containers (default)"
fi
echo ""

# Helper function to check if persistent container is running
check_persistent_container() {
    local arch=$1
    local container_name="yocto-builder-$arch"
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        return 0  # Container is running
    else
        return 1  # Container is not running
    fi
}

# Helper function to build for a specific architecture
build_and_package() {
    local MACHINE=$1
    local ARCH_NAME=$2
    local BUILD_DIR="$SCRIPT_DIR/build-$ARCH_NAME"
    local YOCTO_TMP_VOLUME="yocto-tmp-$ARCH_NAME"
    local OUTPUT_SUBDIR="$OUTPUT_DIR/$ARCH_NAME"

    # Use architecture-specific Docker image
    DOCKER_IMAGE="yocto-qt-builder:$ARCH_NAME"

    # Architecture-specific sstate cache to avoid cache invalidation on arch switches
    local YOCTO_SSTATE_DIR="$YOCTO_CACHE_DIR/sstate-cache-$ARCH_NAME"
    mkdir -p "$YOCTO_SSTATE_DIR"

    local ARCH_START_TIME=$(date +%s)
    local ARCH_START_DISPLAY=$(date "+%H:%M:%S")

    echo "🔨 Building for $ARCH_NAME ($MACHINE)..."
    echo "   Start: $ARCH_START_DISPLAY"
    echo ""

    # Create build directory
    mkdir -p "$BUILD_DIR/conf"
    docker volume create "$YOCTO_TMP_VOLUME" >/dev/null 2>&1 || true

    # Pre-initialize cache volumes with proper permissions (ephemeral or persistent container)
    CONTAINER_NAME="yocto-builder-$ARCH_NAME"
    if [ "$USE_PERSISTENT_CONTAINER" = "1" ] && check_persistent_container "$ARCH_NAME"; then
        echo "   📦 Fixing cache permissions in persistent container: $CONTAINER_NAME"
        docker exec "$CONTAINER_NAME" sudo bash -c "chown -R yocto:yocto /home/yocto/cache/tmp-$ARCH_NAME-glibc /home/yocto/cache/sstate-cache-$ARCH_NAME 2>/dev/null && \
                                                     chmod -R 755 /home/yocto/cache/tmp-$ARCH_NAME-glibc /home/yocto/cache/sstate-cache-$ARCH_NAME 2>/dev/null" || true
    else
        # For ephemeral: fix permissions on both cache volumes (already exist as mount points)
        docker run --rm --user root \
            --mount "type=volume,source=$YOCTO_TMP_VOLUME,target=/home/yocto/cache/tmp-$ARCH_NAME-glibc,volume-nocopy" \
            -v "$YOCTO_SSTATE_DIR:/home/yocto/cache/sstate-cache-$ARCH_NAME" \
            "$DOCKER_IMAGE" \
            bash -c "chown -R yocto:yocto /home/yocto/cache/tmp-$ARCH_NAME-glibc /home/yocto/cache/sstate-cache-$ARCH_NAME && \
                     chmod -R 755 /home/yocto/cache/tmp-$ARCH_NAME-glibc /home/yocto/cache/sstate-cache-$ARCH_NAME"
    fi

    # Copy bblayers.conf
    cp "$SCRIPT_DIR/build/conf/bblayers.conf" "$BUILD_DIR/conf/" 2>/dev/null || \
        echo "⚠️  Warning: bblayers.conf not found, will create in container"

    # Create local.conf for this architecture with architecture-specific sstate cache
    # Note: Yocto will append -glibc to TMPDIR automatically
    cat > "$BUILD_DIR/conf/local.conf" << EOF
MACHINE = "$MACHINE"
TMPDIR = "/home/yocto/cache/tmp-$ARCH_NAME"
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

    # Run build in Docker (ephemeral or persistent container)
    # Determine container execution method
    if [ "$USE_PERSISTENT_CONTAINER" = "1" ] && check_persistent_container "$ARCH_NAME"; then
        echo "📦 Using persistent container: $CONTAINER_NAME"
        # For persistent containers, artifacts go to /tmp/artifacts in container, then copy to host
        docker exec "$CONTAINER_NAME" mkdir -p /tmp/artifacts
        docker exec "$CONTAINER_NAME" \
            bash /home/yocto/project/BUILD_YOCTO_INTERNAL.sh "$ARCH_NAME" "/tmp/artifacts"
        BUILD_RESULT=$?

        # Copy artifacts from container to host temp directory
        if [ $BUILD_RESULT -eq 0 ]; then
            docker cp "$CONTAINER_NAME:/tmp/artifacts/hello-world-$ARCH_NAME" "$TEMP_ARTIFACTS/" 2>/dev/null || true
        fi
    else
        # Ephemeral container (default)
        docker run --rm \
            -m 14g \
            --memory-swap 16g \
            -v "$SCRIPT_DIR:/home/yocto/project" \
            -v "$YOCTO_DL_DIR:/home/yocto/cache/downloads" \
            -v "$YOCTO_SSTATE_DIR:/home/yocto/cache/sstate-cache-$ARCH_NAME" \
            --mount "type=volume,source=$YOCTO_TMP_VOLUME,target=/home/yocto/cache/tmp-$ARCH_NAME-glibc,volume-nocopy" \
            -v "$TEMP_ARTIFACTS:/tmp/artifacts" \
            "$DOCKER_IMAGE" \
            bash /home/yocto/project/BUILD_YOCTO_INTERNAL.sh "$ARCH_NAME" "/tmp/artifacts"
        BUILD_RESULT=$?

        # Debug: show what's in the temp artifacts directory
        echo "   Debug: Checking artifacts directory: $TEMP_ARTIFACTS"
        ls -lah "$TEMP_ARTIFACTS/" 2>&1 | head -20
    fi

    if [ $BUILD_RESULT -eq 0 ]; then
        # Verify artifact file exists
        if [ -f "$TEMP_ARTIFACTS/hello-world-$ARCH_NAME" ]; then
            mkdir -p "$OUTPUT_SUBDIR"
            cp "$TEMP_ARTIFACTS/hello-world-$ARCH_NAME" "$OUTPUT_SUBDIR/hello-world"
            echo "✅ Binary saved to: $OUTPUT_SUBDIR/hello-world"
        else
            echo "❌ Binary not found in artifacts: $TEMP_ARTIFACTS/hello-world-$ARCH_NAME"
            echo "   Build succeeded but artifact transfer failed"
            exit 1
        fi
    else
        echo "❌ Build failed with exit code $BUILD_RESULT"
        exit 1
    fi

    echo ""

    # Timing
    local ARCH_END_TIME=$(date +%s)
    local ARCH_END_DISPLAY=$(date "+%H:%M:%S")
    local ARCH_ELAPSED=$((ARCH_END_TIME - ARCH_START_TIME))
    local ARCH_ELAPSED_MIN=$((ARCH_ELAPSED / 60))

    echo "✅ $ARCH_NAME build completed"
    echo "   End: $ARCH_END_DISPLAY"
    echo "   Duration: ${ARCH_ELAPSED_MIN}m$((ARCH_ELAPSED % 60))s"
    echo ""
}

# Build based on target
case "$TARGET" in
    arm64)
        build_and_package "qemuarm64" "arm64"
        ;;
    x86-64)
        build_and_package "qemux86-64" "x86-64"
        ;;
    both)
        build_and_package "qemuarm64" "arm64"
        build_and_package "qemux86-64" "x86-64"
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
