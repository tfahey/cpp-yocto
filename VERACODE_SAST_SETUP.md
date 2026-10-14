# Veracode SAST Setup Guide

This guide explains how to set up Veracode SAST scanning for the cpp-yocto Qt5 application.

## Overview

Veracode SAST (Static Application Security Testing) scans your source code for security vulnerabilities. This project includes:

- **Intentional security flaws** in the C++ code for testing (see [SECURITY_TEST_FLAWS.md](SECURITY_TEST_FLAWS.md))
- **Automated packaging** via `BUILD_MULTI_ARCH_WITH_SAST.sh`
- **Manual testing** via `CONTAINER_MANAGER.sh`

## Getting Veracode API Credentials

1. **Sign up for Veracode** (if not already done):
   - Go to https://www.veracode.com/
   - Create an account or log in

2. **Generate API Credentials**:
   - Navigate to: https://analysiscenter.veracode.com/auth/index.jsp#APICredentialsGenerator
   - Click "Generate Credentials"
   - Copy the **API ID** and **API Key**
   - Store securely (do not commit to git)

3. **Export Environment Variables**:
   ```bash
   export VERACODE_API_ID="your-api-id-here"
   export VERACODE_API_KEY="your-api-key-here"
   ```

   Or add to your shell profile (e.g., `~/.zshrc`):
   ```bash
   export VERACODE_API_ID="your-api-id-here"
   export VERACODE_API_KEY="your-api-key-here"
   ```

## Architecture Support

### ARM64 Build
- ✅ Full Yocto build support
- ❌ **No Veracode packaging** (Veracode CLI is x86-64 only)
- Use for: Development, testing, quick builds

### x86-64 Build
- ✅ Full Yocto build support
- ✅ **Veracode SAST packaging available**
- ❌ Slower on Mac (QEMU emulation)
- Use for: SAST scanning, production builds

## Automated Build with SAST Packaging

Use `BUILD_MULTI_ARCH_WITH_SAST.sh` to build and automatically package/upload for Veracode SAST.

### Building for x86-64 (with SAST)

```bash
# Set credentials first
export VERACODE_API_ID="your-id"
export VERACODE_API_KEY="your-key"

# Build for x86-64 (includes veracode package command)
bash BUILD_MULTI_ARCH_WITH_SAST.sh x86-64
```

**What happens:**
1. Builds the Qt5 application using Yocto
2. Finds the compiled binary
3. Runs `veracode package` on the Yocto recipe source
4. Generates packaged app in `veracode-package/`
5. If credentials are set: Uploads to Veracode and triggers SAST scan

**Output:**
- Binary: `hello-world-output/hello-world`
- Packaged app: `veracode-package/*.zip`

### Building for ARM64 (without SAST)

```bash
# Build for ARM64 (no veracode packaging, faster)
bash BUILD_MULTI_ARCH_WITH_SAST.sh arm64
```

**What happens:**
1. Builds the Qt5 application using Yocto
2. Finds the compiled binary
3. Skips Veracode packaging (CLI not available)

**Output:**
- Binary: `hello-world-output/arm64/hello-world`

## Manual Testing with CONTAINER_MANAGER.sh

For iterative testing and debugging:

```bash
# Set credentials (if doing SAST packaging)
export VERACODE_API_ID="your-id"
export VERACODE_API_KEY="your-key"

# Start x86-64 container with Veracode CLI
bash CONTAINER_MANAGER.sh x86-64 start
bash CONTAINER_MANAGER.sh x86-64 shell
```

Inside the container:

```bash
# Activate Yocto environment
cd /home/yocto/project
source poky/oe-init-build-env ./build-x86-64

# Fix cache permissions (first time only)
sudo chown -R yocto:yocto /home/yocto/cache/tmp-x86-64-glibc
sudo chmod -R 755 /home/yocto/cache/tmp-x86-64-glibc
sudo chown -R yocto:yocto /home/yocto/cache/sstate-cache-x86-64
sudo chmod -R 755 /home/yocto/cache/sstate-cache-x86-64

# Build
bitbake hello-world

# Package for Veracode SAST
sudo -E /veracode package \
    --source /home/yocto/project/meta-hello-qt/recipes-qt/hello-world \
    --type directory \
    -o /home/yocto/project/veracode-package \
    --trust \
    --verbose
```

See [CONTAINER_USAGE.md](CONTAINER_USAGE.md) for detailed container management.

## Monitoring Scans

After upload, monitor your SAST scans:

1. **Veracode Dashboard**:
   - Go to https://analysiscenter.veracode.com/
   - Select app: `cpp-yocto-hello-world`
   - View scan results

2. **Expected Findings**:
   - The C++ code includes intentional security flaws (see [SECURITY_TEST_FLAWS.md](SECURITY_TEST_FLAWS.md))
   - Veracode should detect these as high-severity issues
   - Use this to validate Veracode's detection capabilities

3. **Review Results**:
   - Check detection of CWE patterns:
     - CWE-78: OS command injection
     - CWE-120: Buffer overflow
     - CWE-134: Format string
     - CWE-22: Path traversal
     - CWE-416: Use after free
     - CWE-415: Double free
     - CWE-190: Integer overflow
     - CWE-401: Memory leak
     - CWE-676: Dangerous functions
     - CWE-119: Stack buffer overflow
     - CWE-732: Insecure file permissions

## Troubleshooting

### "Veracode credentials not set"

**Solution:** Export environment variables:
```bash
export VERACODE_API_ID="your-id"
export VERACODE_API_KEY="your-key"
bash BUILD_MULTI_ARCH_WITH_SAST.sh x86-64
```

### "veracode CLI not found at /veracode"

**Solution:** Verify x86-64 image has Veracode CLI:
```bash
docker run --rm --platform linux/amd64 yocto-qt-builder:x86-64 ls -la /veracode
```

If not found, rebuild:
```bash
docker build --platform linux/amd64 -t yocto-qt-builder:x86-64 -f Dockerfile.x86-64 . --no-cache
```

### "Veracode package failed"

**Possible causes:**
1. Invalid credentials (wrong API ID/KEY)
2. Network connectivity issue
3. Recipe source directory not found

**Solution:** Check logs and verify:
- API credentials are correct
- Source path exists: `/home/yocto/project/meta-hello-qt/recipes-qt/hello-world`
- Network access to Veracode servers

### x86-64 Build Very Slow

**Expected:** x86-64 builds are slow on ARM64 Mac (QEMU emulation)

**Workaround:**
- Use ARM64 for development (10x faster)
- Use x86-64 only for final packaging/scanning
- Or set up CI/CD to run x86-64 builds on native Linux

## Next Steps

1. **Verify detection**: Run a scan and check that intentional flaws are detected
2. **Customize**: Remove intentional flaws from production code
3. **Integrate**: Add to CI/CD pipeline for automated scanning
4. **Monitor**: Track new vulnerabilities in development

## Resources

- [Veracode Documentation](https://help.veracode.com/)
- [SAST Best Practices](https://help.veracode.com/go/c_SAST_prep)
- [Security Test Flaws](SECURITY_TEST_FLAWS.md)
- [Container Usage](CONTAINER_USAGE.md)
