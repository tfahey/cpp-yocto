# Veracode SAST Testing Work Summary

**Branch:** `veracode-security-test`  
**Date:** September 22-26, 2026

## Overview

This document summarizes all work completed on the cpp-yocto project to prepare it for Veracode static analysis testing with intentional security flaws.

---

## 1. BUILD_MULTI_ARCH.sh Script Enhancements

### Issues Fixed

1. **Syntax Error (Line 131)**
   - **Problem:** Missing closing parenthesis for `docker run -d` command
   - **Fix:** Changed `"` to `")` on line 131
   - **Impact:** Script now parses correctly

2. **Build Timing Visibility**
   - **Added:** Start time, end time, and duration tracking for each architecture
   - **Format:** Human-readable timestamps with minute/second duration
   - **Location:** Output at beginning and end of build process
   - **Benefit:** Clear visibility into actual build times (90+ min → 36 sec with caching)

3. **Memory Optimization for Docker**
   - **Added:** Memory limits to prevent OOM kills during GCC compilation
   - **Configuration:** `-m 7g --memory-swap 9g` (7GB RAM + 2GB swap)
   - **Parallelization:** `BB_NUMBER_THREADS = "2"` and `PARALLEL_MAKE = "-j 2"`
   - **Benefit:** Prevents compiler from being killed mid-build

4. **Persistent Cache Volumes**
   - **Added:** Host-side persistent Yocto caches at `/Users/tfahey/github/cpp-yocto/.yocto-cache/`
   - **Directories:**
     - `downloads/` → Container `/home/yocto/cache/downloads` (DL_DIR)
     - `sstate-cache/` → Container `/home/yocto/cache/sstate-cache` (SSTATE_DIR)
   - **Benefit:** Massive speedup on repeat builds (first: 90+ min, subsequent: 5-15 min)
   - **Added to .gitignore:** `.yocto-cache/`

5. **Docker-backed Yocto Temporary Storage**
   - **Problem:** Docker's writable overlay filesystem ran out of space during native toolchain builds.
   - **Fix:** Each architecture uses a persistent Docker volume (`yocto-tmp-arm64` or `yocto-tmp-x86-64`) for `TMPDIR`.
   - **Reason:** Docker volumes provide Linux case-sensitive storage, unlike macOS bind mounts, and avoid Yocto's filesystem sanity error.
   - **Permissions:** A short initialization container assigns the volume to the non-root `yocto` user before BitBake runs.

6. **Binary Search Logic Fix**
   - **Problem:** Script couldn't find the binary after a successful build because the output is stored in the Docker-backed TMPDIR rather than `/tmp/yocto-build-*`.
   - **Fix:** Searches the mounted `tmp-$ARCH_NAME-glibc` volume directly for image, package, build, and IPK outputs.
   - **Artifact staging:** Copies the binary through the writable project mount to avoid macOS temporary-directory bind-mount permissions.
   - **Fallback:** Added IPK extraction logic when raw binary isn't found
     - Uses `ar` to unpack IPK packages
     - Extracts data tarball (supports `.tar.zst`, `.tar.xz`, `.tar.gz`)
     - Validates extracted file is actually ELF binary

7. **Preprocessed Source Generation**
   - **Added:** Automatic generation of `.i` files inside Docker container
   - **Location:** `/home/yocto/project/preprocessed-src/sources/`
   - **Headers:** Finds the application recipe's `recipe-sysroot/usr/include` directory in the Docker volume.
   - **Include paths:** Uses the sysroot root plus `QtCore`, `QtGui`, and `QtWidgets` directories.
   - **Fallback:** Does not use host Qt headers, preventing architecture/version mismatches in analysis.
   - **Output:** Approximately 3MB each for `main.i` and `mainwindow.i` with Yocto's Qt headers expanded.

---

## 2. Veracode Package Creation

### Structure

```
veracode-package/
├── cpp-yocto-qt5/
│   ├── main.cpp              (source with security flaws)
│   ├── mainwindow.cpp        (source with security flaws)
│   ├── mainwindow.h          (updated to pass argc/argv)
│   ├── CMakeLists.txt        (build configuration)
│   ├── main.i                (preprocessed main.cpp - 2.6MB)
│   ├── mainwindow.i          (preprocessed mainwindow.cpp - 2.6MB)
│   └── veracode.json         (Veracode configuration)
└── cpp-yocto-qt5-veracode.zip (784KB - final upload package)
```

### veracode.json Configuration

```json
{
  "buildConfiguration": {
    "compiler": {
      "name": "g++",
      "version": "9.4.0",
      "architecture": "arm64",
      "options": "-std=c++11 -O2"
    }
  }
}
```

**Notes:**
- Compiler version determined from Docker base image (Ubuntu 20.04 → GCC 9.4.0)
- Architecture: arm64 (default Yocto cross-compile target)
- Options: C++11 standard with -O2 production optimization

---

## 3. Intentional Security Flaws (High-Confidence Patterns)

The application was rewritten to include 11 high-confidence vulnerability patterns that Veracode reliably detects. Each flaw has a clear **tainted-input-to-vulnerable-sink data flow** from `argv` or user input.

### Vulnerabilities Introduced

| CWE | Name | Location | Tainted Flow |
|-----|------|----------|--------------|
| 78 | OS Command Injection | main.cpp, processInput() | `argv[1]` → `sprintf()` → `system()` |
| 120 | Buffer Overflow | main.cpp, mainwindow.cpp | `argv` → `strcpy()` into small buffer |
| 134 | Uncontrolled Format String | logAction() | `argv[1]` → `printf(msg)` as format |
| 22 | Path Traversal | constructor, loadConfig() | `argv[2]` → `fopen()` |
| 416 | Use After Free | onButtonClicked() | `malloc()` → `free()` → dereference |
| 415 | Double Free | exportData() | `free(ptr)` called twice |
| 190 | Integer Overflow | onButtonClicked() | `argv[3]` → `atoi()` → multiply overflow |
| 401 | Memory Leak | constructor/destructor | `malloc()` without `free()` |
| 676 | Dangerous Function | logAction() | `tmpnam()` insecure temp file |
| 119 | Out-of-bounds Write | processInput() | User input → `strcat()` overflow |
| 732 | Insecure Permissions | exportData() | `open()` with 0777 |

### Files Modified

- **main.cpp:** Added tainted argv flows to command injection and buffer overflow
- **mainwindow.h:** Added argc/argv parameters, memory leak buffers, slot for input
- **mainwindow.cpp:** Added 11 vulnerable functions with clear data flows
  - `processInput()` - command injection via strcat/sprintf
  - `logAction()` - format string vulnerability
  - `loadConfig()` - path traversal and buffer overflow
  - `exportData()` - insecure file permissions and double free
  - `onButtonClicked()` - use-after-free, integer overflow, memory leak

---

## 4. Preprocessed Source Files

Generated via Docker container with the application recipe's Yocto Qt headers:

```bash
g++ -E -I. \
   -I<recipe-sysroot>/usr/include \
   -I<recipe-sysroot>/usr/include/QtCore \
   -I<recipe-sysroot>/usr/include/QtGui \
   -I<recipe-sysroot>/usr/include/QtWidgets \
    -dD mainwindow.cpp > mainwindow.i
```

**Output:**
- `main.i`: 2.6MB (all Qt5 headers expanded)
- `mainwindow.i`: 2.6MB (all Qt5 headers expanded)

**Why included:**
- Provides full type information for deeper static analysis
- Removes dependency on header files in Veracode scanner
- Helps analyzer understand Qt5 framework usage

---

## 5. Build Performance Improvements

### Before Optimization
- **First build:** 90-100+ minutes
- **Cached build:** N/A (no persistence)

### After Optimization
- **First build:** 90-100 minutes (same - downloading/compiling toolchain)
- **Second build with .yocto-cache:** 5-15 minutes
- **Reason:** 1962 of 1993 Yocto tasks skipped via sstate-cache

### Memory Optimization Impact
- Reduced parallel jobs from default (-j auto) to -j 2
- Allocated 7GB RAM + 2GB swap to Docker container
- Result: Build completes without OOM kills

---

## 6. New Project: cpp-veracode-test

Created a standalone C++ project for rapid Veracode testing iteration.

**Location:** `/Users/tfahey/github/cpp-veracode-test/`

**Purpose:**
- Test Veracode configuration without 90+ minute builds
- Iterate on vulnerability patterns quickly
- Compare LLVM bitcode vs preprocessed source vs debug binary

**Outputs:**
- `.verascan/veracode-upload.zip` (274KB)
  - `main.bc` - LLVM bitcode (for binary analysis)
  - `main.i` - Preprocessed source (2.75MB)
  - `veracode.json` - Configuration

**Build time:** ~36 seconds

---

## 7. Testing Strategy

### Upload to Veracode

1. **Primary package:** `veracode-package/cpp-yocto-qt5-veracode.zip`
   - Source: Preprocessed .i files with Qt5 application
   - Config: veracode.json with GCC 9.4.0, arm64, C++11
   - Size: 784KB

2. **Test project (if needed):** `cpp-veracode-test/.verascan/veracode-upload.zip`
   - Faster iteration for testing configuration
   - 15 high-confidence flaws
   - 36-second build

### Expected Findings

Veracode should detect all 11 CWE types in cpp-yocto package:
- CWE-78, 120, 134, 22, 416, 415, 190, 401, 676, 119, 732

---

## 8. Repository State

**Branch:** `veracode-security-test` (off main)
- Contains intentional security flaws for testing
- **DO NOT merge to main or sast-analysis**

**Files staged and committed:**
- Modified source files with security flaws
- Updated BUILD_MULTI_ARCH.sh with fixes and optimizations
- Created veracode-package with preprocessed sources
- Created SECURITY_TEST_FLAWS.md documentation

**Git state:**
- Script and documentation changes are committed separately from generated `.i` build outputs.
- Ready for Veracode upload after regenerating the preprocessed sources.

---

## 9. Commands for Reproduction

### Generate Veracode package (from clean state)

```bash
# 1. Build with caching
cd /Users/tfahey/github/cpp-yocto
bash ./BUILD_MULTI_ARCH.sh arm64

# 2. Package is automatically created
ls -lh veracode-package/cpp-yocto-qt5-veracode.zip

# 3. Upload to Veracode
# (Via web UI at https://analysiscenter.veracode.com)
```

### Build time with persistent caches

```bash
# First run (populated caches)
time bash ./BUILD_MULTI_ARCH.sh arm64
# Expected: ~5-15 minutes

# Clear caches for full rebuild
rm -rf .yocto-cache/
time bash ./BUILD_MULTI_ARCH.sh arm64
# Expected: ~90-100 minutes
```

---

## 10. Outstanding Items

- [ ] Upload cpp-yocto-qt5-veracode.zip to Veracode platform
- [ ] Verify all 11 CWE types detected in scan results
- [ ] Compare Veracode findings with intentional flaws
- [ ] Document any flaws not detected (improve patterns)
- [ ] Test with cpp-veracode-test project if needed

---

## References

- **BUILD_INSTRUCTIONS.md** - Original Yocto build documentation
- **SECURITY_TEST_FLAWS.md** - Detailed vulnerability explanations
- **README-SAST.md** - SAST analysis and Veracode packaging guide
- **Veracode docs:** https://docs.veracode.com/

