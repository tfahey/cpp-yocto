# Qtbase-gui Missing or Unbuildable - Diagnostic & Fix

**Error:** `Missing or unbuildable dependency chain was: ['hello-world', 'qtbase-gui']`

**Cause:** qtbase-gui recipe not found or has unmet dependencies

**Solution:** Diagnose and fix the layer/dependency configuration

---

## Step 1: Verify Layers Are Loaded

Inside Docker container:

```bash
cd /home/yocto/project/build

# Check if layers are registered
bitbake-layers show-layers
# Should include:
# - openembedded-layer (meta-oe)
# - qt5-layer (meta-qt5)
# - meta-hello-qt

# If qt5-layer is missing, add meta-qt5 to bblayers.conf
```

---

## Step 2: Verify Qt5 Recipes Exist

```bash
# Check if qtbase recipe is found
bitbake-layers show-recipes | grep -i qtbase
# Should show multiple qtbase recipes

# Check specifically for qtbase-gui
bitbake-layers show-recipes | grep "^qtbase-gui "
# Should find: qtbase-gui

# If not found, meta-qt5 isn't loaded correctly
```

---

## Step 3: Check for Parse Errors

```bash
# Run BitBake in verbose mode to see errors
bitbake -vv hello-world 2>&1 | head -50
# Look for parse errors or missing layers

# Or check if meta-qt5 has issues
bitbake-layers show-layers | grep qt5
# Should show something like:
# qt5-layer  /home/yocto/project/meta-qt5

# If not there, check bblayers.conf
cat /home/yocto/project/build/conf/bblayers.conf | grep -E "meta-qt5|meta-oe"
# Should show both paths
```

---

## Step 4: Verify Machine/Distro Configuration

```bash
# Check current machine
grep "^MACHINE" /home/yocto/project/build/conf/local.conf
# Should show: MACHINE = "qemux86-64"

# Check distro
grep "^DISTRO" /home/yocto/project/build/conf/local.conf
# Default is fine (usually unset, uses Poky default)

# For qemux86-64, qtbase should be available
# If using different MACHINE, qtbase might not be supported
```

---

## Step 5: Check qtbase Dependencies

```bash
# Show qtbase-gui recipe details
bitbake-layers show-recipes | grep qtbase-gui

# Or try to parse it
bitbake -e qtbase-gui 2>&1 | head -20
# Look for errors

# Check if qtbase (base package) is buildable
bitbake -e qtbase 2>&1 | head -20
```

---

## Complete Diagnostic Workflow

Run these commands IN ORDER:

```bash
cd /home/yocto/project/build

# 1. Verify layers
echo "=== Checking layers ==="
bitbake-layers show-layers | grep -E "qt5|meta-oe|meta-hello-qt"

# 2. Verify recipes
echo "=== Checking qtbase recipes ==="
bitbake-layers show-recipes | grep "^qtbase" | head -10

# 3. Check specifically for qtbase-gui
echo "=== Checking qtbase-gui ==="
bitbake-layers show-recipes | grep "^qtbase-gui "

# 4. Check configuration
echo "=== Checking bblayers.conf ==="
grep -E "meta-qt5|meta-oe" /home/yocto/project/build/conf/bblayers.conf

# 5. Check local.conf
echo "=== Checking local.conf ==="
grep "^MACHINE\|^DISTRO" /home/yocto/project/build/conf/local.conf

# 6. Try detailed parse
echo "=== Checking for parse errors ==="
bitbake -e qtbase-gui 2>&1 | grep -i "error\|warn" | head -5
```

---

## Common Causes and Fixes

### Issue 1: meta-qt5 Not in BBLAYERS

**Check:**
```bash
grep "meta-qt5" /home/yocto/project/build/conf/bblayers.conf
# Should return a path
```

**Fix:** Add to bblayers.conf
```bash
nano /home/yocto/project/build/conf/bblayers.conf

# Add:
# /home/yocto/project/meta-qt5 \
# /home/yocto/project/meta-openembedded/meta-oe \
```

### Issue 2: meta-oe Not in BBLAYERS

meta-qt5 depends on meta-oe. If meta-oe is missing, qtbase won't build.

**Check:**
```bash
grep "meta-oe" /home/yocto/project/build/conf/bblayers.conf
# Should show meta-openembedded/meta-oe path
```

**Fix:** Add meta-oe (MUST come BEFORE meta-qt5)
```bash
nano /home/yocto/project/build/conf/bblayers.conf

# Add meta-oe BEFORE meta-qt5:
# /home/yocto/project/meta-openembedded/meta-oe \
```

### Issue 3: Wrong Machine Type

Some machines don't have Qt support.

**Check:**
```bash
grep "^MACHINE" /home/yocto/project/build/conf/local.conf
# Should be qemux86-64 for Qt support
```

**Fix:** Use supported machine
```bash
nano /home/yocto/project/build/conf/local.conf

# Should have:
# MACHINE = "qemux86-64"
```

### Issue 4: Layer Order Wrong

Layers must be in dependency order.

**Wrong order:**
```bash
BBLAYERS ?= " \
  /home/yocto/project/meta-qt5 \
  /home/yocto/project/meta-openembedded/meta-oe \
  /home/yocto/project/poky/meta \
"
```

**Correct order:**
```bash
BBLAYERS ?= " \
  /home/yocto/project/poky/meta \
  /home/yocto/project/poky/meta-poky \
  /home/yocto/project/poky/meta-yocto-bsp \
  /home/yocto/project/meta-openembedded/meta-oe \
  /home/yocto/project/meta-qt5 \
  /home/yocto/project/meta-hello-qt \
"
```

---

## Reset and Rebuild

If you can't figure out the issue:

```bash
cd /home/yocto/project/build

# Clean everything
bitbake -c cleanall hello-world
rm -rf tmp/work/*/hello-world-*
rm -rf tmp/cache/

# Verify layers one more time
bitbake-layers show-layers

# Verify qtbase-gui exists
bitbake-layers show-recipes | grep "^qtbase-gui "

# If qtbase-gui shows up, rebuild
bitbake hello-world
```

---

## Verify Everything Works

```bash
# Step 1: Layers
bitbake-layers show-layers | grep -E "qt5|meta-oe"
# Should show both

# Step 2: Recipes
bitbake-layers show-recipes | grep "^qtbase"
# Should show: qtbase, qtbase-gui, qtbase-core, etc.

# Step 3: Dependencies
bitbake -e hello-world | grep "DEPENDS\|RDEPENDS" | head -10
# Should show qt packages

# Step 4: Build
bitbake hello-world
# Should work!
```

---

## Quick Summary

**If qtbase-gui is missing:**

1. Check layers are loaded: `bitbake-layers show-layers`
2. Check recipes exist: `bitbake-layers show-recipes | grep qtbase-gui`
3. Verify bblayers.conf has BOTH meta-oe and meta-qt5
4. Verify order: meta-oe BEFORE meta-qt5
5. Clean and rebuild: `bitbake -c cleanall hello-world && bitbake hello-world`

---

## See Also

- **QT5_WITH_OE_DEPENDENCY.md** - Qt5 setup
- **QUICK_QT5_CORRECT.md** - Quick setup
- **FIX_QT5_PACKAGE_NAMES.md** - Package names
- **TROUBLESHOOTING.md** - General troubleshooting
