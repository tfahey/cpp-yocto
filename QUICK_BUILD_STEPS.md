# Quick Build Steps - Copy & Paste

Follow these exact steps to build successfully.

---

## Inside Docker Container

### Complete Sequence (Copy & Paste)

```bash
# 1. Go to build directory
cd /home/yocto/project/build

# 2. Initialize Yocto environment
source ../poky/oe-init-build-env .

# 3. Verify everything is set up
bash /home/yocto/project/VERIFY_SETUP.sh

# 4. If verification passes, build!
bitbake hello-world
```

---

## One-Liner (If Everything Already Set Up)

```bash
cd /home/yocto/project/build && source ../poky/oe-init-build-env . && bash /home/yocto/project/VERIFY_SETUP.sh && bitbake hello-world
```

---

## Step 1: Navigate to Build Directory

```bash
cd /home/yocto/project/build
```

**Verify:**
```bash
pwd
# Should show: /home/yocto/project/build

ls conf/
# Should show: bblayers.conf, local.conf
```

---

## Step 2: Initialize Yocto Environment

```bash
source ../poky/oe-init-build-env .
```

**Verify:**
```bash
bitbake --version
# Should show: BitBake Build Tool version X.X.X
```

---

## Step 3: Run Verification

```bash
bash /home/yocto/project/VERIFY_SETUP.sh
```

**Expected output:**
```
1. Checking source files...
✓ Source directory exists: /home/yocto/project/meta-hello-qt/recipes-qt/hello-world/hello-world-0.1
  ✓ CMakeLists.txt found
  ✓ main.cpp found
  ✓ mainwindow.h found
  ✓ mainwindow.cpp found

2. Checking locale...
✓ Locale set to en_US.UTF-8

3. Checking Yocto layer...
✓ meta-hello-qt layer registered

4. Checking BitBake recipe...
✓ hello-world recipe found

5. Checking build configuration...
✓ conf/local.conf exists
  ✓ MACHINE = "qemux86-64"
  ✓ hello-world in IMAGE_INSTALL

6. Checking BitBake recipe parsing...
✓ BitBake can parse hello-world recipe

7. Checking BitBake fetch...
✓ BitBake can fetch sources

================================
Verification Complete!
================================

If all checks passed, you can build:
  bitbake hello-world
  or
  bitbake core-image-minimal
```

---

## Step 4: Build

```bash
# Option A: Build just our app (faster, ~30 minutes)
bitbake hello-world

# Option B: Build full image (slower, ~2-6 hours)
bitbake core-image-minimal
```

---

## If Verification Fails

### Issue: "Not in build directory"
```bash
cd /home/yocto/project/build
```

### Issue: "BitBake environment not initialized"
```bash
source ../poky/oe-init-build-env .
```

### Issue: "Locale not set"
```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

### Issue: "meta-hello-qt layer not registered"
Edit `conf/bblayers.conf` and add to BBLAYERS:
```bash
/home/yocto/project/meta-hello-qt
```

### Issue: "hello-world not in IMAGE_INSTALL"
Edit `conf/local.conf` and add:
```bash
IMAGE_INSTALL:append = " hello-world"
```

### Issue: "Source files not found"
Verify files exist:
```bash
ls -la /home/yocto/project/meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/
# Should show: CMakeLists.txt, main.cpp, mainwindow.h, mainwindow.cpp
```

---

## Troubleshooting Build Errors

### Build fails with "Unable to get checksum"
```bash
# The recipe has been fixed, but clear cache:
bitbake -c cleanall hello-world
bitbake hello-world
```

### Build fails with "cmake: command not found"
```bash
# CMake should be available, try rebuilding:
bitbake -c clean hello-world
bitbake hello-world
```

### Build fails with network errors
```bash
# Try with explicit DNS:
docker exec yocto-build bash -c "cd /home/yocto/project/build && bitbake hello-world"
```

### Build times out
```bash
# This is normal for first build. Wait or restart:
bitbake hello-world
```

---

## After Successful Build

Find the built binary:

```bash
find /home/yocto/project/build/tmp -name hello-world -type f -executable
```

It should be in:
```
/home/yocto/project/build/tmp/work/qemux86-64/hello-world-0.1/image/usr/bin/hello-world
```

---

## Common Paths

| Item | Path |
|------|------|
| Build directory | `/home/yocto/project/build` |
| Configuration | `/home/yocto/project/build/conf/` |
| Source files | `/home/yocto/project/meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/` |
| Recipe | `/home/yocto/project/meta-hello-qt/recipes-qt/hello-world/hello-world.bb` |
| Poky | `/home/yocto/project/poky` |
| Build artifacts | `/home/yocto/project/build/tmp/` |

---

## Docker Container Setup Reminder

If starting fresh in Docker:

```bash
# 1. Start container
docker run -it \
  -e LANG=en_US.UTF-8 \
  -e LC_ALL=en_US.UTF-8 \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest

# 2. Then run the quick build steps above
```

---

## Quick Reference Commands

```bash
# Initialize environment (must be in build dir)
source ../poky/oe-init-build-env .

# Run verification
bash /home/yocto/project/VERIFY_SETUP.sh

# Build our app only
bitbake hello-world

# Build full image
bitbake core-image-minimal

# Clean cache and rebuild
bitbake -c cleanall hello-world && bitbake hello-world

# View BitBake version
bitbake --version

# List available recipes
bitbake-layers show-recipes | grep hello

# Check variables
bitbake -e hello-world | grep MACHINE

# View build logs
cat /home/yocto/project/build/tmp/work/qemux86-64/hello-world-0.1/temp/log.do_compile
```

---

## See Also

- [RUN_VERIFICATION.md](RUN_VERIFICATION.md) - Detailed verification guide
- [FIX_AND_BUILD.md](FIX_AND_BUILD.md) - Complete build guide
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Error solutions
