# Manual Veracode Testing in Persistent Container

This guide explains how to manually test the Veracode SAST packaging workflow inside a persistent container for debugging and development.

## ✅ Confirmed Solution

**Veracode package works when pointed to the recipes directory:**
- **Source**: `/home/yocto/project/meta-hello-qt/recipes-qt/hello-world` ✅
- **Why it works**: Veracode discovers the Yocto build environment and uses compiled artifacts
- **Output**: Creates valid zip files ready for upload
- **Persistence**: Output must be in `/home/yocto/project/veracode-package` (persistent volume)

## Quick Start

### Step 1: Start a Persistent Container

```bash
bash CONTAINER_MANAGER.sh x86-64 start
bash CONTAINER_MANAGER.sh x86-64 fix-permissions
```

### Step 2: Enter Container Shell

```bash
bash CONTAINER_MANAGER.sh x86-64 shell
```

### Step 3: Run Veracode Package Manually

Inside the container:

```bash
# Option A: Use the extraction script (recommended)
bash /home/yocto/project/VERACODE_PACKAGE_INTERNAL.sh

# Option B: Manual command (for debugging)
cd /tmp
/veracode package \
    --source /home/yocto/project/meta-hello-qt/recipes-qt/hello-world \
    --type directory \
    -o /home/yocto/project/veracode-package \
    --trust \
    --verbose
```

### Step 4: Check Results

```bash
# View generated package
ls -lh /home/yocto/project/veracode-package/

# View latest log
ls -lh /home/yocto/project/veracode-package-*.log | tail -1
tail -50 /home/yocto/project/veracode-package-*.log | tail -1
```

## Complete Manual Testing Workflow

### Build + Test SAST in One Container

```bash
# Step 1: Start persistent container
bash CONTAINER_MANAGER.sh x86-64 start
bash CONTAINER_MANAGER.sh x86-64 fix-permissions

# Step 2: Build application
USE_PERSISTENT_CONTAINER=1 bash BUILD_MULTI_ARCH_WITH_SAST.sh x86-64

# Step 3: (Optional) Run veracode package again manually
bash CONTAINER_MANAGER.sh x86-64 shell
# Inside container:
bash /home/yocto/project/VERACODE_PACKAGE_INTERNAL.sh
```

## Testing Different Source Directories

The VERACODE_PACKAGE_INTERNAL.sh script accepts parameters for different source locations:

```bash
# Inside container:

# Test 1: Package the original hello-world recipe
bash /home/yocto/project/VERACODE_PACKAGE_INTERNAL.sh \
    /home/yocto/project/meta-hello-qt/recipes-qt/hello-world

# Test 2: Package preprocessed source (if available)
bash /home/yocto/project/VERACODE_PACKAGE_INTERNAL.sh \
    /home/yocto/project/preprocessed-src

# Test 3: Custom source directory
bash /home/yocto/project/VERACODE_PACKAGE_INTERNAL.sh \
    /path/to/custom/source \
    /home/yocto/project/veracode-custom-package
```

## Debugging Issues

### Issue: "Veracode CLI not found"

**Solution:** Verify you're using x86-64 container (Veracode CLI only available on x86-64):

```bash
bash CONTAINER_MANAGER.sh x86-64 shell  # ✅ Correct
# NOT:
bash CONTAINER_MANAGER.sh arm64 shell    # ❌ Veracode CLI not available
```

### Issue: "Source directory not found"

**Solution:** Verify the directory path exists:

```bash
# Inside container:
ls -la /home/yocto/project/meta-hello-qt/recipes-qt/hello-world

# If not found, build first:
bash /home/yocto/project/BUILD_YOCTO_INTERNAL.sh x86-64 /tmp/artifacts
```

### Issue: Permission denied on /veracode

**Solution:** The script uses `sudo -E` to preserve environment. Ensure container was created with fix-permissions:

```bash
bash CONTAINER_MANAGER.sh x86-64 fix-permissions
```

### Issue: No artifacts after packaging

**Possible causes:**
1. Source directory is empty or missing files
2. Veracode doesn't recognize the source type (needs CMakeLists.txt or Makefile)
3. Invalid source path provided

**Debug steps:**
```bash
# Inside container, verify source:
ls -la /home/yocto/project/meta-hello-qt/recipes-qt/hello-world/
find . -name "*.cpp" -o -name "*.h" -o -name "CMakeLists.txt"

# Try building hello-world first:
bash /home/yocto/project/BUILD_YOCTO_INTERNAL.sh x86-64 /tmp/test-artifacts
```

## Manual Upload and Scan

If you have Veracode API credentials:

```bash
# Inside container:
export VERACODE_API_ID="your-id"
export VERACODE_API_KEY="your-key"

# Run packaging
bash /home/yocto/project/VERACODE_PACKAGE_INTERNAL.sh

# Find the packaged zip
PACKAGE_ZIP=$(ls -1 /home/yocto/project/veracode-package/*.zip | head -1)
echo "Package: $PACKAGE_ZIP"

# Upload and scan
veracode scan upload \
    --file "$PACKAGE_ZIP" \
    --app-name "cpp-yocto-hello-world" \
    --sandbox "manual-test"

# Check scan status
veracode scan list --app-name "cpp-yocto-hello-world"
```

## Container Management

### Exit Container

```bash
exit
```

### Stop Container (preserves state)

```bash
bash CONTAINER_MANAGER.sh x86-64 stop
```

### Restart Stopped Container

```bash
bash CONTAINER_MANAGER.sh x86-64 start
bash CONTAINER_MANAGER.sh x86-64 shell
```

### Delete Container (removes everything)

```bash
bash CONTAINER_MANAGER.sh x86-64 stop
bash CONTAINER_MANAGER.sh x86-64 rm
```

## Troubleshooting Container State

### Check Container Status

```bash
# Outside container:
docker ps | grep yocto-builder-x86-64
```

### View Container Logs

```bash
docker logs yocto-builder-x86-64 | tail -50
```

### Run Command Without Shell

```bash
bash CONTAINER_MANAGER.sh x86-64 bash "ls -la /home/yocto/project/veracode-package/"
```

### SSH-like Access for Repeated Testing

```bash
# Keep in background:
bash CONTAINER_MANAGER.sh x86-64 start

# Multiple test runs:
for i in 1 2 3; do
  echo "Test run $i"
  bash CONTAINER_MANAGER.sh x86-64 bash "bash /home/yocto/project/VERACODE_PACKAGE_INTERNAL.sh"
done

# Cleanup:
bash CONTAINER_MANAGER.sh x86-64 stop
```

## What Gets Logged

When you run `VERACODE_PACKAGE_INTERNAL.sh`, logs are saved to:

```
/home/yocto/project/veracode-package-YYYYMMDD-HHMMSS.log
```

**Log contains:**
- ✅ Script initialization (source dir, output dir)
- ✅ Veracode CLI verification
- ✅ Full veracode package command output
- ✅ Success/failure status
- ✅ Upload readiness (if credentials present)

**To view:**
```bash
# Latest log:
tail -50 /home/yocto/project/veracode-package-*.log | tail -50

# All logs:
ls -lh /home/yocto/project/veracode-package-*.log
```

## Integration with CI/CD

The VERACODE_PACKAGE_INTERNAL.sh script is designed to be called from:
1. **BUILD_MULTI_ARCH_WITH_SAST.sh** — Automated builds
2. **CONTAINER_MANAGER.sh shell** — Manual testing (this guide)
3. **CI/CD pipelines** — As a reusable component

Usage in CI:
```bash
docker exec \
  -e VERACODE_API_ID \
  -e VERACODE_API_KEY \
  yocto-builder-x86-64 \
  bash /home/yocto/project/VERACODE_PACKAGE_INTERNAL.sh
```

## Next Steps

1. **Test locally** using this guide
2. **Run BUILD_MULTI_ARCH_WITH_SAST.sh** to verify automated workflow
3. **Check logs** to understand packaging results
4. **Upload to Veracode** if credentials available
5. **Iterate** on source code or Veracode configuration as needed
