param([switch]$Uninstall)

$ErrorActionPreference = "Stop"
$nssm = "C:\FlowSpace\nssm.exe"

Write-Host "FlowSpace Service Manager (NSSM)" -ForegroundColor Cyan
Write-Host ""

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script requires Administrator privileges" -ForegroundColor Red
    exit 1
}

if (!(Test-Path $nssm)) {
    Write-Host "ERROR: NSSM not found at $nssm" -ForegroundColor Red
    exit 1
}

if ($Uninstall) {
    Write-Host "Uninstalling FlowSpace services..." -ForegroundColor Yellow
    Write-Host ""
    
    & $nssm stop FlowSpacePostgreSQL 2>&1 | Out-Null
    & $nssm stop FlowSpaceRedis 2>&1 | Out-Null
    & $nssm stop FlowSpaceKratos 2>&1 | Out-Null
    & $nssm stop FlowSpaceBackend 2>&1 | Out-Null
    
    Start-Sleep -Seconds 2
    
    & $nssm remove FlowSpacePostgreSQL confirm 2>&1 | Out-Null
    & $nssm remove FlowSpaceRedis confirm 2>&1 | Out-Null
    & $nssm remove FlowSpaceKratos confirm 2>&1 | Out-Null
    & $nssm remove FlowSpaceBackend confirm 2>&1 | Out-Null
    
    Write-Host "Services removed" -ForegroundColor Green
    exit 0
}

Write-Host "Installing FlowSpace services with NSSM..." -ForegroundColor Cyan
Write-Host ""

# Remove old services if they exist (ignore errors)
$ErrorActionPreference = "SilentlyContinue"
& $nssm stop FlowSpacePostgreSQL
& $nssm stop FlowSpaceRedis
& $nssm stop FlowSpaceKratos
& $nssm stop FlowSpaceBackend
Start-Sleep -Seconds 1
& $nssm remove FlowSpacePostgreSQL confirm
& $nssm remove FlowSpaceRedis confirm
& $nssm remove FlowSpaceKratos confirm
& $nssm remove FlowSpaceBackend confirm
$ErrorActionPreference = "Stop"

Write-Host "[0/4] Installing PostgreSQL service..." -ForegroundColor Cyan
$pgPath = "$PROGRAMFILES\FlowSpace\PostgreSQL"
$pgDataPath = "$PROGRAMFILES\FlowSpace\data\postgresql"
if (Test-Path "$pgPath\bin\postgres.exe") {
    & $nssm install FlowSpacePostgreSQL "$pgPath\bin\postgres.exe" "-D" "$pgDataPath"
    & $nssm set FlowSpacePostgreSQL DisplayName "FlowSpace PostgreSQL"
    & $nssm set FlowSpacePostgreSQL Description "PostgreSQL database server for FlowSpace"
    & $nssm set FlowSpacePostgreSQL AppDirectory "$pgDataPath"
    & $nssm set FlowSpacePostgreSQL Start SERVICE_AUTO_START
    & $nssm set FlowSpacePostgreSQL AppStdout "C:\FlowSpace\logs\postgresql-stdout.log"
    & $nssm set FlowSpacePostgreSQL AppStderr "C:\FlowSpace\logs\postgresql-stderr.log"
    Write-Host "  OK: PostgreSQL service created" -ForegroundColor Green
} else {
    Write-Host "  WARNING: PostgreSQL not found at $pgPath" -ForegroundColor Yellow
    Write-Host "  Run .\install-postgresql.ps1 first" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[1/4] Installing Redis service..." -ForegroundColor Cyan
if (Test-Path "C:\Redis\redis-server.exe") {
    & $nssm install FlowSpaceRedis "C:\Redis\redis-server.exe"
    & $nssm set FlowSpaceRedis DisplayName "FlowSpace Redis"
    & $nssm set FlowSpaceRedis Description "Redis cache for FlowSpace"
    & $nssm set FlowSpaceRedis AppDirectory "C:\Redis"
    & $nssm set FlowSpaceRedis Start SERVICE_AUTO_START
    & $nssm set FlowSpaceRedis AppStdout "C:\FlowSpace\logs\redis-stdout.log"
    & $nssm set FlowSpaceRedis AppStderr "C:\FlowSpace\logs\redis-stderr.log"
    Write-Host "  OK: Redis service created" -ForegroundColor Green
} else {
    Write-Host "  WARNING: Redis not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[2/4] Installing Kratos service..." -ForegroundColor Cyan
if (Test-Path "C:\Kratos\kratos.exe") {
    & $nssm install FlowSpaceKratos "C:\Kratos\kratos.exe" "serve" "-c" "C:\Kratos\kratos.yaml"
    & $nssm set FlowSpaceKratos DisplayName "FlowSpace Kratos"
    & $nssm set FlowSpaceKratos Description "Authentication service for FlowSpace"
    & $nssm set FlowSpaceKratos AppDirectory "C:\Kratos"
    & $nssm set FlowSpaceKratos Start SERVICE_AUTO_START
    & $nssm set FlowSpaceKratos DependOnService FlowSpaceRedis
    & $nssm set FlowSpaceKratos AppStdout "C:\FlowSpace\logs\kratos-stdout.log"
    & $nssm set FlowSpaceKratos AppStderr "C:\FlowSpace\logs\kratos-stderr.log"
    Write-Host "  OK: Kratos service created" -ForegroundColor Green
} else {
    Write-Host "  WARNING: Kratos not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[3/4] Installing Backend service..." -ForegroundColor Cyan
if (Test-Path "C:\FlowSpace\backend") {
    & $nssm install FlowSpaceBackend "node" "dist/main.js"
    & $nssm set FlowSpaceBackend DisplayName "FlowSpace Backend"
    & $nssm set FlowSpaceBackend Description "Backend API for FlowSpace"
    & $nssm set FlowSpaceBackend AppDirectory "C:\FlowSpace\backend"
    & $nssm set FlowSpaceBackend Start SERVICE_AUTO_START
    & $nssm set FlowSpaceBackend DependOnService FlowSpacePostgreSQL FlowSpaceRedis FlowSpaceKratos
    & $nssm set FlowSpaceBackend AppStdout "C:\FlowSpace\logs\backend-stdout.log"
    & $nssm set FlowSpaceBackend AppStderr "C:\FlowSpace\logs\backend-stderr.log"
    Write-Host "  OK: Backend service created" -ForegroundColor Green
} else {
    Write-Host "  WARNING: Backend not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Starting services..." -ForegroundColor Cyan

if (Get-Service -Name FlowSpacePostgreSQL -ErrorAction SilentlyContinue) {
    & $nssm start FlowSpacePostgreSQL
    Start-Sleep -Seconds 5
    Write-Host "  PostgreSQL started" -ForegroundColor Green
}

& $nssm start FlowSpaceRedis
Start-Sleep -Seconds 3
Write-Host "  Redis started" -ForegroundColor Green

& $nssm start FlowSpaceKratos
Start-Sleep -Seconds 3
Write-Host "  Kratos started" -ForegroundColor Green

& $nssm start FlowSpaceBackend
Start-Sleep -Seconds 5
Write-Host "  Backend started" -ForegroundColor Green

Write-Host ""
Write-Host "Verifying services..." -ForegroundColor Cyan
Get-Service FlowSpace* | Format-Table Name, Status, StartType -AutoSize

Write-Host ""
Write-Host "FlowSpace services installed!" -ForegroundColor Green
Write-Host ""
Write-Host "Services will auto-start with Windows" -ForegroundColor White
Write-Host ""
Write-Host "To manage:" -ForegroundColor Cyan
Write-Host "  View: services.msc" -ForegroundColor White
Write-Host "  Uninstall: .\install-services-nssm.ps1 -Uninstall" -ForegroundColor White
Write-Host ""
