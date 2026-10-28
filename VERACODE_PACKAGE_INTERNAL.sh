#!/bin/bash
# Internal Veracode package script - called from BUILD_MULTI_ARCH_WITH_SAST.sh
#
# This script is designed to run INSIDE a Docker container and perform:
# 1. Verify Veracode CLI is installed
# 2. Package source code for SAST analysis
# 3. Generate timestamped log file
# 4. Optionally upload to Veracode (if credentials provided)
#
# Environment variables (set by caller or inherited):
#   VERACODE_API_ID     - Veracode API ID (for upload, optional)
#   VERACODE_API_KEY    - Veracode API Key (for upload, optional)
#   ARCH_NAME           - Target architecture (for logging, optional)
#
# Parameters:
#   $1 - Source directory to package (default: /home/yocto/project/meta-hello-qt/recipes-qt/hello-world)
#   $2 - Output directory (default: /home/yocto/project/veracode-package)

set -e
set -o pipefail

# Get parameters from caller
SOURCE_DIR="${1:-/home/yocto/project/meta-hello-qt/recipes-qt/hello-world}"
OUTPUT_DIR="${2:-/home/yocto/project/veracode-package}"
ARCH_NAME="${ARCH_NAME:-unknown}"

echo "🔐 VERACODE_PACKAGE_INTERNAL.sh starting..."
echo "   Source:  $SOURCE_DIR"
echo "   Output:  $OUTPUT_DIR"
echo "   Arch:    $ARCH_NAME"
echo ""

# Verify Veracode CLI is available
if [ ! -x /veracode ]; then
    echo "⚠️  Veracode CLI not found at /veracode"
    echo "   Skipping SAST packaging (veracode not available)"
    exit 0
fi

echo "✅ Veracode CLI found"
echo ""

# Verify source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ ERROR: Source directory not found: $SOURCE_DIR"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR" || { echo "❌ Failed to create output directory: $OUTPUT_DIR"; exit 1; }

# Create timestamped log file
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOGS_DIR="/home/yocto/project/logs"
mkdir -p "$LOGS_DIR"
PACKAGE_LOG="$LOGS_DIR/veracode-package-$TIMESTAMP.log"

echo "📦 Running veracode package..."
echo "   Log file: $PACKAGE_LOG"
echo ""

# Ensure Yocto build tools are in PATH for veracode to access
echo "🚀 Initializing Yocto environment..."
if [ ! -f "/home/yocto/project/poky/oe-init-build-env" ]; then
    echo "❌ ERROR: oe-init-build-env not found at /home/yocto/project/poky/oe-init-build-env"
    exit 1
fi

BUILD_DIR="/home/yocto/project/build-$ARCH_NAME"
if [ ! -d "$BUILD_DIR" ]; then
    echo "❌ ERROR: Build directory not found: $BUILD_DIR"
    exit 1
fi

source /home/yocto/project/poky/oe-init-build-env "$BUILD_DIR" > /dev/null 2>&1 || { echo "❌ Failed to source oe-init-build-env"; exit 1; }
cd "$BUILD_DIR" || { echo "❌ Failed to cd to build directory"; exit 1; }
TMP_ROOT="/home/yocto/cache/tmp-$ARCH_NAME-glibc"
echo "✅ Yocto environment ready (PWD: $(pwd))"

# Show config
echo '=== Build Configuration ==='
grep '^MACHINE' conf/local.conf
echo ''

# Build
echo '=== Starting Veracode Package ==='

# Run veracode package with full output to log
# /veracode will discover and use Yocto build environment from source directory
if /veracode package \
    --source "$SOURCE_DIR" \
    --type directory \
    -o "$OUTPUT_DIR" \
    --trust \
    --verbose 2>&1 | tee "$PACKAGE_LOG"; then

    PACKAGE_RESULT=$?
    echo ""
    echo "✅ Veracode package completed successfully"
    echo "   Log: $PACKAGE_LOG"

    # Check if upload credentials are available
    if [ -n "$VERACODE_API_ID" ] && [ -n "$VERACODE_API_KEY" ]; then
        echo ""
        echo "📤 Credentials detected, ready for upload"
        echo "   Run: veracode scan upload --file <app.zip> inside this container"
    else
        echo ""
        echo "ℹ️  No Veracode credentials (VERACODE_API_ID/KEY)"
        echo "   Packaging complete but upload not available"
    fi
else
    PACKAGE_RESULT=$?
    echo ""
    echo "⚠️  Veracode package failed (exit code: $PACKAGE_RESULT)"
    echo "   Log: $PACKAGE_LOG"
    exit $PACKAGE_RESULT
fi
