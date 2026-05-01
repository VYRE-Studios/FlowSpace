#!/usr/bin/env pwsh
# FlowSpace USB Installer Bundler
# This script packages everything needed for offline installation

param(
    [string]$OutputPath = "C:\FlowSpace\FlowSpace-USB-Installer"
)

$ErrorActionPreference = "Stop"

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         FlowSpace USB Installer Bundler                   ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Clean and create output directory
Write-Host "[1/8] Preparing output directory..." -ForegroundColor Cyan
if (Test-Path $OutputPath) {
    Write-Host "      Cleaning existing installer directory..." -ForegroundColor Yellow
    Remove-Item "$OutputPath\FlowSpace" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$OutputPath\Binaries" -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
New-Item -ItemType Directory -Path "$OutputPath\FlowSpace" -Force | Out-Null
New-Item -ItemType Directory -Path "$OutputPath\Binaries" -Force | Out-Null
Write-Host "      ✓ Output directory ready" -ForegroundColor Green

# Copy backend
Write-Host ""
Write-Host "[2/8] Copying backend..." -ForegroundColor Cyan
# Copy backend excluding large directories
robocopy "C:\FlowSpace\backend" "$OutputPath\FlowSpace\backend" /E /XD node_modules dist /XF .env /NFL /NDL /NJH /NJS /NC /NS /NP | Out-Null
if (Test-Path "$OutputPath\FlowSpace\backend\package.json") {
    Write-Host "      ✓ Backend copied (excluding node_modules)" -ForegroundColor Green
} else {
    Write-Host "      ✗ Backend copy failed" -ForegroundColor Red
}

# Build and copy Flutter app
Write-Host ""
Write-Host "[3/8] Building and copying Flutter app..." -ForegroundColor Cyan
$flutterBuildPath = "C:\FlowSpace\client_flutter\build\windows\x64\runner\Release"
if (-not (Test-Path $flutterBuildPath)) {
    Write-Host "      Building Flutter app..." -ForegroundColor Yellow
    Push-Location "C:\FlowSpace\client_flutter"
    flutter build windows --release
    Pop-Location
}
New-Item -ItemType Directory -Path "$OutputPath\FlowSpace\FlowSpaceApp" -Force | Out-Null
Copy-Item -Path "$flutterBuildPath\*" -Destination "$OutputPath\FlowSpace\FlowSpaceApp" -Recurse -Force
Write-Host "      ✓ Flutter app copied" -ForegroundColor Green

# Copy Redis
Write-Host ""
Write-Host "[4/8] Copying Redis..." -ForegroundColor Cyan
if (Test-Path "C:\Redis") {
    Copy-Item -Path "C:\Redis" -Destination "$OutputPath\Binaries\Redis" -Recurse -Force
    Write-Host "      ✓ Redis binaries copied" -ForegroundColor Green
} else {
    Write-Host "      ⚠️  Redis not found at C:\Redis" -ForegroundColor Yellow
    Write-Host "      Please download from: https://github.com/tporadowski/redis/releases" -ForegroundColor Yellow
}

# Copy Kratos
Write-Host ""
Write-Host "[5/8] Copying Kratos..." -ForegroundColor Cyan
if (Test-Path "C:\Kratos\kratos.exe") {
    New-Item -ItemType Directory -Path "$OutputPath\Binaries\Kratos" -Force | Out-Null
    Copy-Item -Path "C:\Kratos\kratos.exe" -Destination "$OutputPath\Binaries\Kratos\" -Force
    Write-Host "      ✓ Kratos binary copied" -ForegroundColor Green
} else {
    Write-Host "      ⚠️  Kratos not found at C:\Kratos\kratos.exe" -ForegroundColor Yellow
    Write-Host "      Please download from: https://github.com/ory/kratos/releases" -ForegroundColor Yellow
}

# Download MinIO if needed
Write-Host ""
Write-Host "[6/8] Getting MinIO..." -ForegroundColor Cyan
$minioPath = "$OutputPath\Binaries\MinIO"
New-Item -ItemType Directory -Path $minioPath -Force | Out-Null
if (Test-Path "C:\MinIO\minio.exe") {
    Copy-Item -Path "C:\MinIO\minio.exe" -Destination $minioPath -Force
    Write-Host "      ✓ MinIO binary copied from C:\MinIO" -ForegroundColor Green
} else {
    Write-Host "      Downloading MinIO..." -ForegroundColor Yellow
    try {
        $minioUrl = "https://dl.min.io/server/minio/release/windows-amd64/minio.exe"
        Invoke-WebRequest -Uri $minioUrl -OutFile "$minioPath\minio.exe" -UseBasicParsing
        Write-Host "      ✓ MinIO downloaded" -ForegroundColor Green
    } catch {
        Write-Host "      ⚠️  Failed to download MinIO: $_" -ForegroundColor Yellow
        Write-Host "      Download manually from: https://min.io/download" -ForegroundColor Yellow
    }
}

# Download LiveKit if needed
Write-Host ""
Write-Host "[7/9] Getting LiveKit..." -ForegroundColor Cyan
$livekitPath = "$OutputPath\Binaries\LiveKit"
New-Item -ItemType Directory -Path $livekitPath -Force | Out-Null
if (Test-Path "C:\LiveKit\livekit-server.exe") {
    Copy-Item -Path "C:\LiveKit\livekit-server.exe" -Destination $livekitPath -Force
    Write-Host "      ✓ LiveKit binary copied from C:\LiveKit" -ForegroundColor Green
} else {
    Write-Host "      ⚠️  LiveKit not found - manual download required" -ForegroundColor Yellow
    Write-Host "      Download from: https://github.com/livekit/livekit/releases" -ForegroundColor Yellow
    Write-Host "      Extract livekit-server.exe to: $livekitPath" -ForegroundColor Yellow
}

# Copy PostgreSQL if available
Write-Host ""
Write-Host "[8/9] Getting PostgreSQL..." -ForegroundColor Cyan
$postgresPath = "$OutputPath\Binaries\PostgreSQL"
New-Item -ItemType Directory -Path $postgresPath -Force | Out-Null
if (Test-Path "C:\FlowSpace\bin\PostgreSQL\bin\postgres.exe") {
    Copy-Item -Path "C:\FlowSpace\bin\PostgreSQL\*" -Destination $postgresPath -Recurse -Force
    Write-Host "      ✓ PostgreSQL binaries copied" -ForegroundColor Green
} elseif (Test-Path "C:\Program Files\PostgreSQL") {
    # Try to find installed PostgreSQL
    $pgVersions = Get-ChildItem "C:\Program Files\PostgreSQL" -Directory -ErrorAction SilentlyContinue
    if ($pgVersions) {
        $latestPg = $pgVersions | Sort-Object Name -Descending | Select-Object -First 1
        Copy-Item -Path "$($latestPg.FullName)\*" -Destination $postgresPath -Recurse -Force
        Write-Host "      ✓ PostgreSQL copied from $($latestPg.Name)" -ForegroundColor Green
    } else {
        Write-Host "      ⚠️  PostgreSQL not found - downloading portable version..." -ForegroundColor Yellow
        try {
            $postgresUrl = "https://get.enterprisedb.com/postgresql/postgresql-16.1-1-windows-x64-binaries.zip"
            $pgZip = "$env:TEMP\postgresql-portable.zip"
            Invoke-WebRequest -Uri $postgresUrl -OutFile $pgZip -UseBasicParsing
            Expand-Archive -Path $pgZip -DestinationPath $postgresPath -Force
            Remove-Item $pgZip -Force
            Write-Host "      ✓ PostgreSQL downloaded and extracted" -ForegroundColor Green
        } catch {
            Write-Host "      ⚠️  Failed to download PostgreSQL: $_" -ForegroundColor Yellow
            Write-Host "      Download manually from: https://www.postgresql.org/download/windows/" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "      ⚠️  PostgreSQL not found - downloading portable version..." -ForegroundColor Yellow
    try {
        $postgresUrl = "https://get.enterprisedb.com/postgresql/postgresql-16.1-1-windows-x64-binaries.zip"
        $pgZip = "$env:TEMP\postgresql-portable.zip"
        Invoke-WebRequest -Uri $postgresUrl -OutFile $pgZip -UseBasicParsing
        Expand-Archive -Path $pgZip -DestinationPath $postgresPath -Force
        Remove-Item $pgZip -Force
        Write-Host "      ✓ PostgreSQL downloaded and extracted" -ForegroundColor Green
    } catch {
        Write-Host "      ⚠️  Failed to download PostgreSQL: $_" -ForegroundColor Yellow
        Write-Host "      Download manually from: https://www.postgresql.org/download/windows/" -ForegroundColor Yellow
    }
}

# Copy NSSM for service installation
Write-Host ""
Write-Host "[9/9] Copying NSSM..." -ForegroundColor Cyan
if (Test-Path "C:\FlowSpace\nssm.exe") {
    Copy-Item -Path "C:\FlowSpace\nssm.exe" -Destination "$OutputPath\Binaries\" -Force
    Write-Host "      ✓ NSSM copied" -ForegroundColor Green
} else {
    Write-Host "      ⚠️  NSSM not found at C:\FlowSpace\nssm.exe" -ForegroundColor Yellow
    Write-Host "      Download from: https://nssm.cc/download" -ForegroundColor Yellow
}

# Copy configs
Write-Host ""
Write-Host "[10/10] Copying configurations..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path "$OutputPath\Config" -Force | Out-Null

# Copy Kratos configs if they exist
if (Test-Path "C:\FlowSpace\infrastructure\kratos") {
    Copy-Item -Path "C:\FlowSpace\infrastructure\kratos\*" -Destination "$OutputPath\Config\" -Force
    Write-Host "      ✓ Kratos config copied" -ForegroundColor Green
}

# Copy LiveKit config if it exists
if (Test-Path "C:\FlowSpace\infrastructure\livekit") {
    Copy-Item -Path "C:\FlowSpace\infrastructure\livekit\*" -Destination "$OutputPath\Config\" -Force
    Write-Host "      ✓ LiveKit config copied" -ForegroundColor Green
}

# Copy startup scripts and setup files
$scriptsPath = "$OutputPath\FlowSpace"
@(
    "dev-server.ps1",
    "start-services.ps1",
    "verify.ps1",
    "FlowSpace-Services.ps1",
    "FlowSpace-Setup.ps1"
) | ForEach-Object {
    if (Test-Path "C:\FlowSpace\$_") {
        Copy-Item -Path "C:\FlowSpace\$_" -Destination $scriptsPath -Force
        Write-Host "      Copied $_" -ForegroundColor Gray
    } else {
        Write-Host "      Missing: $_" -ForegroundColor Yellow
    }
}

# Copy new service management scripts from installer directory
if (Test-Path "$OutputPath\FlowSpace\FlowSpace-Services.ps1") {
    # Already copied, good
} else {
    Write-Host "      ⚠️  FlowSpace-Services.ps1 not found" -ForegroundColor Yellow
}

if (Test-Path "$OutputPath\FlowSpace\FlowSpace-Setup.ps1") {
    # Already copied, good
} else {
    Write-Host "      ⚠️  FlowSpace-Setup.ps1 not found" -ForegroundColor Yellow
}

Write-Host "      ✓ Startup scripts copied" -ForegroundColor Green

# Create README for dependencies
$depsReadme = @"
# FlowSpace Binary Dependencies

This folder contains all required server binaries for FlowSpace.

## Included Binaries

- **PostgreSQL**: Database server (port 5432) - REQUIRED
- **Redis**: In-memory data store (port 6379)
- **MinIO**: S3-compatible object storage (port 9000)
- **Kratos**: Identity and authentication server (port 4433)
- **LiveKit**: Real-time video/audio server (port 7880)
- **NSSM**: Non-Sucking Service Manager for Windows services

## Installation

The INSTALL.ps1 script will automatically extract these binaries to:
- C:\Program Files\FlowSpace\PostgreSQL (or C:\FlowSpace\bin\PostgreSQL)
- C:\FlowSpace\bin\Redis
- C:\FlowSpace\bin\MinIO
- C:\FlowSpace\bin\Kratos
- C:\FlowSpace\bin\LiveKit

## Manual Download

If any binary is missing, download from:
- PostgreSQL: https://www.postgresql.org/download/windows/ (or https://get.enterprisedb.com/postgresql/)
- Redis: https://github.com/tporadowski/redis/releases
- MinIO: https://dl.min.io/server/minio/release/windows-amd64/minio.exe
- Kratos: https://github.com/ory/kratos/releases
- LiveKit: https://github.com/livekit/livekit/releases
- NSSM: https://nssm.cc/download

Place downloaded binaries in this Binaries folder before running INSTALL.ps1
"@

Set-Content -Path "$OutputPath\Binaries\README.txt" -Value $depsReadme

# Summary
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Bundling complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📁 Installer location: $OutputPath" -ForegroundColor White
Write-Host ""
Write-Host "📦 Package contents:" -ForegroundColor Cyan
Write-Host "   ✓ FlowSpace backend" -ForegroundColor White
Write-Host "   ✓ FlowSpace desktop app (client_flutter.exe)" -ForegroundColor White
if (Test-Path "$OutputPath\Binaries\PostgreSQL\bin\postgres.exe") { Write-Host "   ✓ PostgreSQL binary" -ForegroundColor White } else { Write-Host "   ⚠️  PostgreSQL binary (REQUIRED - download needed)" -ForegroundColor Yellow }
if (Test-Path "$OutputPath\Binaries\Redis") { Write-Host "   ✓ Redis binary" -ForegroundColor White }
if (Test-Path "$OutputPath\Binaries\Kratos\kratos.exe") { Write-Host "   ✓ Kratos binary" -ForegroundColor White }
if (Test-Path "$OutputPath\Binaries\MinIO\minio.exe") { Write-Host "   ✓ MinIO binary" -ForegroundColor White }
if (Test-Path "$OutputPath\Binaries\LiveKit\livekit-server.exe") { Write-Host "   ✓ LiveKit binary" -ForegroundColor White } else { Write-Host "   ⚠️  LiveKit binary (manual download needed)" -ForegroundColor Yellow }
if (Test-Path "$OutputPath\Binaries\nssm.exe") { Write-Host "   ✓ NSSM binary" -ForegroundColor White } else { Write-Host "   ⚠️  NSSM binary (required for services)" -ForegroundColor Yellow }
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Copy $OutputPath to USB drive" -ForegroundColor White
Write-Host "   2. Run INSTALL.ps1 from USB on target machine" -ForegroundColor White
Write-Host ""
