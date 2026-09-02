#!/bin/bash

# Verification script for Yocto + Qt setup
# Run this from inside Docker container in the build directory

echo "================================"
echo "Yocto + Qt Setup Verification"
echo "================================"
echo

# Check if we're in the build directory
if [ ! -f "conf/local.conf" ]; then
    echo "❌ Error: Not in build directory!"
    echo
    echo "This script must be run from the build directory."
    echo "Expected: /home/yocto/project/build"
    echo "Current: $(pwd)"
    echo
    echo "Fix:"
    echo "  1. cd /home/yocto/project/build"
    echo "  2. Source environment: source ../poky/oe-init-build-env ."
    echo "  3. Run this script again"
    echo
    exit 1
fi

# Check if BitBake environment is initialized
if ! command -v bitbake &> /dev/null; then
    echo "⚠️  BitBake environment not initialized"
    echo
    echo "Attempting to source oe-init-build-env..."
    if [ -f "../poky/oe-init-build-env" ]; then
        source ../poky/oe-init-build-env . > /dev/null 2>&1
        if command -v bitbake &> /dev/null; then
            echo "✓ BitBake environment initialized successfully"
        else
            echo "❌ Failed to initialize BitBake environment"
            echo
            echo "Try manually:"
            echo "  cd /home/yocto/project/build"
            echo "  source ../poky/oe-init-build-env ."
            echo
            exit 1
        fi
    else
        echo "❌ Could not find oe-init-build-env"
        echo
        echo "Fix:"
        echo "  1. Ensure Poky is cloned: /home/yocto/project/poky/"
        echo "  2. Run: source ../poky/oe-init-build-env ."
        echo "  3. Run this script again"
        echo
        exit 1
    fi
fi

echo

# 1. Check files exist
echo "1. Checking source files..."
FILES_DIR="/home/yocto/project/meta-hello-qt/recipes-qt/hello-world/hello-world-0.1"

if [ -d "$FILES_DIR" ]; then
    echo "✓ Source directory exists: $FILES_DIR"

    for file in CMakeLists.txt main.cpp mainwindow.h mainwindow.cpp; do
        if [ -f "$FILES_DIR/$file" ]; then
            echo "  ✓ $file found"
        else
            echo "  ✗ $file missing!"
        fi
    done
else
    echo "✗ Source directory not found: $FILES_DIR"
    exit 1
fi
echo

# 2. Check locale
echo "2. Checking locale..."
LANG_CHECK=$(locale | grep "LANG=en_US.UTF-8")
if [ -n "$LANG_CHECK" ]; then
    echo "✓ Locale set to en_US.UTF-8"
else
    echo "✗ Locale not set to en_US.UTF-8"
    echo "  Run: export LANG=en_US.UTF-8"
fi
echo

# 3. Check layer
echo "3. Checking Yocto layer..."
if bitbake-layers show-layers | grep -q "meta-hello-qt"; then
    echo "✓ meta-hello-qt layer registered"
else
    echo "✗ meta-hello-qt layer not found in BBLAYERS"
    echo "  Add to conf/bblayers.conf: /home/yocto/project/meta-hello-qt"
    exit 1
fi
echo

# 4. Check recipe
echo "4. Checking BitBake recipe..."
if bitbake-layers show-recipes | grep -q "^hello-world"; then
    echo "✓ hello-world recipe found"
else
    echo "✗ hello-world recipe not found"
    exit 1
fi
echo

# 5. Check configuration
echo "5. Checking build configuration..."
if [ -f "conf/local.conf" ]; then
    echo "✓ conf/local.conf exists"

    if grep -q "^MACHINE = " conf/local.conf; then
        MACHINE=$(grep "^MACHINE = " conf/local.conf)
        echo "  ✓ $MACHINE"
    else
        echo "  ✗ MACHINE not set"
    fi

    if grep -q "IMAGE_INSTALL:append.*hello-world" conf/local.conf; then
        echo "  ✓ hello-world in IMAGE_INSTALL"
    else
        echo "  ✗ hello-world not in IMAGE_INSTALL"
    fi
else
    echo "✗ conf/local.conf not found"
    exit 1
fi
echo

# 6. Check BitBake can parse recipe
echo "6. Checking BitBake recipe parsing..."
if bitbake -e hello-world > /dev/null 2>&1; then
    echo "✓ BitBake can parse hello-world recipe"
else
    echo "✗ BitBake parse error (see below):"
    bitbake -e hello-world 2>&1 | grep -i error | head -3
    exit 1
fi
echo

# 7. Check if can fetch
echo "7. Checking BitBake fetch..."
if bitbake -c fetch hello-world > /dev/null 2>&1; then
    echo "✓ BitBake can fetch sources"
else
    echo "⚠ BitBake fetch warning (may be OK):"
    bitbake -c fetch hello-world 2>&1 | grep -i "warn\|error" | head -3
fi
echo

# Summary
echo "================================"
echo "Verification Complete!"
echo "================================"
echo
echo "If all checks passed, you can build:"
echo "  bitbake hello-world"
echo "  or"
echo "  bitbake core-image-minimal"
echo
