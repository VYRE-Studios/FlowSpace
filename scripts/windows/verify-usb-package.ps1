#!/usr/bin/env pwsh
# FlowSpace USB Installer Package Verification Script
# Verifies the USB installer package is complete and ready for deployment

param(
    [string]$PackagePath = ".\FlowSpace-USB-Installer"
)

$ErrorActionPreference = "Continue"
$failures = @()
$warnings = @()

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      FlowSpace USB Installer Package Verification       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "Package Path: $PackagePath" -ForegroundColor White
Write-Host ""

# Check if package exists
Write-Host "[1/8] Verifying package directory..." -ForegroundColor Cyan
if (Test-Path $PackagePath) {
    Write-Host "      ✓ Package directory exists" -ForegroundColor Green
} else {
    Write-Host "      ✗ Package directory NOT found" -ForegroundColor Red
    $failures += "Package directory missing at $PackagePath"
    Write-Host ""
    Write-Host "Run .\prepare-usb-installer.ps1 to create the package first" -ForegroundColor Yellow
    exit 1
}

# Check root files
Write-Host "[2/8] Checking root files..." -ForegroundColor Cyan
$rootFiles = @(
    "INSTALL.ps1",
    "README.txt"
)

foreach ($file in $rootFiles) {
    $filePath = Join-Path $PackagePath $file
    if (Test-Path $filePath) {
        $size = (Get-Item $filePath).Length / 1KB
        Write-Host "      ✓ $file ($([math]::Round($size, 2)) KB)" -ForegroundColor Green
    } else {
        Write-Host "      ✗ $file MISSING" -ForegroundColor Red
        $failures += "Missing file: $file"
    }
}

# Check Config directory
Write-Host "[3/8] Checking Config directory..." -ForegroundColor Cyan
$configFiles = @(
    "Config\kratos.yaml",
    "Config\identity.schema.json"
)

foreach ($file in $configFiles) {
    $filePath = Join-Path $PackagePath $file
    if (Test-Path $filePath) {
        Write-Host "      ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "      ✗ $file MISSING" -ForegroundColor Red
        $failures += "Missing config: $file"
    }
}

# Check Dependencies directory
Write-Host "[4/8] Checking Dependencies directory..." -ForegroundColor Cyan
if (Test-Path (Join-Path $PackagePath "Dependencies\README.txt")) {
    Write-Host "      ✓ Dependencies\README.txt" -ForegroundColor Green
} else {
    Write-Host "      ✗ Dependencies\README.txt MISSING" -ForegroundColor Red
    $failures += "Missing Dependencies\README.txt"
}

# Check optional dependency installers
$depInstallers = @(
    "Dependencies\node-*.msi",
    "Dependencies\postgresql-*.exe",
    "Dependencies\Redis-*.zip",
    "Dependencies\kratos_*.zip"
)

$depCount = 0
foreach ($pattern in $depInstallers) {
    $files = Get-ChildItem -Path $PackagePath -Filter ($pattern -replace ".*\\", "") -Recurse -ErrorAction SilentlyContinue
    if ($files) {
        $depCount++
    }
}

if ($depCount -gt 0) {
    Write-Host "      ℹ️  $depCount dependency installer(s) included (optional)" -ForegroundColor Cyan
} else {
    Write-Host "      ⚠️  No dependency installers included (users must download)" -ForegroundColor Yellow
    $warnings += "No dependency installers - requires internet on target machine"
}

# Check FlowSpace directory
Write-Host "[5/8] Checking FlowSpace application..." -ForegroundColor Cyan

# Backend
if (Test-Path (Join-Path $PackagePath "FlowSpace\backend\package.json")) {
    Write-Host "      ✓ Backend package.json" -ForegroundColor Green
} else {
    Write-Host "      ✗ Backend package.json MISSING" -ForegroundColor Red
    $failures += "Missing backend\package.json"
}

if (Test-Path (Join-Path $PackagePath "FlowSpace\backend\src")) {
    Write-Host "      ✓ Backend source code" -ForegroundColor Green
} else {
    Write-Host "      ✗ Backend source code MISSING" -ForegroundColor Red
    $failures += "Missing backend\src"
}

if (Test-Path (Join-Path $PackagePath "FlowSpace\backend\node_modules")) {
    $moduleCount = (Get-ChildItem (Join-Path $PackagePath "FlowSpace\backend\node_modules") -Directory).Count
    Write-Host "      ✓ Backend node_modules ($moduleCount packages)" -ForegroundColor Green
} else {
    Write-Host "      ⚠️  Backend node_modules MISSING" -ForegroundColor Yellow
    $warnings += "node_modules not included - npm install required on target"
}

if (Test-Path (Join-Path $PackagePath "FlowSpace\backend\prisma")) {
    Write-Host "      ✓ Backend Prisma schemas" -ForegroundColor Green
} else {
    Write-Host "      ✗ Backend Prisma schemas MISSING" -ForegroundColor Red
    $failures += "Missing backend\prisma"
}

# Flutter App
if (Test-Path (Join-Path $PackagePath "FlowSpace\FlowSpaceApp\client_flutter.exe")) {
    $appSize = (Get-Item (Join-Path $PackagePath "FlowSpace\FlowSpaceApp\client_flutter.exe")).Length / 1MB
    Write-Host "      ✓ Flutter app executable ($([math]::Round($appSize, 2)) MB)" -ForegroundColor Green
} else {
    Write-Host "      ✗ Flutter app executable MISSING" -ForegroundColor Red
    $failures += "Missing FlowSpaceApp\client_flutter.exe - run 'flutter build windows --release'"
}

# Scripts
Write-Host "[6/8] Checking scripts..." -ForegroundColor Cyan
$scripts = @(
    "FlowSpace\start-dev.ps1",
    "FlowSpace\DEPLOY.ps1"
)

foreach ($script in $scripts) {
    $scriptPath = Join-Path $PackagePath $script
    if (Test-Path $scriptPath) {
        Write-Host "      ✓ $script" -ForegroundColor Green
    } else {
        Write-Host "      ⚠️  $script MISSING" -ForegroundColor Yellow
        $warnings += "Missing script: $script"
    }
}

# Documentation
Write-Host "[7/8] Checking documentation..." -ForegroundColor Cyan
$docs = @(
    "FlowSpace\DEPLOYMENT_GUIDE.md"
)

foreach ($doc in $docs) {
    $docPath = Join-Path $PackagePath $doc
    if (Test-Path $docPath) {
        Write-Host "      ✓ $doc" -ForegroundColor Green
    } else {
        Write-Host "      ⚠️  $doc MISSING" -ForegroundColor Yellow
        $warnings += "Missing documentation: $doc"
    }
}

# Calculate total size
Write-Host "[8/8] Calculating package size..." -ForegroundColor Cyan
try {
    $stats = Get-ChildItem -Path $PackagePath -Recurse -File | Measure-Object -Property Length -Sum
    $totalFiles = $stats.Count
    $totalSizeMB = [math]::Round($stats.Sum / 1MB, 2)
    $totalSizeGB = [math]::Round($stats.Sum / 1GB, 2)
    
    Write-Host "      ✓ Total files: $totalFiles" -ForegroundColor Green
    Write-Host "      ✓ Total size: $totalSizeMB MB ($totalSizeGB GB)" -ForegroundColor Green
    
    if ($totalSizeMB -gt 2000) {
        Write-Host "      ⚠️  Package is large (> 2 GB) - may not fit on FAT32 USB" -ForegroundColor Yellow
        $warnings += "Package size > 2 GB - format USB as NTFS or exFAT"
    }
} catch {
    Write-Host "      ⚠️  Could not calculate size: $_" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

if ($failures.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "✅ ALL CHECKS PASSED!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your USB installer package is complete and ready for deployment." -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Copy package to USB drive" -ForegroundColor White
    Write-Host "  2. Test on clean machine (recommended)" -ForegroundColor White
    Write-Host "  3. Deploy to target machines" -ForegroundColor White
    Write-Host ""
    exit 0
} elseif ($failures.Count -eq 0) {
    Write-Host "✅ VERIFICATION PASSED (with warnings)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "⚠️  Warnings ($($warnings.Count)):" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "   • $warning" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Package is functional but has some optional issues." -ForegroundColor White
    Write-Host "You can proceed with deployment." -ForegroundColor White
    Write-Host ""
    exit 0
} else {
    Write-Host "❌ VERIFICATION FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Critical Issues ($($failures.Count)):" -ForegroundColor Red
    foreach ($failure in $failures) {
        Write-Host "   • $failure" -ForegroundColor Red
    }
    
    if ($warnings.Count -gt 0) {
        Write-Host ""
        Write-Host "Warnings ($($warnings.Count)):" -ForegroundColor Yellow
        foreach ($warning in $warnings) {
            Write-Host "   • $warning" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "Please fix the critical issues before deployment:" -ForegroundColor Yellow
    Write-Host "  1. Run .\prepare-usb-installer.ps1 to rebuild package" -ForegroundColor White
    Write-Host "  2. Ensure Flutter app is built: cd client_flutter && flutter build windows" -ForegroundColor White
    Write-Host "  3. Verify Kratos configs exist at C:\Kratos\" -ForegroundColor White
    Write-Host ""
    exit 1
}
