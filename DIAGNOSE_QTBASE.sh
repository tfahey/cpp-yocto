#!/bin/bash

# Diagnostic script for qtbase-gui missing error
# Run this inside Docker container in the build directory

echo "╔════════════════════════════════════════════════════════════╗"
echo "║        Qt5/QtBase Build Diagnostic                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo

# Check 1: Layers
echo "1. Checking Layers..."
echo "─────────────────────────────────"
bitbake-layers show-layers | grep -E "qt5|meta-oe|meta-hello"
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Qt5 or meta-oe layers not found"
    echo "   Add to bblayers.conf:"
    echo "   - /home/yocto/project/meta-openembedded/meta-oe"
    echo "   - /home/yocto/project/meta-qt5"
else
    echo "✓ Layers found"
fi
echo

# Check 2: QtBase Recipe
echo "2. Checking QtBase Recipes..."
echo "─────────────────────────────────"
QTBASE_COUNT=$(bitbake-layers show-recipes | grep "^qtbase" | wc -l)
if [ "$QTBASE_COUNT" -eq 0 ]; then
    echo "❌ ERROR: No qtbase recipes found"
    echo "   Check that meta-qt5 is in BBLAYERS"
    exit 1
else
    echo "✓ Found $QTBASE_COUNT qtbase recipes:"
    bitbake-layers show-recipes | grep "^qtbase" | head -5
fi
echo

# Check 3: QtBase-GUI Specifically
echo "3. Checking QtBase-GUI..."
echo "─────────────────────────────────"
if bitbake-layers show-recipes | grep -q "^qtbase-gui "; then
    echo "✓ qtbase-gui recipe found"
else
    echo "❌ ERROR: qtbase-gui recipe not found"
    echo "   This is required for Qt5 GUI support"
    exit 1
fi
echo

# Check 4: Configuration
echo "4. Checking Configuration..."
echo "─────────────────────────────────"
MACHINE=$(grep "^MACHINE" conf/local.conf | head -1)
echo "Machine: $MACHINE"
if [[ ! "$MACHINE" =~ "qemux86-64" ]]; then
    echo "⚠ Warning: Using non-standard machine. Qt5 may not be supported."
fi
echo

# Check 5: Layer Order
echo "5. Checking Layer Order in bblayers.conf..."
echo "─────────────────────────────────"
OE_POS=$(grep -n "meta-openembedded/meta-oe" conf/bblayers.conf | cut -d: -f1)
QT5_POS=$(grep -n "meta-qt5" conf/bblayers.conf | cut -d: -f1)

if [ -z "$OE_POS" ]; then
    echo "❌ ERROR: meta-oe not in BBLAYERS"
    exit 1
fi

if [ -z "$QT5_POS" ]; then
    echo "❌ ERROR: meta-qt5 not in BBLAYERS"
    exit 1
fi

if [ "$OE_POS" -lt "$QT5_POS" ]; then
    echo "✓ Layer order correct (meta-oe before meta-qt5)"
else
    echo "❌ ERROR: Wrong layer order!"
    echo "   meta-oe must come BEFORE meta-qt5"
    echo "   meta-oe at line: $OE_POS"
    echo "   meta-qt5 at line: $QT5_POS"
    exit 1
fi
echo

# Check 6: Try to parse qtbase-gui
echo "6. Checking QtBase-GUI Buildability..."
echo "─────────────────────────────────"
if bitbake -e qtbase-gui > /dev/null 2>&1; then
    echo "✓ qtbase-gui can be parsed"
else
    echo "❌ ERROR: qtbase-gui has parse errors"
    echo "   Running detailed parse:"
    bitbake -e qtbase-gui 2>&1 | grep -i "error" | head -3
    exit 1
fi
echo

# Summary
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              All Checks Passed! ✓                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo
echo "Your setup looks good. Try building:"
echo "  bitbake -c cleanall hello-world"
echo "  bitbake hello-world"
echo
