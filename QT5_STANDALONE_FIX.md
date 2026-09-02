# Qt5 Standalone Repository - Correct Solution

**Important Update:** Qt5 is no longer part of meta-openembedded. It now has its own dedicated repository at `github.com/meta-qt5`

**Solution:** Use the standalone meta-qt5 repository instead

---

## Quick Fix (On Mac)

### Step 1: Remove Old meta-openembedded (Optional)

```bash
# If you cloned meta-openembedded, you can remove it since we don't need it
rm -rf /Users/tfahey/github/cpp-yocto/meta-openembedded
```

### Step 2: Clone Dedicated meta-qt5 Repository

```bash
cd /Users/tfahey/github/cpp-yocto

# Clone the official meta-qt5 repository
git clone https://github.com/meta-qt5/meta-qt5.git -b scarthgap

# Verify it downloaded
ls -la meta-qt5/
# Should show: conf/, recipes-qt/, etc.
```

If scarthgap branch doesn't exist, try master:
```bash
git clone https://github.com/meta-qt5/meta-qt5.git

# Then check available branches
cd meta-qt5
git branch -a
# And switch to appropriate one
```

---

## In Docker: Update bblayers.conf

```bash
cd /home/yocto/project/build

# Edit bblayers.conf
nano conf/bblayers.conf

# Update BBLAYERS to use standalone meta-qt5 (remove meta-openembedded, add meta-qt5):
BBLAYERS ?= " \
  /home/yocto/project/poky/meta \
  /home/yocto/project/poky/meta-poky \
  /home/yocto/project/poky/meta-yocto-bsp \
  /home/yocto/project/meta-qt5 \
  /home/yocto/project/meta-hello-qt \
"

# Save: Ctrl+O, Enter, Ctrl+X
```

---

## Complete Workflow

### On Mac (2-3 minutes)

```bash
cd /Users/tfahey/github/cpp-yocto

# 1. Remove old meta-openembedded (if you cloned it)
rm -rf meta-openembedded

# 2. Clone official meta-qt5
git clone https://github.com/meta-qt5/meta-qt5.git -b scarthgap

# 3. Verify
ls -la meta-qt5/
# Should show: conf/, recipes-qt/, recipes-qt5/, etc.
```

### In Docker (5 minutes)

```bash
# 1. Stop and restart container
docker stop yocto-build
docker rm yocto-build

# 2. Start fresh
docker run -it \
  -e LANG=en_US.UTF-8 \
  -e LC_ALL=en_US.UTF-8 \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest

# 3. Initialize build
cd /home/yocto/project/poky
source oe-init-build-env ../build
cd ../build

# 4. Update bblayers.conf
nano conf/bblayers.conf

# Add: /home/yocto/project/meta-qt5 (remove meta-openembedded paths)
# Save: Ctrl+O, Enter, Ctrl+X

# 5. Clear cache
bitbake -c cleanall hello-world
rm -rf tmp/work/*/hello-world-*

# 6. Verify Qt5 is found
bitbake-layers show-recipes | grep qt5-base
# Should show: qt5-base

# 7. Build!
bitbake hello-world
```

---

## Project Structure After Fix

```
/Users/tfahey/github/cpp-yocto/
├── poky/                    ← Yocto core
├── meta-qt5/                ← NEW: Official Qt5 layer (standalone)
│   ├── conf/
│   ├── recipes-qt/
│   ├── recipes-qt5/         ← Qt5 recipes here
│   └── ...
├── meta-hello-qt/           ← Our custom layer
└── build/
```

---

## Updated bblayers.conf

```bash
BBLAYERS ?= " \
  /home/yocto/project/poky/meta \
  /home/yocto/project/poky/meta-poky \
  /home/yocto/project/poky/meta-yocto-bsp \
  /home/yocto/project/meta-qt5 \
  /home/yocto/project/meta-hello-qt \
"
```

**Key difference from before:**
- ✅ Use `/home/yocto/project/meta-qt5` (standalone)
- ❌ Don't use `/home/yocto/project/meta-openembedded/meta-oe`
- ❌ Don't use `/home/yocto/project/meta-openembedded/meta-qt5`

---

## Why This Change?

Qt5 was moved out of meta-openembedded to its own repository:

- **Reason:** Qt5 is being phased out in favor of Qt6
- **Benefit:** Standalone repo is easier to maintain and use
- **Repository:** https://github.com/meta-qt5/meta-qt5

The standalone repository contains:
- ✅ Qt5 recipes
- ✅ Build system integration
- ✅ Dependencies
- ✅ All necessary tools

---

## Verify Qt5 is Available

```bash
# In Docker
bitbake-layers show-layers | grep meta-qt5
# Should show: meta-qt5  /home/yocto/project/meta-qt5

bitbake-layers show-recipes | grep qt5-base
# Should show: qt5-base

bitbake -e qt5-base | head -10
# Should show Qt5 variables
```

---

## Branch Availability

For meta-qt5 repository:

```bash
cd /Users/tfahey/github/cpp-yocto/meta-qt5
git branch -a
```

Available branches typically include:
- `master` - Latest development
- `scarthgap` - Latest stable
- `kirkstone` - LTS
- `dunfell` - Older LTS

---

## Quick Summary

**Old way (doesn't work):**
```
meta-openembedded/meta-qt5 ❌ (no longer there)
```

**New way (correct):**
```
meta-qt5 (standalone) ✅
```

**One-liner for cloning:**
```bash
cd /Users/tfahey/github/cpp-yocto && git clone https://github.com/meta-qt5/meta-qt5.git -b scarthgap
```

**Update bblayers.conf:**
```bash
# Use this:
/home/yocto/project/meta-qt5

# Not this:
/home/yocto/project/meta-openembedded/meta-oe
/home/yocto/project/meta-openembedded/meta-qt5
```

---

## Building After Fix

```bash
# In Docker container
cd /home/yocto/project/build

# Update environment
source ../poky/oe-init-build-env .

# Clear cache
bitbake -c cleanall hello-world
rm -rf tmp/work/*/hello-world-*

# Build!
bitbake hello-world
```

**Done!** ✅

---

## See Also

- **QT5_MISSING_FIX.md** - Previous Qt5 setup (for reference)
- **VERIFY_META_OE.md** - Verification guide
- **TROUBLESHOOTING.md** - General troubleshooting
- Repository: https://github.com/meta-qt5/meta-qt5
