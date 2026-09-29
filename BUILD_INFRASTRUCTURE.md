# Build Infrastructure Improvements

## Overview

Updated the multi-architecture Yocto build system with optimized caching, memory management, and container orchestration to enable efficient cross-architecture builds and SCA scanning.

## Key Improvements

### 1. Architecture-Specific Sstate Cache

**Problem:** Yocto's compiled state cache (`SSTATE_DIR`) is architecture-specific. Switching between ARM64 and x86_64 targets with a shared sstate cache caused complete cache invalidation and full rebuilds every time.

**Solution:** Separate sstate cache directories per architecture:
- `~/.yocto-cache/downloads/` — Shared (packages are architecture-independent)
- `~/.yocto-cache/sstate-cache-arm64/` — ARM64 compiled binaries
- `~/.yocto-cache/sstate-cache-x86_64/` — x86_64 compiled binaries

**Result:** Switching architectures reuses cached binaries for each architecture, reducing build time from 90+ minutes to 5-15 minutes on subsequent runs.

### 2. Increased Memory Allocation

**Problem:** GCC cross-compiler compilation was causing OOM (Out of Memory) kills with 7GB memory.

**Solution:** Increased Docker container memory from 7GB to 14GB:
```bash
docker run -m 14g --memory-swap 16g
```

**Result:** Reliable builds without OOM interruptions on 36GB Mac host.

### 3. Script Consistency

All three build scripts now use identical settings:

| Setting | Value |
|---------|-------|
| Memory | 14GB |
| Memory-swap | 16GB |
| DL_DIR | `/home/yocto/cache/downloads` (shared) |
| SSTATE_DIR | `/home/yocto/cache/sstate-cache-{arm64,x86_64}` (per-arch) |

### 4. Multi-Architecture Docker Image

**New:** CONTAINER_MANAGER.sh supports multi-architecture containers.

Build multi-arch image:
```bash
docker buildx build --platform linux/arm64,linux/amd64 -t yocto-qt-builder:latest .
```

Run architecture-specific containers:
```bash
# ARM64
bash CONTAINER_MANAGER.sh arm64 start
bash CONTAINER_MANAGER.sh arm64 shell

# x86_64
bash CONTAINER_MANAGER.sh x86-64 start
bash CONTAINER_MANAGER.sh x86-64 shell
```

## Build Scripts

### BUILD_MULTI_ARCH.sh
- Primary multi-architecture build script
- Builds for ARM64 and/or x86_64
- Uses ephemeral Docker containers (`--rm`)
- Automatically manages per-architecture caches

**Usage:**
```bash
bash BUILD_MULTI_ARCH.sh [arm64|x86-64|both]
```

### BUILD_MULTI_ARCH_WITH_SCA.sh
- Extends BUILD_MULTI_ARCH.sh with Veracode SCA scanning
- Runs srcclr inside Docker container after build completes
- Generates SCA reports in `sca-reports/` directory
- Requires `SRCCLR_API_TOKEN` environment variable

**Usage:**
```bash
export SRCCLR_API_TOKEN="your-token-here"
bash BUILD_MULTI_ARCH_WITH_SCA.sh [arm64|x86-64|both]
```

**Note:** srcclr has Rosetta/QEMU incompatibility issues when running x86_64 on ARM64 Mac. Recommended: build and scan x86_64 targets natively on Linux CI/CD.

### CONTAINER_MANAGER.sh
- Manages persistent named containers for manual exploration and debugging
- Supports both ARM64 and x86_64 containers
- Preserves container state between commands

**Usage:**
```bash
bash CONTAINER_MANAGER.sh [arm64|x86-64] [command]

# Commands
start              # Start container in background
shell              # Open interactive shell
stop               # Stop container
rm                 # Remove container
status             # Show container status
logs               # Show container logs
bash [cmd]         # Run bash command in container
```

**Examples:**
```bash
# Explore ARM64 container
bash CONTAINER_MANAGER.sh arm64 start
bash CONTAINER_MANAGER.sh arm64 shell

# Debug x86_64 srcclr issue
bash CONTAINER_MANAGER.sh x86-64 start
bash CONTAINER_MANAGER.sh x86-64 bash 'uname -m'
bash CONTAINER_MANAGER.sh x86-64 bash 'srcclr --version'
```

## Cache Behavior

### First build (arm64):
```
~/.yocto-cache/downloads/        (populated)
~/.yocto-cache/sstate-cache-arm64/  (populated)
Time: ~90 minutes
```

### Switch to x86_64:
```
~/.yocto-cache/downloads/        (reused)
~/.yocto-cache/sstate-cache-x86_64/ (fresh)
Time: ~90 minutes (new architecture)
```

### Return to arm64:
```
~/.yocto-cache/downloads/        (reused)
~/.yocto-cache/sstate-cache-arm64/  (reused!)
Time: ~5-15 minutes (cached binaries)
```

## Docker Image

### Dockerfile Updates

Added srcclr (Veracode SCA agent) installation:
```dockerfile
RUN curl -sSL https://download.sourceclear.com/install | sh
```

GPG key workarounds for Ubuntu 20.04:
```dockerfile
apt-get update --allow-insecure-repositories --allow-unauthenticated
apt-get install -y --allow-unauthenticated
```

### Build Multi-Arch Image

```bash
# Requires buildx (included with Docker Desktop)
docker buildx build --platform linux/arm64,linux/amd64 -t yocto-qt-builder:latest .

# Or separate per-architecture if buildx is unavailable
docker build --platform linux/arm64 -t yocto-qt-builder:arm64 .
docker build --platform linux/amd64 -t yocto-qt-builder:x86-64 .
```

## Future Improvements

1. **Separate Images:** If multi-arch build time becomes excessive, split into per-architecture images
2. **SCA on Linux:** Run srcclr on Linux CI/CD to avoid Mac emulation issues
3. **Cache Backup:** Implement periodic backup of `.yocto-cache/` to speed up CI/CD
4. **Build Parallelization:** Coordinate parallel ARM64 + x86_64 builds on CI/CD

## Legacy Scripts

- `BUILD_HELLO_WORLD.sh` — Single-architecture build (no caching)
- `BUILD_MULTI_ARCH_PERSISTENT.sh` — Multi-arch with persistent containers (no caching)

These are kept for reference but not recommended for new work.
