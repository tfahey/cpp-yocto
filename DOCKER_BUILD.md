# Building with Docker - Complete Guide

Building Yocto on macOS is problematic because the build system requires Linux tools and a Linux kernel. **Docker solves this elegantly** by providing a containerized Linux environment with all dependencies pre-installed.

This guide walks you through building the Qt application with Docker.

---

## Why Docker?

**Pros:**
- ✓ Works on any OS (macOS, Windows, Linux)
- ✓ All dependencies included in container
- ✓ Reproducible builds (same environment everywhere)
- ✓ Isolated from your system (no dependency conflicts)
- ✓ Easy to start fresh (just delete container)

**Cons:**
- ✗ Slightly slower I/O on macOS (filesystem overhead)
- ✗ Requires Docker installation (~4 GB)
- ✗ First container build takes time (~20 min)

---

## Prerequisites

1. **Docker installed**
   - macOS: [Docker Desktop](https://www.docker.com/products/docker-desktop)
   - Linux: `sudo apt-get install docker.io`
   - Windows: [Docker Desktop](https://www.docker.com/products/docker-desktop)

2. **Disk space**
   - ~60 GB free (for Yocto build cache)
   - Docker image: ~5 GB

3. **Internet**
   - Initial Yocto downloads: ~1-2 GB

Verify Docker is installed:
```bash
docker --version
docker run hello-world
```

---

## Step 1: Create a Dockerfile

Create a file named `Dockerfile` in the project root:

```bash
touch /Users/tfahey/github/cpp-yocto/Dockerfile
```

Add this content:

```dockerfile
# Use Ubuntu 20.04 as base image
FROM ubuntu:20.04

# Set non-interactive mode (no prompts during build)
ENV DEBIAN_FRONTEND=noninteractive

# Install all build dependencies
RUN apt-get update && apt-get install -y \
    git \
    chrpath \
    diffstat \
    wget \
    python3 \
    python3-dev \
    python3-pip \
    texinfo \
    gcc \
    g++ \
    build-essential \
    ipython3 \
    cmake \
    curl \
    libncurses-dev \
    zlib1g-dev \
    gawk \
    libbz2-dev \
    libssl-dev \
    socat \
    cpio \
    time \
    bison \
    flex \
    xz-utils \
    liblz4-tool \
    zstd \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user (Yocto recommends this)
RUN useradd -m -s /bin/bash yocto && \
    echo "yocto ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to yocto user
USER yocto

# Set working directory
WORKDIR /home/yocto/project

# Print info on startup
CMD ["/bin/bash"]
```

---

## Step 2: Build the Docker Image

From the project root directory:

```bash
cd /Users/tfahey/github/cpp-yocto
docker build -t yocto-qt-builder:latest .
```

**What happens:**
- Downloads Ubuntu 20.04 base image (~200 MB)
- Installs all build dependencies (~2-3 GB)
- Creates user `yocto` for builds
- Tags the image as `yocto-qt-builder:latest`

**Time:** ~10-20 minutes (depends on internet speed)

Verify the image was created:
```bash
docker images | grep yocto-qt-builder
```

---

## Step 3: Run the Docker Container

### Option A: Interactive Session (Recommended for Learning)

Start an interactive shell:

```bash
docker run -it \
  --name yocto-build \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest
```

**What this does:**
- `-it` = Interactive terminal
- `--name yocto-build` = Container name (use this to reference it later)
- `-v` = Volume mount (share directory between host and container)
  - `/Users/tfahey/github/cpp-yocto` = Your project on host
  - `/home/yocto/project` = Where it appears in container
- `yocto-qt-builder:latest` = Image to run

You're now inside the container! Verify:
```bash
pwd          # Should be /home/yocto/project
ls -la       # Should see meta-hello-qt/, LEARNING_GUIDE.md, etc.
whoami       # Should be "yocto"
```

### Option B: Run Command Directly

To run a single command without interactive shell:

```bash
docker run --rm \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest \
  whoami
```

**Use cases:**
- Running scripts
- One-off commands
- CI/CD pipelines
- `--rm` automatically removes container after it exits

### Option C: Execute Commands in Running Container

If you have a running container:

```bash
docker exec -it yocto-build bash
```

---

## Step 4: Initialize Yocto (Inside Container)

**Inside the Docker container**, run:

```bash
cd /home/yocto/project
git clone git://git.yoctoproject.org/poky -b scarthgap
cd poky
source oe-init-build-env ../build
```

This is identical to the native build process!

---

## Step 5: Configure Yocto (Inside Container)

Edit `conf/bblayers.conf`:

```bash
cd /home/yocto/project/build
nano conf/bblayers.conf
# or use: cat conf/bblayers.conf (to view)
```

Update the BBLAYERS line:

```
BBLAYERS ?= " \
  /home/yocto/project/poky/meta \
  /home/yocto/project/poky/meta-poky \
  /home/yocto/project/poky/meta-yocto-bsp \
  /home/yocto/project/meta-hello-qt \
"
```

Edit `conf/local.conf`:

```bash
nano conf/local.conf
```

Add/modify:

```bash
MACHINE = "qemux86-64"
IMAGE_INSTALL:append = " hello-world"
```

---

## Step 6: Build (Inside Container)

Build our recipe:

```bash
cd /home/yocto/project/build
bitbake hello-world
```

Or build the full image:

```bash
bitbake core-image-minimal
```

**Note:** Build times are the same as native:
- First build: 2-6 hours
- Cached builds: 5-30 minutes

The `-v` volume mount means build artifacts are saved to your host system!

---

## Step 7: Access Build Output (From Host)

While the container is running (or after it completes), from your **host machine**:

```bash
# List deployed images
ls -la /Users/tfahey/github/cpp-yocto/build/tmp/deploy/images/

# Find the built executable
find /Users/tfahey/github/cpp-yocto/build/tmp -name hello-world -type f -executable

# View build logs
cat /Users/tfahey/github/cpp-yocto/build/tmp/work/qemux86-64/hello-world-0.1/temp/log.do_compile
```

All files are accessible from your host machine because of the `-v` volume mount!

---

## Docker Container Management

### Stop a Running Container

```bash
docker stop yocto-build
```

### Resume a Stopped Container

```bash
docker start -ai yocto-build
```

The `-a` attaches stdout/stderr, `-i` makes it interactive.

### Remove a Container

```bash
docker rm yocto-build
```

Or use `--rm` flag when running to auto-remove.

### List Containers

```bash
docker ps           # Running containers
docker ps -a        # All containers
```

### View Container Logs

```bash
docker logs yocto-build
```

### Execute Command in Running Container

```bash
docker exec -it yocto-build bash
# or run specific command:
docker exec yocto-build bitbake --version
```

---

## Performance Optimization

### 1. Enable Docker BuildKit (Faster Building)

```bash
export DOCKER_BUILDKIT=1
docker build -t yocto-qt-builder:latest .
```

### 2. Use Named Volumes for Cache Persistence

Docker containers normally lose data when deleted. To preserve the Yocto cache:

```bash
# Create a named volume
docker volume create yocto-cache

# Run container with volume mount
docker run -it \
  --name yocto-build \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  -v yocto-cache:/home/yocto/yocto-cache \
  yocto-qt-builder:latest
```

Then in the container, configure BitBake cache:

```bash
# In build/conf/local.conf, add:
DL_DIR = "/home/yocto/yocto-cache/downloads"
SSTATE_DIR = "/home/yocto/yocto-cache/sstate-cache"
```

### 3. Increase Docker Memory (If Needed)

Edit Docker settings:
- **macOS/Windows**: Docker Desktop → Preferences → Resources → Memory
- **Linux**: No limit by default

Recommended: 4+ GB

### 4. Mount Host's SSH Keys (For Git Access)

If building from private repos:

```bash
docker run -it \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  -v ~/.ssh:/home/yocto/.ssh:ro \
  yocto-qt-builder:latest
```

---

## Advanced: Docker Compose Setup

For more complex setups, create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  yocto-builder:
    build:
      context: .
      dockerfile: Dockerfile
    image: yocto-qt-builder:latest
    container_name: yocto-build
    volumes:
      - .:/home/yocto/project
      - yocto-cache:/home/yocto/yocto-cache
    environment:
      - MACHINE=qemux86-64
    stdin_open: true
    tty: true

volumes:
  yocto-cache:
```

Then run:

```bash
# Start
docker-compose up -d

# Access shell
docker-compose exec yocto-builder bash

# Build
docker-compose exec yocto-builder bash -c "cd build && bitbake hello-world"

# Stop
docker-compose down
```

---

## Troubleshooting

### Docker Daemon Not Running

**Error:** `Cannot connect to the Docker daemon`

**Solution:**
- macOS: Open Docker Desktop application
- Linux: `sudo systemctl start docker`
- Windows: Open Docker Desktop application

### Permission Denied

**Error:** `permission denied while trying to connect to Docker daemon`

**Solution (Linux only):**
```bash
sudo usermod -aG docker $USER
newgrp docker  # Refresh group membership
```

### Out of Disk Space

**Error:** `no space left on device`

**Solution:**
```bash
# Clean up Docker
docker system prune

# Or specifically:
docker container prune  # Remove stopped containers
docker image prune       # Remove unused images
```

### Slow Build on macOS

**Issue:** macOS with M1/M2 chip has filesystem overhead

**Solution:**
- Use native Linux VM or cloud instance
- Or accept slower speed (still works)

### Container Can't Access Network

**Error:** `Cannot fetch from git`

**Solution:**
```bash
# Ensure Docker has network access
docker run -it --network host yocto-qt-builder:latest
```

### Volume Mount Permissions

**Error:** `permission denied` when accessing mounted files

**Solution:** Ensure your `yocto` user in container can access files:
```bash
# Adjust in Dockerfile or container:
sudo chown -R yocto:yocto /home/yocto/project
```

---

## Building from Host vs Container

### Pure Native Build (No Docker)
```bash
# Requires: Linux OS, all dependencies installed
bitbake hello-world
# Fast, no container overhead
```

### Docker Container Build (Recommended for macOS)
```bash
# Works on: macOS, Windows, Linux
docker run -it -v ./:/home/yocto/project yocto-qt-builder:latest
# Inside container:
bitbake hello-world
# Portable, reproducible, isolated
```

### Docker Background Build
```bash
# Start container in background
docker run -d \
  --name yocto-bg \
  -v ./:/home/yocto/project \
  yocto-qt-builder:latest \
  sleep infinity

# Check on build
docker exec yocto-bg ps aux | grep bitbake

# View logs
docker logs yocto-bg
```

---

## Quick Reference: Docker Commands for This Project

```bash
# Build Docker image
docker build -t yocto-qt-builder:latest .

# Start interactive session
docker run -it \
  --name yocto-build \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest

# Execute command in running container
docker exec yocto-build bitbake hello-world

# View running containers
docker ps

# Stop container
docker stop yocto-build

# Resume container
docker start -ai yocto-build

# Remove container
docker rm yocto-build

# View container logs
docker logs yocto-build

# Access running container shell
docker exec -it yocto-build bash

# Copy file from container to host
docker cp yocto-build:/home/yocto/project/build/tmp/deploy ./output

# List images
docker images
```

---

## Summary: Docker Build Workflow

```
1. Create Dockerfile (instructions for image)
   ↓
2. Build Docker image: docker build -t yocto-qt-builder:latest .
   ↓
3. Run container with volume mount: docker run -it -v ./:/home/yocto/project ...
   ↓
4. Inside container: Clone poky, init build env
   ↓
5. Inside container: Configure bblayers.conf and local.conf
   ↓
6. Inside container: Run bitbake hello-world
   ↓
7. Build artifacts saved to host via volume mount
   ↓
8. Done! All files accessible on host machine
```

---

## Next Steps

- **Ready to build?** Start with: `docker build -t yocto-qt-builder:latest .`
- **Already have container?** Use: `docker run -it -v /Users/tfahey/github/cpp-yocto:/home/yocto/project yocto-qt-builder:latest`
- **Having issues?** Check the Troubleshooting section above
- **Want to persist cache?** Use Docker volumes for faster rebuilds

**Happy containerized building! 🐳**
