# Docker with Host Git Clone - Best Practice

If `git clone` hangs inside the Docker container, you can clone Poky on your Mac host instead. The volume mount automatically shares it with the container!

---

## Why This Works

The `-v` flag in docker run creates a **shared volume**:

```bash
-v /Users/tfahey/github/cpp-yocto:/home/yocto/project
```

This means:
- **Host side:** `/Users/tfahey/github/cpp-yocto/` 
- **Container side:** `/home/yocto/project/`
- **Files are shared in real-time** (bidirectional)

So if you clone on the host, the container sees it immediately!

---

## Quick Workflow (Recommended)

### Step 1: Clone Poky on Your Mac

```bash
cd /Users/tfahey/github/cpp-yocto
git clone git://git.yoctoproject.org/poky -b scarthgap
```

Or if `git://` doesn't work, use HTTPS:

```bash
git clone https://git.yoctoproject.org/poky -b scarthgap
```

This should work fine on your Mac where network is normal.

### Step 2: Start Docker Container

```bash
docker run -it \
  --name yocto-build \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest
```

### Step 3: Inside Container, Poky is Already There!

```bash
# You're in: /home/yocto/project (which is your Mac's cpp-yocto/)
ls -la poky/     # It's there!
cd poky
source oe-init-build-env ../build
# ... continue with build steps ...
```

That's it! No need to clone inside the container.

---

## Why Git Might Hang Inside Container

Several possible causes:

1. **DNS issues**: Container can't resolve git.yoctoproject.org
2. **Network isolation**: Docker networking configuration
3. **Firewall**: Container network filtered
4. **Protocol**: `git://` protocol might be blocked (try `https://`)

**Solution:** Clone on host where network definitely works!

---

## Troubleshooting Git Clone on Mac

If cloning on Mac also has issues, try alternatives:

### Option A: Use HTTPS instead of git://

```bash
# Instead of:
git clone git://git.yoctoproject.org/poky -b scarthgap

# Try:
git clone https://git.yoctoproject.org/poky -b scarthgap
```

### Option B: Check Network Connectivity

```bash
# Test if you can reach the server
ping git.yoctoproject.org

# Or try SSH key-based clone
git clone ssh://git@git.yoctoproject.org/poky -b scarthgap
# (requires SSH key setup)
```

### Option C: Download as Zip

```bash
# If git doesn't work, download directly:
cd /Users/tfahey/github/cpp-yocto
curl -L https://git.yoctoproject.org/poky/snapshot/poky-scarthgap.tar.gz | tar xz
mv poky-scarthgap poky
```

---

## Docker Network Configuration (If Needed)

If you still have issues, try running container with host network:

```bash
docker run -it \
  --name yocto-build \
  --network host \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest
```

Note: `--network host` shares the host's network stack (works better for network issues on Linux, less effective on macOS Docker Desktop).

---

## Complete Workflow with Host Clone

```bash
# ==================== ON YOUR MAC ====================

# 1. Clone Poky (this will work fine on your Mac)
cd /Users/tfahey/github/cpp-yocto
git clone https://git.yoctoproject.org/poky -b scarthgap

# 2. Verify clone was successful
ls -la poky/
ls -la poky/meta/       # Should see layers

# 3. Start Docker container
docker run -it \
  --name yocto-build \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest

# ==================== INSIDE DOCKER CONTAINER ====================

# 4. Verify poky is accessible (it is!)
ls -la /home/yocto/project/poky/

# 5. Initialize build environment
cd /home/yocto/project/poky
source oe-init-build-env ../build

# 6. Configure (back in build dir)
cd ../build
nano conf/bblayers.conf
nano conf/local.conf

# 7. Build!
bitbake hello-world

# 8. Exit container when done
exit

# ==================== BACK ON YOUR MAC ====================

# 9. Build output is on your Mac!
ls -la /Users/tfahey/github/cpp-yocto/build/tmp/deploy/
```

---

## Volume Mount Behavior

### What's Shared Automatically?

- ✅ Files created/modified on host → visible in container (instantly)
- ✅ Files created/modified in container → visible on host (instantly)
- ✅ Poky cloned on host → usable in container
- ✅ Build artifacts in container → available on host after build

### What's NOT Shared?

- ❌ Permissions/ownership (may differ)
- ❌ Hard links (Docker limitation)
- ❌ Some file metadata

---

## Performance Benefit

**Cloning on host vs in container:**

| Aspect | Host Clone | Container Clone |
|--------|-----------|-----------------|
| Network | Works (your network) | May have issues |
| Speed | ~2-5 minutes | May hang/timeout |
| Reliability | High (proven) | Uncertain |
| Effort | 1 command | 1 command + troubleshooting |

**Winner:** Clone on host! 🎯

---

## Accessing Output After Build

After you `exit` the container, all build artifacts are on your Mac:

```bash
# On your Mac:
ls /Users/tfahey/github/cpp-yocto/build/tmp/deploy/images/qemux86-64/

# Find the binary:
find /Users/tfahey/github/cpp-yocto/build/tmp -name hello-world -type f -executable

# Check build logs:
cat /Users/tfahey/github/cpp-yocto/build/tmp/work/qemux86-64/hello-world-0.1/temp/log.do_compile
```

Everything is accessible because of the volume mount!

---

## Pro Tips

### Tip 1: Persistent Container

Keep your container running for faster iteration:

```bash
# Terminal 1: Start container (stays running)
docker run -it \
  --name yocto-build \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest

# Terminal 2: Clone on Mac while container waits
cd /Users/tfahey/github/cpp-yocto
git clone https://git.yoctoproject.org/poky -b scarthgap

# Back to Terminal 1 inside container: Container sees it automatically!
```

### Tip 2: Background Container

Clone while container runs in background:

```bash
# Start container in background
docker run -d \
  --name yocto-build \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest \
  sleep infinity

# Clone on Mac
cd /Users/tfahey/github/cpp-yocto
git clone https://git.yoctoproject.org/poky -b scarthgap

# Enter container when ready
docker exec -it yocto-build bash
```

### Tip 3: Symlink for Faster Startup

If you clone Poky frequently:

```bash
# On Mac: Create a shared cache directory
mkdir -p ~/yocto-cache
cd ~/yocto-cache
git clone https://git.yoctoproject.org/poky -b scarthgap poky-shared

# In projects, symlink it:
cd /Users/tfahey/github/cpp-yocto
ln -s ~/yocto-cache/poky-shared poky
```

---

## Summary

**Best Practice:** Clone Poky on your Mac, use volume mount to share with container

✅ More reliable (known-good network)
✅ Faster (no container network overhead)
✅ Simpler troubleshooting (clone on host where you can debug)
✅ Better performance (direct filesystem access)

---

## Reference: All Three Options

### Option 1: Clone on Host (Recommended) ⭐

```bash
# On Mac
git clone https://git.yoctoproject.org/poky -b scarthgap
cd poky
# Enter container
# Container sees it via volume mount
```

**Pros:** Reliable, fast, debuggable
**Cons:** Extra step

### Option 2: Clone in Container

```bash
docker run -it ... yocto-qt-builder:latest
# Inside container:
git clone git://git.yoctoproject.org/poky -b scarthgap
```

**Pros:** One-shot process
**Cons:** May hang, harder to debug

### Option 3: Clone with HTTPS in Container

```bash
docker run -it ... yocto-qt-builder:latest
# Inside container:
git clone https://git.yoctoproject.org/poky -b scarthgap
```

**Pros:** More likely to work than git://
**Cons:** Still subject to container network issues

---

## Next Steps

1. Clone Poky on your Mac (use HTTPS if unsure)
2. Verify: `ls /Users/tfahey/github/cpp-yocto/poky/`
3. Start Docker container
4. Inside container: `ls /home/yocto/project/poky/` (it's there!)
5. Follow BUILD_INSTRUCTIONS.md steps from there

**Good luck! 🚀**
