#!/usr/bin/env pwsh
# FlowSpace - PostgreSQL Auto-Install Script
# Downloads and installs PostgreSQL automatically

param(
    [string]$InstallPath = "C:\FlowSpace\bin\PostgreSQL",
    [string]$DataPath = "C:\FlowSpace\data\postgresql",
    [string]$Port = "5432",
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script requires Administrator privileges" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

if ($Uninstall) {
    Write-Host "Uninstalling PostgreSQL..." -ForegroundColor Yellow
    
    # Stop and remove service
    $service = Get-Service -Name FlowSpacePostgreSQL -ErrorAction SilentlyContinue
    if ($service) {
        Stop-Service -Name FlowSpacePostgreSQL -Force -ErrorAction SilentlyContinue
        sc.exe delete FlowSpacePostgreSQL | Out-Null
        Write-Host "  PostgreSQL service removed" -ForegroundColor Green
    }
    
    Write-Host "PostgreSQL uninstalled" -ForegroundColor Green
    exit 0
}

Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "        FlowSpace - PostgreSQL Auto-Install                 " -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

# Check if already installed
if (Test-Path "$InstallPath\bin\psql.exe") {
    Write-Host "[CHECK] PostgreSQL already installed at $InstallPath" -ForegroundColor Green
    
    # Check if service exists
    $service = Get-Service -Name FlowSpacePostgreSQL -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "[CHECK] PostgreSQL service already installed" -ForegroundColor Green
        if ($service.Status -ne "Running") {
            Write-Host "[START] Starting PostgreSQL service..." -ForegroundColor Yellow
            Start-Service -Name FlowSpacePostgreSQL
            Start-Sleep -Seconds 3
        }
        
        # Verify it's running
        $pgRunning = Test-NetConnection -ComputerName localhost -Port $Port -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction SilentlyContinue
        if ($pgRunning) {
            Write-Host "[OK] PostgreSQL is running on port $Port" -ForegroundColor Green
            exit 0
        }
    }
} else {
    Write-Host "[INSTALL] PostgreSQL not found, installing..." -ForegroundColor Yellow
}

# Create directories
Write-Host "[SETUP] Creating directories..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
New-Item -ItemType Directory -Path $DataPath -Force | Out-Null
New-Item -ItemType Directory -Path "C:\FlowSpace\logs" -Force | Out-Null

# Option 1: Use portable PostgreSQL (ZIP)
# Download PostgreSQL portable from EnterpriseDB
Write-Host "[DOWNLOAD] Downloading PostgreSQL..." -ForegroundColor Cyan
Write-Host "  This may take a few minutes..." -ForegroundColor Gray

$postgresVersion = "16.1"
$postgresUrl = "https://get.enterprisedb.com/postgresql/postgresql-${postgresVersion}-1-windows-x64-binaries.zip"
$zipPath = "$env:TEMP\postgresql-portable.zip"

try {
    # Try to download PostgreSQL portable
    Write-Host "  Downloading from: $postgresUrl" -ForegroundColor Gray
    Invoke-WebRequest -Uri $postgresUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
    Write-Host "  Download complete" -ForegroundColor Green
} catch {
    Write-Host "  [WARNING] Direct download failed, trying alternative method..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Please download PostgreSQL manually:" -ForegroundColor Yellow
    Write-Host "  1. Go to: https://www.postgresql.org/download/windows/" -ForegroundColor Cyan
    Write-Host "  2. Download PostgreSQL ${postgresVersion} (or latest)" -ForegroundColor Cyan
    Write-Host "  3. Extract to: $InstallPath" -ForegroundColor Cyan
    Write-Host "  4. Run this script again" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  OR use the official installer and set it up manually" -ForegroundColor Gray
    exit 1
}

# Extract PostgreSQL
Write-Host "[EXTRACT] Extracting PostgreSQL..." -ForegroundColor Cyan
Expand-Archive -Path $zipPath -DestinationPath $InstallPath -Force
Remove-Item $zipPath -Force

# Find the actual PostgreSQL directory (it might be nested)
$pgBinPath = Get-ChildItem -Path $InstallPath -Recurse -Filter "psql.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($pgBinPath) {
    $actualPgPath = $pgBinPath.Directory.Parent.FullName
    if ($actualPgPath -ne $InstallPath) {
        # Move contents up
        Get-ChildItem -Path $actualPgPath | Move-Item -Destination $InstallPath -Force
        Remove-Item $actualPgPath -Force
    }
}

# Initialize database if not already initialized
if (-not (Test-Path "$DataPath\PG_VERSION")) {
    Write-Host "[INIT] Initializing PostgreSQL database..." -ForegroundColor Cyan
    
    $initdbPath = Join-Path $InstallPath "bin\initdb.exe"
    if (-not (Test-Path $initdbPath)) {
        Write-Host "  ERROR: initdb.exe not found at $initdbPath" -ForegroundColor Red
        Write-Host "  PostgreSQL installation may be incomplete" -ForegroundColor Yellow
        exit 1
    }
    
    # Initialize database with UTF8 encoding
    & $initdbPath -D $DataPath -U postgres -A trust -E UTF8 --locale=C
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: Failed to initialize database" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "  Database initialized" -ForegroundColor Green
}

# Create postgresql.conf if it doesn't exist
$confPath = "$DataPath\postgresql.conf"
if (-not (Test-Path $confPath)) {
    Write-Host "[CONFIG] Creating postgresql.conf..." -ForegroundColor Cyan
    @"
# PostgreSQL configuration for FlowSpace
port = $Port
listen_addresses = 'localhost'
max_connections = 100
shared_buffers = 128MB
effective_cache_size = 512MB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 4MB
min_wal_size = 1GB
max_wal_size = 4GB
"@ | Set-Content -Path $confPath
}

# Create pg_hba.conf for local access
$hbaPath = "$DataPath\pg_hba.conf"
if (-not (Test-Path $hbaPath)) {
    Write-Host "[CONFIG] Creating pg_hba.conf..." -ForegroundColor Cyan
    @"
# PostgreSQL client authentication configuration
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
"@ | Set-Content -Path $hbaPath
}

# Install as Windows Service using NSSM
Write-Host "[SERVICE] Installing PostgreSQL as Windows Service..." -ForegroundColor Cyan

$nssm = "C:\FlowSpace\nssm.exe"
if (-not (Test-Path $nssm)) {
    Write-Host "  ERROR: NSSM not found at $nssm" -ForegroundColor Red
    Write-Host "  Please ensure NSSM is available" -ForegroundColor Yellow
    exit 1
}

$pgServiceName = "FlowSpacePostgreSQL"
$pgExe = Join-Path $InstallPath "bin\postgres.exe"

# Remove old service if exists
$oldService = Get-Service -Name $pgServiceName -ErrorAction SilentlyContinue
if ($oldService) {
    Stop-Service -Name $pgServiceName -Force -ErrorAction SilentlyContinue
    & $nssm remove $pgServiceName confirm | Out-Null
    Start-Sleep -Seconds 1
}

# Install service
& $nssm install $pgServiceName $pgExe
& $nssm set $pgServiceName DisplayName "FlowSpace PostgreSQL"
& $nssm set $pgServiceName Description "PostgreSQL database server for FlowSpace"
& $nssm set $pgServiceName AppDirectory $DataPath
& $nssm set $pgServiceName AppParameters "-D `"$DataPath`""
& $nssm set $pgServiceName Start SERVICE_AUTO_START
& $nssm set $pgServiceName AppStdout "C:\FlowSpace\logs\postgresql-stdout.log"
& $nssm set $pgServiceName AppStderr "C:\FlowSpace\logs\postgresql-stderr.log"

Write-Host "  Service installed" -ForegroundColor Green

# Create database if it doesn't exist
Write-Host "[DATABASE] Creating FlowSpace database..." -ForegroundColor Cyan

# Start service
& $nssm start $pgServiceName
Start-Sleep -Seconds 5

# Wait for PostgreSQL to be ready
$maxRetries = 30
$retryCount = 0
$pgReady = $false

while ($retryCount -lt $maxRetries -and -not $pgReady) {
    $pgReady = Test-NetConnection -ComputerName localhost -Port $Port -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction SilentlyContinue
    if (-not $pgReady) {
        Start-Sleep -Seconds 1
        $retryCount++
    }
}

if (-not $pgReady) {
    Write-Host "  WARNING: PostgreSQL service started but not responding on port $Port" -ForegroundColor Yellow
    Write-Host "  Check logs: C:\FlowSpace\logs\postgresql-stderr.log" -ForegroundColor Gray
} else {
    Write-Host "  PostgreSQL is running" -ForegroundColor Green
    
    # Create database
    $psqlPath = Join-Path $InstallPath "bin\psql.exe"
    $env:PGPASSWORD = "postgres"
    
    # Check if database exists
    $dbExists = & $psqlPath -U postgres -h localhost -p $Port -lqt | Select-String "flowspace"
    
    if (-not $dbExists) {
        Write-Host "  Creating 'flowspace' database..." -ForegroundColor Gray
        & $psqlPath -U postgres -h localhost -p $Port -c "CREATE DATABASE flowspace;" 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Database 'flowspace' created" -ForegroundColor Green
        } else {
            Write-Host "  WARNING: Could not create database (may already exist)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Database 'flowspace' already exists" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "PostgreSQL Installation Complete!" -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installation Path: $InstallPath" -ForegroundColor White
Write-Host "Data Path:         $DataPath" -ForegroundColor White
Write-Host "Port:              $Port" -ForegroundColor White
Write-Host "Service Name:      FlowSpacePostgreSQL" -ForegroundColor White
Write-Host ""
Write-Host "The service will start automatically with Windows" -ForegroundColor Green
Write-Host ""
Write-Host "Connection String:" -ForegroundColor Cyan
Write-Host "  postgresql://postgres:postgres@localhost:$Port/flowspace" -ForegroundColor White
Write-Host ""

