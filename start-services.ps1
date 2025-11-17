#!/usr/bin/env pwsh
# FlowSpace Infrastructure Startup Script for Windows

Write-Host "🚀 Starting FlowSpace Services" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

$serviceErrors = @()

# Check PostgreSQL
Write-Host "Checking PostgreSQL..." -ForegroundColor Yellow
$pgCheck = Test-NetConnection -ComputerName localhost -Port 5432 -WarningAction SilentlyContinue -InformationLevel Quiet
if ($pgCheck) {
    Write-Host "  ✓ PostgreSQL already running on port 5432" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  PostgreSQL not running. Start it manually:" -ForegroundColor Yellow
    Write-Host "     - Windows Service: pg_ctl start" -ForegroundColor DarkGray
    Write-Host "     - Or start via Services app (services.msc)" -ForegroundColor DarkGray
    $serviceErrors += "PostgreSQL"
}

# Check Redis
Write-Host "Checking Redis..." -ForegroundColor Yellow
$redisCheck = Test-NetConnection -ComputerName localhost -Port 6379 -WarningAction SilentlyContinue -InformationLevel Quiet
if ($redisCheck) {
    Write-Host "  ✓ Redis already running on port 6379" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Redis not running. Starting..." -ForegroundColor Yellow
    # Try to start Redis if installed
    $redisPath = Get-Command redis-server -ErrorAction SilentlyContinue
    if (-not $redisPath -and (Test-Path "C:\Redis\redis-server.exe")) {
        $redisPath = "C:\Redis\redis-server.exe"
    }
    if ($redisPath) {
        Start-Process -FilePath $redisPath -WindowStyle Minimized
        Start-Sleep -Seconds 2
        $redisRecheck = Test-NetConnection -ComputerName localhost -Port 6379 -WarningAction SilentlyContinue -InformationLevel Quiet
        if ($redisRecheck) {
            Write-Host "  ✓ Redis started successfully" -ForegroundColor Green
        } else {
            $serviceErrors += "Redis"
        }
    } else {
        Write-Host "     redis-server not found. Install Redis first." -ForegroundColor Red
        $serviceErrors += "Redis"
    }
}

# Check MinIO
Write-Host "Checking MinIO..." -ForegroundColor Yellow
$minioCheck = Test-NetConnection -ComputerName localhost -Port 9000 -WarningAction SilentlyContinue -InformationLevel Quiet
if ($minioCheck) {
    Write-Host "  ✓ MinIO already running on port 9000" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  MinIO not running. Start manually:" -ForegroundColor Yellow
    Write-Host "     minio.exe server C:\MinIO\data --console-address :9001" -ForegroundColor DarkGray
    $serviceErrors += "MinIO"
}

# Check Kratos
Write-Host "Checking Ory Kratos..." -ForegroundColor Yellow
$kratosCheck = Test-NetConnection -ComputerName localhost -Port 4433 -WarningAction SilentlyContinue -InformationLevel Quiet
if ($kratosCheck) {
    Write-Host "  ✓ Kratos already running on port 4433" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Kratos not running. Start manually:" -ForegroundColor Yellow
    Write-Host "     kratos.exe serve -c infrastructure/kratos/kratos.yml --dev" -ForegroundColor DarkGray
    $serviceErrors += "Kratos"
}

# Check LiveKit
Write-Host "Checking LiveKit..." -ForegroundColor Yellow
$livekitCheck = Test-NetConnection -ComputerName localhost -Port 7880 -WarningAction SilentlyContinue -InformationLevel Quiet
if ($livekitCheck) {
    Write-Host "  ✓ LiveKit already running on port 7880" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  LiveKit not running. Start manually:" -ForegroundColor Yellow
    Write-Host "     livekit-server.exe --dev --config infrastructure/livekit/livekit.yaml" -ForegroundColor DarkGray
    $serviceErrors += "LiveKit"
}

# Summary
Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

if ($serviceErrors.Count -eq 0) {
    Write-Host "✅ All services are running!" -ForegroundColor Green
    Write-Host "`nYou can now start the backend:" -ForegroundColor Cyan
    Write-Host "  cd backend" -ForegroundColor White
    Write-Host "  npm run start:dev" -ForegroundColor White
} else {
    Write-Host "⚠️  Some services need to be started manually:" -ForegroundColor Yellow
    foreach ($service in $serviceErrors) {
        Write-Host "  - $service" -ForegroundColor Yellow
    }
    Write-Host "`nRefer to README.md for setup instructions." -ForegroundColor Cyan
}
