#!/usr/bin/env pwsh
# FlowSpace - Verify and Start Everything Automatically
# This script checks the system and ensures all services are running

$ErrorActionPreference = "Continue"

Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "        FlowSpace - Automated Service Verification           " -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠️  Not running as Administrator" -ForegroundColor Yellow
    Write-Host "   Some operations may require admin privileges" -ForegroundColor Gray
    Write-Host ""
}

# 1. Verify backend code is built
Write-Host "[1/5] Verifying backend build..." -ForegroundColor Cyan
if (Test-Path "C:\FlowSpace\backend\dist\main.js") {
    Write-Host "   ✓ Backend is built" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Backend not built, building now..." -ForegroundColor Yellow
    Push-Location "C:\FlowSpace\backend"
    npm run build
    Pop-Location
    Write-Host "   ✓ Build complete" -ForegroundColor Green
}

# 2. Verify .env file has correct DATABASE_URL
Write-Host "[2/5] Verifying database configuration..." -ForegroundColor Cyan
$envPath = "C:\FlowSpace\backend\.env"
if (Test-Path $envPath) {
    $envContent = Get-Content $envPath -Raw
    if ($envContent -match "postgres:5432") {
        Write-Host "   Fixing DATABASE_URL (changing postgres to localhost)..." -ForegroundColor Yellow
        $envContent = $envContent -replace 'postgres:5432', 'localhost:5432'
        $envContent = $envContent -replace 'redis://redis:', 'redis://localhost:'
        Set-Content -Path $envPath -Value $envContent
        Write-Host "   Database URL fixed" -ForegroundColor Green
    } else {
        Write-Host "   Database URL is correct" -ForegroundColor Green
    }
} else {
    Write-Host "   .env file not found, creating from template..." -ForegroundColor Yellow
    Copy-Item "C:\FlowSpace\backend\env.development" $envPath
    $envContent = Get-Content $envPath -Raw
    $envContent = $envContent -replace 'postgres:5432', 'localhost:5432'
    $envContent = $envContent -replace 'redis://redis:', 'redis://localhost:'
    Set-Content -Path $envPath -Value $envContent
    Write-Host "   .env file created" -ForegroundColor Green
}

# 3. Check PostgreSQL
Write-Host "[3/5] Checking PostgreSQL..." -ForegroundColor Cyan
$pgRunning = Test-NetConnection -ComputerName localhost -Port 5432 -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction SilentlyContinue
if ($pgRunning) {
    Write-Host "   ✓ PostgreSQL is running on port 5432" -ForegroundColor Green
} else {
    Write-Host "   ✗ PostgreSQL is NOT running on port 5432" -ForegroundColor Red
    Write-Host "     Start PostgreSQL service or install PostgreSQL" -ForegroundColor Yellow
}

# 4. Check Windows Service Status
Write-Host "[4/5] Checking Windows Services..." -ForegroundColor Cyan
$backendService = Get-Service -Name FlowSpaceBackend -ErrorAction SilentlyContinue
if ($backendService) {
    Write-Host "   Service Status: $($backendService.Status)" -ForegroundColor $(if ($backendService.Status -eq "Running") { "Green" } else { "Yellow" })
    Write-Host "   Start Type: $($backendService.StartType)" -ForegroundColor Gray
    
    if ($backendService.Status -ne "Running" -and $isAdmin) {
        Write-Host "   ⚠️  Starting service..." -ForegroundColor Yellow
        Start-Service -Name FlowSpaceBackend -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        $backendService = Get-Service -Name FlowSpaceBackend
        Write-Host "   Status: $($backendService.Status)" -ForegroundColor $(if ($backendService.Status -eq "Running") { "Green" } else { "Red" })
    }
} else {
    Write-Host "   ⚠️  FlowSpaceBackend service not found" -ForegroundColor Yellow
    Write-Host "     Run: .\install-services-nssm.ps1 (as Administrator)" -ForegroundColor Gray
}

# 5. Test P2P Endpoint
Write-Host "[5/5] Testing P2P endpoint..." -ForegroundColor Cyan
Start-Sleep -Seconds 2
try {
    $response = Invoke-WebRequest -Uri "http://localhost:4000/api/v1/p2p/status" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    Write-Host "   ✓ P2P endpoint is responding!" -ForegroundColor Green
    Write-Host "   Response: $($response.StatusCode)" -ForegroundColor Gray
    
    try {
        $json = $response.Content | ConvertFrom-Json
        Write-Host "   Node ID: $($json.nodeId)" -ForegroundColor Gray
        Write-Host "   Runtime State: $($json.runtimeState)" -ForegroundColor Gray
        Write-Host "   Peer Count: $($json.peers.Count)" -ForegroundColor Gray
    } catch {
        Write-Host "   Response: $($response.Content.Substring(0, [Math]::Min(100, $response.Content.Length)))" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ✗ P2P endpoint not responding" -ForegroundColor Red
    Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Gray
    
    # Check if backend is listening
    $backendListening = Test-NetConnection -ComputerName localhost -Port 4000 -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction SilentlyContinue
    if ($backendListening) {
        Write-Host "     ⚠️  Backend is listening on port 4000 but endpoint failed" -ForegroundColor Yellow
        Write-Host "     Check logs: C:\FlowSpace\logs\Backend-stderr.log" -ForegroundColor Gray
    } else {
        Write-Host "     ⚠️  Backend is not listening on port 4000" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend Service:" -ForegroundColor White
if ($backendService) {
    Write-Host "  Status: $($backendService.Status)" -ForegroundColor $(if ($backendService.Status -eq "Running") { "Green" } else { "Red" })
    Write-Host "  Auto-start: $($backendService.StartType)" -ForegroundColor Gray
} else {
    Write-Host "  Status: Not installed" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "P2P Runtime:" -ForegroundColor White
$p2pTest = try { 
    $r = Invoke-WebRequest -Uri "http://localhost:4000/api/v1/p2p/status" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
    "OK - Running - Status $($r.StatusCode)"
} catch { 
    "FAIL - Not responding"
}
$p2pColor = if ($p2pTest -match "OK") { "Green" } else { "Red" }
Write-Host "  $p2pTest" -ForegroundColor $p2pColor

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
if (-not $pgRunning) {
    Write-Host "  1. Start PostgreSQL service" -ForegroundColor Yellow
}
if (-not $backendService -or $backendService.Status -ne "Running") {
    Write-Host "  2. Install/Start FlowSpaceBackend service (requires Admin)" -ForegroundColor Yellow
    Write-Host "     Run: .\install-services-nssm.ps1" -ForegroundColor Gray
}
if ($p2pTest -match "FAIL") {
    Write-Host "  3. Check backend logs: C:\FlowSpace\logs\Backend-stderr.log" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "All services should start automatically with Windows!" -ForegroundColor Green
Write-Host ""

