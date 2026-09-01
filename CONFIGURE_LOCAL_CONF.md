# Configuring conf/local.conf - Step by Step

When you run `oe-init-build-env`, it creates `conf/local.conf` but **doesn't set IMAGE_INSTALL by default**. You need to add it manually.

---

## The Problem

```bash
# After running oe-init-build-env, conf/local.conf exists but:
# - No MACHINE setting
# - No IMAGE_INSTALL setting
# - Mostly commented-out examples
```

## The Solution

Add these lines to `conf/local.conf`:

```bash
MACHINE = "qemux86-64"
IMAGE_INSTALL:append = " hello-world"
```

---

## Step-by-Step Guide

### Step 1: Open conf/local.conf

Inside your Docker container (or native Linux):

```bash
# Navigate to build directory
cd /home/yocto/project/build    # (Docker) or /Users/tfahey/.../build (native)

# Open the file
nano conf/local.conf
```

### Step 2: Find a Good Place to Add Your Settings

Scroll to the **end of the file** (after all the commented-out examples).

**Typical conf/local.conf structure:**
```bash
# Lines 1-100: Comments and examples (mostly commented with #)
# Lines 100-200: More commented examples
# Line 200+: End of file (blank space)

← Add your settings HERE (at the end)
```

### Step 3: Add Your Settings

At the **very end of the file**, add these two lines:

```bash
# Target machine
MACHINE = "qemux86-64"

# Include our hello-world application
IMAGE_INSTALL:append = " hello-world"
```

### Step 4: Save and Exit

- **nano:** Press `Ctrl+O`, then `Enter` to save, then `Ctrl+X` to exit
- **vi:** Press `Esc`, type `:wq`, press `Enter`

### Step 5: Verify

```bash
# Check that your settings were added
tail -5 conf/local.conf

# Should show:
# MACHINE = "qemux86-64"
# IMAGE_INSTALL:append = " hello-world"
```

---

## What These Settings Do

### `MACHINE = "qemux86-64"`

- **MACHINE** specifies the target architecture
- `qemux86-64` = 64-bit x86 emulation (good for testing on Mac/Linux)
- Other options:
  - `qemux86` = 32-bit emulation
  - `raspberrypi4` = Raspberry Pi 4
  - `intel-corei7-64` = x86-64 hardware

### `IMAGE_INSTALL:append = " hello-world"`

- **IMAGE_INSTALL** lists packages to include in the image
- `:append` means "add to existing list" (don't replace)
- `" hello-world"` adds our custom Qt application
- The leading space is important!

---

## Common Issues and Fixes

### Issue 1: No IMAGE_INSTALL after editing

**Problem:** After adding IMAGE_INSTALL, bitbake doesn't find hello-world

**Solution:** Make sure syntax is exactly:
```bash
IMAGE_INSTALL:append = " hello-world"
# Not: IMAGE_INSTALL = "hello-world"
# Not: IMAGE_INSTALL:append="hello-world"  (no space before hello-world)
```

### Issue 2: MACHINE setting ignored

**Problem:** MACHINE is set but bitbake uses default

**Check:** Make sure it's at the **end** of the file, not commented out

```bash
# This doesn't work (commented):
# MACHINE = "qemux86-64"

# This works (no #):
MACHINE = "qemux86-64"
```

### Issue 3: Multiple IMAGE_INSTALL lines

**Problem:** If you add IMAGE_INSTALL multiple times:

```bash
IMAGE_INSTALL:append = " hello-world"
IMAGE_INSTALL:append = " some-other-package"  # Overwrites previous!
```

**Solution:** Use a single line with space-separated packages:

```bash
IMAGE_INSTALL:append = " hello-world some-other-package"
```

### Issue 4: Syntax error in conf/local.conf

**Problem:** BitBake fails with syntax error

**Check:** Make sure:
- No trailing spaces after values
- Equal signs don't have spaces: `MACHINE=` not `MACHINE =`
- Actually, equal signs CAN have spaces: `MACHINE = "qemux86-64"` is fine
- String values must be in quotes: `"qemux86-64"` not `qemux86-64`

---

## What Your conf/local.conf Should Look Like

### Minimal Example

```bash
#
# This is the local configuration file and defines local user policy. It is always
# placed in the build/conf/ directory.
#
# ... (lots of commented examples) ...
#

# Add your custom settings at the end:

MACHINE = "qemux86-64"
IMAGE_INSTALL:append = " hello-world"
```

### Complete Minimal Build

For a complete minimal build that definitely works:

```bash
# Machine and distro
MACHINE = "qemux86-64"

# Package to include
IMAGE_INSTALL:append = " hello-world"

# Image type
IMAGE_FSTYPES = "wic"
```

---

## Viewing Current Settings

After configuring, verify BitBake sees your settings:

```bash
# From build/ directory:
bitbake -e | grep "^MACHINE="
bitbake -e | grep "^IMAGE_INSTALL="

# Should show your values
```

---

## Advanced Configuration

### Including Multiple Packages

```bash
IMAGE_INSTALL:append = " hello-world wget curl openssh"
```

### Different Configurations for Different Images

If you build multiple images:

```bash
# For core-image-minimal
IMAGE_INSTALL:append = " hello-world"

# For other images, use different variables
CORE_IMAGE_EXTRA_INSTALL = "additional-package"
```

### Conditional Settings

```bash
# Only add if building for specific machine
MACHINE = "qemux86-64"
IMAGE_INSTALL:append:qemux86-64 = " hello-world"
```

---

## Troubleshooting Commands

If build fails, check these:

```bash
# Verify local.conf syntax
bitbake -e 2>&1 | grep -i error | head -5

# Show all variables
bitbake -e > /tmp/bitbake-vars.txt
grep "^MACHINE=" /tmp/bitbake-vars.txt
grep "^IMAGE_INSTALL=" /tmp/bitbake-vars.txt

# Show just our app
bitbake -e | grep hello-world
```

---

## Recreating local.conf from Scratch

If you mess up conf/local.conf:

```bash
# Backup bad file
cp conf/local.conf conf/local.conf.backup

# Remove it
rm conf/local.conf

# Regenerate default
cd ../poky
source oe-init-build-env ../build
cd ../build

# Now edit conf/local.conf again
nano conf/local.conf
```

---

## Quick Reference: Adding Settings

**File:** `build/conf/local.conf`

**Location:** End of file (after all commented examples)

**Add these lines:**
```bash
MACHINE = "qemux86-64"
IMAGE_INSTALL:append = " hello-world"
```

**Save:** Ctrl+O, Enter, Ctrl+X (nano)

**Verify:**
```bash
tail conf/local.conf
bitbake -e | grep MACHINE
```

---

## Complete Workflow with Configuration

```bash
# Inside container
cd /home/yocto/project/poky
source oe-init-build-env ../build
cd ../build

# Edit configuration
nano conf/bblayers.conf
# Make sure meta-hello-qt is in BBLAYERS

nano conf/local.conf
# Add:
# MACHINE = "qemux86-64"
# IMAGE_INSTALL:append = " hello-world"

# Verify
tail conf/local.conf    # Should show your settings
bitbake -e | grep "^MACHINE="  # Should show qemux86-64

# Now build!
bitbake core-image-minimal
```

---

## If You Still Have Issues

Check these in order:

1. **File exists?**
   ```bash
   ls -la conf/local.conf
   ```

2. **Syntax correct?**
   ```bash
   tail conf/local.conf
   # Should show your settings without # symbols
   ```

3. **Bitbake sees it?**
   ```bash
   bitbake -e | grep "^MACHINE=" | head -1
   # Should show your MACHINE setting
   ```

4. **Layer included?**
   ```bash
   bitbake -e | grep "meta-hello-qt"
   # Should show path to meta-hello-qt
   ```

---

## See Also

- **BUILD_INSTRUCTIONS.md** - Full build workflow
- **DOCKER_QUICK_FIX.md** - Docker configuration
- **QUICK_REFERENCE.md** - BitBake variables
