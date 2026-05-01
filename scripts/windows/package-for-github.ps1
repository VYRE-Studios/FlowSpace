# FlowSpace - Package for GitHub Release
# This script builds the Flutter app and prepares it for GitHub release

param(
    [string]$Version = "1.0.0",
    [string]$BuildNumber = "1"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FlowSpace - GitHub Release Packaging" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is installed
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
$flutterPath = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterPath) {
    Write-Host "ERROR: Flutter is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Navigate to Flutter project
$flutterDir = Join-Path $PSScriptRoot "client_flutter"
if (-not (Test-Path $flutterDir)) {
    Write-Host "ERROR: Flutter project not found at $flutterDir" -ForegroundColor Red
    exit 1
}

Set-Location $flutterDir

# Clean previous builds
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
flutter clean | Out-Null

# Get dependencies
Write-Host "Getting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to get dependencies" -ForegroundColor Red
    exit 1
}

# Build Windows release
Write-Host "Building Windows release (this may take a few minutes)..." -ForegroundColor Yellow
flutter build windows --release --build-name=$Version --build-number=$BuildNumber
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to build Windows release" -ForegroundColor Red
    exit 1
}

# Create release directory
$releaseDir = Join-Path $PSScriptRoot "releases"
if (-not (Test-Path $releaseDir)) {
    New-Item -ItemType Directory -Path $releaseDir | Out-Null
}

$versionDir = Join-Path $releaseDir "v$Version"
if (Test-Path $versionDir) {
    Remove-Item -Path $versionDir -Recurse -Force
}
New-Item -ItemType Directory -Path $versionDir | Out-Null

# Copy build artifacts
Write-Host "Copying build artifacts..." -ForegroundColor Yellow
$buildDir = Join-Path $flutterDir "build\windows\x64\runner\Release"
$targetDir = Join-Path $versionDir "FlowSpace-Windows-x64"

if (Test-Path $targetDir) {
    Remove-Item -Path $targetDir -Recurse -Force
}
New-Item -ItemType Directory -Path $targetDir | Out-Null

Copy-Item -Path "$buildDir\*" -Destination $targetDir -Recurse -Force

# Create a README for the release
$readmeContent = @"
# FlowSpace v$Version

## Installation

1. Extract this archive to a folder (e.g., `C:\FlowSpace`)
2. Run `FlowSpace.exe` to start the application
3. On first run, the app will guide you through setup

## Requirements

- Windows 10/11 (64-bit)
- PostgreSQL (will be installed automatically if needed)
- Internet connection for initial setup

## Backend Services

The backend services need to be running for full functionality:
- Backend API (Node.js/NestJS)
- PostgreSQL database
- Redis (optional, for caching)

See the main repository README for backend setup instructions.

## Support

For issues and questions, please open an issue on GitHub.
"@

Set-Content -Path (Join-Path $targetDir "README.txt") -Value $readmeContent

# Create ZIP archive
Write-Host "Creating ZIP archive..." -ForegroundColor Yellow
$zipPath = Join-Path $releaseDir "FlowSpace-v$Version-Windows-x64.zip"
if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
}

Compress-Archive -Path $targetDir -DestinationPath $zipPath -Force

# Get file size
$zipSize = (Get-Item $zipPath).Length / 1MB
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Build Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Release package: $zipPath" -ForegroundColor Cyan
Write-Host "Size: $([math]::Round($zipSize, 2)) MB" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review the package in: $versionDir" -ForegroundColor White
Write-Host "2. Test the application" -ForegroundColor White
Write-Host "3. Create a GitHub release and upload: $zipPath" -ForegroundColor White
Write-Host ""

