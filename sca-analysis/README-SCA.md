# Veracode SCA Analysis - Qt5 Hello World

## Overview

This directory contains scripts and artifacts for running **Veracode Software Composition Analysis (SCA)** on the Qt5 Hello World application.

SCA focuses on identifying vulnerabilities in third-party libraries and open-source dependencies, complementing SAST (Static Application Security Testing) which analyzes your code.

## Directory Structure

```
sca-analysis/
├── README-SCA.md                 # This file
├── scripts/
│   ├── generate-sbom.sh          # Generate Software Bill of Materials
│   ├── run-sca-agent.sh          # Run Veracode SCA Agent
│   ├── gather-dependencies.sh    # Identify all dependencies
│   └── upload-to-veracode.sh     # Upload scan results
├── config/
│   ├── veracode-sca.yml          # SCA configuration file
│   └── agent-config.json         # SCA Agent configuration
├── dependencies/
│   ├── qt5-dependencies.txt      # Qt5 library dependencies
│   ├── system-dependencies.txt   # System library dependencies
│   └── manifest.txt              # Complete dependency manifest
└── sbom/
    ├── sbom.json                 # SBOM in JSON format
    ├── sbom.xml                  # SBOM in XML/CYCLONEDX format
    └── sbom.spdx                 # SBOM in SPDX format
```

## Dependencies for Qt5 Hello World

### Direct Dependencies

**Qt5 Framework:**
- qtbase (5.15.13) - Core, GUI, Widgets modules
- qtdeclarative (5.15.13) - QML declarative support

**System Libraries:**
- libstdc++ - C++ Standard Library
- libc - C Standard Library (glibc 2.34+)
- libm - Math Library
- libdl - Dynamic Loader
- libpthread - Threading Library
- libX11 - X Window System (for GUI on Linux)
- libxcb - X11 Protocol C Binding
- libxkbcommon - Keyboard Handling
- libfontconfig - Font Configuration
- libfreetype - Font Rendering
- libpng - PNG Image Support
- libjpeg - JPEG Image Support
- libz - Compression Library

### Transitive Dependencies

Qt5 dependencies include:
- OpenSSL (if network support compiled)
- Zlib (compression)
- Fontconfig & FreeType (font rendering)
- X11 libraries (on Linux/Unix)
- ICU libraries (Unicode support)

## Quick Start: Running SCA Scan

### 1. Setup Veracode Credentials

```bash
# Create credentials file
cat > ~/.veracode/.credentials << 'EOF'
[DEFAULT]
veracode_api_key_id = <YOUR_API_ID>
veracode_api_key_secret = <YOUR_API_SECRET>
veracode_base_url = https://api.veracode.com
EOF

chmod 600 ~/.veracode/.credentials
```

### 2. Generate Dependency Information

```bash
cd sca-analysis
bash scripts/gather-dependencies.sh
bash scripts/generate-sbom.sh
```

### 3. Run SCA Agent

```bash
# Automated approach
bash scripts/run-sca-agent.sh

# Manual approach
bash scripts/upload-to-veracode.sh <APP_NAME> <SCAN_NAME>
```

## SCA Agent Installation

### Option 1: Using pip

```bash
pip install veracode-python-sca
```

### Option 2: Using Docker

```bash
docker run --rm \
  -v $(pwd):/workspace \
  -e VERACODE_API_ID=<YOUR_API_ID> \
  -e VERACODE_API_KEY=<YOUR_API_KEY> \
  veracode/sca:latest scan --source-dir /workspace
```

### Option 3: Download from Veracode

```bash
# Download agent from Veracode portal
# https://docs.veracode.com/r/c_SCA_Agent

# Extract and run
./agent -sf . -o sca-results.json
```

## Generating SBOM (Software Bill of Materials)

### Using CycloneDX (Recommended)

```bash
cd sca-analysis
bash scripts/generate-sbom.sh
```

This generates:
- `sbom/sbom.json` - CycloneDX JSON format
- `sbom/sbom.xml` - CycloneDX XML format  
- `sbom/sbom.spdx` - SPDX format

### Manual SBOM Generation

```bash
# Using cyclonedx-cmake tool
cd ..
cyclonedx-cmake -o sca-analysis/sbom/sbom.xml .

# Or using cyclonedx-python for Python tools
cyclonedx-bom --output-file sca-analysis/sbom/sbom.json
```

## Vulnerability Identification

### Known Vulnerabilities to Monitor

Qt5 (5.15.13) known issues:
- CVE-2023-38545: QUIC protocol handling (if compiled with QUIC support)
- CVE-2023-43114: QML type confusion (less likely in this GUI app)
- Various buffer overflows in image handling (mitigation: only load trusted images)

### Expected Findings

For this application, expect minimal findings:
- ✅ Qt5 is actively maintained
- ✅ No direct use of deprecated functions
- ✅ No unbounded string operations
- ✅ Modern glibc version (2.34+)

### Remediation Priority

1. **Critical** - Remote code execution, data exposure
2. **High** - Local privilege escalation, denial of service
3. **Medium** - Information disclosure, limited functionality impact
4. **Low** - Non-security bugs, performance issues

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Veracode SCA Scan
on: [push, pull_request]

jobs:
  sca-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Run Veracode SCA
        env:
          VERACODE_API_ID: ${{ secrets.VERACODE_API_ID }}
          VERACODE_API_KEY: ${{ secrets.VERACODE_API_KEY }}
        run: |
          cd sca-analysis
          bash scripts/run-sca-agent.sh
          
      - name: Upload Results
        if: always()
        uses: actions/upload-artifact@v2
        with:
          name: sca-results
          path: sca-analysis/results/
```

### GitLab CI Example

```yaml
veracode-sca:
  image: ubuntu:22.04
  script:
    - cd sca-analysis
    - bash scripts/run-sca-agent.sh
  artifacts:
    paths:
      - sca-analysis/results/
    reports:
      dependency_scanning: sca-analysis/results/sca-report.json
```

## SCA vs SAST

| Aspect | SCA | SAST |
|--------|-----|------|
| **Focus** | Third-party libraries | Your own code |
| **Finds** | Known vulnerabilities in dependencies | Logic flaws, insecure patterns |
| **Examples** | Outdated OpenSSL, vulnerable Qt5 | Buffer overflow, SQL injection |
| **Tools** | Black Duck, Snyk, Veracode SCA | Veracode SAST, Sonarqube, Clang |
| **Artifacts** | SBOM, dependency report | Finding list with line numbers |

## Compliance & Reporting

### SBOM Use Cases

1. **Supply Chain Risk Management** - Know what's in your software
2. **Compliance** - CFAA, EO 14028, CISA requirements
3. **Incident Response** - Quickly identify if you're affected
4. **Licensing** - Track open-source license compliance

### Generating Compliance Report

```bash
# Generate CycloneDX SBOM for compliance
cd sca-analysis
bash scripts/generate-sbom.sh

# Upload to Veracode for formal reporting
bash scripts/upload-to-veracode.sh
```

## Troubleshooting

### "No agent found"
```bash
# Download or install agent
pip install veracode-python-sca
```

### "Authentication failed"
```bash
# Verify credentials
cat ~/.veracode/.credentials

# Test connectivity
curl -u $VERACODE_API_ID:$VERACODE_API_KEY https://api.veracode.com/
```

### "No dependencies detected"
```bash
# Ensure you're scanning the correct directory
cd sca-analysis/..
bash scripts/gather-dependencies.sh
```

## References

- [Veracode SCA Documentation](https://docs.veracode.com/r/c_SCA)
- [CycloneDX SBOM Format](https://cyclonedx.org/)
- [SPDX License List](https://spdx.org/licenses/)
- [CISA SBOM Requirements](https://www.cisa.gov/sbom)

## Next Steps

1. ✅ Set up credentials
2. ✅ Run dependency gathering: `bash scripts/gather-dependencies.sh`
3. ✅ Generate SBOM: `bash scripts/generate-sbom.sh`
4. ✅ Run SCA Agent: `bash scripts/run-sca-agent.sh`
5. ✅ Review findings
6. ✅ Upload to Veracode for formal scanning
