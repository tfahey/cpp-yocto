# Configuring conf/bblayers.conf - Step by Step

After running `oe-init-build-env`, you need to **tell BitBake about our custom layer** by adding it to `conf/bblayers.conf`.

---

## The Problem

```bash
# conf/bblayers.conf exists but only has core layers:
# - poky/meta
# - poky/meta-poky
# - poky/meta-yocto-bsp

# Missing: meta-hello-qt (our custom layer!)
```

## The Solution

Add the path to `meta-hello-qt` in the `BBLAYERS` variable.

---

## Step-by-Step Guide

### Step 1: Open conf/bblayers.conf

Inside your Docker container (or native Linux):

```bash
# Navigate to build directory
cd /home/yocto/project/build    # (Docker) or /Users/tfahey/.../build (native)

# Open the file
nano conf/bblayers.conf
```

### Step 2: Find the BBLAYERS Variable

Scroll to find something like this:

```bash
BBLAYERS ?= " \
  /home/yocto/project/poky/meta \
  /home/yocto/project/poky/meta-poky \
  /home/yocto/project/poky/meta-yocto-bsp \
"
```

Or on native Linux:

```bash
BBLAYERS ?= " \
  /Users/tfahey/github/cpp-yocto/poky/meta \
  /Users/tfahey/github/cpp-yocto/poky/meta-poky \
  /Users/tfahey/github/cpp-yocto/poky/meta-yocto-bsp \
"
```

### Step 3: Add meta-hello-qt Path

**For Docker:**

```bash
BBLAYERS ?= " \
  /home/yocto/project/poky/meta \
  /home/yocto/project/poky/meta-poky \
  /home/yocto/project/poky/meta-yocto-bsp \
  /home/yocto/project/meta-hello-qt \
"
```

**For Native Linux:**

```bash
BBLAYERS ?= " \
  /Users/tfahey/github/cpp-yocto/poky/meta \
  /Users/tfahey/github/cpp-yocto/poky/meta-poky \
  /Users/tfahey/github/cpp-yocto/poky/meta-yocto-bsp \
  /Users/tfahey/github/cpp-yocto/meta-hello-qt \
"
```

**Key points:**
- ✅ Add the path on a new line
- ✅ Keep the backslash at the end of other lines (for line continuation)
- ✅ Remove backslash from the last line (before closing quote)
- ✅ Use absolute paths (full path from root)
- ✅ Check spacing and indentation

### Step 4: Save and Exit

- **nano:** Press `Ctrl+O`, then `Enter` to save, then `Ctrl+X` to exit
- **vi:** Press `Esc`, type `:wq`, press `Enter`

### Step 5: Verify

```bash
# Check that meta-hello-qt was added
grep -A 5 "BBLAYERS" conf/bblayers.conf

# Should show your path to meta-hello-qt
```

---

## What BBLAYERS Does

**BBLAYERS** tells BitBake which directories contain recipes.

Each layer is a directory with recipes (`.bb` files) and metadata (`conf/layer.conf`).

```
BitBake searches in BBLAYERS for:
  ├─ poky/meta/ (core recipes: GCC, Linux, etc.)
  ├─ poky/meta-poky/ (Poky-specific config)
  ├─ poky/meta-yocto-bsp/ (hardware support)
  └─ meta-hello-qt/ ← Our layer (Qt recipes, our app)
```

---

## Path Format

### Docker Container Paths

Inside container, use `/home/yocto/project/...`:

```bash
# ✅ Correct for Docker:
/home/yocto/project/meta-hello-qt
/home/yocto/project/poky/meta

# ❌ Wrong for Docker:
/Users/tfahey/github/cpp-yocto/meta-hello-qt  (host path!)
/root/project/meta-hello-qt  (different user)
meta-hello-qt  (relative path)
~/meta-hello-qt  (home shortcut won't expand)
```

### Native Linux Paths

On your Mac or Linux machine, use full absolute paths:

```bash
# ✅ Correct for native:
/Users/tfahey/github/cpp-yocto/meta-hello-qt
/Users/tfahey/github/cpp-yocto/poky/meta

# ❌ Wrong for native:
/home/yocto/project/meta-hello-qt  (container path!)
meta-hello-qt  (relative path)
~/meta-hello-qt  (home shortcut)
```

---

## Common Issues and Fixes

### Issue 1: BitBake Can't Find Layer

**Error:** `Unable to find layer`

**Solution:** Verify the path:
```bash
# In Docker:
ls -la /home/yocto/project/meta-hello-qt/

# Or native:
ls -la /Users/tfahey/github/cpp-yocto/meta-hello-qt/

# Should show: conf/ recipes-qt/ COPYING
```

### Issue 2: BitBake Can't Find Recipe

**Error:** `hello-world: Recipe not found`

**Causes:**
1. Layer not in BBLAYERS
2. Layer path wrong
3. Recipe file missing

**Fix:**
```bash
# Verify layer is in BBLAYERS
grep -A 5 BBLAYERS conf/bblayers.conf | grep meta-hello-qt

# Verify recipe exists
ls -la meta-hello-qt/recipes-qt/hello-world/
# Should show: hello-world.bb hello-world-0.1/

# Search for recipe
bitbake-layers show-recipes | grep hello-world
```

### Issue 3: Wrong Path in BBLAYERS

**Problem:** Path points to wrong location

**Solution:**
```bash
# Verify path exists
stat /home/yocto/project/meta-hello-qt  # (Docker)
# or
stat /Users/tfahey/github/cpp-yocto/meta-hello-qt  # (native)

# Should show: directory, not error
```

### Issue 4: Formatting Error

**Problem:** BitBake fails to parse BBLAYERS

**Common mistakes:**
```bash
# ❌ Missing backslash for continuation:
BBLAYERS ?= " \
  /path/to/meta1 \
  /path/to/meta2
  /path/to/meta3 \  (missing backslash above!)
"

# ❌ Wrong quote style:
BBLAYERS = "
  /path/to/meta \
"  (should be BBLAYERS ?=)

# ❌ Trailing spaces:
BBLAYERS ?= " \
  /path/to/meta \     (space after backslash!)
"
```

---

## Correct Format Template

```bash
BBLAYERS ?= " \
  /path/to/meta1 \
  /path/to/meta2 \
  /path/to/meta3 \
  /path/to/custom-layer \
"
```

**Rules:**
- Start with `BBLAYERS ?= "`
- Each path on new line
- Backslash (`\`) at end of lines (except last)
- Close with `"`
- No trailing spaces

---

## Verifying Configuration

### Test 1: Can BitBake parse it?

```bash
bitbake -e > /dev/null && echo "OK" || echo "ERROR"
```

### Test 2: Can BitBake find the layer?

```bash
bitbake-layers show-recipes | grep -E "(meta|hello)"
```

### Test 3: Can BitBake find our recipe?

```bash
bitbake-layers show-recipes | grep hello-world
```

### Test 4: Full verification

```bash
# Show all layers
bitbake-layers show-layers

# Should list:
# meta-hello-qt /path/to/meta-hello-qt

# Search for our recipe
bitbake-layers show-recipes hello-world

# Should show recipe details
```

---

## Quick Fix: Using Relative Paths

If absolute paths are problematic, you can use relative paths **but you must run from the right directory**:

```bash
# From build/ directory:
BBLAYERS ?= " \
  ../poky/meta \
  ../poky/meta-poky \
  ../poky/meta-yocto-bsp \
  ../meta-hello-qt \
"

# Then must always run from build/:
cd /home/yocto/project/build
bitbake hello-world
```

**Note:** Absolute paths are safer and recommended.

---

## Before and After

### Before (doesn't work)
```bash
BBLAYERS ?= " \
  /home/yocto/project/poky/meta \
  /home/yocto/project/poky/meta-poky \
  /home/yocto/project/poky/meta-yocto-bsp \
"
# ❌ BitBake can't find hello-world recipe
```

### After (works!)
```bash
BBLAYERS ?= " \
  /home/yocto/project/poky/meta \
  /home/yocto/project/poky/meta-poky \
  /home/yocto/project/poky/meta-yocto-bsp \
  /home/yocto/project/meta-hello-qt \
"
# ✅ BitBake finds hello-world recipe
```

---

## Complete Verification Workflow

```bash
# 1. Edit the file
nano conf/bblayers.conf

# 2. Check formatting
cat conf/bblayers.conf | grep -A 5 BBLAYERS

# 3. Verify BitBake can parse it
bitbake -e > /dev/null 2>&1 && echo "Syntax OK" || echo "Syntax ERROR"

# 4. Verify layer is loaded
bitbake-layers show-layers | grep hello

# 5. Verify recipe is found
bitbake-layers show-recipes | grep hello-world

# 6. Now build
bitbake hello-world
```

---

## Troubleshooting: Layer Not Found

If BitBake still can't find meta-hello-qt:

```bash
# 1. Check the path exists
ls -la /home/yocto/project/meta-hello-qt/
# Should show: conf/, recipes-qt/, COPYING

# 2. Check layer.conf exists
ls -la /home/yocto/project/meta-hello-qt/conf/layer.conf
# Should exist

# 3. Check BBLAYERS in config
grep meta-hello-qt conf/bblayers.conf
# Should show the path

# 4. Check BitBake recognizes it
bitbake-layers show-layers | grep -i hello
# Should show meta-hello-qt in output

# 5. If still not working, rebuild
rm -rf tmp/
bitbake -c cleanall hello-world
bitbake hello-world
```

---

## See Also

- **CONFIGURE_LOCAL_CONF.md** - Configure IMAGE_INSTALL and MACHINE
- **BUILD_INSTRUCTIONS.md** - Full build workflow
- **QUICK_REFERENCE.md** - BitBake variables reference
