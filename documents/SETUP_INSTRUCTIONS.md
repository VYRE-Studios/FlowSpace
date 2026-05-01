# FlowSpace - Complete Setup Guide

## ✅ What's Been Built

### 1. Onboarding Flow
- **Welcome Screen** - Beautiful intro with feature list
- **User Registration** - Name, email, password, workspace setup
- **Local Storage** - User data saved in Hive (works offline)
- **Backend Integration** - Tries to register with backend, falls back to local-only mode

### 2. Service Management
- **FlowSpace-Services.ps1** - Manages all backend services (hidden processes)
- **FlowSpace-Setup.ps1** - One-time setup (installs deps, builds backend)
- **Launch-FlowSpace.ps1** - Ensures services running before app launch

### 3. Complete Installer
- **Bundles everything**: Flutter app, backend code, all server binaries
- **One-command install**: Just run INSTALL.ps1
- **Auto-setup option**: Configures everything after install

## 🚀 How to Use

### Option A: Quick Test (From Development)
```powershell
# Launch the app directly
C:\FlowSpace\client_flutter\build\windows\x64\runner\Release\client_flutter.exe
```

### Option B: Full Install (Production-like)
```powershell
# 1. Run installer with admin privileges
cd C:\FlowSpace\FlowSpace-USB-Installer
Start-Process pwsh -Verb RunAs -ArgumentList "-NoExit", "-Command", ".\INSTALL.ps1"

# 2. Follow prompts:
#    - Install to: C:\Users\YourName\FlowSpace (or custom path)
#    - Say YES to run setup
#    - Setup will install backend deps and start services

# 3. Launch FlowSpace from desktop shortcut
```

## 📝 What Happens on First Launch

1. **App Opens** → Shows Welcome Screen
2. **Click "Get Started"** → Setup User Screen
3. **Fill in Details:**
   - Full Name
   - Email
   - Password  
   - Workspace Name
4. **Click "Create Account"**
   - Saves user locally in Hive
   - Tries to register with backend (3 second timeout)
   - If backend unavailable: continues in local-only mode
5. **Redirects to Main App** → FlowShell with all features

## 🔧 Backend Setup (Optional)

FlowSpace works **without any backend** - everything is stored locally.

To enable collaboration features (chat, video, file sharing):

### Prerequisites
- Node.js 18+ (required)
- PostgreSQL 15+ (required)

### Setup Steps
```powershell
# Navigate to your FlowSpace installation
cd C:\Users\YourName\FlowSpace

# Run setup (only needed once)
.\FlowSpace-Setup.ps1

# Start all services (hidden in background)
.\FlowSpace-Services.ps1 -Action Start

# Check service status
.\FlowSpace-Services.ps1 -Action Status

# Stop services
.\FlowSpace-Services.ps1 -Action Stop
```

### Services Managed
- **Redis** (port 6379) - Caching & pub/sub
- **MinIO** (port 9000) - File storage
- **Kratos** (port 4433) - Authentication  
- **LiveKit** (port 7880) - Video/audio
- **Backend API** (port 4000) - NestJS server

All run **hidden in background** - you never see console windows.

## 📦 USB Distribution

To create a USB installer:

```powershell
# 1. Rebuild installer (includes latest changes)
cd C:\FlowSpace
.\bundle-installer.ps1

# 2. Copy to USB
Copy-Item C:\FlowSpace\FlowSpace-USB-Installer E:\FlowSpace-Installer -Recurse

# 3. On target machine, run:
E:\FlowSpace-Installer\INSTALL.ps1
```

## 🎯 Key Features

### Works Offline
- No internet required
- No servers needed  
- Everything stored locally

### Optional Backend
- Enable when you want collaboration
- Hidden background services
- One-command start/stop

### True Native App
- Flutter compiled to Windows .exe
- Fast, responsive UI
- No browser, no Electron

## 🗂️ File Locations

### After Installation
```
C:\Users\YourName\FlowSpace\
├── FlowSpaceApp\
│   └── client_flutter.exe          # Main app
├── backend\                         # NestJS backend
├── bin\                            # Server binaries
│   ├── Redis\
│   ├── MinIO\
│   ├── Kratos\
│   └── LiveKit\
├── data\                           # App data
│   └── minio\                      # File storage
├── config\                         # Server configs
├── logs\                           # Service logs
├── FlowSpace-Services.ps1          # Service manager
├── FlowSpace-Setup.ps1             # Setup script
└── Launch-FlowSpace.ps1            # App launcher
```

### User Data
```
C:\Users\YourName\Documents\
└── flowspace_hive\                 # Local user database
```

## 🔍 Troubleshooting

### App won't launch
```powershell
# Check if services are running
C:\Users\YourName\FlowSpace\FlowSpace-Services.ps1 -Action Status

# Try launching directly
C:\Users\YourName\FlowSpace\FlowSpaceApp\client_flutter.exe
```

### Backend errors
```powershell
# Reinstall backend dependencies
cd C:\Users\YourName\FlowSpace\backend
npm install
npm run build

# Restart services
..\FlowSpace-Services.ps1 -Action Restart
```

### Reset user data
```powershell
# Delete local user storage
Remove-Item "$env:USERPROFILE\Documents\flowspace_hive" -Recurse -Force

# App will show onboarding again
```

## ✨ Summary

**FlowSpace is now ready to use!**

- ✅ Beautiful onboarding flow
- ✅ Local-first (works offline)
- ✅ Optional backend (for collaboration)
- ✅ Hidden services (no console windows)
- ✅ One-command install
- ✅ USB distributable

**Next Steps:**
1. Run the installer
2. Launch FlowSpace
3. Create your account
4. Start collaborating!

The app works **immediately** - no servers, no setup, no hassle. Enable backend features later when you need them.
