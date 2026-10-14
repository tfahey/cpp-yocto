# Container Manual Testing Guide

This guide shows how to manually test builds and Veracode SAST packaging using `CONTAINER_MANAGER.sh`.

## Prerequisites

1. **Docker images built:**
   ```bash
   docker build -t yocto-qt-builder:arm64 .
   docker build --platform linux/amd64 -t yocto-qt-builder:x86-64 -f Dockerfile.x86-64 .
   ```

2. **Veracode credentials (optional, for x86-64 SAST packaging):**
   ```bash
   export VERACODE_API_ID="your-id"
   export VERACODE_API_KEY="your-key"
   ```

## Quick Start

### Start a Container

```bash
# ARM64 (native on Mac)
bash CONTAINER_MANAGER.sh arm64 start

# x86-64 (emulated on Mac via QEMU)
bash CONTAINER_MANAGER.sh x86-64 start
```

### Open Interactive Shell

```bash
bash CONTAINER_MANAGER.sh arm64 shell
# or
bash CONTAINER_MANAGER.sh x86-64 shell
```

## Manual Build Workflow

Inside the container shell:

### 1. Activate Yocto Environment

```bash
cd /home/yocto/project
source poky/oe-init-build-env ./build-arm64
# or for x86-64:
# source poky/oe-init-build-env ./build-x86-64
```

### 2. Fix Cache Permissions

The first time you build, fix permissions on the cache volumes:

```bash
# For ARM64
sudo mkdir -p /home/yocto/cache/tmp-arm64-glibc
sudo chown -R yocto:yocto /home/yocto/cache/tmp-arm64-glibc
sudo chmod -R 755 /home/yocto/cache/tmp-arm64-glibc
sudo mkdir -p /home/yocto/cache/sstate-cache-arm64
sudo chown -R yocto:yocto /home/yocto/cache/sstate-cache-arm64
sudo chmod -R 755 /home/yocto/cache/sstate-cache-arm64

# For x86-64
sudo mkdir -p /home/yocto/cache/tmp-x86-64-glibc
sudo chown -R yocto:yocto /home/yocto/cache/tmp-x86-64-glibc
sudo chmod -R 755 /home/yocto/cache/tmp-x86-64-glibc
sudo mkdir -p /home/yocto/cache/sstate-cache-x86-64
sudo chown -R yocto:yocto /home/yocto/cache/sstate-cache-x86-64
sudo chmod -R 755 /home/yocto/cache/sstate-cache-x86-64
```

### 3. Run Bitbake

```bash
bitbake hello-world
```

### 4. Find the Binary

After successful build:

```bash
find /home/yocto/cache/tmp-*/work -name "hello-world" -type f | grep -v "\.so"
```

Or check the output directory:

```bash
ls -lh /home/yocto/project/hello-world-output/
```

### 5. Run Veracode SAST Packaging (x86-64 only)

After build completes, in the same shell (environment still active):

```bash
# Make sure credentials are available (if set at container start)
sudo -E /veracode package \
    --source /home/yocto/project/meta-hello-qt/recipes-qt/hello-world \
    --type directory \
    -o /home/yocto/project/veracode-package \
    --trust \
    --verbose
```

Check the output:

```bash
ls -lh /home/yocto/project/veracode-package/
```

## Container Management

### View Container Status

```bash
bash CONTAINER_MANAGER.sh arm64 status
bash CONTAINER_MANAGER.sh x86-64 status
```

### Stop Container

```bash
bash CONTAINER_MANAGER.sh arm64 stop
bash CONTAINER_MANAGER.sh x86-64 stop
```

### Remove Container

```bash
bash CONTAINER_MANAGER.sh arm64 rm
bash CONTAINER_MANAGER.sh x86-64 rm
```

### Run Commands Without Shell

```bash
bash CONTAINER_MANAGER.sh arm64 bash "cd /home/yocto/project && ls -la"
bash CONTAINER_MANAGER.sh x86-64 bash "bitbake hello-world"
```

### View Container Logs

```bash
bash CONTAINER_MANAGER.sh arm64 logs
bash CONTAINER_MANAGER.sh x86-64 logs
```

## Troubleshooting

### Permission Denied on Cache Directories

**Symptom:** `PermissionError: [Errno 13] Permission denied: '/home/yocto/cache/tmp-*-glibc'`

**Solution:** Run the permission fix (step 2 above)

```bash
sudo chown -R yocto:yocto /home/yocto/cache/tmp-*-glibc
sudo chmod -R 755 /home/yocto/cache/tmp-*-glibc
```

### Bitbake Server Startup Failure

**Symptom:** `ERROR: Unable to start bitbake server`

**Solution:** Clean the container and restart:

```bash
bash CONTAINER_MANAGER.sh x86-64 rm
bash CONTAINER_MANAGER.sh x86-64 start
bash CONTAINER_MANAGER.sh x86-64 shell
```

### Veracode CLI Not Found (x86-64)

**Symptom:** `/veracode: No such file or directory`

**Solution:** Verify the x86-64 image has veracode installed:

```bash
docker run --rm --platform linux/amd64 yocto-qt-builder:x86-64 ls -la /veracode
```

If not found, rebuild the image:

```bash
docker build --platform linux/amd64 -t yocto-qt-builder:x86-64 -f Dockerfile.x86-64 . --no-cache
```

### x86-64 Emulation Slowness

On ARM64 Mac, x86-64 builds run through QEMU emulation and are significantly slower. This is expected.

**Recommendation:** For fast iteration, use ARM64:

```bash
bash CONTAINER_MANAGER.sh arm64 start
bash CONTAINER_MANAGER.sh arm64 shell
```

## Environment-Specific Notes

### ARM64 (Native on Mac)

- ✅ Fast (no emulation)
- ❌ Veracode packaging not available (CLI x86-64 only)
- Use for: Development, testing, quick builds

### x86-64 (Emulated via QEMU on Mac)

- ❌ Slower due to emulation
- ✅ Veracode SAST packaging available
- Use for: Final packaging, SAST analysis, production builds

## Reusing Persistent Containers

Containers persist between runs, so you can:

1. Start the container once
2. Run multiple commands/shells without rebuilding
3. Cache is preserved across sessions

This is useful for iterative development:

```bash
# Session 1: Build
bash CONTAINER_MANAGER.sh arm64 shell
bitbake hello-world
exit

# Session 2: Modify source, rebuild (cache reused)
bash CONTAINER_MANAGER.sh arm64 shell
bitbake hello-world
exit

# Session 3: Package and test
bash CONTAINER_MANAGER.sh arm64 shell
ls -la hello-world-output/
exit
```

To start fresh, remove the container:

```bash
bash CONTAINER_MANAGER.sh arm64 rm
bash CONTAINER_MANAGER.sh arm64 start
```
