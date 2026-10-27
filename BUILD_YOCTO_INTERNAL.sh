#!/bin/bash
# Internal Yocto build script - called from BUILD_MULTI_ARCH.sh and BUILD_MULTI_ARCH_WITH_SAST.sh
#
# This script is designed to run INSIDE a Docker container and perform:
# 1. Permission setup on cache volumes
# 2. Yocto environment initialization
# 3. BitBake compilation
# 4. Binary extraction and artifact copying
#
# Environment variables (set by caller):
#   ARCH_NAME          - Target architecture (arm64, x86-64)
#   TEMP_ARTIFACTS     - Temporary directory for artifacts (on host via volume mount)

set -e
set -o pipefail

# Get arch from environment (passed by BUILD_MULTI_ARCH.sh caller)
ARCH_NAME="${1:-arm64}"
TEMP_ARTIFACTS="${2:-/tmp/artifacts}"

echo "🔧 BUILD_YOCTO_INTERNAL.sh starting..."
echo "   ARCH_NAME: $ARCH_NAME"
echo "   TEMP_ARTIFACTS: $TEMP_ARTIFACTS"
echo ""

# Ensure artifact directory exists (for both mounted and non-mounted scenarios)
mkdir -p "$TEMP_ARTIFACTS" || { echo "❌ Failed to create artifact directory: $TEMP_ARTIFACTS"; exit 1; }

# Initialize and fix permissions on Yocto TMPDIR and SSTATE cache volumes
echo "🔒 Initializing cache directories..."
sudo bash -c "
  mkdir -p /home/yocto/cache/tmp-$ARCH_NAME-glibc /home/yocto/cache/sstate-cache-$ARCH_NAME
  chown -R yocto:yocto /home/yocto/cache/tmp-$ARCH_NAME-glibc /home/yocto/cache/sstate-cache-$ARCH_NAME
  chmod -R 755 /home/yocto/cache/tmp-$ARCH_NAME-glibc /home/yocto/cache/sstate-cache-$ARCH_NAME
" 2>/dev/null || \
    { echo "⚠️  Warning: Cache initialization may have partial issues, continuing..."; }

BUILD_DIR="/home/yocto/project/build-$ARCH_NAME"
echo "📂 Build directory: $BUILD_DIR"

# Setup
echo "📋 Verifying build configuration..."
if [ ! -d "$BUILD_DIR/conf" ]; then
    echo "❌ ERROR: Build config directory not found: $BUILD_DIR/conf"
    exit 1
fi

echo "🚀 Initializing Yocto environment..."
if [ ! -f "/home/yocto/project/poky/oe-init-build-env" ]; then
    echo "❌ ERROR: oe-init-build-env not found at /home/yocto/project/poky/oe-init-build-env"
    exit 1
fi
cd "$BUILD_DIR"
source /home/yocto/project/poky/oe-init-build-env . > /dev/null 2>&1 || { echo "❌ Failed to source oe-init-build-env"; exit 1; }
TMP_ROOT="/home/yocto/cache/tmp-$ARCH_NAME-glibc"

# Verify yocto user can write to cache directories
if [ ! -w "$TMP_ROOT" ] || [ ! -w "/home/yocto/cache/sstate-cache-$ARCH_NAME" ]; then
    echo "⚠️  Cache directories not writable, attempting sudo fix..."
    sudo bash -c "
      chown -R yocto:yocto /home/yocto/cache/tmp-$ARCH_NAME-glibc /home/yocto/cache/sstate-cache-$ARCH_NAME
      chmod -R 755 /home/yocto/cache/tmp-$ARCH_NAME-glibc /home/yocto/cache/sstate-cache-$ARCH_NAME
    " 2>/dev/null || true
fi

echo "✅ Yocto environment ready"

# Show config
echo '=== Build Configuration ==='
grep '^MACHINE' conf/local.conf
echo ''

# Build
echo '=== Print Working Directory ==='
echo `pwd`
echo '=== Starting Build ==='
bitbake hello-world

BUILD_STATUS=$?
echo ''

if [ $BUILD_STATUS -eq 0 ]; then
    echo '🔍 Searching for binary in Yocto build outputs...'
    echo "Build directory: $(pwd)"

    # Yocto may append libc name to TMPDIR (e.g. tmp-glibc instead of tmp)
    # Search all tmp* directories, filter for ELF binaries (not text files)
    BINARY=""

    # Check in image directory (installed binary)
    if [ -z "$BINARY" ]; then
        for F in $(find "$TMP_ROOT/work" -path '*/image/usr/bin/hello-world' -type f 2>/dev/null); do
            if file "$F" | grep -q 'ELF'; then BINARY="$F"; break; fi
        done
    fi

    # Check in package directory
    if [ -z "$BINARY" ]; then
        for F in $(find "$TMP_ROOT/work" -path '*/package/usr/bin/hello-world' -type f 2>/dev/null); do
            if file "$F" | grep -q 'ELF'; then BINARY="$F"; break; fi
        done
    fi

    # Check in build directory
    if [ -z "$BINARY" ]; then
        for F in $(find "$TMP_ROOT/work" -path '*/build/hello-world' -type f 2>/dev/null); do
            if file "$F" | grep -q 'ELF'; then BINARY="$F"; break; fi
        done
    fi

    # Fallback: any ELF file named hello-world in the build tree
    if [ -z "$BINARY" ]; then
        for F in $(find "$TMP_ROOT" -type f -name 'hello-world' ! -name '*.so' ! -name '*.a' ! -name '*.o' ! -name '*.ipk' 2>/dev/null); do
            if file "$F" | grep -q 'ELF'; then BINARY="$F"; break; fi
        done
    fi

    if [ -n "$BINARY" ] && [ -f "$BINARY" ]; then
        echo "✅ Found binary: $BINARY"
        if cp "$BINARY" "$TEMP_ARTIFACTS/hello-world-$ARCH_NAME"; then
            echo '✅ Binary copied to artifacts'
            ls -lh "$TEMP_ARTIFACTS/hello-world-$ARCH_NAME"
        else
            echo "❌ Failed to copy binary to $TEMP_ARTIFACTS"
            exit 1
        fi
        file "$BINARY"
    else
        echo '❌ Binary not found after successful build'
        exit 1
    fi
else
    echo '❌ Build failed'
    exit 1
fi
