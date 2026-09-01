# Docker Quick Reference for Yocto Builds

Copy-paste commands for common Docker tasks with this project.

---

## Basic Setup

### Build Docker Image

```bash
cd /Users/tfahey/github/cpp-yocto
docker build -t yocto-qt-builder:latest .
```

Time: ~15-20 minutes (first time only)

### Start Interactive Container

```bash
docker run -it \
  --name yocto-build \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest
```

Now you're inside the container. All paths inside are `/home/yocto/project/...`

---

## Inside the Container

```bash
# Clone Poky
cd /home/yocto/project
git clone git://git.yoctoproject.org/poky -b scarthgap

# Initialize build
cd poky
source oe-init-build-env ../build
cd ../build

# Edit config files
nano conf/bblayers.conf
nano conf/local.conf

# Build our app
bitbake hello-world

# Build full image
bitbake core-image-minimal

# Exit container (doesn't stop it, just disconnects shell)
exit
```

---

## Container Management (From Host)

### View Running Containers

```bash
docker ps
```

### View All Containers (including stopped)

```bash
docker ps -a
```

### Stop Running Container

```bash
docker stop yocto-build
```

### Resume Stopped Container

```bash
docker start -ai yocto-build
```

The `-a` flag attaches output, `-i` makes it interactive.

### Remove Container

```bash
docker rm yocto-build
```

Only works if container is stopped.

### View Container Logs

```bash
docker logs yocto-build
```

### Check Container Status

```bash
docker inspect yocto-build
```

---

## Running Commands Without Interactive Shell

### Execute Command in Running Container

```bash
docker exec yocto-build bitbake hello-world
```

Or with interactive terminal:

```bash
docker exec -it yocto-build bash
```

### Run Command and Get Output

```bash
docker exec yocto-build bash -c "cd /home/yocto/project/build && bitbake --version"
```

### Copy File from Container to Host

```bash
docker cp yocto-build:/home/yocto/project/build/tmp/deploy /tmp/yocto-output
```

### Copy File from Host to Container

```bash
docker cp /path/to/file yocto-build:/home/yocto/project/
```

---

## One-Off Commands (No Persistent Container)

### Run and Automatically Remove

```bash
docker run --rm \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest \
  whoami
```

The `--rm` flag automatically deletes the container when it exits.

### Run Background Build and Check Later

```bash
# Start container in background
docker run -d \
  --name yocto-build-bg \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest \
  bash -c "cd /home/yocto/project && git clone git://git.yoctoproject.org/poky -b scarthgap && \
           cd poky && source oe-init-build-env ../build && cd ../build && \
           bitbake hello-world"

# Check on it
docker logs -f yocto-build-bg

# When done
docker rm yocto-build-bg
```

---

## Image Management

### List Images

```bash
docker images
```

### Remove Image

```bash
docker rmi yocto-qt-builder:latest
```

Can only remove if no containers use it.

### Rebuild Image (Force)

```bash
docker build --no-cache -t yocto-qt-builder:latest .
```

### Tag Image with Different Name

```bash
docker tag yocto-qt-builder:latest yocto-builder:v1
```

---

## Debugging

### Enter Running Container Shell

```bash
docker exec -it yocto-build bash
```

### View Full Container Details

```bash
docker inspect yocto-build | jq .
```

(requires `jq` on host; use `docker inspect yocto-build` without piping for raw JSON)

### Check Disk Usage

```bash
docker exec yocto-build df -h /home/yocto/project
```

### View Processes in Container

```bash
docker exec yocto-build ps aux
```

### Monitor Resource Usage

```bash
docker stats yocto-build
```

---

## Volume & Data Persistence

### Create Named Volume

```bash
docker volume create yocto-cache
```

### Use Named Volume

```bash
docker run -it \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  -v yocto-cache:/home/yocto/yocto-cache \
  yocto-qt-builder:latest
```

Then configure in `build/conf/local.conf`:
```bash
DL_DIR = "/home/yocto/yocto-cache/downloads"
SSTATE_DIR = "/home/yocto/yocto-cache/sstate-cache"
```

### List Volumes

```bash
docker volume ls
```

### Remove Volume

```bash
docker volume rm yocto-cache
```

### Inspect Volume

```bash
docker volume inspect yocto-cache
```

---

## Cleanup

### Stop and Remove All Containers

```bash
docker container prune
```

Will prompt for confirmation.

### Remove All Unused Images

```bash
docker image prune
```

### Remove All Unused Volumes

```bash
docker volume prune
```

### Clean Everything (Dangerous!)

```bash
docker system prune -a
```

Removes all containers, images, volumes, networks not in use.

---

## Troubleshooting

### Docker Daemon Not Running

```bash
# macOS: Open Docker Desktop app
# Linux: sudo systemctl start docker
# Windows: Open Docker Desktop app
```

### Permission Denied (Linux)

```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Out of Disk Space

```bash
# Check Docker disk usage
docker system df

# Clean up
docker system prune -a --volumes
```

### Slow Build on macOS

```bash
# Docker Desktop > Preferences > Resources
# Increase CPU cores and memory allocation
```

### Can't Connect to Network Inside Container

```bash
docker run -it --network host yocto-qt-builder:latest
```

---

## Docker Compose (Alternative)

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  yocto-builder:
    build: .
    image: yocto-qt-builder:latest
    container_name: yocto-build
    volumes:
      - .:/home/yocto/project
    stdin_open: true
    tty: true
```

Then:

```bash
# Start
docker-compose up -d

# Access shell
docker-compose exec yocto-builder bash

# Run command
docker-compose exec yocto-builder bitbake hello-world

# Stop
docker-compose down
```

---

## Quick Command Summary

```bash
# Most common workflow
docker build -t yocto-qt-builder:latest .              # Build image
docker run -it --name yocto-build -v $(pwd):/home/yocto/project yocto-qt-builder:latest  # Start
# ... build inside ...
exit                                                    # Exit shell
docker start -ai yocto-build                           # Resume later
docker exec yocto-build bitbake hello-world            # Run command without shell
docker logs yocto-build                                # View logs
docker stop yocto-build                                # Stop
docker rm yocto-build                                  # Delete
```

---

## For More Information

- **Complete Docker guide:** See [DOCKER_BUILD.md](DOCKER_BUILD.md)
- **Official Docker docs:** https://docs.docker.com/
- **This project's README:** See [README.md](README.md)
