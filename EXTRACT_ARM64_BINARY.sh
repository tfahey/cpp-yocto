#!/bin/bash
# Extract ARM64 binary directly from Docker build
# This keeps a persistent container running to copy the binary

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUTPUT_DIR="$SCRIPT_DIR/hello-world-output"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Extracting ARM64 Binary from Docker Build                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Start a persistent container (don't use --rm)
CONTAINER_ID=$(docker run -d \
    -v "$SCRIPT_DIR:/home/yocto/project" \
    yocto-qt-builder:latest \
    sleep 999)

echo "Started container: $CONTAINER_ID"
echo ""

# Clean up on exit
cleanup() {
    echo "Cleaning up container..."
    docker rm -f "$CONTAINER_ID" > /dev/null 2>&1 || true
}
trap cleanup EXIT

# Run the build
echo "Building ARM64 version..."
docker exec -u yocto "$CONTAINER_ID" bash -c "
    cd /tmp
    mkdir -p yocto-build-arm64
    cd yocto-build-arm64

    # Setup
    cp -r /home/yocto/project/build-arm64/conf .
    source /home/yocto/project/poky/oe-init-build-env . > /dev/null 2>&1

    # Build
    bitbake hello-world 2>&1 | tail -20

    # Find and copy binary
    echo ''
    echo '🔍 Searching for binary in work directory...'

    find tmp/work -type d -name 'hello-world' | while read dir; do
        if [ -f \"\$dir/0.1/image/usr/bin/hello-world\" ]; then
            echo \"✅ Found at: \$dir/0.1/image/usr/bin/hello-world\"
            mkdir -p /tmp/arm64-output
            cp \"\$dir/0.1/image/usr/bin/hello-world\" /tmp/arm64-output/
        fi
    done
" || { echo "Build failed"; exit 1; }

# Copy from container to Mac
echo ""
echo "📦 Copying binary from container to Mac..."
docker cp "$CONTAINER_ID:/tmp/arm64-output/hello-world" "$OUTPUT_DIR/arm64/hello-world" 2>/dev/null || {
    echo "❌ Failed to copy binary"
    exit 1
}

# Verify
if [ -f "$OUTPUT_DIR/arm64/hello-world" ]; then
    echo "✅ ARM64 binary successfully extracted!"
    echo ""
    echo "File: $OUTPUT_DIR/arm64/hello-world"
    file "$OUTPUT_DIR/arm64/hello-world"
    ls -lh "$OUTPUT_DIR/arm64/hello-world"
    echo ""
else
    echo "❌ Binary not found at output location"
    exit 1
fi
