# Intentional Security Flaws for Veracode Testing

**PURPOSE:** This branch (`veracode-security-test`) contains deliberately introduced security vulnerabilities for testing Veracode's static analysis capabilities. **DO NOT use this code in production.**

## Flaws Introduced

### 1. Buffer Overflow (mainwindow.cpp)
**Location:** `MainWindow::onButtonClicked()` and `updateCounterDisplay()`

**Vulnerability Type:** CWE-120 (Buffer Copy without Checking Size of Input)

**Description:** Uses `strcpy()` with an unbounded input buffer to copy counter value to a fixed-size array. If the counter becomes large enough, it will overflow the buffer.

**Test Case:** Click the button 100+ times to trigger buffer overflow.

**Expected Veracode Finding:** "Buffer overflow" / "Unbounded string operation"

---

### 2. Integer Overflow (mainwindow.cpp)
**Location:** `MainWindow::onButtonClicked()`

**Vulnerability Type:** CWE-190 (Integer Overflow or Wraparound)

**Description:** Counter increments without bounds checking or overflow protection. On 32-bit int, incrementing beyond INT_MAX causes undefined behavior.

**Test Case:** Click the button until counter value wraps negative.

**Expected Veracode Finding:** "Integer overflow" / "Arithmetic without bounds checking"

---

### 3. Uninitialized Variable (mainwindow.cpp)
**Location:** `MainWindow::MainWindow()` constructor

**Vulnerability Type:** CWE-457 (Use of Uninitialized Variable)

**Description:** Member variable `m_lastClickTime` is declared but not initialized. Using uninitialized variables can lead to unpredictable behavior.

**Expected Veracode Finding:** "Use of uninitialized variable"

---

### 4. Use-After-Free (mainwindow.cpp)
**Location:** `MainWindow::onButtonClicked()` - conditional cleanup path

**Vulnerability Type:** CWE-416 (Use After Free)

**Description:** Under certain conditions, a dynamically allocated temporary object is deleted and then accessed, causing a use-after-free vulnerability.

**Expected Veracode Finding:** "Use after free" / "Reference to freed memory"

---

### 5. Qt-Specific: Unsafe Type Conversion (mainwindow.cpp)
**Location:** `MainWindow::onButtonClicked()` - custom signal handling

**Vulnerability Type:** CWE-588 (Attempt to Access Child of Non-Structure Pointer)

**Description:** Uses `static_cast` instead of `qobject_cast` for type conversion between Qt objects, bypassing type safety checks. If the object isn't actually of the expected type, this causes undefined behavior.

**Expected Veracode Finding:** "Unsafe type conversion" / "Type confusion"

---

### 6. Qt-Specific: Direct Pointer Cast without Validation (main.cpp)
**Location:** `main()` function

**Vulnerability Type:** CWE-591 (Sensitive Data Storage in Externally Accessible Location)

**Description:** Stores raw pointer to MainWindow without proper lifecycle management. Qt parent-child model is bypassed with direct void* casting.

**Expected Veracode Finding:** "Unsafe pointer cast" / "Memory management issue"

---

### 7. Resource Leak (mainwindow.cpp)
**Location:** `MainWindow::~MainWindow()` destructor

**Vulnerability Type:** CWE-401 (Missing Release of Memory after Effective Lifetime)

**Description:** Intentionally missing cleanup of dynamically allocated data in destructors and some code paths, causing memory leaks.

**Expected Veracode Finding:** "Resource leak" / "Memory leak"

---

### 8. Qt-Specific: Direct Memory Access Without Bounds (mainwindow.cpp)
**Location:** `MainWindow::updateCounterDisplay()`

**Vulnerability Type:** CWE-119 (Improper Restriction of Operations within the Bounds of a Memory Buffer)

**Description:** Direct array indexing without bounds checking, combined with user-influenced index calculation.

**Expected Veracode Finding:** "Out of bounds access" / "Array index out of bounds"

---

## How to Test with Veracode

1. **Create Veracode package from this branch:**
   ```bash
   cd preprocessed-src
   bash ../BUILD_MULTI_ARCH.sh arm64
   ```

2. **Package for Veracode:**
   ```bash
   mkdir -p veracode-package-test/cpp-yocto-qt5
   cp -r preprocessed-src/sources/* veracode-package-test/cpp-yocto-qt5/
   cp preprocessed-src/veracode.json veracode-package-test/cpp-yocto-qt5/
   cd veracode-package-test
   zip -r cpp-yocto-qt5-test.zip cpp-yocto-qt5/
   ```

3. **Upload to Veracode:**
   ```bash
   veracode upload-app \
     --app-name "Qt5-HelloWorld-Test" \
     --file cpp-yocto-qt5-test.zip \
     --scan-name "Security Test Flaws"
   ```

4. **Compare results:**
   - Compare findings with the clean `sast-analysis` branch
   - Verify Veracode detects all 8+ introduced flaws
   - Check severity levels and confidence ratings

---

## Cleanup

**To remove these flaws and return to production-ready code:**

```bash
git checkout sast-analysis
```

**DO NOT merge this branch into main or sast-analysis.**

---

## Files Modified

- `preprocessed-src/sources/mainwindow.h` - Added vulnerable member variables
- `preprocessed-src/sources/mainwindow.cpp` - Added vulnerable code paths
- `preprocessed-src/sources/main.cpp` - Added unsafe pointer casting

All vulnerable code is marked with `// [INTENTIONAL SECURITY FLAW]` comments for easy identification.
