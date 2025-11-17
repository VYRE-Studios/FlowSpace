# FLŌ Installer - Quick Start Guide

## 🎯 Goal
Create a professional Windows installer for FLŌ in under 5 minutes.

---

## ⚡ One-Time Setup

### 1. Install NSIS

**Option A: Chocolatey (Recommended)**
```powershell
choco install nsis
```

**Option B: Manual Download**
1. Go to https://nsis.sourceforge.io/Download
2. Download NSIS 3.x installer
3. Install to default location: `C:\Program Files (x86)\NSIS`

### 2. Verify Installation
```powershell
Test-Path "C:\Program Files (x86)\NSIS\makensis.exe"
# Should return: True
```

---

## 🚀 Build Your First Installer

### Step 1: Navigate to installer directory
```powershell
cd C:\FlowSpace\client_flutter\installer
```

### Step 2: Build everything
```powershell
.\build-installer.ps1
```

That's it! 🎉

**What happens:**
1. ✅ Builds Flutter Windows app (Release mode)
2. ✅ Creates LICENSE file (if missing)
3. ✅ Compiles NSIS installer
4. ✅ Outputs: `FLO-1.0.0-Setup.exe`

**Time:** ~3-5 minutes (depending on Flutter build)

---

## 📦 Output Files

After successful build, you'll have:

```
installer/
└── FLO-1.0.0-Setup.exe    (~30-50 MB)
```

### Test It Immediately

**Standard install:**
```powershell
.\FLO-1.0.0-Setup.exe
```

**Silent install (for testing automation):**
```powershell
.\FLO-1.0.0-Setup.exe /S
```

**Where it installs:**
```
%LOCALAPPDATA%\FLŌ\
```

**Verify installation:**
```powershell
& "$env:LOCALAPPDATA\FLŌ\client_flutter.exe"
```

---

## 🎒 Create Portable Version

Want a USB-ready version?

```powershell
.\create-portable.ps1
```

**Output:**
```
installer/
└── FLO-Portable/
    ├── FLO-Portable.bat    ← Double-click this!
    ├── README.txt
    ├── app/
    └── data/
```

**Test it:**
```powershell
.\FLO-Portable\FLO-Portable.bat
```

**Create ZIP for distribution:**
```powershell
.\create-portable.ps1 -ZipPackage
```

---

## 🔄 Common Build Scenarios

### Clean Rebuild
When you've made code changes:
```powershell
.\build-installer.ps1 -Clean
```

### Different Version Number
```powershell
.\build-installer.ps1 -Version "1.1.0"
```

### Quick Rebuild (Skip Flutter Build)
If you just modified NSIS script:
```powershell
.\build-installer.ps1 -SkipFlutterBuild
```

### Verbose Output (for debugging)
```powershell
.\build-installer.ps1 -Verbose
```

---

## 🎯 What Gets Installed?

**Installer creates:**
- ✅ `%LOCALAPPDATA%\FLŌ\` - Application files
- ✅ Start Menu → FLŌ
- ✅ Desktop shortcut (optional)
- ✅ Windows registry entries
- ✅ Add/Remove Programs entry
- ✅ Uninstaller

**User data stored separately:**
- Database: `%APPDATA%\com.example\client_flutter\flowspace.db`
- Vault files: Safe from uninstall

**No admin rights required!**

---

## 📋 Feature Checklist

### NSIS Installer Includes:

- [x] **No admin rights** - User-level installation
- [x] **Modern UI** - Professional wizard interface
- [x] **License screen** - MIT license display
- [x] **Component selection** - Choose what to install
- [x] **Desktop shortcut** - Optional
- [x] **Portable version** - Optional
- [x] **Uninstaller** - Clean removal
- [x] **Registry integration** - Proper Windows integration
- [x] **Add/Remove Programs** - Shows in Windows Settings

### Portable Version Includes:

- [x] **Single folder** - Everything self-contained
- [x] **Batch launcher** - Easy to run
- [x] **Data isolation** - Uses local data folder
- [x] **USB-ready** - Copy to any location
- [x] **Comprehensive README** - User documentation
- [x] **ZIP option** - Easy distribution

---

## 🐛 Troubleshooting

### "NSIS not found"
```powershell
# Install NSIS first
choco install nsis

# Or update path in build script
```

### "Flutter build failed"
```powershell
# Check Flutter installation
flutter doctor

# Try manual build
cd ..
flutter build windows --release
```

### "File not found" errors
```powershell
# Verify Flutter built successfully
dir build\windows\x64\runner\Release\client_flutter.exe
```

### Installer won't run
```
Right-click FLO-1.0.0-Setup.exe → Properties → Unblock
```

---

## 📊 File Sizes (Approximate)

| Component | Size |
|-----------|------|
| Flutter App (built) | ~25 MB |
| NSIS Installer | ~30 MB |
| Portable Package | ~28 MB |
| Portable ZIP | ~12 MB (compressed) |

---

## 🎓 Next Steps

### Production Builds

**1. Version Your Release**
```powershell
.\build-installer.ps1 -Version "1.0.0" -Clean
```

**2. Code Sign (Optional)**
- Get code signing certificate
- Configure signing in `build-installer.ps1`
- Removes Windows SmartScreen warnings

**3. Test on Clean Machine**
- Use Windows VM or clean test system
- Verify all features work
- Test uninstall process

**4. Distribute**
- Upload to website
- Share via cloud storage
- Enterprise deployment via SCCM/Intune

---

## 📚 Learn More

**Full documentation:**
- `README.md` - Complete guide
- `flo-installer.nsi` - NSIS script (commented)
- `build-installer.ps1` - Build automation

**NSIS documentation:**
- https://nsis.sourceforge.io/Docs/

---

## 🎯 Common Commands (Copy-Paste Ready)

```powershell
# Build installer
cd C:\FlowSpace\client_flutter\installer
.\build-installer.ps1

# Build portable version
.\create-portable.ps1 -ZipPackage

# Test installer (normal)
.\FLO-1.0.0-Setup.exe

# Test installer (silent)
.\FLO-1.0.0-Setup.exe /S

# Test portable
.\FLO-Portable\FLO-Portable.bat

# Clean rebuild
.\build-installer.ps1 -Clean -Verbose

# Version bump
.\build-installer.ps1 -Version "1.1.0" -Clean
```

---

## ✅ Success Checklist

Your installer is ready when:

- [ ] `FLO-1.0.0-Setup.exe` exists in installer folder
- [ ] Installer runs without errors
- [ ] FLŌ launches after installation
- [ ] Start Menu shortcut works
- [ ] Uninstaller works properly
- [ ] Portable version launches correctly
- [ ] Database persists between runs

---

**🎉 You're now ready to distribute FLŌ!**

**Questions?** Check `README.md` for detailed information.

---

*FLŌ Installer System - VyreVault Studios*
