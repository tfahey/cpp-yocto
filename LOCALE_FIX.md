# Locale Error Fix - "en_US.UTF-8" Not Available

**Error:** `Please make sure locale 'en_US.UTF-8' is available on your system`

**Cause:** Docker container doesn't have the locale installed or configured

**Solution:** Install and generate the locale

---

## Quick Fix (Inside Container)

Run these commands **inside your Docker container**:

```bash
# Install locale package
sudo apt-get update
sudo apt-get install -y locales

# Generate en_US.UTF-8 locale
sudo locale-gen en_US.UTF-8

# Update locale database
sudo update-locale LANG=en_US.UTF-8

# Set environment variable for current session
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Verify locale is available
locale -a | grep en_US
# Should show: en_US.utf8
```

Then try your build again:

```bash
bitbake core-image-minimal
```

---

## If Quick Fix Doesn't Work

Try these additional steps:

### Option 1: Set Locale in Current Shell

```bash
# Just for this terminal session
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# Verify
locale
# Should show en_US.UTF-8 for LANG

# Try build again
bitbake core-image-minimal
```

### Option 2: Rebuild Docker Image (Permanent Fix)

Stop container and rebuild with locale support:

```bash
# Exit container
exit

# Stop container
docker stop yocto-build

# Rebuild image with locale fix
docker build -t yocto-qt-builder:latest .

# Start new container
docker run -it \
  --name yocto-build-2 \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest
```

Note: The Dockerfile now includes locale generation automatically!

---

## How to Prevent This (Updated Dockerfile)

The Dockerfile has been updated to include locale support automatically. If you rebuild the image, you won't get this error.

**New Dockerfile includes:**
```dockerfile
# Generate locales
RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

# Set environment
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
```

---

## Understanding the Error

### Why This Happens

1. **Yocto requires UTF-8 locale** for proper character handling
2. **Docker containers start minimal** - locales aren't pre-installed
3. **Ubuntu 20.04 in container** doesn't generate locales by default
4. **BitBake checks for locale** before building

### Why It Matters

- UTF-8 encoding supports international characters
- Yocto recipes may include non-ASCII text
- Build tools need consistent encoding

---

## Verification Commands

After fixing, verify locale is set:

```bash
# Check current locale
locale

# Should show:
# LANG=en_US.UTF-8
# LC_ALL=en_US.UTF-8
# LANGUAGE=en_US.UTF-8

# Check available locales
locale -a | grep en_US
# Should show: en_US.utf8

# Check system locale database
cat /etc/default/locale
# Should show: LANG=en_US.UTF-8
```

---

## If Still Getting Error

### Check locale was actually generated

```bash
# Regenerate locale explicitly
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8

# Force update
sudo dpkg-reconfigure locales
# Select en_US.UTF-8 when prompted
```

### Check container environment

```bash
# Show all environment variables
env | grep -i locale

# Should show:
# LANG=en_US.UTF-8
# LC_ALL=en_US.UTF-8

# If not set, add to .bashrc
echo "export LANG=en_US.UTF-8" >> ~/.bashrc
echo "export LC_ALL=en_US.UTF-8" >> ~/.bashrc
source ~/.bashrc
```

### Restart container with locale

```bash
# Exit and remove container
exit
docker rm yocto-build

# Start with explicit locale env vars
docker run -it \
  --name yocto-build \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  -e LANG=en_US.UTF-8 \
  -e LC_ALL=en_US.UTF-8 \
  yocto-qt-builder:latest
```

---

## Complete Locale Setup (All Steps)

If you want to be thorough:

```bash
# 1. Install locales package
sudo apt-get update
sudo apt-get install -y locales

# 2. Generate en_US.UTF-8
sudo locale-gen en_US.UTF-8

# 3. Update locale database
sudo update-locale LANG=en_US.UTF-8

# 4. Set for current session
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# 5. Add to shell config for persistence
echo "export LANG=en_US.UTF-8" >> ~/.bashrc
echo "export LC_ALL=en_US.UTF-8" >> ~/.bashrc

# 6. Apply changes
source ~/.bashrc

# 7. Verify
locale
locale -a | grep en_US

# 8. Now build
bitbake core-image-minimal
```

---

## Docker Run with Locale (Easiest)

Next time you start a container, include locale env vars:

```bash
docker run -it \
  --name yocto-build \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  -e LANG=en_US.UTF-8 \
  -e LC_ALL=en_US.UTF-8 \
  -e LANGUAGE=en_US.UTF-8 \
  yocto-qt-builder:latest
```

Then inside container, just run:

```bash
bitbake core-image-minimal
```

---

## Advanced: Docker Compose with Locale

If using Docker Compose, add environment to `docker-compose.yml`:

```yaml
version: '3.8'

services:
  yocto-builder:
    build: .
    image: yocto-qt-builder:latest
    container_name: yocto-build
    volumes:
      - .:/home/yocto/project
    environment:
      - LANG=en_US.UTF-8
      - LC_ALL=en_US.UTF-8
      - LANGUAGE=en_US.UTF-8
    stdin_open: true
    tty: true
```

---

## Summary

**Immediate fix (inside container):**
```bash
sudo apt-get install -y locales
sudo locale-gen en_US.UTF-8
export LANG=en_US.UTF-8
bitbake core-image-minimal
```

**Better fix (rebuild image):**
```bash
# Exit container, rebuild with updated Dockerfile
docker stop yocto-build
docker build -t yocto-qt-builder:latest .
docker run -it -v $(pwd):/home/yocto/project yocto-qt-builder:latest
```

**Best fix (next time):**
```bash
# Start container with locale env vars
docker run -it \
  -e LANG=en_US.UTF-8 \
  -e LC_ALL=en_US.UTF-8 \
  -v $(pwd):/home/yocto/project \
  yocto-qt-builder:latest
```

---

## Related Issues

If you see similar locale errors with other languages:
- `de_DE.UTF-8` not found → `sudo locale-gen de_DE.UTF-8`
- `fr_FR.UTF-8` not found → `sudo locale-gen fr_FR.UTF-8`
- `ja_JP.UTF-8` not found → `sudo locale-gen ja_JP.UTF-8`

The pattern is always: `sudo locale-gen [LANGUAGE_CODE].UTF-8`

---

## See Also

- **Dockerfile** - Now includes locale generation
- **DOCKER_BUILD.md** - Docker setup guide
- **DOCKER_CHEATSHEET.md** - Docker commands
- **TROUBLESHOOTING.md** (coming soon) - Other Yocto errors
