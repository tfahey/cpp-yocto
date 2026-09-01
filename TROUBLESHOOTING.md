# Troubleshooting Guide - Common Yocto + Docker Issues

This guide covers common errors and how to fix them.

---

## Locale Errors

### Error: "Please make sure locale 'en_US.UTF-8' is available"

**Cause:** Docker container doesn't have UTF-8 locale configured

**Solutions (pick one):**

**Quick fix (inside container):**
```bash
sudo apt-get install -y locales
sudo locale-gen en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
bitbake core-image-minimal
```

**Better fix (rebuild Docker image):**
```bash
# The updated Dockerfile now includes locale support
docker stop yocto-build
docker build -t yocto-qt-builder:latest .
docker run -it -v $(pwd):/home/yocto/project yocto-qt-builder:latest
```

**See:** [LOCALE_FIX.md](LOCALE_FIX.md)

---

## Recipe Not Found

### Error: "ERROR: Could not find recipe for hello-world"

**Possible causes:**
1. Layer not in BBLAYERS
2. Recipe file doesn't exist
3. Path to layer is wrong

**Diagnosis:**
```bash
# Check if layer is registered
bitbake-layers show-layers | grep hello

# Check if recipe exists
find . -name "hello-world.bb"

# Check BBLAYERS
grep meta-hello-qt conf/bblayers.conf
```

**Fix:**
```bash
# 1. Verify meta-hello-qt path exists
ls -la /home/yocto/project/meta-hello-qt/recipes-qt/hello-world/

# 2. Add to bblayers.conf if missing
nano conf/bblayers.conf
# Add: /home/yocto/project/meta-hello-qt

# 3. Verify BitBake sees it
bitbake-layers show-recipes | grep hello-world

# 4. Try again
bitbake hello-world
```

**See:** [CONFIGURE_BBLAYERS.md](CONFIGURE_BBLAYERS.md)

---

## Parse Errors

### Error: "ERROR: Parse error in conf/bblayers.conf"

**Possible causes:**
1. Syntax error (missing backslash, wrong quotes)
2. Invalid path
3. Trailing spaces

**Diagnosis:**
```bash
# Show the exact error
bitbake -e 2>&1 | grep -i "error\|parse" | head -5

# Check syntax
cat -A conf/bblayers.conf | tail -10
# Look for trailing spaces (shown as $) or missing backslashes
```

**Fix:**
```bash
# Backup and recreate
cp conf/bblayers.conf conf/bblayers.conf.bad
rm conf/bblayers.conf

# Regenerate
cd ../poky
source oe-init-build-env ../build
cd ../build

# Edit carefully
nano conf/bblayers.conf
# Follow the template exactly
```

**Common bblayers.conf mistakes:**
```bash
# ❌ WRONG - missing backslash
BBLAYERS ?= " \
  /path/to/meta \
  /path/to/layer
  /path/to/another \
"

# ✅ CORRECT - all have backslashes except last line
BBLAYERS ?= " \
  /path/to/meta \
  /path/to/layer \
  /path/to/another \
"
```

**See:** [CONFIGURE_BBLAYERS.md](CONFIGURE_BBLAYERS.md)

---

## Build Failures

### Error: "ERROR: Task xyz failed"

**Cause varies by task. Common ones:**

**Task: do_fetch**
```
ERROR: Fetcher failure for URL: git://git.yoctoproject.org/poky
```
→ Network issue, check internet connection

```bash
# Fix: try ping
ping git.yoctoproject.org

# If DNS fails:
cat /etc/resolv.conf
# In Docker, may need: --dns 8.8.8.8
```

**Task: do_configure**
```
ERROR: cmake: command not found
```
→ Build dependency missing

```bash
# Check if cmake is installed
which cmake
```

**Task: do_compile**
```
ERROR: fatal error: mainwindow.h: No such file or directory
```
→ Source file missing or path wrong in CMakeLists.txt

```bash
# Verify source files exist
ls -la meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/
# Should show: main.cpp, mainwindow.h, mainwindow.cpp

# Check CMakeLists.txt references them
grep "mainwindow" meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/CMakeLists.txt
```

**Task: do_package**
```
ERROR: Package hello-world: Files/directories were found, but no packages were specified
```
→ Recipe doesn't specify what files to package

```bash
# In hello-world.bb, make sure you have:
# install(TARGETS hello-world DESTINATION bin)
# in CMakeLists.txt
```

---

## Out of Disk Space

### Error: "No space left on device"

**Cause:** Build cache got too large

**Diagnosis:**
```bash
# Check disk usage
df -h /home/yocto/project

# Check Yocto cache size
du -sh /home/yocto/project/build/tmp/
```

**Fix:**
```bash
# Clean build cache
bitbake -c cleanall hello-world
# or
bitbake -c clean core-image-minimal

# Or remove entire cache
rm -rf /home/yocto/project/build/tmp/

# Verify space freed
df -h /home/yocto/project
```

**Prevention:** For Docker, use named volumes:
```bash
docker run -it \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  -v yocto-cache:/home/yocto/yocto-cache \
  yocto-qt-builder:latest

# Then configure in local.conf:
DL_DIR = "/home/yocto/yocto-cache/downloads"
SSTATE_DIR = "/home/yocto/yocto-cache/sstate-cache"
```

---

## Qt5 Not Found

### Error: "Could not find Qt5"

**Cause:** Qt5 recipes not available or path wrong

**Diagnosis:**
```bash
# Check if Qt5 recipes are in layers
bitbake-layers show-recipes | grep qt5

# Check if qt5-base is available
bitbake-layers show-recipes | grep "^qt5-base "
```

**Fix:**
```bash
# Make sure core layers are in BBLAYERS
grep "BBLAYERS" conf/bblayers.conf | head -5

# Should include:
# - /path/to/poky/meta
# - /path/to/poky/meta-poky

# Qt5 is in those core layers, shouldn't need anything else
```

---

## Git Clone Hanging

### Issue: `git clone` hangs when cloning Poky

**Cause:** Network issue in Docker container

**Solution:** Clone on host machine

```bash
# On your Mac
cd /Users/tfahey/github/cpp-yocto
git clone https://git.yoctoproject.org/poky -b scarthgap

# Start Docker (Poky already accessible via volume mount)
docker run -it -v $(pwd):/home/yocto/project yocto-qt-builder:latest

# In container
ls /home/yocto/project/poky/
# Already there!
```

**See:** [DOCKER_QUICK_FIX.md](DOCKER_QUICK_FIX.md)

---

## Permission Denied in Container

### Error: "Permission denied" when accessing files

**Cause:** File ownership mismatch between host and container

**Diagnosis:**
```bash
# Check file ownership in container
ls -la /home/yocto/project/
# Shows what user owns the files

# Check current user in container
whoami
# Should be "yocto"
```

**Fix:**
```bash
# Option 1: Fix ownership in container
sudo chown -R yocto:yocto /home/yocto/project/

# Option 2: Run container with specific user
docker run -it \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  --user yocto \
  yocto-qt-builder:latest
```

---

## Cannot Connect to Network

### Error: "Failed to download file" or network timeouts

**Cause:** Docker network isolation or firewall

**Diagnosis:**
```bash
# Check if can reach internet
ping 8.8.8.8

# Check DNS
nslookup google.com
```

**Fix:**
```bash
# Option 1: Use host network (Linux only)
docker run -it \
  --network host \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest

# Option 2: Specify DNS
docker run -it \
  --dns 8.8.8.8 \
  --dns 1.1.1.1 \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest
```

---

## Container Crashes or Stops

### Issue: Container exits after starting

**Diagnosis:**
```bash
# Check exit code
docker ps -a | grep yocto-build
# Look at STATUS column

# Check logs
docker logs yocto-build
# Shows why container stopped
```

**Common causes:**

**Out of memory:**
```
docker logs shows: "Cannot allocate memory"
→ Increase Docker memory in settings
```

**Corrupt filesystem:**
```
docker logs shows: filesystem errors
→ Restart Docker daemon
```

**Old image:**
```
docker logs shows: strange errors
→ Rebuild image: docker build --no-cache ...
```

---

## Verifying Setup

When things go wrong, verify step-by-step:

```bash
# 1. Check layer is registered
bitbake-layers show-layers | grep hello

# 2. Check recipe is found
bitbake-layers show-recipes | grep hello-world

# 3. Check variables are set
bitbake -e | grep "^MACHINE="
bitbake -e | grep "^IMAGE_INSTALL="

# 4. Check BBLAYERS syntax
bitbake -e 2>&1 | head -5
# Should NOT show "Parse error"

# 5. Try building with verbose
bitbake -v hello-world

# 6. Check build logs
cat /home/yocto/project/build/tmp/work/*/hello-world-*/temp/log.do_*
```

---

## Getting Help

If you're still stuck:

1. **Check the error message carefully** - it usually says what's wrong
2. **Search [LEARNING_GUIDE.md](LEARNING_GUIDE.md)** for concepts
3. **Check [QUICK_REFERENCE.md](QUICK_REFERENCE.md)** for variables
4. **Run verification commands** above
5. **Check logs** in `build/tmp/work/.../temp/`

**Log file locations:**
```bash
# BitBake logs
build/tmp/work/qemux86-64/hello-world-0.1/temp/

# Compile log
build/tmp/work/qemux86-64/hello-world-0.1/temp/log.do_compile

# Configure log
build/tmp/work/qemux86-64/hello-world-0.1/temp/log.do_configure

# Install log
build/tmp/work/qemux86-64/hello-world-0.1/temp/log.do_install
```

---

## Related Documents

- [LOCALE_FIX.md](LOCALE_FIX.md) - Locale errors
- [CONFIGURE_BBLAYERS.md](CONFIGURE_BBLAYERS.md) - Configuration errors
- [CONFIGURE_LOCAL_CONF.md](CONFIGURE_LOCAL_CONF.md) - local.conf errors
- [DOCKER_QUICK_FIX.md](DOCKER_QUICK_FIX.md) - Docker/git issues
- [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md) - Full build workflow
