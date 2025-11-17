# FLŌ Portable Package Creator
# Creates USB-ready portable version

param(
    [string]$Version = "1.0.0",
    [string]$OutputPath = ".\FLO-Portable",
    [switch]$ZipPackage
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ReleasePath = Join-Path $ProjectRoot "build\windows\x64\runner\Release"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "FLŌ Portable Package Creator" -ForegroundColor Cyan
Write-Host "Version: $Version" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Verify release build exists
if (-not (Test-Path $ReleasePath)) {
    Write-Host "❌ Release build not found at: $ReleasePath" -ForegroundColor Red
    Write-Host "Please run: flutter build windows --release" -ForegroundColor Yellow
    exit 1
}

$exePath = Join-Path $ReleasePath "client_flutter.exe"
if (-not (Test-Path $exePath)) {
    Write-Host "❌ Application executable not found: $exePath" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Release build found" -ForegroundColor Green

# Create directory structure
Write-Host ""
Write-Host "📁 Creating portable directory structure..." -ForegroundColor Yellow

$portablePath = $OutputPath
if (Test-Path $portablePath) {
    Write-Host "   ⚠️  Removing existing portable directory..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $portablePath
}

$appPath = Join-Path $portablePath "app"
$dataPath = Join-Path $portablePath "data"
$vaultPath = Join-Path $dataPath "vault"
$cachePath = Join-Path $dataPath "cache"

New-Item -ItemType Directory -Force -Path $appPath | Out-Null
New-Item -ItemType Directory -Force -Path $dataPath | Out-Null
New-Item -ItemType Directory -Force -Path $vaultPath | Out-Null
New-Item -ItemType Directory -Force -Path $cachePath | Out-Null

Write-Host "   ✅ Directory structure created" -ForegroundColor Green

# Copy application files
Write-Host ""
Write-Host "📦 Copying application files..." -ForegroundColor Yellow
Copy-Item -Path "$ReleasePath\*" -Destination $appPath -Recurse -Force

$appSize = (Get-ChildItem $appPath -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "   ✅ Application files copied ($([math]::Round($appSize, 2)) MB)" -ForegroundColor Green

# Create portable launcher
Write-Host ""
Write-Host "🚀 Creating portable launcher..." -ForegroundColor Yellow

$launcherContent = @"
@echo off
title FLŌ - Portable Mode
color 0B
cls

echo.
echo ╔═══════════════════════════════════════════╗
echo ║         FLŌ - Portable Edition           ║
echo ║         Teams. Unified.                   ║
echo ╚═══════════════════════════════════════════╝
echo.
echo Starting FLŌ in portable mode...
echo.
echo Data Location: %~dp0data
echo.

REM Set portable mode environment variables
set FLO_PORTABLE=1
set FLO_DATA_DIR=%~dp0data
set LOCALAPPDATA=%~dp0data

REM Change to app directory and launch
cd /d "%~dp0app"
start "" "client_flutter.exe"

echo FLŌ is now running!
echo You can close this window.
timeout /t 3 >nul
exit
"@

$launcherPath = Join-Path $portablePath "FLO-Portable.bat"
Set-Content -Path $launcherPath -Value $launcherContent -Encoding ASCII
Write-Host "   ✅ Launcher created: FLO-Portable.bat" -ForegroundColor Green

# Create README
Write-Host ""
Write-Host "📄 Creating README..." -ForegroundColor Yellow

$readmeContent = @"
╔═══════════════════════════════════════════════════════════════════════╗
║                    FLŌ - Portable Edition                             ║
║                    Version $Version                                      ║
║                    © VyreVault Studios                                ║
╚═══════════════════════════════════════════════════════════════════════╝

WHAT IS FLŌ PORTABLE?
═════════════════════════════════════════════════════════════════════════
FLŌ Portable is a fully self-contained version of FLŌ that runs entirely
from this folder. No installation required!

All your data (teams, workspaces, chat history, vault files) is stored
locally in the 'data' folder, making it perfect for:

  • USB drives
  • Network shares
  • Cloud storage (Dropbox, OneDrive, Google Drive)
  • Encrypted containers (VeraCrypt, BitLocker)


HOW TO RUN
═════════════════════════════════════════════════════════════════════════
1. Double-click 'FLO-Portable.bat'
2. FLŌ will launch using this folder for all data
3. Close the batch window after FLŌ starts (optional)


FOLDER STRUCTURE
═════════════════════════════════════════════════════════════════════════
  FLO-Portable/
  ├── FLO-Portable.bat    ← Launch this!
  ├── README.txt          ← You are here
  ├── app/                ← Application files (don't modify)
  │   └── client_flutter.exe
  └── data/               ← Your data (portable)
      ├── vault/          ← Encrypted file storage
      └── cache/          ← Temporary files


DATA PORTABILITY
═════════════════════════════════════════════════════════════════════════
• Your database: data/com.example/client_flutter/flowspace.db
• Vault files:   data/vault/
• Cache:         data/cache/

To backup your data:
  → Simply copy the entire 'FLO-Portable' folder


MOVING TO A NEW DEVICE
═════════════════════════════════════════════════════════════════════════
1. Close FLŌ if running
2. Copy the entire 'FLO-Portable' folder to new device
3. Run FLO-Portable.bat on the new device
4. All your data will be instantly available!


SECURITY NOTES
═════════════════════════════════════════════════════════════════════════
✅ Zero-knowledge encryption for messages and vault files
✅ Master encryption key stored securely in Windows Credential Manager
✅ All data is local-first (no cloud dependency)

⚠️  IMPORTANT: If you move this to a new device, you'll need to:
   - Re-enter your password (encryption keys are device-specific)
   - The app will re-encrypt your data with a new device key


SYSTEM REQUIREMENTS
═════════════════════════════════════════════════════════════════════════
• Operating System: Windows 10 or later (64-bit)
• Memory: 4 GB RAM minimum (8 GB recommended)
• Storage: 500 MB available space
• Network: Internet connection for video calls (Jitsi)


FEATURES
═════════════════════════════════════════════════════════════════════════
✓ Teams & Workspaces (5 types: Project/Whiteboard/Document/Brainstorm/Design)
✓ Real-time Chat with channels
✓ File Vault with encryption
✓ Video Calling (Jitsi integration)
✓ Project Management (Kanban boards)
✓ Whiteboard collaboration
✓ Document editor
✓ 100% local-first operation


TROUBLESHOOTING
═════════════════════════════════════════════════════════════════════════
Problem: FLŌ won't start
Solution: Make sure you're running FLO-Portable.bat, not client_flutter.exe

Problem: Data not persisting
Solution: Ensure the 'data' folder has write permissions

Problem: "Database is locked" error
Solution: Only run one instance of FLŌ Portable at a time

Problem: Video calls not working
Solution: Check firewall settings and internet connection


SUPPORT
═════════════════════════════════════════════════════════════════════════
Website:  https://flo.app
Email:    support@flo.app
GitHub:   github.com/vyrevault/flo


LICENSE
═════════════════════════════════════════════════════════════════════════
FLŌ is distributed under the MIT License.
See LICENSE file in the app folder for details.


═════════════════════════════════════════════════════════════════════════
                        Enjoy FLŌ Portable!
                        Teams. Unified. Anywhere.
═════════════════════════════════════════════════════════════════════════
"@

$readmePath = Join-Path $portablePath "README.txt"
Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
Write-Host "   ✅ README created" -ForegroundColor Green

# Create .gitignore for data folder
Write-Host ""
Write-Host "🔒 Creating .gitignore..." -ForegroundColor Yellow

$gitignoreContent = @"
# Ignore all data (user-specific)
*

# But keep the directory structure
!.gitignore
"@

$gitignorePath = Join-Path $dataPath ".gitignore"
Set-Content -Path $gitignorePath -Value $gitignoreContent -Encoding UTF8
Write-Host "   ✅ .gitignore created" -ForegroundColor Green

# Calculate total size
$totalSize = (Get-ChildItem $portablePath -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB

# Create ZIP package (optional)
if ($ZipPackage) {
    Write-Host ""
    Write-Host "📦 Creating ZIP package..." -ForegroundColor Yellow
    
    $zipPath = ".\FLO-Portable-$Version.zip"
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    
    Compress-Archive -Path "$portablePath\*" -DestinationPath $zipPath -CompressionLevel Optimal
    
    $zipSize = (Get-Item $zipPath).Length / 1MB
    Write-Host "   ✅ ZIP package created: FLO-Portable-$Version.zip ($([math]::Round($zipSize, 2)) MB)" -ForegroundColor Green
}

# Summary
Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "✅ PORTABLE PACKAGE COMPLETE!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Package location:" -ForegroundColor White
Write-Host "  $portablePath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Package details:" -ForegroundColor White
Write-Host "  Version:     $Version" -ForegroundColor Gray
Write-Host "  Total Size:  $([math]::Round($totalSize, 2)) MB" -ForegroundColor Gray
Write-Host "  Launcher:    FLO-Portable.bat" -ForegroundColor Gray
Write-Host "  Data Folder: data\" -ForegroundColor Gray
Write-Host ""
Write-Host "How to use:" -ForegroundColor White
Write-Host "  1. Copy 'FLO-Portable' folder to USB drive or cloud storage" -ForegroundColor Gray
Write-Host "  2. Double-click 'FLO-Portable.bat' to launch" -ForegroundColor Gray
Write-Host "  3. All data will be stored in the 'data' folder" -ForegroundColor Gray
Write-Host ""
Write-Host "Ready to deploy! 🚀" -ForegroundColor Green
Write-Host ""
