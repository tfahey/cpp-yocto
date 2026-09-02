# Qt5 Not in scarthgap Branch - Fix

**Issue:** Cloned meta-openembedded on scarthgap branch, but `meta-qt5` directory doesn't exist

**Reason:** `meta-qt5` is only in certain branches of meta-openembedded, not in scarthgap

**Solution:** Switch to a branch that has meta-qt5

---

## Quick Fix (On Mac)

### Option A: Switch to master branch (Recommended)

```bash
cd /Users/tfahey/github/cpp-yocto/meta-openembedded

# Switch to master branch (which has meta-qt5)
git checkout master

# Verify meta-qt5 now exists
ls -la meta-qt5/
# Should show: conf/, recipes-qt/, etc.
```

### Option B: Use a stable branch

```bash
cd /Users/tfahey/github/cpp-yocto/meta-openembedded

# List available branches
git branch -a | grep -E "master|main|[a-z]+-stable"

# Switch to master
git checkout master

# Or switch to another branch
git checkout dunfell  # (LTS release)

# Verify
ls -la meta-qt5/
```

### Option C: Clone from a different source

If switching branches doesn't work, use the Qt5-specific repository:

```bash
# This is NOT recommended but is an alternative:
# There's no direct Qt5-only repo, so the meta-openembedded master branch is best
```

---

## Complete Fix Workflow

### Step 1: On Mac

```bash
cd /Users/tfahey/github/cpp-yocto/meta-openembedded

# Check current branch
git branch
# Shows: * scarthgap (has NO meta-qt5)

# Switch to master
git checkout master

# Verify meta-qt5 exists now
ls -la meta-qt5/
# Should show: conf/, recipes-qt/, and other directories
```

### Step 2: In Docker

Restart container to get fresh view (optional but recommended):

```bash
# On Mac
docker stop yocto-build
docker rm yocto-build

# Restart
docker run -it \
  -e LANG=en_US.UTF-8 \
  -e LC_ALL=en_US.UTF-8 \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest
```

### Step 3: In Docker

```bash
cd /home/yocto/project/build

# Verify meta-qt5 is visible
ls -la /home/yocto/project/meta-openembedded/meta-qt5/
# Should now show directories!

# Update bblayers.conf if not already done
nano conf/bblayers.conf

# Make sure it has:
# /home/yocto/project/meta-openembedded/meta-oe \
# /home/yocto/project/meta-openembedded/meta-qt5 \

# Clear cache and rebuild
bitbake -c cleanall hello-world
rm -rf tmp/work/*/hello-world-*

# Verify Qt5 is found
bitbake-layers show-recipes | grep qt5-base
# Should show: qt5-base

# Build!
bitbake hello-world
```

---

## Why This Happens

Different branches of meta-openembedded contain different recipes:

- **scarthgap branch** (current): Doesn't have meta-qt5 (Qt5 is considered legacy in newer releases)
- **master branch**: Has meta-qt5 (supports Qt5)
- **dunfell branch**: Has meta-qt5 (LTS, stable)
- **kirkstone branch**: Has meta-qt5 (LTS, supported)

For Qt5 support, we need to use a branch that includes the meta-qt5 layer.

---

## Branch Compatibility

| Branch | Qt5 Support | Status | Recommendation |
|--------|------------|--------|-----------------|
| master | ✅ Yes | Latest | Best for Qt5 |
| kirkstone | ✅ Yes | LTS | Stable alternative |
| dunfell | ✅ Yes | LTS | Older stable |
| scarthgap | ❌ No | Latest | Not suitable for Qt5 |
| langdale | ❌ No | EOL | Don't use |

---

## Alternative: Use Different Yocto Branch

If you want to keep using scarthgap, you could instead:

1. Use a newer Qt framework (Qt6)
2. Build Qt5 from source manually
3. Use a prebuilt Qt5 binary

But the easiest solution is to use the master branch of meta-openembedded, which has full Qt5 support.

---

## Verification After Fix

```bash
# On Mac
cd /Users/tfahey/github/cpp-yocto/meta-openembedded

# Verify current branch
git branch
# Should show: * master

# Verify meta-qt5 exists
ls -la meta-qt5/recipes-qt/qt5-base/ 2>/dev/null && echo "✓ Qt5 recipes found" || echo "✗ Qt5 recipes missing"
```

---

## Quick Summary

**Problem:** scarthgap branch doesn't have meta-qt5

**Solution:** Switch to master branch:

```bash
cd /Users/tfahey/github/cpp-yocto/meta-openembedded
git checkout master
```

**Then rebuild in Docker:**

```bash
cd /home/yocto/project/build
bitbake -c cleanall hello-world
rm -rf tmp/work/*/hello-world-*
bitbake hello-world
```

**Done!** ✅

---

## See Also

- **QT5_MISSING_FIX.md** - Complete Qt5 setup
- **QUICK_QT5_FIX.md** - Quick fix guide
- **VERIFY_META_OE.md** - Verification checklist
