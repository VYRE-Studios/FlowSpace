#!/usr/bin/env pwsh
# FlowSpace Packaging Script
# Creates a deployment-ready ZIP package

$ErrorActionPreference = "Stop"

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           FlowSpace Deployment Packager                  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Build Flutter release if not already built
Write-Host "[1/4] Building Flutter release..." -ForegroundColor Cyan
if (!(Test-Path ".\client_flutter\build\windows\x64\runner\Release\client_flutter.exe")) {
    Write-Host "      Building Flutter app..." -ForegroundColor Yellow
    cd client_flutter
    flutter build windows --release
    cd ..
    Write-Host "      ✓ Flutter app built" -ForegroundColor Green
} else {
    Write-Host "      ✓ Flutter release already exists" -ForegroundColor Green
}

# Create package directory
Write-Host "[2/4] Preparing package directory..." -ForegroundColor Cyan
$packageDir = ".\FlowSpace-Package"
if (Test-Path $packageDir) {
    Remove-Item -Path $packageDir -Recurse -Force
}
New-Item -ItemType Directory -Path $packageDir | Out-Null

# Copy backend
Write-Host "      Copying backend..." -ForegroundColor Yellow
Copy-Item -Path ".\backend" -Destination "$packageDir\backend" -Recurse -Force -Exclude node_modules,dist,.env

# Copy Flutter app
Write-Host "      Copying Flutter app..." -ForegroundColor Yellow
Copy-Item -Path ".\client_flutter\build\windows\x64\runner\Release" -Destination "$packageDir\FlowSpaceApp" -Recurse -Force

# Copy scripts and docs
Write-Host "      Copying configuration files..." -ForegroundColor Yellow
Copy-Item -Path ".\start-dev.ps1" -Destination "$packageDir\" -Force
Copy-Item -Path ".\DEPLOY.ps1" -Destination "$packageDir\" -Force
Copy-Item -Path ".\DEPLOYMENT_GUIDE.md" -Destination "$packageDir\README.md" -Force
Copy-Item -Path ".\IMPLEMENTATION_STATUS.md" -Destination "$packageDir\" -Force -ErrorAction SilentlyContinue

# Copy Kratos configs
Write-Host "      Copying Kratos configuration..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "$packageDir\kratos-config" -Force | Out-Null
Copy-Item -Path "C:\Kratos\kratos.yaml" -Destination "$packageDir\kratos-config\" -Force -ErrorAction SilentlyContinue
Copy-Item -Path "C:\Kratos\identity.schema.json" -Destination "$packageDir\kratos-config\" -Force -ErrorAction SilentlyContinue

Write-Host "      ✓ Files copied" -ForegroundColor Green

# Create installation instructions
Write-Host "[3/4] Creating quick start guide..." -ForegroundColor Cyan
$quickStart = @"
# FlowSpace Quick Start

## Installation Steps

1. Install prerequisites:
   - Node.js: https://nodejs.org/
   - PostgreSQL: https://www.postgresql.org/download/
   - Redis: https://github.com/microsoftarchive/redis/releases
   - Ory Kratos: https://github.com/ory/kratos/releases

2. Copy this entire folder to C:\FlowSpace

3. Copy kratos-config\* to C:\Kratos\

4. Open PowerShell as Administrator and run:
   ```powershell
   cd C:\FlowSpace
   .\DEPLOY.ps1
   ```

5. Follow the prompts to complete setup

## Default Credentials
Email: ava@vyrevault.studio
Password: flowspace123

For detailed instructions, see README.md
"@
Set-Content -Path "$packageDir\QUICK_START.txt" -Value $quickStart
Write-Host "      ✓ Quick start guide created" -ForegroundColor Green

# Create ZIP
Write-Host "[4/4] Creating ZIP archive..." -ForegroundColor Cyan
$zipName = "FlowSpace-Deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"
Compress-Archive -Path "$packageDir\*" -DestinationPath ".\$zipName" -Force
Write-Host "      ✓ ZIP created: $zipName" -ForegroundColor Green

# Cleanup
Remove-Item -Path $packageDir -Recurse -Force

# Summary
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Deployment package created!" -ForegroundColor Green
Write-Host ""
Write-Host "📦 Package: $zipName" -ForegroundColor White
Write-Host "📊 Size: $((Get-Item $zipName).Length / 1MB | ForEach-Object { [math]::Round($_, 2) }) MB" -ForegroundColor White
Write-Host ""
Write-Host "📤 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Transfer $zipName to target workstation" -ForegroundColor White
Write-Host "   2. Extract to any location" -ForegroundColor White
Write-Host "   3. Follow QUICK_START.txt instructions" -ForegroundColor White
Write-Host ""
