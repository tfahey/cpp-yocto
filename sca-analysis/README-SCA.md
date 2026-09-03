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

### 1. Setup SRCCLR_API_TOKEN

The SCA Agent requires the SRCCLR_API_TOKEN for authentication.

```bash
# Set the token as environment variable
export SRCCLR_API_TOKEN="<YOUR_SRCCLR_API_TOKEN>"

# Verify token is set
echo $SRCCLR_API_TOKEN

# Optional: Make permanent (add to ~/.bashrc or ~/.zshrc)
echo 'export SRCCLR_API_TOKEN="<YOUR_SRCCLR_API_TOKEN>"' >> ~/.bashrc
source ~/.bashrc
```

### 2. Generate Dependency Information

```bash
cd sca-analysis
bash scripts/gather-dependencies.sh
bash scripts/generate-sbom.sh
```

### 3. Run SCA Agent

```bash
# Ensure SRCCLR_API_TOKEN is set
export SRCCLR_API_TOKEN="<YOUR_SRCCLR_API_TOKEN>"

# Run the scan
srcclr scan --allow-dirty
```

## SCA Agent Installation & Usage

### Option 1: Using pip (SRCCLR CLI - Recommended)

```bash
# Install the Veracode SCA CLI agent
pip install veracode-python-sca

# Verify installation
srcclr --version

# Or use: veracode-sca --version
```

### Option 2: Using Docker

```bash
export SRCCLR_API_TOKEN="<YOUR_SRCCLR_API_TOKEN>"

docker run --rm \
  -v $(pwd):/workspace \
  -e SRCCLR_API_TOKEN=$SRCCLR_API_TOKEN \
  veracode/sca:latest scan --source-dir /workspace
```

## Using SCA CLI Agent with SRCCLR_API_TOKEN

The SRCCLR API token is the modern, simplified authentication method for Veracode SCA scanning.

### Getting Your SRCCLR_API_TOKEN

The SRCCLR_API_TOKEN is generated in the context of a project workspace in Veracode.

**For complete and accurate instructions, refer to the official Veracode documentation:**
- https://docs.veracode.com/

The documentation will guide you through:
1. Logging into your Veracode platform
2. Navigating to your project/workspace
3. Generating the SRCCLR_API_TOKEN in the workspace context
4. Storing the token securely

**Important Notes:**
- The SRCCLR_API_TOKEN is workspace-specific and tied to your project
- It is different from personal API credentials (API ID/Secret)  
- Store the token securely immediately after generation (may only display once)
- Treat it like a password - do not commit to git or share publicly

### Setup SRCCLR_API_TOKEN

**Method 1: Export as Environment Variable (Temporary)**
```bash
export SRCCLR_API_TOKEN="<your_token_here>"

# Verify it's set
echo $SRCCLR_API_TOKEN
```

**Method 2: Add to Shell Profile (Permanent)**
```bash
# For bash
echo 'export SRCCLR_API_TOKEN="<your_token_here>"' >> ~/.bashrc
source ~/.bashrc

# For zsh
echo 'export SRCCLR_API_TOKEN="<your_token_here>"' >> ~/.zshrc
source ~/.zshrc

# For fish
set -Ux SRCCLR_API_TOKEN "<your_token_here>"
```

**Method 3: Store in Credentials File**
```bash
mkdir -p ~/.srcclr
cat > ~/.srcclr/config.json << 'EOF'
{
  "api_token": "<your_token_here>",
  "base_url": "https://api.veracode.com"
}
EOF

chmod 600 ~/.srcclr/config.json
```

### Running SCA Scan with SRCCLR_API_TOKEN

**Basic Scan (Current Directory)**
```bash
export SRCCLR_API_TOKEN="<your_token_here>"

# Scan current directory
srcclr scan

# Or be explicit
srcclr scan --allow-dirty

# Show what would be scanned without uploading
srcclr scan --dry-run
```

**Scan Specific Directory**
```bash
export SRCCLR_API_TOKEN="<your_token_here>"

# Scan the project root
srcclr scan --source-dir ..

# Scan multiple directories
srcclr scan --source-dir ../meta-hello-qt --source-dir ../build
```

**With Custom Output**
```bash
export SRCCLR_API_TOKEN="<your_token_here>"

# Generate JSON report
srcclr scan --output json > results/sca-report.json

# Generate SARIF report (for CI/CD integration)
srcclr scan --output sarif > results/sca-report.sarif

# Generate detailed HTML report
srcclr scan --output html > results/sca-report.html
```

**CI/CD Integration**
```bash
# GitHub Actions
export SRCCLR_API_TOKEN="${{ secrets.SRCCLR_API_TOKEN }}"
srcclr scan --output sarif > results.sarif

# GitLab CI
export SRCCLR_API_TOKEN="${SRCCLR_API_TOKEN}"
srcclr scan --output json > sca-report.json

# Jenkins
export SRCCLR_API_TOKEN="${SRCCLR_API_TOKEN}"
srcclr scan --output xml > sca-report.xml
```

### Scan Options & Flags

```bash
# Display all available options
srcclr scan --help

# Key options:
srcclr scan \
  --allow-dirty                      # Scan uncommitted changes
  --source-dir <path>                # Directory to scan
  --output <format>                  # Output format: json, xml, sarif, html
  --dynatrace-host <url>             # Send to Dynatrace
  --github-token <token>             # GitHub integration
  --gitlab-token <token>             # GitLab integration
  --fail-on-cli-errors               # Exit with error code
  --timeout <seconds>                # Scan timeout
  --verbose                          # Verbose logging
  --debug                            # Debug mode
```

### Example: Full Scan Workflow with SRCCLR_API_TOKEN

```bash
#!/bin/bash

# Setup
export SRCCLR_API_TOKEN="<your_token_here>"
RESULTS_DIR="results"
mkdir -p "$RESULTS_DIR"

# Step 1: Verify token
echo "🔑 Verifying SRCCLR_API_TOKEN..."
if [ -z "$SRCCLR_API_TOKEN" ]; then
    echo "❌ ERROR: SRCCLR_API_TOKEN not set"
    exit 1
fi
echo "✅ Token is set"

# Step 2: Scan the application
echo ""
echo "🔍 Scanning with Veracode SCA..."
srcclr scan \
    --source-dir .. \
    --allow-dirty \
    --output json > "$RESULTS_DIR/sca-report.json"

echo "✅ Scan complete"

# Step 3: Generate reports
echo ""
echo "📊 Generating reports..."
srcclr scan \
    --source-dir .. \
    --allow-dirty \
    --output html > "$RESULTS_DIR/sca-report.html"

srcclr scan \
    --source-dir .. \
    --allow-dirty \
    --output sarif > "$RESULTS_DIR/sca-report.sarif"

# Step 4: Show summary
echo ""
echo "✅ All scans complete!"
echo ""
echo "Results:"
ls -lh "$RESULTS_DIR/"

# Step 5: Parse results for critical issues
echo ""
echo "🔍 Checking for critical vulnerabilities..."
CRITICAL_COUNT=$(grep -c '"severity":"critical"' "$RESULTS_DIR/sca-report.json" || echo "0")

if [ "$CRITICAL_COUNT" -gt 0 ]; then
    echo "⚠️  Found $CRITICAL_COUNT critical vulnerabilities"
    exit 1
else
    echo "✅ No critical vulnerabilities found"
fi
```

### Troubleshooting SRCCLR_API_TOKEN

**"Invalid or expired token"**
```bash
# Regenerate token in Veracode portal
# Then update environment variable
export SRCCLR_API_TOKEN="<new_token>"

# Verify new token
srcclr scan --dry-run
```

**"Token not found"**
```bash
# Check if variable is set
echo $SRCCLR_API_TOKEN

# If empty, set it
export SRCCLR_API_TOKEN="<your_token>"

# Or use credentials file
cat ~/.srcclr/config.json
```

**"Scan fails silently"**
```bash
# Run with verbose/debug logging
srcclr scan --verbose --allow-dirty
srcclr scan --debug --allow-dirty

# Check logs
srcclr scan --allow-dirty 2>&1 | tee scan.log
```

**"Connection timeout"**
```bash
# Increase timeout
srcclr scan --timeout 600 --allow-dirty

# Check network connectivity
curl -H "Authorization: Bearer $SRCCLR_API_TOKEN" \
     https://api.veracode.com/srcclr/v3/organizations
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

### GitHub Actions Example (with SRCCLR_API_TOKEN)

```yaml
name: Veracode SCA Scan
on: [push, pull_request]

jobs:
  sca-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install Veracode SCA CLI
        run: pip install veracode-python-sca
      
      - name: Run Veracode SCA with SRCCLR Token
        env:
          SRCCLR_API_TOKEN: ${{ secrets.SRCCLR_API_TOKEN }}
        run: |
          srcclr scan \
            --source-dir . \
            --allow-dirty \
            --output json > sca-report.json \
            --output sarif > sca-report.sarif
          
      - name: Upload Results
        if: always()
        uses: actions/upload-artifact@v2
        with:
          name: sca-results
          path: |
            sca-report.json
            sca-report.sarif
            
      - name: Check for Critical Issues
        run: |
          CRITICAL=$(grep -c '"severity":"critical"' sca-report.json || echo "0")
          if [ "$CRITICAL" -gt 0 ]; then
            echo "❌ Found $CRITICAL critical vulnerabilities"
            exit 1
          fi
```

### GitLab CI Example (with SRCCLR_API_TOKEN)

```yaml
stages:
  - scan

veracode-sca:
  stage: scan
  image: ubuntu:22.04
  before_script:
    - apt-get update && apt-get install -y python3 pip
    - pip install veracode-python-sca
  script:
    - export SRCCLR_API_TOKEN="${SRCCLR_API_TOKEN}"
    - srcclr scan 
        --allow-dirty 
        --output json > sca-report.json
        --output sarif > sca-report.sarif
  artifacts:
    paths:
      - sca-report.json
      - sca-report.sarif
    reports:
      dependency_scanning: sca-report.json
```


### Jenkins Pipeline Example (with SRCCLR_API_TOKEN)

```groovy
pipeline {
    agent any
    
    environment {
        SRCCLR_API_TOKEN = credentials('srcclr-api-token')
    }
    
    stages {
        stage('Setup') {
            steps {
                sh '''
                    pip install veracode-python-sca
                    srcclr --version
                '''
            }
        }
        
        stage('SCA Scan') {
            steps {
                sh '''
                    srcclr scan \
                        --source-dir . \
                        --allow-dirty \
                        --output json > sca-report.json \
                        --output sarif > sca-report.sarif
                '''
            }
        }
        
        stage('Archive Results') {
            steps {
                archiveArtifacts artifacts: 'sca-report.*', 
                                 allowEmptyArchive: true
            }
        }
        
        stage('Check Results') {
            steps {
                sh '''
                    CRITICAL=$(grep -c '"severity":"critical"' sca-report.json || echo "0")
                    if [ "$CRITICAL" -gt 0 ]; then
                        echo "❌ Found $CRITICAL critical issues"
                        exit 1
                    fi
                '''
            }
        }
    }
}

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
```

## Troubleshooting

### "No agent found"
```bash
# Download or install agent
pip install veracode-python-sca
```

### "Authentication failed"
```bash
# Verify SRCCLR_API_TOKEN is set
echo $SRCCLR_API_TOKEN

# If empty, set it
export SRCCLR_API_TOKEN="<your_token>"

# Test token by running a dry-run scan
srcclr scan --dry-run
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
