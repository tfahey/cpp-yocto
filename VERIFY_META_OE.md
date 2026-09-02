# Verify meta-openembedded - Troubleshooting

**Issue:** `/home/yocto/project/meta-openembedded/meta-qt5` doesn't exist

**Likely causes:**
1. meta-openembedded not cloned on Mac yet
2. Clone is in progress (takes a few minutes)
3. Clone failed silently
4. Volume mount issue

---

## Step-by-Step Verification

### Step 1: Check if Clone Exists on Mac

On your Mac:

```bash
# Check if meta-openembedded exists
ls -la /Users/tfahey/github/cpp-yocto/meta-openembedded/

# If it doesn't exist, clone it now:
cd /Users/tfahey/github/cpp-yocto
git clone https://github.com/openembedded/meta-openembedded.git -b scarthgap

# Wait for it to complete (5-10 minutes)
# You'll see progress like:
# Cloning into 'meta-openembedded'...
# remote: Enumerating objects: 12345, done.
# ...
# Receiving objects: 100% ...
# Resolving deltas: 100% ...
```

### Step 2: Verify Clone Contents

After cloning, verify the structure:

```bash
# Check directory structure
ls -la /Users/tfahey/github/cpp-yocto/meta-openembedded/

# Should show directories including:
# - meta-oe/
# - meta-qt5/     ← This is what we need
# - meta-python/
# - etc.

# Specifically verify meta-qt5 exists
ls -la /Users/tfahey/github/cpp-yocto/meta-openembedded/meta-qt5/

# Should show:
# - conf/
# - recipes-qt/
# - etc.
```

### Step 3: Verify Volume Mount in Container

Inside Docker, check if the directory is accessible:

```bash
# In Docker container
ls -la /home/yocto/project/meta-openembedded/

# Should show same directories as on Mac:
# meta-oe/
# meta-qt5/
# meta-python/
# etc.

# If you see it on Mac but not in Docker, the volume mount might be incomplete
```

### Step 4: If Not Visible in Container

If it exists on Mac but not in container:

**Option A: Restart Container**

```bash
# On Mac
docker stop yocto-build
docker rm yocto-build

# Wait a few seconds

# Restart
docker run -it \
  -e LANG=en_US.UTF-8 \
  -e LC_ALL=en_US.UTF-8 \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest

# Inside container, verify
ls -la /home/yocto/project/meta-openembedded/
```

**Option B: Reinitialize Yocto Build**

```bash
# Inside container
cd /home/yocto/project/build
source ../poky/oe-init-build-env .

# Check again
ls -la /home/yocto/project/meta-openembedded/
```

---

## Clone Status Check

### If Clone is Taking Time

Git clones can take 5-10 minutes depending on:
- Internet speed
- Repository size (~500MB)
- Disk speed

**Check progress:**

```bash
# On Mac, while cloning is happening
ps aux | grep git

# Should show:
# git clone https://github.com/openembedded/...

# Or check disk usage (files being written)
du -sh /Users/tfahey/github/cpp-yocto/meta-openembedded/
# Will show growing size like: 100M, 200M, 300M...
```

### If Clone Failed

```bash
# Check if partial clone exists
ls -la /Users/tfahey/github/cpp-yocto/meta-openembedded/

# If it's incomplete or empty
rm -rf /Users/tfahey/github/cpp-yocto/meta-openembedded/

# Try again with HTTPS (more reliable)
cd /Users/tfahey/github/cpp-yocto
git clone https://github.com/openembedded/meta-openembedded.git -b scarthgap

# Or if HTTPS fails, try git protocol
git clone git://git.openembedded.org/meta-openembedded -b scarthgap
```

---

## Complete Verification Checklist

Run these checks in order:

### On Mac:

```bash
# 1. Does meta-openembedded exist?
ls -d /Users/tfahey/github/cpp-yocto/meta-openembedded && echo "✓ exists" || echo "✗ missing"

# 2. Does meta-qt5 subdirectory exist?
ls -d /Users/tfahey/github/cpp-yocto/meta-openembedded/meta-qt5 && echo "✓ exists" || echo "✗ missing"

# 3. Does meta-oe subdirectory exist?
ls -d /Users/tfahey/github/cpp-yocto/meta-openembedded/meta-oe && echo "✓ exists" || echo "✗ missing"

# 4. How much space does it take?
du -sh /Users/tfahey/github/cpp-yocto/meta-openembedded/
# Should be ~500MB if complete
```

### In Docker:

```bash
# 1. Is volume mount working?
ls -d /home/yocto/project && echo "✓ project dir exists" || echo "✗ missing"

# 2. Can we see meta-openembedded?
ls -d /home/yocto/project/meta-openembedded && echo "✓ exists" || echo "✗ missing"

# 3. Can we see meta-qt5?
ls -d /home/yocto/project/meta-openembedded/meta-qt5 && echo "✓ exists" || echo "✗ missing"

# 4. If all exist, verify bblayers.conf paths are correct
grep meta-qt5 /home/yocto/project/build/conf/bblayers.conf
# Should show: /home/yocto/project/meta-openembedded/meta-qt5
```

---

## If meta-openembedded Still Doesn't Exist

### Option 1: Manual Download

```bash
# On Mac, download from GitHub
cd /Users/tfahey/github/cpp-yocto

# Visit: https://github.com/openembedded/meta-openembedded
# Click "Code" button
# Click "Download ZIP"
# Save to Downloads folder
# Extract: unzip ~/Downloads/meta-openembedded-scarthgap.zip
# Rename: mv meta-openembedded-scarthgap meta-openembedded

# Verify
ls -la meta-openembedded/meta-qt5/
```

### Option 2: Check Git Configuration

```bash
# Verify git is working
git --version

# Test git connectivity
git ls-remote https://github.com/openembedded/meta-openembedded.git | head -5

# If this works, try cloning again
git clone https://github.com/openembedded/meta-openembedded.git -b scarthgap
```

### Option 3: Check Network/Firewall

```bash
# Test internet connection
ping -c 3 github.com

# If this fails, you may need to configure network/proxy
# Contact your network administrator
```

---

## What to Do Next

Once meta-openembedded is verified on Mac and visible in Docker:

```bash
# In Docker
cd /home/yocto/project/build

# Verify layers are registered
bitbake-layers show-layers | grep -E "meta-oe|meta-qt5"

# Should show:
# meta-oe            /home/yocto/project/meta-openembedded/meta-oe
# meta-qt5           /home/yocto/project/meta-openembedded/meta-qt5

# Verify Qt5 recipes are found
bitbake-layers show-recipes | grep qt5-base

# Should show: qt5-base

# Build!
bitbake hello-world
```

---

## Summary

**Issue:** Directory not found

**Fix checklist:**
1. ☐ Clone meta-openembedded on Mac
2. ☐ Verify clone completed successfully  
3. ☐ Verify meta-qt5 directory exists on Mac
4. ☐ Restart Docker container
5. ☐ Verify volume mount shows directory in container
6. ☐ Update bblayers.conf (if not already done)
7. ☐ Run bitbake-layers to verify registration
8. ☐ Build

---

## See Also

- **QT5_MISSING_FIX.md** - Complete Qt5 setup guide
- **QUICK_QT5_FIX.md** - 5-minute quick fix
- **TROUBLESHOOTING.md** - General troubleshooting
