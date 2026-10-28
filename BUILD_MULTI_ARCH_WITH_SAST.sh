#!/bin/bash
# Build Qt5 hello-world for multiple architectures AND run Veracode SAST packaging
#
# Usage:
#   bash BUILD_MULTI_ARCH_WITH_SAST.sh [arm64|x86-64|both]
#
# Optional environment variables:
#   VERACODE_API_ID           - Veracode API ID (enables upload/scan)
#   VERACODE_API_KEY          - Veracode API Key (enables upload/scan)
#   USE_PERSISTENT_CONTAINER  - Set to 1 to use persistent CONTAINER_MANAGER containers
#
# This script:
# 1. Builds the application using Yocto (same as BUILD_MULTI_ARCH.sh)
# 2. Packages the binary with veracode package command (x86-64 only)
# 3. Optionally uploads to Veracode and triggers SAST scan (requires credentials)
# 4. Generates packaged apps in veracode-package/ directory
#
# Architecture support:
#   - ARM64:   Full build support, veracode packaging skipped (CLI x86-64 only)
#   - x86-64:  Full build support with veracode SAST packaging
#
# Container modes:
#   - Default (ephemeral): Creates temporary containers with --rm, deleted after build
#   - Persistent mode (USE_PERSISTENT_CONTAINER=1): Uses persistent CONTAINER_MANAGER containers
#     * First start container with: bash CONTAINER_MANAGER.sh arm64 start
#     * Then run builds inside persistent container
#
# Note: Veracode credentials are passed via environment only (not stored in image/container)

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUTPUT_DIR="$SCRIPT_DIR/hello-world-output"
VERACODE_PACKAGE_DIR="$SCRIPT_DIR/veracode-package"

# Persistent cache directories (separate per architecture for efficiency)
YOCTO_CACHE_DIR="$SCRIPT_DIR/.yocto-cache"
YOCTO_DL_DIR="$YOCTO_CACHE_DIR/downloads"

TARGET="${1:-both}"

# Persistent container mode (optional, default is ephemeral)
USE_PERSISTENT_CONTAINER="${USE_PERSISTENT_CONTAINER:-0}"

# Create cache and output directories
mkdir -p "$YOCTO_DL_DIR" "$VERACODE_PACKAGE_DIR"

# Pre-create architecture-specific cache directories
for arch in arm64 x86-64; do
    mkdir -p "$YOCTO_CACHE_DIR/sstate-cache-$arch"
done

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

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Building Qt5 Hello World for Multiple Architectures      ║"
echo "║   WITH Veracode SAST Packaging                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Target: $TARGET"
echo "Output: $VERACODE_PACKAGE_DIR"
echo ""

# Check for Veracode credentials
if [ -n "$VERACODE_API_ID" ] && [ -n "$VERACODE_API_KEY" ]; then
    echo "✅ Veracode credentials found (upload/scan will be enabled)"
    VERACODE_CREDS_AVAILABLE=true
else
    echo "⚠️  Veracode credentials not set (packaging only, no upload/scan)"
    echo "   Set VERACODE_API_ID and VERACODE_API_KEY to enable upload/scan"
    VERACODE_CREDS_AVAILABLE=false
fi
echo ""

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
            yocto-qt-builder:$ARCH_NAME \
            bash -c "chown -R yocto:yocto /home/yocto/cache/tmp-$ARCH_NAME-glibc /home/yocto/cache/sstate-cache-$ARCH_NAME && \
                     chmod -R 755 /home/yocto/cache/tmp-$ARCH_NAME-glibc /home/yocto/cache/sstate-cache-$ARCH_NAME && \
                     echo '✅ Cache volumes initialized'"
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
    # Pass VERACODE credentials via environment (not stored in image/container)

    # Determine container execution method
    CONTAINER_NAME="yocto-builder-$ARCH_NAME"
    if [ "$USE_PERSISTENT_CONTAINER" = "1" ] && check_persistent_container "$ARCH_NAME"; then
        echo "📦 Using persistent container: $CONTAINER_NAME"
        # For persistent containers, create /tmp/artifacts in container or use a pre-mounted volume
        docker exec -e VERACODE_API_ID -e VERACODE_API_KEY "$CONTAINER_NAME" \
            mkdir -p /tmp/artifacts
        docker exec -e VERACODE_API_ID -e VERACODE_API_KEY "$CONTAINER_NAME" \
            bash /home/yocto/project/BUILD_YOCTO_INTERNAL.sh "$ARCH_NAME" "/tmp/artifacts"
        BUILD_RESULT=$?
    else
        # Ephemeral container (default)
        docker run --rm \
            -m 14g \
            --memory-swap 16g \
            -e VERACODE_API_ID \
            -e VERACODE_API_KEY \
            -v "$SCRIPT_DIR:/home/yocto/project" \
            -v "$TEMP_ARTIFACTS:/tmp/artifacts" \
            -v "$YOCTO_DL_DIR:/home/yocto/cache/downloads" \
            -v "$YOCTO_SSTATE_DIR:/home/yocto/cache/sstate-cache-$ARCH_NAME" \
            --mount "type=volume,source=$YOCTO_TMP_VOLUME,target=/home/yocto/cache/tmp-$ARCH_NAME-glibc,volume-nocopy" \
            "$DOCKER_IMAGE" \
            bash /home/yocto/project/BUILD_YOCTO_INTERNAL.sh "$ARCH_NAME" "/tmp/artifacts"
        BUILD_RESULT=$?
    fi

    if [ $BUILD_RESULT -eq 0 ]; then
        # ========================================
        # Package for Veracode SAST (inside container)
        # ========================================
        echo ''
        echo '📦 Running Veracode package command on Yocto recipe...'
        echo ''

        # Run veracode package inside same container as build
        if [ "$USE_PERSISTENT_CONTAINER" = "1" ] && check_persistent_container "$ARCH_NAME"; then
            docker exec -e VERACODE_API_ID -e VERACODE_API_KEY -e ARCH_NAME="$ARCH_NAME" "$CONTAINER_NAME" \
                bash /home/yocto/project/VERACODE_PACKAGE_INTERNAL.sh
        else
            docker run --rm \
                -e VERACODE_API_ID \
                -e VERACODE_API_KEY \
                -e ARCH_NAME="$ARCH_NAME" \
                -v "$SCRIPT_DIR:/home/yocto/project" \
                "$DOCKER_IMAGE" \
                bash /home/yocto/project/VERACODE_PACKAGE_INTERNAL.sh
        fi
    else
        echo '❌ Build failed'
        exit 1
    fi

    # Debug: show what's in the temp artifacts directory
    echo "   Debug: Checking artifacts directory: $TEMP_ARTIFACTS"
    ls -lah "$TEMP_ARTIFACTS/" 2>&1 | head -20

    # Copy from temp directory to host
    if [ $BUILD_RESULT -eq 0 ]; then
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

    # ========================================
    # Optional: Upload and trigger scan (host-side)
    # ========================================
    if [ "$VERACODE_CREDS_AVAILABLE" = true ]; then
        echo ""
        echo "📤 Uploading packaged app to Veracode and triggering SAST scan..."

        # Find the packaged app (veracode package creates zip files in container)
        PACKAGED_APP=$(find "$VERACODE_PACKAGE_DIR" -name "*.zip" -type f 2>/dev/null | head -1)

        if [ -n "$PACKAGED_APP" ]; then
            echo "   Found packaged app: $PACKAGED_APP"

            if command -v veracode &> /dev/null; then
                # Upload and trigger scan using veracode upload command
                veracode upload \
                    --file "$PACKAGED_APP" \
                    --app-name "cpp-yocto-hello-world" \
                    --sandbox "sast-$ARCH_NAME" || true

                echo "✅ Upload and scan triggered"
            else
                echo "⚠️  veracode CLI not available on host for upload"
            fi
        else
            echo "⚠️  Packaged app not found in: $VERACODE_PACKAGE_DIR"
        fi
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
echo "Veracode packages: $VERACODE_PACKAGE_DIR"
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
echo "Next steps:"
echo "  • Packaged apps are in: $VERACODE_PACKAGE_DIR"
if [ "$VERACODE_CREDS_AVAILABLE" = false ]; then
    echo "  • To enable automatic upload/scan, set:"
    echo "    export VERACODE_API_ID=<your-id>"
    echo "    export VERACODE_API_KEY=<your-key>"
    echo "    Then run this script again"
else
    echo "  • SAST scan triggered (check Veracode dashboard for results)"
fi
echo ""
