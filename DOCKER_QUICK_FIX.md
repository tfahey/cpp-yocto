# Docker Quick Fix - Git Clone Hanging Issue

**Problem:** `git clone` hangs when running inside Docker container
**Solution:** Clone Poky on your Mac, let Docker container access it via volume mount

---

## The Fix (Copy-Paste)

### On Your Mac (Terminal 1)

```bash
cd /Users/tfahey/github/cpp-yocto
git clone https://git.yoctoproject.org/poky -b scarthgap
```

This will take 1-5 minutes. If it works, continue. If it times out, this might be a network issue on your Mac too.

### Inside Docker Container (Terminal 2)

```bash
# Start container
docker run -it \
  --name yocto-build \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest

# Inside container - Poky is already there!
cd /home/yocto/project
ls -la poky/     # ← Should show the poky directory you cloned

# Initialize
cd poky
source oe-init-build-env ../build
cd ../build

# Edit configs
nano conf/bblayers.conf
nano conf/local.conf

# Build!
bitbake hello-world
```

---

## Why This Works

The `-v` flag shares your Mac's filesystem with the container:

```
/Users/tfahey/github/cpp-yocto (Mac)
        ↕️ (volume mount)
/home/yocto/project (Container)
```

Files cloned on your Mac appear instantly in the container. No need to clone twice!

---

## If Clone Fails on Mac

### Try HTTPS instead of SSH/git protocol

```bash
# Instead of:
git clone git://git.yoctoproject.org/poky -b scarthgap

# Try:
git clone https://git.yoctoproject.org/poky -b scarthgap
```

### Or download as archive

```bash
cd /Users/tfahey/github/cpp-yocto
curl -L https://git.yoctoproject.org/poky/snapshot/poky-scarthgap.tar.gz | tar xz
mv poky-scarthgap poky
```

---

## Verify It Worked

```bash
# On Mac - verify clone succeeded
ls -la /Users/tfahey/github/cpp-yocto/poky/
ls /Users/tfahey/github/cpp-yocto/poky/meta/   # Should have layers

# In container - verify it sees the clone
ls -la /home/yocto/project/poky/
ls /home/yocto/project/poky/meta/   # Should be identical
```

If both show the same files, you're good to go!

---

## Why Git Hangs in Docker (Technical)

Possible reasons:

1. **DNS**: Container can't resolve git.yoctoproject.org
2. **Network**: Docker network configuration differs from host
3. **Firewall**: Container traffic is filtered
4. **Protocol**: git:// protocol vs https://
5. **VPN**: If you're on VPN, container might not route through it

**Solution:** Use your Mac's network (proven to work) instead of container's network.

---

## Complete Step-by-Step

```bash
# ===== ON YOUR MAC =====

# 1. Navigate to project
cd /Users/tfahey/github/cpp-yocto

# 2. Clone Poky (this is the key step!)
git clone https://git.yoctoproject.org/poky -b scarthgap

# 3. Verify it worked
ls poky/   # Should show oe-init-build-env, meta/, etc.

# 4. Build Docker image
docker build -t yocto-qt-builder:latest .

# 5. Start container
docker run -it \
  --name yocto-build \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest

# ===== INSIDE CONTAINER =====

# 6. Verify poky is accessible
ls /home/yocto/project/poky/

# 7. Initialize build
cd /home/yocto/project/poky
source oe-init-build-env ../build

# 8. Go to build directory
cd ../build

# 9. Edit configurations
nano conf/bblayers.conf
# Make sure to add:
# /home/yocto/project/meta-hello-qt

nano conf/local.conf
# Make sure to add:
# MACHINE = "qemux86-64"
# IMAGE_INSTALL:append = " hello-world"

# 10. Build!
bitbake hello-world

# 11. When done, check output
find tmp -name hello-world -type f -executable

# 12. Exit container
exit

# ===== BACK ON YOUR MAC =====

# 13. Build artifacts are on your Mac!
ls /Users/tfahey/github/cpp-yocto/build/tmp/deploy/
```

---

## Troubleshooting

### "Permission denied" when accessing files in container

```bash
# Restart container without it
docker rm -f yocto-build

# Run with explicit permissions
docker run -it \
  --name yocto-build \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  --user yocto \
  yocto-qt-builder:latest
```

### "poky: No such file or directory" in container

```bash
# You forgot to clone on Mac first! Do this:
# 1. Exit container: exit
# 2. Clone on Mac: git clone https://...
# 3. Restart container: docker start -ai yocto-build
```

### Still can't see poky in container

```bash
# Verify volume mount worked
docker inspect yocto-build | grep -A 5 Mounts

# Should show something like:
# "Source": "/Users/tfahey/github/cpp-yocto",
# "Destination": "/home/yocto/project",
```

### Build is slow inside container

This is normal! Docker has filesystem overhead on macOS. It'll still finish.

To speed up (slightly):
- Increase Docker memory in settings
- Use a named volume for cache (see DOCKER_BUILD.md)

---

## One-Liner Alternative

If you want everything in one script:

```bash
cd /Users/tfahey/github/cpp-yocto && \
git clone https://git.yoctoproject.org/poky -b scarthgap && \
docker run -it \
  --name yocto-build \
  -v $(pwd):/home/yocto/project \
  yocto-qt-builder:latest
```

Then inside container, start from step 6 above.

---

## Summary

✅ Clone Poky on Mac (network you trust)
✅ Volume mount shares it automatically
✅ Container sees it immediately
✅ No hanging, no timeouts
✅ Build proceeds normally

**That's it! 🎉**

---

## More Info

- Complete Docker guide: [DOCKER_BUILD.md](DOCKER_BUILD.md)
- Volume mount details: [DOCKER_HOST_SETUP.md](DOCKER_HOST_SETUP.md)
- Docker commands: [DOCKER_CHEATSHEET.md](DOCKER_CHEATSHEET.md)
