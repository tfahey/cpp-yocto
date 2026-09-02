#!/bin/bash
# Build Qt5 Hello World application with Yocto
#
# Usage:
#   bash BUILD_HELLO_WORLD.sh
#
# This script:
# - Runs BitBake in Docker with build dir inside container (avoids socket issues)
# - Shows build progress
# - Copies binary to host if successful

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR_HOST="$SCRIPT_DIR/build"
OUTPUT_DIR="$SCRIPT_DIR/hello-world-output"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Building Hello World Qt5 Application with Yocto          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "Starting build in Docker container..."
echo "Location: /tmp/yocto-build (inside container)"
echo ""

# Create a temporary directory for build artifacts
TEMP_BUILD=$(mktemp -d)
trap "rm -rf $TEMP_BUILD" EXIT

# Run bitbake in Docker with build dir inside container
docker run --rm \
  -v "$SCRIPT_DIR:/home/yocto/project" \
  -v "$TEMP_BUILD:/tmp/artifacts" \
  yocto-qt-builder:latest \
  bash -c "
    # Create build dir inside container (avoids socket binding issues)
    cd /tmp
    mkdir -p yocto-build
    cd yocto-build

    # Copy config from mounted volume
    cp -r /home/yocto/project/build/conf .

    # Initialize Yocto environment
    source /home/yocto/project/poky/oe-init-build-env . > /dev/null 2>&1

    # Show build configuration
    echo '=== Build Configuration ==='
    bitbake -e hello-world 2>&1 | head -40 | grep -E 'MACHINE|DISTRO|meta|0 errors'
    echo ''

    # Run the build
    echo '=== Starting Build ==='
    bitbake hello-world 2>&1

    # If successful, copy binary to Mac host
    if [ \$? -eq 0 ]; then
      echo ''
      echo '=== Build Successful! Copying binary to Mac host... ==='
      echo ''

      BINARY_PATH=\$(find tmp/work -name 'hello-world' -type f 2>/dev/null | grep -v '\.so' | head -1)
      if [ -f \"\$BINARY_PATH\" ]; then
        echo \"Found binary: \$BINARY_PATH\"
        cp \"\$BINARY_PATH\" /tmp/artifacts/hello-world
        echo \"✅ Binary copied to Mac host\"
      else
        echo '❌ Could not find hello-world binary'
        exit 1
      fi
    else
      echo ''
      echo '❌ Build failed!'
      exit 1
    fi
  "

if [ $? -eq 0 ] && [ -f "$TEMP_BUILD/hello-world" ]; then
  echo ""
  echo "✅ Build completed successfully!"
  echo ""
  echo "Binary copied to: $OUTPUT_DIR/hello-world"
  cp "$TEMP_BUILD/hello-world" "$OUTPUT_DIR/hello-world"

  # Show file info
  echo ""
  echo "File details:"
  file "$OUTPUT_DIR/hello-world"
  ls -lh "$OUTPUT_DIR/hello-world"
  echo ""
  echo "To test the binary:"
  echo "  file $OUTPUT_DIR/hello-world        # Check binary type"
  echo "  strings $OUTPUT_DIR/hello-world | grep Qt  # Verify Qt5 linking"
else
  echo "❌ Build failed or binary not found"
  exit 1
fi
