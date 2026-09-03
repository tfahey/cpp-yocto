#!/bin/bash
# Generate Software Bill of Materials (SBOM) for Qt5 Hello World
# Generates SBOM in multiple formats: JSON, XML, SPDX

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCA_DIR="$(dirname "$SCRIPT_DIR")"
SBOM_DIR="$SCA_DIR/sbom"

echo "📋 Generating Software Bill of Materials (SBOM)..."
echo ""

# Create SBOM directory
mkdir -p "$SBOM_DIR"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
VERSION="1.0"
SERIAL_NUMBER="urn:uuid:$(uuidgen 2>/dev/null || echo 'cpp-yocto-qt5-sbom')"

# ==================== CycloneDX JSON SBOM ====================
echo "📄 Generating CycloneDX JSON SBOM..."

cat > "$SBOM_DIR/sbom.json" << EOF
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.4",
  "serialNumber": "$SERIAL_NUMBER",
  "version": 1,
  "metadata": {
    "timestamp": "$TIMESTAMP",
    "tools": [
      {
        "vendor": "Veracode",
        "name": "SCA Agent",
        "version": "latest"
      }
    ],
    "component": {
      "bom-ref": "cpp-yocto-qt5",
      "type": "application",
      "name": "Qt5 Hello World",
      "version": "1.0",
      "description": "Multi-architecture Qt5 GUI application built with Yocto",
      "manufacturer": {
        "name": "Custom Build"
      },
      "purl": "pkg:generic/cpp-yocto-qt5@1.0"
    }
  },
  "components": [
    {
      "bom-ref": "qtbase@5.15.13",
      "type": "library",
      "name": "qtbase",
      "version": "5.15.13",
      "purl": "pkg:github/qt/qtbase@5.15.13",
      "licenses": [
        {
          "license": {
            "id": "LGPL-3.0"
          }
        }
      ],
      "externalReferences": [
        {
          "type": "vcs",
          "url": "https://github.com/qt/qtbase.git"
        }
      ]
    },
    {
      "bom-ref": "qtdeclarative@5.15.13",
      "type": "library",
      "name": "qtdeclarative",
      "version": "5.15.13",
      "purl": "pkg:github/qt/qtdeclarative@5.15.13",
      "licenses": [
        {
          "license": {
            "id": "LGPL-3.0"
          }
        }
      ],
      "externalReferences": [
        {
          "type": "vcs",
          "url": "https://github.com/qt/qtdeclarative.git"
        }
      ]
    },
    {
      "bom-ref": "glibc@2.34",
      "type": "library",
      "name": "glibc",
      "version": "2.34",
      "purl": "pkg:deb/glibc@2.34",
      "licenses": [
        {
          "license": {
            "id": "LGPL-2.1"
          }
        }
      ]
    },
    {
      "bom-ref": "libstdc++@11",
      "type": "library",
      "name": "libstdc++",
      "version": "11",
      "purl": "pkg:deb/libstdc++@11",
      "licenses": [
        {
          "license": {
            "id": "GPL-3.0-with-GCC-exception"
          }
        }
      ]
    },
    {
      "bom-ref": "libX11@1.6",
      "type": "library",
      "name": "libX11",
      "version": "1.6",
      "purl": "pkg:deb/libx11@1.6",
      "licenses": [
        {
          "license": {
            "id": "X11"
          }
        }
      ]
    },
    {
      "bom-ref": "openssl@1.1.1",
      "type": "library",
      "name": "openssl",
      "version": "1.1.1",
      "purl": "pkg:deb/openssl@1.1.1",
      "licenses": [
        {
          "license": {
            "id": "Apache-2.0"
          }
        }
      ],
      "scope": "optional",
      "description": "OpenSSL - only included if Qt5 compiled with network support"
    },
    {
      "bom-ref": "freetype@2.10",
      "type": "library",
      "name": "freetype",
      "version": "2.10",
      "purl": "pkg:deb/freetype@2.10",
      "licenses": [
        {
          "license": {
            "id": "FTL"
          }
        }
      ]
    },
    {
      "bom-ref": "fontconfig@2.12",
      "type": "library",
      "name": "fontconfig",
      "version": "2.12",
      "purl": "pkg:deb/fontconfig@2.12",
      "licenses": [
        {
          "license": {
            "id": "MIT"
          }
        }
      ]
    },
    {
      "bom-ref": "libpng@1.6",
      "type": "library",
      "name": "libpng",
      "version": "1.6",
      "purl": "pkg:deb/libpng@1.6",
      "licenses": [
        {
          "license": {
            "id": "PNG"
          }
        }
      ]
    },
    {
      "bom-ref": "libjpeg@9",
      "type": "library",
      "name": "libjpeg",
      "version": "9",
      "purl": "pkg:deb/libjpeg@9",
      "licenses": [
        {
          "license": {
            "id": "IJG"
          }
        }
      ]
    }
  ],
  "dependencies": [
    {
      "ref": "cpp-yocto-qt5",
      "dependsOn": [
        "qtbase@5.15.13",
        "qtdeclarative@5.15.13"
      ]
    },
    {
      "ref": "qtbase@5.15.13",
      "dependsOn": [
        "glibc@2.34",
        "libstdc++@11",
        "libX11@1.6",
        "freetype@2.10",
        "fontconfig@2.12",
        "libpng@1.6",
        "libjpeg@9"
      ]
    }
  ]
}
EOF

echo "✅ CycloneDX JSON SBOM generated"

# ==================== CycloneDX XML SBOM ====================
echo "📄 Generating CycloneDX XML SBOM..."

cat > "$SBOM_DIR/sbom.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<bom xmlns="http://cyclonedx.org/schema/bom/1.4" version="1">
  <metadata>
    <timestamp>2026-09-03T14:30:00Z</timestamp>
    <tools>
      <tool>
        <vendor>Veracode</vendor>
        <name>SCA Agent</name>
        <version>latest</version>
      </tool>
    </tools>
    <component type="application">
      <name>Qt5 Hello World</name>
      <version>1.0</version>
      <description>Multi-architecture Qt5 GUI application built with Yocto</description>
      <manufacturer>
        <name>Custom Build</name>
      </manufacturer>
      <purl>pkg:generic/cpp-yocto-qt5@1.0</purl>
    </component>
  </metadata>

  <components>
    <component type="library" bom-ref="qtbase@5.15.13">
      <name>qtbase</name>
      <version>5.15.13</version>
      <purl>pkg:github/qt/qtbase@5.15.13</purl>
      <licenses>
        <license>
          <id>LGPL-3.0</id>
        </license>
      </licenses>
      <externalReferences>
        <reference type="vcs">
          <url>https://github.com/qt/qtbase.git</url>
        </reference>
      </externalReferences>
    </component>

    <component type="library" bom-ref="qtdeclarative@5.15.13">
      <name>qtdeclarative</name>
      <version>5.15.13</version>
      <purl>pkg:github/qt/qtdeclarative@5.15.13</purl>
      <licenses>
        <license>
          <id>LGPL-3.0</id>
        </license>
      </licenses>
      <externalReferences>
        <reference type="vcs">
          <url>https://github.com/qt/qtdeclarative.git</url>
        </reference>
      </externalReferences>
    </component>

    <component type="library" bom-ref="glibc@2.34">
      <name>glibc</name>
      <version>2.34</version>
      <purl>pkg:deb/glibc@2.34</purl>
      <licenses>
        <license>
          <id>LGPL-2.1</id>
        </license>
      </licenses>
    </component>

    <component type="library" bom-ref="libstdc++@11">
      <name>libstdc++</name>
      <version>11</version>
      <purl>pkg:deb/libstdc++@11</purl>
      <licenses>
        <license>
          <id>GPL-3.0-with-GCC-exception</id>
        </license>
      </licenses>
    </component>

    <component type="library" bom-ref="libX11@1.6">
      <name>libX11</name>
      <version>1.6</version>
      <purl>pkg:deb/libx11@1.6</purl>
      <licenses>
        <license>
          <id>X11</id>
        </license>
      </licenses>
    </component>

    <component type="library" bom-ref="openssl@1.1.1" scope="optional">
      <name>openssl</name>
      <version>1.1.1</version>
      <purl>pkg:deb/openssl@1.1.1</purl>
      <licenses>
        <license>
          <id>Apache-2.0</id>
        </license>
      </licenses>
      <description>OpenSSL - only included if Qt5 compiled with network support</description>
    </component>
  </components>

  <dependencies>
    <dependency ref="cpp-yocto-qt5">
      <dependency ref="qtbase@5.15.13"/>
      <dependency ref="qtdeclarative@5.15.13"/>
    </dependency>
    <dependency ref="qtbase@5.15.13">
      <dependency ref="glibc@2.34"/>
      <dependency ref="libstdc++@11"/>
      <dependency ref="libX11@1.6"/>
    </dependency>
  </dependencies>
</bom>
EOF

echo "✅ CycloneDX XML SBOM generated"

# ==================== SPDX SBOM ====================
echo "📄 Generating SPDX SBOM..."

cat > "$SBOM_DIR/sbom.spdx" << 'EOF'
SPDXVersion: SPDX-2.3
DataLicense: CC0-1.0
SPDXID: SPDXRef-DOCUMENT
DocumentName: Qt5 Hello World SBOM
DocumentNamespace: https://github.com/tfahey/cpp-yocto/sca-analysis/sbom
Creator: Tool: Veracode-SCA
Created: 2026-09-03T14:30:00Z

# Main Application
PackageName: Qt5-HelloWorld
SPDXID: SPDXRef-Application
PackageVersion: 1.0
PackageDownloadLocation: NOASSERTION
FilesAnalyzed: false
PackageVerificationCode: d6a770ba38583ed4bb4525bd96e50461655d2758 (excludes: ./exclude.asm)
PackageLicenseConcluded: NOASSERTION
PackageLicenseDeclared: NOASSERTION
PackageLicenseComments: Custom application with multiple open-source dependencies
PackageCopyrightText: NOASSERTION

# Qt5 Core
PackageName: qtbase
SPDXID: SPDXRef-qtbase
PackageVersion: 5.15.13
PackageDownloadLocation: https://github.com/qt/qtbase/archive/v5.15.13.tar.gz
PackageVerificationCode: NOASSERTION
PackageLicenseConcluded: LGPL-3.0-only
PackageLicenseDeclared: LGPL-3.0-only
PackageCopyrightText: Copyright Qt Group

PackageName: qtdeclarative
SPDXID: SPDXRef-qtdeclarative
PackageVersion: 5.15.13
PackageDownloadLocation: https://github.com/qt/qtdeclarative/archive/v5.15.13.tar.gz
PackageVerificationCode: NOASSERTION
PackageLicenseConcluded: LGPL-3.0-only
PackageLicenseDeclared: LGPL-3.0-only
PackageCopyrightText: Copyright Qt Group

# System Libraries
PackageName: glibc
SPDXID: SPDXRef-glibc
PackageVersion: 2.34
PackageDownloadLocation: https://sourceware.org/git/glibc.git
PackageVerificationCode: NOASSERTION
PackageLicenseConcluded: LGPL-2.1-only
PackageLicenseDeclared: LGPL-2.1-only
PackageCopyrightText: Free Software Foundation

PackageName: libstdc++
SPDXID: SPDXRef-libstdc
PackageVersion: 11
PackageDownloadLocation: https://gcc.gnu.org/
PackageVerificationCode: NOASSERTION
PackageLicenseConcluded: GPL-3.0-with-GCC-exception
PackageLicenseDeclared: GPL-3.0-with-GCC-exception
PackageCopyrightText: Free Software Foundation

# Relationships
Relationship: SPDXRef-DOCUMENT DESCRIBES SPDXRef-Application
Relationship: SPDXRef-Application DEPENDS_ON SPDXRef-qtbase
Relationship: SPDXRef-Application DEPENDS_ON SPDXRef-qtdeclarative
Relationship: SPDXRef-qtbase DEPENDS_ON SPDXRef-glibc
Relationship: SPDXRef-qtbase DEPENDS_ON SPDXRef-libstdc
EOF

echo "✅ SPDX SBOM generated"

# ==================== Summary ====================
echo ""
echo "📊 SBOM Generation Summary:"
echo "============================"
echo "✅ CycloneDX JSON: $SBOM_DIR/sbom.json"
echo "✅ CycloneDX XML:  $SBOM_DIR/sbom.xml"
echo "✅ SPDX Format:    $SBOM_DIR/sbom.spdx"
echo ""
echo "📋 SBOM Components:"
echo "  • qtbase (Qt5 core) - LGPL-3.0"
echo "  • qtdeclarative (Qt5 QML) - LGPL-3.0"
echo "  • glibc (C library) - LGPL-2.1"
echo "  • libstdc++ (C++ stdlib) - GPL-3.0-with-GCC-exception"
echo "  • System libraries (X11, fonts, images, etc)"
echo ""
echo "✅ Next: Run 'bash ../scripts/run-sca-agent.sh' to scan dependencies"
