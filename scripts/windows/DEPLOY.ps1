#!/usr/bin/env pwsh
# FlowSpace Deployment Script
# Run this on any Windows workstation to set up FlowSpace

param(
    [string]$InstallPath = "C:\FlowSpace",
    [switch]$SkipDependencies
)

$ErrorActionPreference = "Stop"

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         FlowSpace Deployment & Installation             ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "⚠️  This script requires Administrator privileges" -ForegroundColor Yellow
    Write-Host "   Please run PowerShell as Administrator" -ForegroundColor Yellow
    exit 1
}

# Create installation directory
Write-Host "[1/7] Creating installation directory..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
Write-Host "      ✓ Directory created at $InstallPath" -ForegroundColor Green

# Check dependencies
Write-Host "[2/7] Checking dependencies..." -ForegroundColor Cyan

$missingDeps = @()

# Check Node.js
try {
    $nodeVersion = node --version 2>$null
    Write-Host "      ✓ Node.js $nodeVersion" -ForegroundColor Green
} catch {
    $missingDeps += "Node.js (https://nodejs.org/)"
}

# Check PostgreSQL
try {
    $pgVersion = psql --version 2>$null
    Write-Host "      ✓ PostgreSQL installed" -ForegroundColor Green
} catch {
    $missingDeps += "PostgreSQL (https://www.postgresql.org/download/)"
}

# Check Redis
if (Test-Path "C:\Redis\redis-server.exe") {
    Write-Host "      ✓ Redis installed" -ForegroundColor Green
} else {
    $missingDeps += "Redis (https://github.com/microsoftarchive/redis/releases)"
}

# Check Kratos
if (Test-Path "C:\Kratos\kratos.exe") {
    Write-Host "      ✓ Kratos installed" -ForegroundColor Green
} else {
    $missingDeps += "Ory Kratos (manual download required)"
}

if ($missingDeps.Count -gt 0 -and -not $SkipDependencies) {
    Write-Host ""
    Write-Host "❌ Missing dependencies:" -ForegroundColor Red
    foreach ($dep in $missingDeps) {
        Write-Host "   - $dep" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Please install the missing dependencies and run again." -ForegroundColor Yellow
    Write-Host "Or use -SkipDependencies to continue anyway." -ForegroundColor Yellow
    exit 1
}

# Copy backend files
Write-Host "[3/7] Deploying backend..." -ForegroundColor Cyan
if (Test-Path ".\backend") {
    Copy-Item -Path ".\backend" -Destination "$InstallPath\backend" -Recurse -Force
    Write-Host "      ✓ Backend files copied" -ForegroundColor Green
} else {
    Write-Host "      ⚠️  Backend directory not found" -ForegroundColor Yellow
}

# Copy Flutter app
Write-Host "[4/7] Deploying Flutter client..." -ForegroundColor Cyan
if (Test-Path ".\client_flutter\build\windows\x64\runner\Release") {
    Copy-Item -Path ".\client_flutter\build\windows\x64\runner\Release" -Destination "$InstallPath\FlowSpaceApp" -Recurse -Force
    Write-Host "      ✓ Flutter app deployed" -ForegroundColor Green
} else {
    Write-Host "      ⚠️  Flutter release build not found. Run 'flutter build windows' first." -ForegroundColor Yellow
}

# Copy configuration files
Write-Host "[5/7] Setting up configuration..." -ForegroundColor Cyan
Copy-Item -Path ".\start-dev.ps1" -Destination "$InstallPath\start-dev.ps1" -Force
Copy-Item -Path ".\IMPLEMENTATION_STATUS.md" -Destination "$InstallPath\README.md" -Force -ErrorAction SilentlyContinue
Write-Host "      ✓ Configuration files copied" -ForegroundColor Green

# Setup database
Write-Host "[6/7] Setting up database..." -ForegroundColor Cyan
$setupDb = Read-Host "Do you want to set up the database now? (y/n)"
if ($setupDb -eq 'y') {
    try {
        cd "$InstallPath\backend"
        npm install --production 2>&1 | Out-Null
        npx prisma migrate deploy 2>&1 | Out-Null
        npx prisma db seed 2>&1 | Out-Null
        Write-Host "      ✓ Database initialized" -ForegroundColor Green
    } catch {
        Write-Host "      ⚠️  Database setup failed: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "      ⊗ Skipped database setup" -ForegroundColor Yellow
}

# Create desktop shortcut
Write-Host "[7/7] Creating shortcuts..." -ForegroundColor Cyan
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\FlowSpace.lnk")
$Shortcut.TargetPath = "$InstallPath\FlowSpaceApp\client_flutter.exe"
$Shortcut.WorkingDirectory = "$InstallPath\FlowSpaceApp"
$Shortcut.Save()
Write-Host "      ✓ Desktop shortcut created" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ FlowSpace deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📁 Installation directory: $InstallPath" -ForegroundColor White
Write-Host ""
Write-Host "🚀 To start FlowSpace:" -ForegroundColor Cyan
Write-Host "   1. Open PowerShell as Administrator" -ForegroundColor White
Write-Host "   2. Run: cd $InstallPath" -ForegroundColor White
Write-Host "   3. Run: .\start-dev.ps1" -ForegroundColor White
Write-Host ""
Write-Host "🖥️  Or double-click the FlowSpace icon on your Desktop" -ForegroundColor Cyan
Write-Host "   (Services must be running first)" -ForegroundColor Yellow
Write-Host ""
Write-Host "📋 Default credentials:" -ForegroundColor Cyan
Write-Host "   Email: ava@vyrevault.studio" -ForegroundColor White
Write-Host "   Password: flowspace123" -ForegroundColor White
Write-Host ""
