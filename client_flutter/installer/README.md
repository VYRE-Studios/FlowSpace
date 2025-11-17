# FLŌ Installer System

Professional NSIS-based installer for FLŌ (Teams. Unified.)

## 📦 What's Included

This installer system provides three deployment options:

1. **NSIS Installer** - Professional Windows installer with no admin rights required
2. **Portable Version** - USB-ready package that runs from any location
3. **Build Automation** - PowerShell scripts for consistent builds

## 🚀 Quick Start

### Prerequisites

**Required:**
- Windows 10 or later
- Flutter SDK (for building the app)
- NSIS 3.x or later

**Installing NSIS:**
```powershell
# Option 1: Chocolatey
choco install nsis

# Option 2: Manual download
# https://nsis.sourceforge.io/Download
```

### Build Everything

```powershell
# Navigate to installer directory
cd installer

# Build installer (includes Flutter build)
.\build-installer.ps1

# Clean build with verbose output
.\build-installer.ps1 -Clean -Verbose

# Build specific version
.\build-installer.ps1 -Version "1.0.1"
```

## 📄 Files Overview

```
installer/
├── flo-installer.nsi           # NSIS installer script
├── build-installer.ps1         # Main build automation
├── create-portable.ps1         # Portable version creator
└── README.md                   # This file
```

## 🔨 Build Scripts

### build-installer.ps1

**Main build script** that handles the complete installer creation process.

**Parameters:**
- `-Version` - Version number (default: "1.0.0")
- `-BuildType` - Build configuration (default: "Release")
- `-Clean` - Clean build directories before building
- `-SkipFlutterBuild` - Use existing Flutter build
- `-SignExecutable` - Enable code signing (requires configuration)
- `-Verbose` - Detailed build output

**Examples:**
```powershell
# Standard build
.\build-installer.ps1

# Clean build with specific version
.\build-installer.ps1 -Version "1.2.3" -Clean

# Quick rebuild (skip Flutter build)
.\build-installer.ps1 -SkipFlutterBuild

# Verbose output for debugging
.\build-installer.ps1 -Verbose
```

**What it does:**
1. ✅ Checks for NSIS installation
2. 🧹 Cleans previous builds (if `-Clean`)
3. 🔨 Builds Flutter Windows app
4. 📄 Creates/verifies LICENSE file
5. 🔄 Updates version in NSIS script
6. 📦 Compiles NSIS installer
7. ✍️ Signs installer (if configured)
8. ✅ Validates output

### create-portable.ps1

**Creates USB-ready portable package** from Flutter release build.

**Parameters:**
- `-Version` - Version number (default: "1.0.0")
- `-OutputPath` - Output directory (default: ".\FLO-Portable")
- `-ZipPackage` - Create ZIP archive

**Examples:**
```powershell
# Create portable version
.\create-portable.ps1

# Create with ZIP package
.\create-portable.ps1 -ZipPackage

# Custom output location
.\create-portable.ps1 -OutputPath "E:\FLO-Portable"

# Specific version with ZIP
.\create-portable.ps1 -Version "1.0.1" -ZipPackage
```

**Output structure:**
```
FLO-Portable/
├── FLO-Portable.bat        # Launch script
├── README.txt              # User documentation
├── app/                    # Application files
│   └── client_flutter.exe
└── data/                   # Portable data storage
    ├── vault/
    └── cache/
```

## 🎯 Installer Features

### NSIS Installer (flo-installer.nsi)

**Core Features:**
- ✅ No administrator rights required (user-level install)
- ✅ Installs to `%LOCALAPPDATA%\FLŌ`
- ✅ Creates Start Menu shortcuts
- ✅ Optional desktop shortcut
- ✅ Optional portable version creation
- ✅ Clean uninstaller
- ✅ Registry integration
- ✅ Windows Add/Remove Programs entry

**Installation Sections:**

1. **FLŌ Core** (Required)
   - Application files
   - Data directories
   - Start Menu shortcuts
   - Registry entries
   - Uninstaller

2. **Desktop Shortcut** (Optional)
   - Creates desktop shortcut for quick access

3. **Portable Version** (Optional)
   - Creates portable package in install directory
   - Includes launcher script and README
   - Perfect for creating USB versions

**User Experience:**
- Welcome screen with FLŌ branding
- License agreement (MIT)
- Custom install location
- Component selection
- Install progress
- Launch FLŌ on finish

**Uninstall:**
- Removes application files
- Removes shortcuts
- Removes registry entries
- Preserves user data in AppData (safe)
- Confirmation dialog

## 📊 Installer Output

**After building, you'll have:**

```
installer/
└── FLO-1.0.0-Setup.exe     # ~30-50 MB installer
```

**Installer behavior:**
- **Default location**: `%LOCALAPPDATA%\FLŌ`
- **Silent install**: `FLO-1.0.0-Setup.exe /S`
- **Custom location**: User can choose during install
- **Uninstall**: Via Start Menu or Windows Settings

## 🔧 Customization

### Changing Version

**Option 1: Via script parameter**
```powershell
.\build-installer.ps1 -Version "2.0.0"
```

**Option 2: Edit NSIS script directly**
```nsis
!define PRODUCT_VERSION "1.0.0"  # Change this
```

### Changing Publisher

Edit `flo-installer.nsi`:
```nsis
!define PRODUCT_PUBLISHER "Your Company Name"
```

### Adding Files to Installer

Edit the `SecCore` section:
```nsis
Section "FLŌ Core" SecCore
    # ... existing code ...
    
    ; Add custom files
    File "path\to\your\file.txt"
    File /r "path\to\folder\*.*"
SectionEnd
```

### Custom Icons

Replace icons (must be .ico format):
```nsis
!define MUI_ICON "..\windows\runner\resources\app_icon.ico"
!define MUI_UNICON "..\windows\runner\resources\app_icon.ico"
```

## 🧪 Testing Checklist

### Test Installation
```powershell
# Normal install (GUI)
.\FLO-1.0.0-Setup.exe

# Silent install
.\FLO-1.0.0-Setup.exe /S

# Check installed files
dir "$env:LOCALAPPDATA\FLŌ"

# Launch FLŌ
& "$env:LOCALAPPDATA\FLŌ\client_flutter.exe"
```

### Test Portable Version
```powershell
# Create portable package
.\create-portable.ps1

# Launch portable version
.\FLO-Portable\FLO-Portable.bat

# Verify data isolation
dir .\FLO-Portable\data
```

### Test Uninstall
1. Open Start Menu → FLŌ → Uninstall FLŌ
2. Or: Windows Settings → Apps → FLŌ → Uninstall
3. Verify files removed
4. Verify shortcuts removed
5. Verify registry entries removed

## 🔐 Code Signing (Optional)

To enable code signing for trusted installation:

1. **Obtain certificate**
   - Purchase code signing certificate
   - Or use self-signed for internal testing

2. **Install Windows SDK**
   - Includes `signtool.exe`
   - Location: `C:\Program Files (x86)\Windows Kits\10\bin\...\signtool.exe`

3. **Configure signing**
   - Edit `build-installer.ps1`
   - Uncomment signing section (lines 176-177)
   - Add certificate details

**Example signing command:**
```powershell
$signtool = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe"
& $signtool sign /f "certificate.pfx" /p "password" /t http://timestamp.digicert.com FLO-1.0.0-Setup.exe
```

## 📦 Distribution

### For End Users

**Standard Installation:**
1. Download `FLO-1.0.0-Setup.exe`
2. Run installer (double-click)
3. Follow setup wizard
4. Launch FLŌ from Start Menu

**Portable Version:**
1. Download `FLO-Portable-1.0.0.zip`
2. Extract to USB drive or any location
3. Run `FLO-Portable.bat`
4. All data stored in `data\` folder

### For Enterprises

**Silent Deployment:**
```batch
REM Deploy to all workstations
FLO-1.0.0-Setup.exe /S /D=C:\Program Files\FLO
```

**Network Share:**
```batch
REM Install from network share
\\server\apps\FLO-1.0.0-Setup.exe /S
```

**Configuration Management:**
- Integrates with SCCM, Intune, PDQ Deploy
- MSI wrapper available if needed
- GPO deployment supported

## 🐛 Troubleshooting

### Build Issues

**Problem**: NSIS not found
```
Solution: Install NSIS or update $NsisPath in build script
```

**Problem**: Flutter build fails
```
Solution: Run 'flutter doctor' and fix issues
         Verify 'flutter build windows --release' works
```

**Problem**: Installer compilation errors
```
Solution: Check NSIS script syntax
         Run with -Verbose flag for details
```

### Installer Issues

**Problem**: "Not a valid Win32 application"
```
Solution: Ensure you built for correct architecture (x64)
```

**Problem**: Installer won't run
```
Solution: Check Windows SmartScreen settings
         Sign installer for production use
```

**Problem**: Files missing after install
```
Solution: Verify NSIS File commands in script
         Check build output directory
```

### Portable Issues

**Problem**: Data not persisting
```
Solution: Ensure 'data' folder has write permissions
         Run from location with write access
```

**Problem**: Multiple instances conflicting
```
Solution: Only run one instance at a time
         Database locks prevent concurrent access
```

## 📚 Resources

**NSIS Documentation:**
- Official docs: https://nsis.sourceforge.io/Docs/
- Modern UI: https://nsis.sourceforge.io/Docs/Modern%20UI%202/Readme.html
- Examples: https://nsis.sourceforge.io/Examples/

**Flutter Windows Deployment:**
- https://docs.flutter.dev/deployment/windows

**Code Signing:**
- https://learn.microsoft.com/en-us/windows/win32/seccrypto/cryptography-tools

## 🎯 Best Practices

1. **Version everything** - Use semantic versioning (1.0.0)
2. **Test on clean VM** - Verify installer on fresh Windows install
3. **Sign releases** - Code signing builds trust
4. **Provide both** - Offer installer AND portable versions
5. **Document changes** - Maintain changelog for updates
6. **Backup user data** - Never delete user data on uninstall

## 📞 Support

For issues with the installer system:
- Check this README first
- Review NSIS script comments
- Test with `-Verbose` flag
- Check Flutter build output

---

**FLŌ Installer System v1.0.0**  
© VyreVault Studios  
MIT License
