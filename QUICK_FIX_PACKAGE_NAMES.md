# Quick Fix - Qt5 Package Names

**Error:** `Nothing PROVIDES 'qt5-declarative'` (suggests `qtdeclarative`)

**Fix:** Recipe already updated! Package names corrected for meta-qt5

---

## What Changed

The recipe (`hello-world_0.1.bb`) was updated:

**Old (Wrong):**
```bash
DEPENDS = "qt5-qmake-native qt5-base qt5-declarative"
RDEPENDS:${PN} = "qt5-core qt5-gui qt5-widgets"
```

**New (Correct):**
```bash
DEPENDS = "qtbase-native qtbase qtdeclarative"
RDEPENDS:${PN} = "qtbase-core qtbase-gui qtbase-widgets"
```

The file has been updated. Just rebuild!

---

## In Docker (2 minutes)

```bash
cd /home/yocto/project/build

# Clear cache
bitbake -c cleanall hello-world
rm -rf tmp/work/*/hello-world-*

# Rebuild
bitbake hello-world
```

---

## Package Name Mappings

| Old | New (meta-qt5) |
|-----|---|
| qt5-qmake-native | qtbase-native |
| qt5-base | qtbase |
| qt5-declarative | qtdeclarative |
| qt5-core | qtbase-core |
| qt5-gui | qtbase-gui |
| qt5-widgets | qtbase-widgets |

---

Done! Ready to build 🚀

For details: [FIX_QT5_PACKAGE_NAMES.md](FIX_QT5_PACKAGE_NAMES.md)
