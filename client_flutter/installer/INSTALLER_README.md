# FLO Installer - Complete Setup Guide

## Overview

The FLO installer is a comprehensive NSIS-based installer that automatically sets up:
- FLO desktop application
- PostgreSQL database server
- Backend API service
- All required Windows services

## Building the Installer

### Prerequisites

1. **NSIS** - Install from https://nsis.sourceforge.io/Download or via Chocolatey: `choco install nsis`
2. **PostgreSQL** - Either:
   - Install PostgreSQL to `C:\Program Files\PostgreSQL` (any version)
   - Or place PostgreSQL binaries in `C:\FlowSpace\bin\PostgreSQL`
3. **NSSM** - Download from https://nssm.cc/download and place `nssm.exe` in `C:\FlowSpace\`
4. **Node.js** - Required for building the backend

### Build Steps

1. **Build Flutter app** (if not already built):
   ```powershell
   cd C:\FlowSpace\client_flutter
   flutter build windows --release
   ```

2. **Build backend** (if not already built):
   ```powershell
   cd C:\FlowSpace\backend
   npm install
   npm run build
   npx prisma generate
   ```

3. **Run installer build script**:
   ```powershell
   cd C:\FlowSpace\client_flutter\installer
   .\build-installer.ps1
   ```

The script will:
- Build the Flutter app (if needed)
- Build the backend
- Copy all dependencies to `installer\deps\`
- Compile the NSIS installer
- Create `FLO-1.0.0-Setup.exe`

## Installation Process

When the installer runs, it will:

1. **Install FLO Core** (required):
   - Extract Flutter app to `%LOCALAPPDATA%\FLO`
   - Create Start Menu shortcuts
   - Set up registry entries

2. **Install Backend Services** (required):
   - Extract PostgreSQL to `C:\Program Files\FlowSpace\PostgreSQL`
   - Extract backend to `C:\Program Files\FlowSpace\backend`
   - Extract NSSM to `C:\Program Files\FlowSpace\`
   - Initialize PostgreSQL database
   - Create database `flowspace`
   - Install PostgreSQL as Windows service (`FlowSpacePostgreSQL`)
   - Install backend as Windows service (`FlowSpaceBackend`)
   - Run Prisma migrations
   - Start all services

3. **Optional Components**:
   - Desktop shortcut
   - Portable version

## Post-Installation

After installation, verify everything is running:

```powershell
# Check services
Get-Service FlowSpacePostgreSQL
Get-Service FlowSpaceBackend

# Test backend API
curl http://localhost:4000/api/v1/p2p/status

# Check logs
Get-Content "C:\Program Files\FlowSpace\logs\Backend-stdout.log" -Tail 20
```

## Troubleshooting

### Services Not Starting

1. Check logs in `C:\Program Files\FlowSpace\logs\`
2. Verify PostgreSQL is running:
   ```powershell
   Test-NetConnection -ComputerName localhost -Port 5432
   ```
3. Verify backend can connect:
   ```powershell
   curl http://localhost:4000/api/v1/p2p/status
   ```

### Database Connection Issues

1. Check `.env` file in `C:\Program Files\FlowSpace\backend\.env`
2. Verify DATABASE_URL is correct
3. Check PostgreSQL is listening on localhost:
   ```powershell
   Get-Content "C:\Program Files\FlowSpace\data\postgresql\postgresql.conf" | Select-String "listen_addresses"
   ```

### Missing Dependencies

If the installer fails to find dependencies:
1. Ensure PostgreSQL is installed or copied to the correct location
2. Ensure NSSM is in `C:\FlowSpace\nssm.exe`
3. Rebuild the backend before building the installer

## Uninstallation

The uninstaller will:
- Remove FLO application files
- Remove shortcuts
- Optionally remove PostgreSQL (prompts user)
- Remove backend service
- Remove registry entries

**Note**: User data in AppData is preserved by default.

## Silent Installation

To install silently (no UI):
```powershell
.\FLO-1.0.0-Setup.exe /S
```

To install with specific components:
```powershell
.\FLO-1.0.0-Setup.exe /S /D=C:\FLO
```

## File Structure After Installation

```
C:\Program Files\FlowSpace\
├── PostgreSQL\          # PostgreSQL binaries
├── backend\             # Backend application
│   ├── dist\            # Compiled TypeScript
│   ├── node_modules\    # Node.js dependencies
│   ├── prisma\          # Database schema
│   └── .env             # Configuration
├── service-wrappers\    # Service wrapper scripts
├── logs\                # Service logs
└── nssm.exe             # Service manager

%LOCALAPPDATA%\FLO\
├── client_flutter.exe   # FLO desktop app
└── data\                # User data
```

## Next Steps

After successful installation:
1. Launch FLO from Start Menu or desktop shortcut
2. Backend API will be available at `http://localhost:4000`
3. P2P Runtime will be available on UDP port `33445`
4. All services start automatically on Windows boot

