# FLO Backend - Standalone Executable Builder
# Compiles Node.js backend into single .exe file

param(
    [string]$OutputDir = "..\client_flutter\assets\backend"
)

$ErrorActionPreference = "Stop"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "FLO Backend Builder" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check for pkg
Write-Host "Checking for pkg..." -ForegroundColor Yellow
$pkgInstalled = npm list -g pkg --depth=0 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Installing pkg globally..." -ForegroundColor Yellow
    npm install -g pkg
}
Write-Host "✅ pkg is available" -ForegroundColor Green

# Install dependencies
Write-Host ""
Write-Host "Installing backend dependencies..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ npm install failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dependencies installed" -ForegroundColor Green

# Build TypeScript
Write-Host ""
Write-Host "Building TypeScript..." -ForegroundColor Yellow
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ TypeScript build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ TypeScript compiled" -ForegroundColor Green

# Create pkg config if it doesn't exist
Write-Host ""
Write-Host "Configuring pkg..." -ForegroundColor Yellow

$pkgConfig = @"
{
  "name": "flo-sync",
  "version": "1.0.0",
  "bin": "dist/main.js",
  "pkg": {
    "scripts": "dist/**/*.js",
    "assets": [
      "node_modules/.prisma/**/*",
      "node_modules/@prisma/client/**/*"
    ],
    "targets": ["node20-win-x64"],
    "outputPath": "build"
  }
}
"@

# Backup original package.json
Copy-Item package.json package.json.backup -Force

# Merge pkg config into package.json
$originalPkg = Get-Content package.json -Raw | ConvertFrom-Json
$pkgSettings = $pkgConfig | ConvertFrom-Json

# Add pkg settings
if (-not $originalPkg.pkg) {
    $originalPkg | Add-Member -NotePropertyName "pkg" -NotePropertyValue $pkgSettings.pkg -Force
}
$originalPkg | ConvertTo-Json -Depth 10 | Set-Content package.json

Write-Host "✅ pkg configured" -ForegroundColor Green

# Build standalone executable
Write-Host ""
Write-Host "Building standalone executable..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Gray

pkg . --targets node20-win-x64 --output build/flo-sync.exe --compress GZip

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ pkg build failed!" -ForegroundColor Red
    # Restore original package.json
    Move-Item package.json.backup package.json -Force
    exit 1
}

# Restore original package.json
Move-Item package.json.backup package.json -Force

Write-Host "✅ Executable built" -ForegroundColor Green

# Get file size
$exeSize = (Get-Item build/flo-sync.exe).Length / 1MB

# Create output directory
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# Copy executable
Copy-Item build/flo-sync.exe $OutputDir/flo-sync.exe -Force
Write-Host "✅ Copied to: $OutputDir/flo-sync.exe" -ForegroundColor Green

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "✅ BUILD COMPLETE!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Executable:" -ForegroundColor White
Write-Host "  Location: $OutputDir\flo-sync.exe" -ForegroundColor Cyan
Write-Host "  Size:     $([math]::Round($exeSize, 2)) MB" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Test: .\build\flo-sync.exe" -ForegroundColor Gray
Write-Host "  2. Backend will run on http://localhost:4000" -ForegroundColor Gray
Write-Host "  3. Rebuild Flutter installer to include backend" -ForegroundColor Gray
Write-Host ""
