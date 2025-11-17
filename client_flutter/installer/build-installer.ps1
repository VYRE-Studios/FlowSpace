# FLŌ Installer Build Script
# Builds Flutter app and creates NSIS installer

param(
    [string]$Version = "",
    [string]$BuildType = "Release",
    [switch]$Clean,
    [switch]$SkipFlutterBuild,
    [switch]$SignExecutable,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# If version not provided, read from pubspec.yaml
if ([string]::IsNullOrEmpty($Version)) {
    $pubspecPath = Join-Path $ProjectRoot "pubspec.yaml"
    if (Test-Path $pubspecPath) {
        $pubspecContent = Get-Content $pubspecPath -Raw
        if ($pubspecContent -match 'version:\s*([\d.]+)\+(\d+)') {
            $Version = $matches[1]
            $BuildNumber = $matches[2]
            Write-Host "📦 Version detected from pubspec.yaml: $Version (build $BuildNumber)" -ForegroundColor Cyan
        } else {
            $Version = "1.0.0"
            Write-Host "⚠️  Could not parse version from pubspec.yaml, using default: $Version" -ForegroundColor Yellow
        }
    } else {
        $Version = "1.0.0"
        Write-Host "⚠️  pubspec.yaml not found, using default version: $Version" -ForegroundColor Yellow
    }
}

Write-Host "================================" -ForegroundColor Cyan
Write-Host "FLŌ Installer Build Script" -ForegroundColor Cyan
Write-Host "Version: $Version" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check for NSIS installation
$NsisPath = "C:\Program Files (x86)\NSIS\makensis.exe"
if (-not (Test-Path $NsisPath)) {
    Write-Host "❌ ERROR: NSIS not found at: $NsisPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install NSIS from: https://nsis.sourceforge.io/Download" -ForegroundColor Yellow
    Write-Host "Or install via Chocolatey: choco install nsis" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ NSIS found: $NsisPath" -ForegroundColor Green

# Step 1: Clean build (optional)
if ($Clean) {
    Write-Host ""
    Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
    Set-Location $ProjectRoot
    
    if (Test-Path "build") {
        Remove-Item -Recurse -Force "build"
        Write-Host "   Removed build directory" -ForegroundColor Gray
    }
    
    flutter clean
    Write-Host "   ✅ Clean complete" -ForegroundColor Green
}

# Step 2: Build Flutter Windows app
if (-not $SkipFlutterBuild) {
    Write-Host ""
    Write-Host "🔨 Building Flutter Windows application..." -ForegroundColor Yellow
    Set-Location $ProjectRoot
    
    # Get dependencies
    Write-Host "   Getting Flutter dependencies..." -ForegroundColor Gray
    flutter pub get
    
    # Build Windows release
    Write-Host "   Building Windows release..." -ForegroundColor Gray
    $buildArgs = @("build", "windows", "--release")
    if ($Verbose) {
        $buildArgs += "--verbose"
    }
    
    & flutter $buildArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Flutter build failed!" -ForegroundColor Red
        exit $LASTEXITCODE
    }
    
    # Verify build output
    $exePath = Join-Path $ProjectRoot "build\windows\x64\runner\Release\client_flutter.exe"
    if (-not (Test-Path $exePath)) {
        Write-Host "❌ Build output not found: $exePath" -ForegroundColor Red
        exit 1
    }
    
    # Get file size
    $exeSize = (Get-Item $exePath).Length / 1MB
    Write-Host "   ✅ Flutter build complete ($([math]::Round($exeSize, 2)) MB)" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "⏭️  Skipping Flutter build (using existing)" -ForegroundColor Yellow
}

# Step 3: Check for LICENSE file
Write-Host ""
Write-Host "📄 Checking for LICENSE file..." -ForegroundColor Yellow
$licensePath = Join-Path $ProjectRoot "LICENSE"
if (-not (Test-Path $licensePath)) {
    Write-Host "   ⚠️  LICENSE file not found, creating default..." -ForegroundColor Yellow
    
    $defaultLicense = @"
MIT License

Copyright (c) 2024 VyreVault Studios

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"@
    
    Set-Content -Path $licensePath -Value $defaultLicense -Encoding UTF8
    Write-Host "   ✅ Default MIT license created" -ForegroundColor Green
} else {
    Write-Host "   ✅ LICENSE file found" -ForegroundColor Green
}

# Step 4: Build backend
Write-Host ""
Write-Host "🔨 Building backend..." -ForegroundColor Yellow
$backendPath = Join-Path $ProjectRoot "..\backend"
if (Test-Path $backendPath) {
    Set-Location $backendPath
    
    # Install dependencies if needed
    if (-not (Test-Path "node_modules")) {
        Write-Host "   Installing backend dependencies..." -ForegroundColor Gray
        npm install
    }
    
    # Build TypeScript
    Write-Host "   Compiling TypeScript..." -ForegroundColor Gray
    npm run build
    
    # Generate Prisma client
    Write-Host "   Generating Prisma client..." -ForegroundColor Gray
    npx prisma generate
    
    Write-Host "   ✅ Backend build complete" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Backend not found at $backendPath" -ForegroundColor Yellow
}

# Step 5: Prepare dependencies for embedding
Write-Host ""
Write-Host "📦 Preparing dependencies..." -ForegroundColor Yellow
$depsDir = Join-Path $ScriptDir "deps"
if (Test-Path $depsDir) {
    Remove-Item $depsDir -Recurse -Force
}
New-Item -ItemType Directory -Path $depsDir -Force | Out-Null

# Copy NSSM
$nssmSource = Join-Path $ProjectRoot "..\nssm.exe"
if (Test-Path $nssmSource) {
    Copy-Item $nssmSource $depsDir
    Write-Host "   ✅ NSSM copied" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  NSSM not found at $nssmSource" -ForegroundColor Yellow
    Write-Host "   Download from: https://nssm.cc/download" -ForegroundColor Yellow
}

# Copy PostgreSQL (if available)
$pgSource = Join-Path $ProjectRoot "..\bin\PostgreSQL"
if (-not (Test-Path $pgSource)) {
    $pgSource = "C:\Program Files\PostgreSQL"
    $pgVersions = Get-ChildItem $pgSource -Directory -ErrorAction SilentlyContinue
    if ($pgVersions) {
        $latestPg = $pgVersions | Sort-Object Name -Descending | Select-Object -First 1
        $pgSource = $latestPg.FullName
    }
}
if (Test-Path "$pgSource\bin\postgres.exe") {
    $pgDest = Join-Path $depsDir "PostgreSQL"
    New-Item -ItemType Directory -Path $pgDest -Force | Out-Null
    Write-Host "   Copying PostgreSQL from $pgSource..." -ForegroundColor Gray
    robocopy $pgSource $pgDest /E /NFL /NDL /NJH /NJS /NC /NS /NP | Out-Null
    Write-Host "   ✅ PostgreSQL copied" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  PostgreSQL not found" -ForegroundColor Yellow
    Write-Host "   PostgreSQL will need to be downloaded separately" -ForegroundColor Yellow
}

# Copy backend files
$backendDest = Join-Path $depsDir "backend"
if (Test-Path $backendPath) {
    New-Item -ItemType Directory -Path $backendDest -Force | Out-Null
    Write-Host "   Copying backend files..." -ForegroundColor Gray
    
    # Copy dist
    if (Test-Path "$backendPath\dist") {
        Copy-Item "$backendPath\dist" $backendDest -Recurse -Force
    }
    
    # Copy node_modules (production only)
    if (Test-Path "$backendPath\node_modules") {
        Write-Host "   Copying node_modules (this may take a while)..." -ForegroundColor Gray
        robocopy "$backendPath\node_modules" "$backendDest\node_modules" /E /NFL /NDL /NJH /NJS /NC /NS /NP | Out-Null
    }
    
    # Copy prisma
    if (Test-Path "$backendPath\prisma") {
        Copy-Item "$backendPath\prisma" $backendDest -Recurse -Force
    }
    
    # Copy package files
    Copy-Item "$backendPath\package.json" $backendDest -ErrorAction SilentlyContinue
    Copy-Item "$backendPath\package-lock.json" $backendDest -ErrorAction SilentlyContinue
    
    Write-Host "   ✅ Backend files copied" -ForegroundColor Green
}

# Copy service wrappers
$wrappersSource = Join-Path $ProjectRoot "..\service-wrappers"
if (Test-Path $wrappersSource) {
    $wrappersDest = Join-Path $depsDir "service-wrappers"
    Copy-Item $wrappersSource $wrappersDest -Recurse -Force
    Write-Host "   ✅ Service wrappers copied" -ForegroundColor Green
}

# Step 6: Update version in NSIS script
Write-Host ""
Write-Host "🔄 Updating version in NSIS script..." -ForegroundColor Yellow
$nsiPath = Join-Path $ScriptDir "flo-installer.nsi"
$nsiContent = Get-Content $nsiPath -Raw

# Update PRODUCT_VERSION definition
# Use a line-by-line approach to avoid regex issues
$lines = Get-Content $nsiPath
$newLines = @()
$viVersion = "$Version.0"
foreach ($line in $lines) {
    if ($line -match '^!define PRODUCT_VERSION ') {
        $newLines += "!define PRODUCT_VERSION `"$Version`""
    } elseif ($line -match '^VIProductVersion ') {
        $newLines += "VIProductVersion `"$viVersion`""
    } elseif ($line -match 'VIAddVersionKey "FileVersion" ') {
        $newLines += "VIAddVersionKey `"FileVersion`" `"$Version`""
    } elseif ($line -match 'VIAddVersionKey "ProductVersion" ') {
        $newLines += "VIAddVersionKey `"ProductVersion`" `"$Version`""
    } elseif ($line -match 'StrCpy \$R6 ') {
        # Update the version variable used in FileWrite
        $newLines += "    StrCpy `$R6 `"$Version`""
    } else {
        $newLines += $line
    }
}
$newLines | Set-Content $nsiPath -Encoding UTF8
Write-Host "   ✅ Version updated to $Version" -ForegroundColor Green

# Step 7: Verify dependencies are ready
Write-Host ""
Write-Host "🔍 Verifying dependencies..." -ForegroundColor Yellow
$missing = @()
if (-not (Test-Path "$depsDir\nssm.exe")) { $missing += "NSSM" }
if (-not (Test-Path "$depsDir\PostgreSQL\bin\postgres.exe")) { $missing += "PostgreSQL" }
if (-not (Test-Path "$depsDir\backend\dist")) { $missing += "Backend (dist)" }
if (-not (Test-Path "$depsDir\service-wrappers\backend-wrapper.bat")) { $missing += "Service wrappers" }

if ($missing.Count -gt 0) {
    Write-Host "   ⚠️  Missing dependencies: $($missing -join ', ')" -ForegroundColor Yellow
    Write-Host "   Installer will be created but may fail during installation" -ForegroundColor Yellow
} else {
    Write-Host "   ✅ All dependencies ready" -ForegroundColor Green
}

# Step 8: Compile NSIS installer
Write-Host ""
Write-Host "📦 Compiling NSIS installer..." -ForegroundColor Yellow
Set-Location $ScriptDir

$nsisArgs = @()
if ($Verbose) {
    $nsisArgs += "/V4"  # Verbose output
} else {
    $nsisArgs += "/V2"  # Normal output
}
$nsisArgs += "flo-installer.nsi"

& $NsisPath $nsisArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ NSIS compilation failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}

# Step 9: Verify installer was created
$installerPath = Join-Path $ScriptDir "FLO-$Version-Setup.exe"
if (-not (Test-Path $installerPath)) {
    Write-Host "❌ Installer not found: $installerPath" -ForegroundColor Red
    exit 1
}

$installerSize = (Get-Item $installerPath).Length / 1MB
Write-Host "   ✅ Installer created: FLO-$Version-Setup.exe ($([math]::Round($installerSize, 2)) MB)" -ForegroundColor Green

# Step 10: Code signing (optional)
if ($SignExecutable) {
    Write-Host ""
    Write-Host "✍️  Code signing installer..." -ForegroundColor Yellow
    Write-Host "   ⚠️  Code signing not configured" -ForegroundColor Yellow
    Write-Host "   To enable signing:" -ForegroundColor Gray
    Write-Host "   1. Obtain a code signing certificate" -ForegroundColor Gray
    Write-Host "   2. Install signtool.exe from Windows SDK" -ForegroundColor Gray
    Write-Host "   3. Add signing command to this script" -ForegroundColor Gray
    
    # Example signing command (uncomment and configure):
    # $signtool = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe"
    # & $signtool sign /f "path\to\certificate.pfx" /p "password" /t http://timestamp.digicert.com $installerPath
}

# Step 11: Summary
Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "✅ BUILD COMPLETE!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installer location:" -ForegroundColor White
Write-Host "  $installerPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installer details:" -ForegroundColor White
Write-Host "  Name:    FLŌ v$Version" -ForegroundColor Gray
Write-Host "  Size:    $([math]::Round($installerSize, 2)) MB" -ForegroundColor Gray
Write-Host "  Type:    NSIS Installer" -ForegroundColor Gray
Write-Host "  Admin:   Required (for service installation)" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Test the installer on a clean Windows machine" -ForegroundColor Gray
Write-Host "  2. Verify all features work after installation" -ForegroundColor Gray
Write-Host "  3. Test the portable version option" -ForegroundColor Gray
Write-Host "  4. Test uninstall process" -ForegroundColor Gray
Write-Host ""
Write-Host "To test installation:" -ForegroundColor White
Write-Host "  .\\FLO-$Version-Setup.exe" -ForegroundColor Cyan
Write-Host ""
Write-Host "To test silent installation:" -ForegroundColor White
Write-Host "  .\\FLO-$Version-Setup.exe /S" -ForegroundColor Cyan
Write-Host ""
