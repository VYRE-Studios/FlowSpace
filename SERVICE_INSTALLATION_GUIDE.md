# FlowSpace Service-Based Installation Guide

## Overview

FlowSpace now runs as a proper Windows application with background services - no visible PowerShell windows or console prompts!

## What's Changed

### ✅ Before (Old Way)
- Start PowerShell as Admin
- Run `start-dev.ps1`
- See multiple console windows
- Manual startup every time

### ✨ After (New Way - Service-Based)
- Double-click FlowSpace icon
- Services run silently in background
- No console windows
- Auto-starts with Windows
- Runs like a native application

---

## Installation Process

### Step 1: Run USB Installer

```powershell
D:
.\INSTALL.ps1
```

### Step 2: Choose Service Installation

When prompted:
```
Install FlowSpace as Windows Services (auto-start)? (y/n)
```

**Choose 'y' for automatic background operation**

### Step 3: Launch FlowSpace

After installation:
- Double-click **FlowSpace** icon on Desktop
- Services start automatically in background (if not already running)
- Flutter app launches
- No console windows visible!

---

## What Gets Installed

### Windows Services

Three services are registered to run automatically:

1. **FlowSpaceRedis** - Redis cache server
2. **FlowSpaceKratos** - Authentication service  
3. **FlowSpaceBackend** - Backend API server

**Service Properties:**
- Start Type: Automatic
- Dependencies: Redis → Kratos → Backend
- Auto-restart on failure
- Hidden (no console windows)

### Desktop Launcher

**FlowSpace.vbs** - Silent VBScript launcher that:
1. Checks if services are running
2. Starts any stopped services (hidden)
3. Launches Flutter desktop app
4. No PowerShell windows shown

---

## File Structure

```
C:\FlowSpace\
├── FlowSpace.vbs              # Silent launcher (what desktop shortcut runs)
├── start-services-silent.ps1  # Background service starter
├── install-services.ps1       # Service installation script
├── uninstall.ps1              # Complete uninstaller
├── service-wrappers/          # Service wrapper scripts
│   ├── redis-wrapper.bat
│   ├── kratos-wrapper.bat
│   └── backend-wrapper.bat
├── backend/                   # Backend API
├── FlowSpaceApp/              # Flutter desktop app
└── ...
```

---

## Managing Services

### View Services

Open **Services** app:
```powershell
services.msc
```

Look for:
- FlowSpace Redis
- FlowSpace Kratos  
- FlowSpace Backend

### Manual Service Control

```powershell
# Start all services
Start-Service FlowSpaceRedis
Start-Service FlowSpaceKratos
Start-Service FlowSpaceBackend

# Stop all services
Stop-Service FlowSpaceBackend
Stop-Service FlowSpaceKratos
Stop-Service FlowSpaceRedis

# Check status
Get-Service FlowSpace*
```

### Reinstall Services

```powershell
cd C:\FlowSpace
.\install-services.ps1
```

### Uninstall Services

```powershell
cd C:\FlowSpace
.\install-services.ps1 -Uninstall
```

---

## Uninstalling FlowSpace

### Complete Removal

```powershell
cd C:\FlowSpace
.\uninstall.ps1
```

This will:
1. Stop all services
2. Remove Windows services
3. Delete desktop shortcuts
4. Remove FlowSpace directory
5. Optionally remove Kratos config

### Keep Data

```powershell
.\uninstall.ps1 -KeepData
```

---

## User Experience

### First Launch
1. User double-clicks **FlowSpace** icon
2. VBScript launcher runs (invisible)
3. Services start in background (3-5 seconds)
4. Flutter app opens
5. User sees login screen

### Subsequent Launches
1. User double-clicks **FlowSpace** icon
2. Services already running (instant)
3. Flutter app opens immediately
4. Seamless experience!

### After Windows Restart
1. Services start automatically with Windows
2. User double-clicks **FlowSpace** icon
3. App launches immediately (services already running)

---

## Troubleshooting

### Services Won't Start

Check logs:
```powershell
Get-Content C:\FlowSpace\logs\redis.log -Tail 20
Get-Content C:\FlowSpace\logs\kratos.log -Tail 20
Get-Content C:\FlowSpace\logs\backend.log -Tail 20
```

### App Won't Launch

1. Check services are running:
   ```powershell
   Get-Service FlowSpace*
   ```

2. Verify ports:
   ```powershell
   Test-NetConnection localhost -Port 4000
   Test-NetConnection localhost -Port 4433
   ```

3. Check service status in Event Viewer:
   ```powershell
   eventvwr.msc
   # Navigate to Windows Logs > Application
   # Filter by "FlowSpace"
   ```

### Reinstall Services

```powershell
# Uninstall first
.\install-services.ps1 -Uninstall

# Wait a moment
Start-Sleep -Seconds 3

# Reinstall
.\install-services.ps1
```

---

## Manual Start (Without Services)

If you don't want services, you can still start manually:

```powershell
# Option 1: PowerShell (visible windows)
cd C:\FlowSpace
.\start-dev.ps1

# Option 2: Silent background start
cd C:\FlowSpace
powershell.exe -WindowStyle Hidden -File start-services-silent.ps1
.\FlowSpaceApp\client_flutter.exe
```

---

## Advantages of Service-Based Installation

### ✅ User Benefits
- **No console windows** - Clean, professional experience
- **Auto-start** - Services run automatically with Windows
- **Always available** - Backend ready when you launch app
- **Native feel** - Just like any other Windows application
- **Reliable** - Auto-restart on failure

### ✅ Admin Benefits
- **Centralized management** - Standard Windows Services
- **Logging** - Service logs in Event Viewer
- **Dependencies** - Proper startup order (Redis → Kratos → Backend)
- **Recovery** - Automatic restart policies
- **Monitoring** - Use standard Windows tools

---

## Migration from Manual Start

If you previously used `start-dev.ps1`:

1. Stop all running services manually
2. Run `.\install-services.ps1`  
3. Services now handle startup automatically
4. Use Desktop shortcut to launch app
5. Delete any custom startup scripts

---

## Technical Details

### Service Startup Order

```
1. FlowSpaceRedis (Port 6379)
   ↓
2. FlowSpaceKratos (Ports 4433/4456)
   ↓ (depends on Redis)
3. FlowSpaceBackend (Port 4000)
   ↓ (depends on Redis & Kratos)
Flutter App launches
```

### Failure Recovery

Each service is configured to:
- Auto-restart on failure after 5 seconds
- Second failure: restart after 10 seconds
- Third failure: restart after 30 seconds
- Reset failure count after 24 hours

### Security Context

Services run under:
- **Local System** account by default
- Can be changed to specific service account
- Logs written to `C:\FlowSpace\logs\`

---

## Comparison: Service vs Manual

| Feature | Service Mode | Manual Mode |
|---------|-------------|-------------|
| Console Windows | ❌ None | ✅ 3-4 visible |
| Auto-start | ✅ Yes | ❌ Manual |
| Restart on failure | ✅ Yes | ❌ No |
| Admin required | Once (install) | Every time |
| User experience | Native app | Dev tools |
| Management | services.msc | PowerShell |
| Logging | Event Viewer | Console only |

---

## Best Practices

### For End Users
1. ✅ Install as services (choose 'y' during install)
2. ✅ Use desktop shortcut to launch
3. ✅ Check services.msc if issues arise
4. ❌ Don't run start-dev.ps1 manually (conflicts with services)

### For Administrators
1. ✅ Install services on all workstations
2. ✅ Monitor via Event Viewer
3. ✅ Configure service accounts if needed
4. ✅ Set up backup/recovery procedures

---

## Summary

FlowSpace now runs like a proper Windows application:
- **Silent background services** handle all backend operations
- **Clean desktop experience** without console windows
- **Auto-start capability** for always-available functionality
- **Professional appearance** suitable for end users

No more PowerShell windows, no more manual startup - just double-click and go!
