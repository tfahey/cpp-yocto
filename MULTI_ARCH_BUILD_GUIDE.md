# Multi-Architecture Qt5 Build Guide

## Overview

This project now supports building your Qt5 hello-world application for multiple target architectures from a single codebase.

## Supported Architectures

| Architecture | Machine | Use Cases | Can Test on Mac |
|--------------|---------|-----------|-----------------|
| **ARM64** | qemuarm64 | Raspberry Pi, ARM servers, Mac Docker | ✅ Yes |
| **x86-64** | qemux86-64 | Linux servers, cloud, x86 embedded | ❌ No (use Linux VM) |

## Quick Start

### Build for ARM64 (Testable on Mac Docker)
```bash
bash BUILD_MULTI_ARCH.sh arm64
```

Output: `/Users/tfahey/github/cpp-yocto/hello-world-output/arm64/hello-world`

### Build for x86-64 (For Linux Servers)
```bash
bash BUILD_MULTI_ARCH.sh x86-64
```

Output: `/Users/tfahey/github/cpp-yocto/hello-world-output/hello-world`

### Build Both Architectures
```bash
bash BUILD_MULTI_ARCH.sh both
```

## Build Times

| Stage | First Build | Subsequent Builds |
|-------|------------|-------------------|
| Download sources | 10-15 min | (skipped) |
| Build toolchain | 30-45 min | (cached) |
| Build Qt5 | 20-40 min | (cached) |
| Build hello-world | 1-2 min | 1-2 min |
| **Total** | 60-100 min | 5-15 min |

Subsequent builds of the same architecture are **much faster** due to sstate caching.

## File Organization

After building both architectures:

```
hello-world-output/
├── hello-world              ← x86-64 binary
└── arm64/
    └── hello-world          ← ARM64 binary
```

## Testing Each Binary

### ARM64 Binary on Mac Docker

```bash
docker run --rm \
  -e QT_QPA_PLATFORM=offscreen \
  -v /Users/tfahey/github/cpp-yocto/hello-world-output/arm64:/app \
  --platform linux/arm64 \
  ubuntu:20.04 \
  bash -c "
    apt-get update && apt-get install -y libqt5core5a libqt5gui5 libqt5widgets5
    /app/hello-world
  "
```

### x86-64 Binary on Linux VM

```bash
# Copy to Linux machine
scp /Users/tfahey/github/cpp-yocto/hello-world-output/hello-world user@linux-vm:

# SSH to VM
ssh user@linux-vm

# Install Qt5 libraries
sudo apt-get install libqt5core5a libqt5gui5 libqt5widgets5

# Run application
./hello-world
```

### With XQuartz Display (GUI)

**ARM64 on Mac with GUI:**
```bash
MAC_IP=$(ifconfig en0 | grep "inet " | awk '{print $2}')

docker run --rm \
  -e DISPLAY=$MAC_IP:0 \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v /Users/tfahey/github/cpp-yocto/hello-world-output/arm64:/app \
  --platform linux/arm64 \
  ubuntu:20.04 \
  bash -c "
    apt-get update && apt-get install -y libqt5core5a libqt5gui5 libqt5widgets5
    /app/hello-world
  "
```

## Modifying the Application

If you update your C++ code:

1. **Edit source files** in `meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/`
2. **Rebuild**:
   ```bash
   bash BUILD_MULTI_ARCH.sh arm64    # For ARM64
   # or
   bash BUILD_MULTI_ARCH.sh x86-64   # For x86-64
   ```

The sstate cache ensures only changed files are recompiled (usually just hello-world, ~1-2 min).

## Deployment Options

### Option 1: Raspberry Pi (ARM64)
```bash
scp hello-world-output/arm64/hello-world pi@raspberrypi:
ssh pi@raspberrypi
sudo apt-get install -y libqt5core5a libqt5gui5 libqt5widgets5
./hello-world
```

### Option 2: Cloud Server (x86-64)
```bash
scp hello-world-output/hello-world user@aws-ec2:/app/
ssh user@aws-ec2 '/app/hello-world'
```

### Option 3: Docker Registry
Push both architectures to Docker Hub for deployment:

```bash
# Create Dockerfile using the ARM64 binary
cat > Dockerfile << 'EOF'
FROM ubuntu:20.04
RUN apt-get update && apt-get install -y \
  libqt5core5a libqt5gui5 libqt5widgets5
COPY hello-world-output/arm64/hello-world /app/hello-world
ENTRYPOINT ["/app/hello-world"]
EOF

# Build and push
docker build -t myregistry/hello-world:arm64 .
docker push myregistry/hello-world:arm64
```

## Troubleshooting

### "Binary not found after build"
The build completed but the binary copy failed:
1. Check Docker is running
2. Check disk space available
3. Rebuild with verbose output:
   ```bash
   bash BUILD_MULTI_ARCH.sh arm64 2>&1 | tee build.log
   ```

### Build is very slow
On first build, this is normal. For subsequent rebuilds:
1. Check if reusing sstate cache from first build
2. Verify TMPDIR is on fast storage (SSD)
3. Check if disk is full: `df -h`

### Binary won't run on target
1. Verify binary architecture matches target:
   ```bash
   file hello-world-output/arm64/hello-world
   # Should show "ARM aarch64" or "aarch64"
   ```

2. Verify Qt5 libraries installed on target:
   ```bash
   ldd ./hello-world  # Shows dependencies
   ```

3. Verify library versions compatible:
   ```bash
   strings ./hello-world | grep Qt | head
   ```

## Build System Details

### Yocto Configuration

Each architecture has its own config:

- **ARM64**: `build-arm64/conf/local.conf` (MACHINE = qemuarm64)
- **x86-64**: `build/conf/local.conf` (MACHINE = qemux86-64)

Both share:
- Same recipe: `meta-hello-qt/recipes-qt/hello-world/hello-world_0.1.bb`
- Same source code: `meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/`
- Same layers: poky, meta-oe, meta-qt5

### Cross-Compilation

Yocto handles all cross-compilation complexity:
- ✅ Native tools built for build machine (Mac)
- ✅ Cross-compiler built for target architecture (ARM64 or x86-64)
- ✅ Libraries compiled for target
- ✅ Binary executable for target only

### Shared State Cache

BitBake caches build artifacts in `build-*/sstate-cache/`:
- Speeds up subsequent builds of same architecture
- Can be shared between machines for faster CI/CD
- Safe to delete if disk space needed (will rebuild)

## Advanced Usage

### Clean specific architecture
```bash
rm -rf build-arm64/tmp build-arm64/sstate-cache
```

### Share sstate cache between machines
```bash
# On build machine 1
tar czf sstate-arm64.tar.gz build-arm64/sstate-cache

# Transfer to build machine 2
scp sstate-arm64.tar.gz user@machine2:
tar xzf sstate-arm64.tar.gz
bash BUILD_MULTI_ARCH.sh arm64  # Will reuse cached artifacts
```

### Build for Yocto releases
Different Yocto versions available:
- scarthgap (current - what we're using)
- nanbield
- mickledore

To target different version, check out different branch of poky before building.

## What's Next

1. **Test on actual hardware** - Raspberry Pi or x86-64 device
2. **Customize your application** - Modify C++ code and rebuild
3. **Add more packages** - Use Yocto layers for additional libraries
4. **Production deployment** - Create full Yocto images with your app
5. **CI/CD integration** - Automate builds in GitHub Actions or GitLab

## Reference

- Yocto Project: https://www.yoctoproject.org/
- Qt5 with Yocto: https://github.com/meta-qt5/meta-qt5
- OpenEmbedded: https://www.openembedded.org/

