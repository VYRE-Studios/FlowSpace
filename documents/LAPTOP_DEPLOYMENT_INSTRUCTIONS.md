# FLO Laptop Deployment Instructions

## Overview

The USB installer has been updated to automatically install Flutter SDK on the laptop. This eliminates the manual setup steps and provides a one-command installation.

## What Changed

### Before
- Laptop needed Flutter pre-installed
- P2P test failed with "dart/flutter not found"
- Required manual Flutter installation (~30 minutes)

### After
- **Installer auto-detects Flutter**
- **Automatically downloads and installs Flutter SDK** (~500MB, 5-10 min)
- **Adds Flutter to system PATH**
- **Runs `flutter doctor` to verify installation**
- **Installs P2P dependencies** (`flutter pub get`)
- **Ready to test P2P immediately**

## USB Installer Package

**Location:** `C:\FlowSpace\FlowSpace-USB-Installer`  
**Size:** 469.72 MB (25,184 files)  
**Ready to copy to USB drive**

### Package Contents

```
FlowSpace-USB-Installer/
├── INSTALL.ps1                  # Main installer script (UPDATED)
├── START_HERE_LAPTOP.md         # Quick start guide (NEW)
├── README.txt                   # General info
├── FlowSpace/                   # Application files
│   ├── FlowSpaceApp/           # Pre-built Flutter app
│   ├── backend/                # Node.js backend
│   ├── client_flutter/         # Flutter source + P2P code
│   │   ├── lib/                # Dart source code
│   │   ├── setup_p2p.ps1      # P2P setup script
│   │   └── test_p2p.ps1       # P2P test script
│   ├── start-dev.ps1           # Development launcher
│   └── DEPLOYMENT_GUIDE.md     # Full documentation
├── Config/                      # Kratos configuration
│   ├── kratos.yaml
│   └── identity.schema.json
└── Dependencies/                # (Optional) Offline installers
```

## Deployment Steps

### 1. Copy to USB Drive

```powershell
# Plug in USB drive (e.g., H:\)
Copy-Item -Path "C:\FlowSpace\FlowSpace-USB-Installer\*" -Destination "H:\" -Recurse -Force
```

### 2. On Laptop

```powershell
# Open PowerShell as Administrator
cd H:\
.\INSTALL.ps1
```

### 3. Installation Flow

The installer will:

1. **[Step 1/6] Check prerequisites**
   - Node.js, PostgreSQL, Redis, Kratos, **Flutter**
   - If Flutter is missing, offers to auto-install

2. **[Auto-Install Flutter]** (if needed)
   - Downloads `flutter_windows_3.24.5-stable.zip` (~500MB)
   - Extracts to `C:\Flutter`
   - Adds `C:\Flutter\flutter\bin` to system PATH
   - Runs `flutter doctor` to verify
   - Takes 5-10 minutes on good connection

3. **[Step 2/6] Copy FlowSpace to C:\FlowSpace**

4. **[Step 3/6] Install Kratos configuration**

5. **[Step 4/6] Install backend dependencies**
   - Runs `npm install` in backend directory

6. **[Step 5/6] Setup P2P messaging**
   - Adds firewall rule: UDP port 33445
   - Runs `flutter pub get` for P2P dependencies

7. **[Step 6/7] Initialize database**
   - Creates PostgreSQL tables
   - Seeds initial data

8. **[Step 7/7] Test P2P** (optional)
   - Runs 30-second P2P test
   - Looks for desktop peer on LAN

### 4. Test P2P Connection

On **both desktop and laptop**, run simultaneously:

```powershell
cd C:\FlowSpace\client_flutter
.\test_p2p.ps1
```

Expected output:
```
🔵 Peer discovered: [peer_id]... at 10.5.0.x
   Total peers: 1

✅ Peer discovered on LAN
✅ Connection established  
✅ Message sent
✅ Message received

════════════════════════════════════════════════════════
Test Summary:
  Duration: 30 seconds
  Peers Discovered: 1
  Messages Sent: 5
  Messages Received: 5
  Status: SUCCESS
════════════════════════════════════════════════════════
```

## Technical Details

### Flutter Installation Process

The installer:
1. Downloads from Google's official Flutter CDN
2. Extracts to `C:\Flutter` (requires ~1.5GB disk space)
3. Modifies **Machine-level PATH** (requires admin)
4. Verifies with `flutter doctor`
5. Continues even if `flutter doctor` shows warnings

### Manual Flutter Installation (Fallback)

If auto-install fails:

```powershell
# Download Flutter SDK
$url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip"
Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\flutter.zip"

# Extract
Expand-Archive -Path "$env:TEMP\flutter.zip" -DestinationPath "C:\" -Force

# Add to PATH (admin PowerShell)
$path = [Environment]::GetEnvironmentVariable("Path", "Machine")
[Environment]::SetEnvironmentVariable("Path", "$path;C:\Flutter\flutter\bin", "Machine")

# Restart PowerShell
exit

# Verify
flutter --version
flutter doctor
```

### P2P System Requirements

- **Network:** Both devices on same WiFi (10.5.0.x)
- **Firewall:** UDP port 33445 inbound allowed
- **Dependencies:** Flutter SDK, Dart cryptography packages
- **Discovery:** UDP broadcast every 2 seconds
- **Encryption:** X25519 + ChaCha20-Poly1305

### Firewall Configuration

The installer automatically adds:
```powershell
New-NetFirewallRule `
    -DisplayName "FLO P2P" `
    -Direction Inbound `
    -Protocol UDP `
    -LocalPort 33445 `
    -Action Allow `
    -Profile Any `
    -Description "Allow FLO peer-to-peer messaging on UDP port 33445"
```

To verify:
```powershell
Get-NetFirewallRule -DisplayName "FLO P2P" | Format-List
```

## Troubleshooting

### Issue: Flutter not found after installation

**Cause:** PATH not updated in current session  
**Solution:**
```powershell
# Restart PowerShell, or add manually:
$env:Path += ";C:\Flutter\flutter\bin"
flutter --version
```

### Issue: P2P test shows "No peers discovered"

**Causes:**
1. Devices on different networks
2. Firewall blocking UDP 33445
3. Test not running simultaneously

**Solutions:**
```powershell
# Check network
ipconfig | Select-String "IPv4"
# Both should show 10.5.0.x

# Check firewall
Get-NetFirewallRule -DisplayName "FLO P2P"

# Add firewall rule manually
New-NetFirewallRule -DisplayName "FLO P2P" -Direction Inbound -Protocol UDP -LocalPort 33445 -Action Allow
```

### Issue: Flutter download fails

**Cause:** Network timeout, proxy, or CDN issue  
**Solution:**
1. Try manual installation (see above)
2. Download on desktop and copy flutter.zip to USB
3. Extract manually on laptop

### Issue: "Dart not found" when running test

**Cause:** Flutter not in PATH  
**Solution:**
```powershell
# Check Flutter installation
Test-Path "C:\Flutter\flutter\bin\dart.exe"

# If exists, add to PATH
$env:Path += ";C:\Flutter\flutter\bin"

# Verify
dart --version
```

## Time Estimates

| Step | Duration |
|------|----------|
| Prerequisites check | 10 seconds |
| Flutter download | 3-8 minutes (500MB) |
| Flutter extraction | 1-2 minutes |
| Copy FlowSpace | 30 seconds |
| Backend dependencies | 1-2 minutes |
| Flutter dependencies | 30 seconds |
| Database init | 30 seconds |
| P2P test | 30 seconds |
| **Total** | **10-15 minutes** |

*Note: Times assume good internet connection*

## Success Criteria

After installation, the laptop should have:
- ✅ Flutter SDK at `C:\Flutter\flutter\bin`
- ✅ `flutter --version` works in PowerShell
- ✅ FLO application at `C:\FlowSpace`
- ✅ Firewall rule "FLO P2P" active
- ✅ P2P test discovers desktop peer
- ✅ Desktop shortcut created
- ✅ Database initialized

## Next Steps

1. **Deploy to USB**
   ```powershell
   Copy-Item -Path "C:\FlowSpace\FlowSpace-USB-Installer\*" -Destination "H:\" -Recurse -Force
   ```

2. **Run on Laptop**
   ```powershell
   cd H:\
   .\INSTALL.ps1
   ```

3. **Test P2P** (both devices)
   ```powershell
   cd C:\FlowSpace\client_flutter
   .\test_p2p.ps1
   ```

4. **Verify Success**
   - Both devices discover each other
   - Messages exchanged
   - Test shows "SUCCESS"

## Files Updated

- `prepare-usb-installer.ps1` - Added Flutter auto-install logic
- `INSTALL.ps1` - Embedded in USB installer with Flutter support
- `START_HERE_LAPTOP.md` - New quick start guide
- `LAPTOP_DEPLOYMENT_INSTRUCTIONS.md` - This file

## References

- Flutter installation: https://docs.flutter.dev/get-started/install/windows
- FLO P2P design: `C:\FlowSpace\docs\FLO_P2P_DESIGN.md`
- FLO P2P quick start: `C:\FlowSpace\docs\FLO_P2P_QUICKSTART.md`
- Deployment guide: `C:\FlowSpace\DEPLOYMENT_GUIDE.md`
