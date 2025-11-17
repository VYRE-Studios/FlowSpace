#!/usr/bin/env pwsh
# FlowSpace USB Installer Preparation Script
# Creates a complete standalone installer package for USB deployment

param(
    [string]$OutputPath = ".\FlowSpace-USB-Installer",
    [switch]$IncludeDependencies,
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        FlowSpace USB Installer Preparation              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build Flutter release
if (-not $SkipBuild) {
    Write-Host "[1/6] Building Flutter release..." -ForegroundColor Cyan
    if (!(Test-Path ".\client_flutter\build\windows\x64\runner\Release\client_flutter.exe")) {
        Write-Host "      Building Flutter app..." -ForegroundColor Yellow
        Push-Location client_flutter
        flutter build windows --release
        Pop-Location
        Write-Host "      ✓ Flutter app built" -ForegroundColor Green
    } else {
        Write-Host "      ✓ Flutter release already exists" -ForegroundColor Green
    }
} else {
    Write-Host "[1/6] Skipping Flutter build..." -ForegroundColor Yellow
}

# Step 2: Create package directory structure
Write-Host "[2/6] Creating USB installer structure..." -ForegroundColor Cyan
if (Test-Path $OutputPath) {
    Remove-Item -Path $OutputPath -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
New-Item -ItemType Directory -Path "$OutputPath\FlowSpace" -Force | Out-Null
New-Item -ItemType Directory -Path "$OutputPath\Dependencies" -Force | Out-Null
New-Item -ItemType Directory -Path "$OutputPath\Config" -Force | Out-Null
Write-Host "      ✓ Directory structure created" -ForegroundColor Green

# Step 3: Copy application files
Write-Host "[3/6] Copying application files..." -ForegroundColor Cyan

# Copy backend
Write-Host "      Copying backend..." -ForegroundColor Yellow
Copy-Item -Path ".\backend" -Destination "$OutputPath\FlowSpace\backend" -Recurse -Force -Exclude node_modules,dist,.env,*.log

# Copy Flutter app
Write-Host "      Copying Flutter app..." -ForegroundColor Yellow
if (Test-Path ".\client_flutter\build\windows\x64\runner\Release") {
    Copy-Item -Path ".\client_flutter\build\windows\x64\runner\Release" -Destination "$OutputPath\FlowSpace\FlowSpaceApp" -Recurse -Force
} else {
    Write-Host "      ⚠️  Flutter release build not found" -ForegroundColor Red
}

# Copy Flutter P2P source (needed for P2P functionality)
Write-Host "      Copying Flutter P2P source..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "$OutputPath\FlowSpace\client_flutter" -Force | Out-Null
Copy-Item -Path ".\client_flutter\lib" -Destination "$OutputPath\FlowSpace\client_flutter\" -Recurse -Force
Copy-Item -Path ".\client_flutter\pubspec.yaml" -Destination "$OutputPath\FlowSpace\client_flutter\" -Force
Copy-Item -Path ".\client_flutter\pubspec.lock" -Destination "$OutputPath\FlowSpace\client_flutter\" -Force -ErrorAction SilentlyContinue
Copy-Item -Path ".\client_flutter\setup_p2p.ps1" -Destination "$OutputPath\FlowSpace\client_flutter\" -Force -ErrorAction SilentlyContinue
Copy-Item -Path ".\client_flutter\test_p2p.ps1" -Destination "$OutputPath\FlowSpace\client_flutter\" -Force -ErrorAction SilentlyContinue
Write-Host "      ✓ P2P source files copied" -ForegroundColor Green

# Copy scripts
Write-Host "      Copying scripts..." -ForegroundColor Yellow
Copy-Item -Path ".\start-dev.ps1" -Destination "$OutputPath\FlowSpace\" -Force
Copy-Item -Path ".\start-services.ps1" -Destination "$OutputPath\FlowSpace\" -Force -ErrorAction SilentlyContinue
Copy-Item -Path ".\DEPLOY.ps1" -Destination "$OutputPath\FlowSpace\" -Force

# Copy documentation
Write-Host "      Copying documentation..." -ForegroundColor Yellow
Copy-Item -Path ".\DEPLOYMENT_GUIDE.md" -Destination "$OutputPath\FlowSpace\" -Force
Copy-Item -Path ".\IMPLEMENTATION_STATUS.md" -Destination "$OutputPath\FlowSpace\" -Force -ErrorAction SilentlyContinue
Copy-Item -Path ".\README.md" -Destination "$OutputPath\FlowSpace\PROJECT_README.md" -Force -ErrorAction SilentlyContinue

Write-Host "      ✓ Application files copied" -ForegroundColor Green

# Step 4: Copy Kratos configuration
Write-Host "[4/6] Copying Kratos configuration..." -ForegroundColor Cyan
if (Test-Path "C:\Kratos\kratos.yaml") {
    Copy-Item -Path "C:\Kratos\kratos.yaml" -Destination "$OutputPath\Config\" -Force
    Write-Host "      ✓ kratos.yaml copied" -ForegroundColor Green
} else {
    Write-Host "      ⚠️  C:\Kratos\kratos.yaml not found - creating template" -ForegroundColor Yellow
}

if (Test-Path "C:\Kratos\identity.schema.json") {
    Copy-Item -Path "C:\Kratos\identity.schema.json" -Destination "$OutputPath\Config\" -Force
    Write-Host "      ✓ identity.schema.json copied" -ForegroundColor Green
} else {
    Write-Host "      ⚠️  C:\Kratos\identity.schema.json not found - creating template" -ForegroundColor Yellow
}

# Step 5: Create installer script
Write-Host "[5/6] Creating USB installer script..." -ForegroundColor Cyan

$installerScript = @'
#!/usr/bin/env pwsh
# FlowSpace USB Installer
# Run this script from the USB drive to install FlowSpace

param(
    [string]$InstallPath = "C:\FlowSpace",
    [string]$KratosPath = "C:\Kratos"
)

$ErrorActionPreference = "Stop"

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              FlowSpace USB Installer                      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ This installer requires Administrator privileges" -ForegroundColor Red
    Write-Host "   Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[Step 1/6] Checking prerequisites..." -ForegroundColor Cyan
$missing = @()

# Check Node.js
try {
    $nodeVersion = node --version 2>$null
    Write-Host "      ✓ Node.js $nodeVersion" -ForegroundColor Green
} catch {
    $missing += "Node.js"
    Write-Host "      ✗ Node.js not found" -ForegroundColor Red
}

# Check Flutter/Dart
try {
    $flutterVersion = flutter --version 2>$null | Select-Object -First 1
    Write-Host "      ✓ Flutter installed" -ForegroundColor Green
} catch {
    $missing += "Flutter"
    Write-Host "      ✗ Flutter not found" -ForegroundColor Red
}

# Check PostgreSQL
try {
    $pgVersion = psql --version 2>$null
    Write-Host "      ✓ PostgreSQL installed" -ForegroundColor Green
} catch {
    $missing += "PostgreSQL"
    Write-Host "      ✗ PostgreSQL not found" -ForegroundColor Red
}

# Check Redis
if (Test-Path "C:\Redis\redis-server.exe") {
    Write-Host "      ✓ Redis installed" -ForegroundColor Green
} else {
    $missing += "Redis"
    Write-Host "      ✗ Redis not found at C:\Redis\redis-server.exe" -ForegroundColor Red
}

# Check Kratos
if (Test-Path "C:\Kratos\kratos.exe") {
    Write-Host "      ✓ Kratos installed" -ForegroundColor Green
} else {
    $missing += "Kratos"
    Write-Host "      ✗ Kratos not found at C:\Kratos\kratos.exe" -ForegroundColor Red
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ Missing required dependencies:" -ForegroundColor Red
    foreach ($dep in $missing) {
        Write-Host "   - $dep" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Auto-install Flutter if missing
    if ($missing -contains "Flutter") {
        Write-Host "📦 Flutter is required for P2P testing" -ForegroundColor Cyan
        $installFlutter = Read-Host "Install Flutter now? (y/n)"
        if ($installFlutter -eq 'y') {
            Write-Host "      Installing Flutter SDK..." -ForegroundColor Yellow
            Write-Host "      This may take 5-10 minutes..." -ForegroundColor Yellow
            
            # Download Flutter SDK
            $flutterZip = "$env:TEMP\flutter_windows.zip"
            $flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip"
            
            try {
                Write-Host "      Downloading Flutter SDK..." -ForegroundColor Yellow
                Invoke-WebRequest -Uri $flutterUrl -OutFile $flutterZip -UseBasicParsing
                
                Write-Host "      Extracting Flutter SDK to C:\Flutter..." -ForegroundColor Yellow
                Expand-Archive -Path $flutterZip -DestinationPath "C:\" -Force
                
                # Add to PATH
                Write-Host "      Adding Flutter to system PATH..." -ForegroundColor Yellow
                $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
                if ($currentPath -notlike "*C:\Flutter\flutter\bin*") {
                    [Environment]::SetEnvironmentVariable("Path", "$currentPath;C:\Flutter\flutter\bin", "Machine")
                    $env:Path += ";C:\Flutter\flutter\bin"
                }
                
                # Run flutter doctor
                Write-Host "      Running flutter doctor..." -ForegroundColor Yellow
                flutter doctor
                
                Write-Host "      ✓ Flutter installed successfully" -ForegroundColor Green
                Write-Host "      You may need to restart PowerShell for PATH changes" -ForegroundColor Yellow
                
                # Remove Flutter from missing list
                $missing = $missing | Where-Object { $_ -ne "Flutter" }
            } catch {
                Write-Host "      ⚠️  Flutter installation failed: $_" -ForegroundColor Red
                Write-Host "      Please install manually from: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
            } finally {
                if (Test-Path $flutterZip) {
                    Remove-Item $flutterZip -Force
                }
            }
        }
    }
    
    # Show remaining missing dependencies
    if ($missing.Count -gt 0) {
        Write-Host ""
        Write-Host "Please install remaining dependencies:" -ForegroundColor Yellow
        if ($missing -contains "Node.js") { Write-Host "  • Node.js: https://nodejs.org/" -ForegroundColor White }
        if ($missing -contains "PostgreSQL") { Write-Host "  • PostgreSQL: https://www.postgresql.org/download/" -ForegroundColor White }
        if ($missing -contains "Redis") { Write-Host "  • Redis: https://github.com/microsoftarchive/redis/releases" -ForegroundColor White }
        if ($missing -contains "Kratos") { Write-Host "  • Kratos: https://github.com/ory/kratos/releases" -ForegroundColor White }
        if ($missing -contains "Flutter") { Write-Host "  • Flutter: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor White }
        Write-Host ""
        $continue = Read-Host "Continue anyway? (y/n)"
        if ($continue -ne 'y') {
            exit 1
        }
    }
}

# Install FlowSpace
Write-Host ""
Write-Host "[Step 2/6] Installing FlowSpace to $InstallPath..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
Copy-Item -Path ".\FlowSpace\*" -Destination $InstallPath -Recurse -Force
Write-Host "      ✓ FlowSpace installed" -ForegroundColor Green

# Install Kratos configs
Write-Host ""
Write-Host "[Step 3/6] Installing Kratos configuration to $KratosPath..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $KratosPath -Force | Out-Null
if (Test-Path ".\Config\kratos.yaml") {
    Copy-Item -Path ".\Config\kratos.yaml" -Destination $KratosPath -Force
    Write-Host "      ✓ kratos.yaml installed" -ForegroundColor Green
}
if (Test-Path ".\Config\identity.schema.json") {
    Copy-Item -Path ".\Config\identity.schema.json" -Destination $KratosPath -Force
    Write-Host "      ✓ identity.schema.json installed" -ForegroundColor Green
}

# Setup backend dependencies
Write-Host ""
Write-Host "[Step 4/6] Installing backend dependencies..." -ForegroundColor Cyan
$setupBackend = Read-Host "Install Node.js dependencies now? (y/n)"
if ($setupBackend -eq 'y') {
    Push-Location "$InstallPath\backend"
    npm install --production
    Pop-Location
    Write-Host "      ✓ Dependencies installed" -ForegroundColor Green
} else {
    Write-Host "      ⊗ Skipped - run 'npm install' in backend directory later" -ForegroundColor Yellow
}

# Setup P2P (NEW)
Write-Host ""
Write-Host "[Step 5/6] Setting up P2P messaging..." -ForegroundColor Cyan
try {
    Write-Host "      Adding firewall rule for UDP port 33445..." -ForegroundColor Yellow
    New-NetFirewallRule `
        -DisplayName "FLO P2P" `
        -Direction Inbound `
        -Protocol UDP `
        -LocalPort 33445 `
        -Action Allow `
        -Profile Any `
        -Description "Allow FLO peer-to-peer messaging on UDP port 33445" -ErrorAction SilentlyContinue | Out-Null
    Write-Host "      ✓ P2P firewall rule configured" -ForegroundColor Green
} catch {
    Write-Host "      ⚠️  Could not add firewall rule (may need manual configuration)" -ForegroundColor Yellow
}

# Install Flutter dependencies for P2P
if (Test-Path "$InstallPath\client_flutter\pubspec.yaml") {
    try {
        Push-Location "$InstallPath\client_flutter"
        Write-Host "      Installing Flutter P2P dependencies..." -ForegroundColor Yellow
        flutter pub get 2>&1 | Out-Null
        Write-Host "      ✓ P2P dependencies installed" -ForegroundColor Green
        Pop-Location
    } catch {
        Write-Host "      ⚠️  Could not install Flutter dependencies" -ForegroundColor Yellow
        Write-Host "      Run 'flutter pub get' manually in $InstallPath\client_flutter" -ForegroundColor Yellow
        Pop-Location
    }
}

# Setup database
Write-Host ""
Write-Host "[Step 6/7] Setting up database..." -ForegroundColor Cyan
$setupDb = Read-Host "Initialize databases now? (y/n)"
if ($setupDb -eq 'y') {
    try {
        Push-Location "$InstallPath\backend"
        
        # Check if .env exists
        if (-not (Test-Path ".env")) {
            Write-Host "      Creating .env file..." -ForegroundColor Yellow
            $envContent = @"
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/flowspace
MINIO_ENDPOINT=http://localhost:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_BUCKET=flowspace
MINIO_PUBLIC_ENDPOINT=http://localhost:9000
KRATOS_PUBLIC_URL=http://localhost:4433
KRATOS_ADMIN_URL=http://localhost:4456
PORT=4000
NODE_ENV=production
"@
            Set-Content -Path ".env" -Value $envContent
        }
        
        npx prisma migrate deploy
        npx prisma db seed
        Write-Host "      ✓ Database initialized" -ForegroundColor Green
        Pop-Location
    } catch {
        Write-Host "      ⚠️  Database setup failed: $_" -ForegroundColor Yellow
        Write-Host "      You can run this manually later" -ForegroundColor Yellow
        Pop-Location
    }
} else {
    Write-Host "      ⊗ Skipped - run migrations manually later" -ForegroundColor Yellow
}

# Create desktop shortcut
Write-Host ""
Write-Host "Creating desktop shortcut..." -ForegroundColor Cyan
try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\FlowSpace.lnk")
    $Shortcut.TargetPath = "$InstallPath\FlowSpaceApp\client_flutter.exe"
    $Shortcut.WorkingDirectory = "$InstallPath\FlowSpaceApp"
    $Shortcut.Save()
    Write-Host "      ✓ Desktop shortcut created" -ForegroundColor Green
} catch {
    Write-Host "      ⊗ Could not create shortcut" -ForegroundColor Yellow
}

# Test P2P (NEW)
Write-Host ""
Write-Host "[Step 7/7] Testing P2P messaging..." -ForegroundColor Cyan
$testP2P = Read-Host "Run P2P test now? (y/n)"
if ($testP2P -eq 'y') {
    if (Test-Path "$InstallPath\client_flutter\lib\test\p2p_test_main.dart") {
        Write-Host "      Starting P2P test (30 seconds)..." -ForegroundColor Yellow
        Write-Host "      Looking for peers on LAN..." -ForegroundColor Yellow
        Push-Location "$InstallPath\client_flutter"
        Start-Job -ScriptBlock { dart run lib/test/p2p_test_main.dart } | Out-Null
        Start-Sleep -Seconds 30
        Get-Job | Stop-Job
        Get-Job | Remove-Job
        Pop-Location
        Write-Host "      ✓ P2P test complete" -ForegroundColor Green
    }
} else {
    Write-Host "      ⊗ Skipped - run '.\test_p2p.ps1' in client_flutter directory later" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ FlowSpace installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📁 Installation: $InstallPath" -ForegroundColor White
Write-Host "📁 Kratos Config: $KratosPath" -ForegroundColor White
Write-Host ""
Write-Host "🚀 To start FlowSpace:" -ForegroundColor Cyan
Write-Host "   1. Open PowerShell as Administrator" -ForegroundColor White
Write-Host "   2. cd $InstallPath" -ForegroundColor White
Write-Host "   3. .\start-dev.ps1" -ForegroundColor White
Write-Host ""
Write-Host "🔗 To test P2P messaging:" -ForegroundColor Cyan
Write-Host "   1. cd $InstallPath\client_flutter" -ForegroundColor White
Write-Host "   2. .\test_p2p.ps1" -ForegroundColor White
Write-Host ""
Write-Host "📋 Default credentials:" -ForegroundColor Cyan
Write-Host "   Email: ava@vyrevault.studio" -ForegroundColor White
Write-Host "   Password: flowspace123" -ForegroundColor White
Write-Host ""
Write-Host "📖 For detailed instructions, see:" -ForegroundColor Cyan
Write-Host "   $InstallPath\DEPLOYMENT_GUIDE.md" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to exit"
'@

Set-Content -Path "$OutputPath\INSTALL.ps1" -Value $installerScript
Write-Host "      ✓ INSTALL.ps1 created" -ForegroundColor Green

# Step 6: Create README for USB
Write-Host "[6/6] Creating USB installer README..." -ForegroundColor Cyan

$usbReadme = @'
# FlowSpace USB Installer

## Quick Start

1. **Ensure prerequisites are installed:**
   - Node.js (v18+): https://nodejs.org/
   - PostgreSQL (v14+): https://www.postgresql.org/download/
   - Redis: Extract from Dependencies folder to C:\Redis
   - Kratos: Extract from Dependencies folder to C:\Kratos

2. **Run the installer:**
   - Right-click PowerShell
   - Select "Run as Administrator"
   - Navigate to this USB drive
   - Run: `.\INSTALL.ps1`

3. **Follow the installation prompts**

## What Gets Installed

- FlowSpace backend (NestJS API)
- FlowSpace desktop app (Flutter Windows client)
- Configuration files for Kratos
- Startup scripts
- Documentation

## Installation Locations

- **FlowSpace**: `C:\FlowSpace`
- **Kratos Config**: `C:\Kratos`

## After Installation

1. Open PowerShell as Administrator
2. Run: `cd C:\FlowSpace`
3. Run: `.\start-dev.ps1`
4. Launch FlowSpace from desktop shortcut

## Default Login

**Email**: ava@vyrevault.studio
**Password**: flowspace123

## Manual Installation

If automated install fails, see `FlowSpace\DEPLOYMENT_GUIDE.md` for step-by-step manual instructions.

## Directory Structure

```
USB Drive
├── INSTALL.ps1           # Main installer script
├── README.txt            # This file
├── FlowSpace/            # Application files
│   ├── backend/          # Backend API
│   ├── FlowSpaceApp/     # Desktop client
│   ├── start-dev.ps1     # Startup script
│   └── DEPLOYMENT_GUIDE.md
├── Config/               # Kratos configuration
│   ├── kratos.yaml
│   └── identity.schema.json
└── Dependencies/         # (Optional) Dependency installers
    ├── README.txt        # Download links
    └── (Place installers here)
```

## Troubleshooting

### "Script execution is disabled"
Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

### Missing dependencies
Download from Dependencies/README.txt links or install manually

### Database errors
Ensure PostgreSQL is running and accessible with default credentials

### Port conflicts
Check that ports 4000, 4433, 4456, 5432, 6379 are available

## Support

For detailed troubleshooting, see:
- `FlowSpace\DEPLOYMENT_GUIDE.md`
- `FlowSpace\IMPLEMENTATION_STATUS.md`

## System Requirements

- Windows 10/11 (64-bit)
- 4GB RAM minimum (8GB recommended)
- 2GB free disk space
- Network access for initial setup
'@

Set-Content -Path "$OutputPath\README.txt" -Value $usbReadme
Write-Host "      ✓ README.txt created" -ForegroundColor Green

# Create Dependencies README
$depsReadme = @'
# FlowSpace Dependencies

Place dependency installers in this folder for offline installation, or download directly:

## Required Software

### Node.js (Required)
- **Version**: 18.x or later
- **Download**: https://nodejs.org/en/download/
- **Installer**: node-v18.x.x-x64.msi

### PostgreSQL (Required)
- **Version**: 14.x or later
- **Download**: https://www.postgresql.org/download/windows/
- **Installer**: postgresql-14.x-x-windows-x64.exe
- **Setup**: Use default settings, remember the postgres user password

### Redis (Required)
- **Version**: Latest Windows build
- **Download**: https://github.com/microsoftarchive/redis/releases
- **File**: Redis-x64-3.0.504.zip
- **Install**: Extract to C:\Redis

### Ory Kratos (Required)
- **Version**: v1.0.0 or later
- **Download**: https://github.com/ory/kratos/releases
- **File**: kratos_1.x.x_windows_amd64.zip
- **Install**: 
  1. Extract kratos.exe to C:\Kratos
  2. Copy Config\kratos.yaml to C:\Kratos
  3. Copy Config\identity.schema.json to C:\Kratos

## Installation Order

1. Node.js
2. PostgreSQL (create databases: flowspace, flowspace_identity)
3. Redis (extract to C:\Redis)
4. Kratos (extract to C:\Kratos)
5. Run INSTALL.ps1 from USB root

## Verification

After installing dependencies, verify:

```powershell
# Node.js
node --version

# PostgreSQL
psql --version

# Redis
Test-Path C:\Redis\redis-server.exe

# Kratos
Test-Path C:\Kratos\kratos.exe
```

All checks should pass before running INSTALL.ps1
'@

Set-Content -Path "$OutputPath\Dependencies\README.txt" -Value $depsReadme

# Final summary
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ USB installer package created!" -ForegroundColor Green
Write-Host ""
Write-Host "📁 Location: $OutputPath" -ForegroundColor White
Write-Host "📊 Ready to copy to USB drive" -ForegroundColor White
Write-Host ""
Write-Host "📦 Package contents:" -ForegroundColor Cyan
Write-Host "   ✓ INSTALL.ps1 (main installer)" -ForegroundColor Green
Write-Host "   ✓ FlowSpace application files" -ForegroundColor Green
Write-Host "   ✓ Kratos configuration" -ForegroundColor Green
Write-Host "   ✓ Documentation and guides" -ForegroundColor Green
Write-Host ""
Write-Host "📤 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Copy $OutputPath to USB drive" -ForegroundColor White
Write-Host "   2. (Optional) Add dependency installers to Dependencies folder" -ForegroundColor White
Write-Host "   3. On target machine, run INSTALL.ps1 as Administrator" -ForegroundColor White
Write-Host ""
Write-Host "💡 Tip: For offline installation, download dependencies and place in" -ForegroundColor Yellow
Write-Host "   Dependencies folder (see Dependencies\README.txt for links)" -ForegroundColor Yellow
Write-Host ""
