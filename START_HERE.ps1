#!/usr/bin/env pwsh
# FlowSpace - Complete Startup Guide
# This script shows you exactly what to do

Clear-Host
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                            ║" -ForegroundColor Cyan
Write-Host "║                  🚀 FLOWSPACE STARTUP                     ║" -ForegroundColor Cyan
Write-Host "║                                                            ║" -ForegroundColor Cyan
Write-Host "║         Your Teams × Slack × Zoom hybrid platform        ║" -ForegroundColor Cyan
Write-Host "║                                                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1
Write-Host "STEP 1: " -ForegroundColor Yellow -NoNewline
Write-Host "Make sure PostgreSQL is running" -ForegroundColor White
Write-Host "        Check: " -NoNewline -ForegroundColor DarkGray
$pgRunning = Test-NetConnection -ComputerName localhost -Port 5432 -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction SilentlyContinue
if ($pgRunning) {
    Write-Host "✓ PostgreSQL is running" -ForegroundColor Green
} else {
    Write-Host "✗ PostgreSQL NOT running" -ForegroundColor Red
    Write-Host "        Start PostgreSQL service or run: pg_ctl start" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter when PostgreSQL is running"
}

Write-Host ""

# Step 2
Write-Host "STEP 2: " -ForegroundColor Yellow -NoNewline
Write-Host "Start infrastructure services (one command)" -ForegroundColor White
Write-Host "        This starts: Redis, MinIO, Kratos, LiveKit" -ForegroundColor DarkGray
Write-Host ""
Write-Host "        Run this in a NEW terminal window:" -ForegroundColor Cyan
Write-Host "        " -NoNewline
Write-Host ".\dev-server.ps1" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host ""
Write-Host "        (Keep that window open - it runs all services)" -ForegroundColor DarkGray
Write-Host ""
Read-Host "Press Enter when you've started dev-server.ps1 in another window"

# Check services
Write-Host ""
Write-Host "        Checking services..." -ForegroundColor DarkGray
$allGood = $true

$checks = @(
    @{Name="Redis"; Port=6379},
    @{Name="MinIO"; Port=9000},
    @{Name="Kratos"; Port=4433},
    @{Name="LiveKit"; Port=7880}
)

foreach ($check in $checks) {
    $running = Test-NetConnection -ComputerName localhost -Port $check.Port -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction SilentlyContinue
    Write-Host "        " -NoNewline
    if ($running) {
        Write-Host "✓ $($check.Name)" -ForegroundColor Green
    } else {
        Write-Host "✗ $($check.Name) not responding" -ForegroundColor Red
        $allGood = $false
    }
}

if (-not $allGood) {
    Write-Host ""
    Write-Host "        Some services aren't ready. Check the dev-server window for errors." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to continue anyway, or Ctrl+C to stop"
}

Write-Host ""

# Step 3
Write-Host "STEP 3: " -ForegroundColor Yellow -NoNewline
Write-Host "Start backend API server" -ForegroundColor White
Write-Host "        Run this in ANOTHER new terminal:" -ForegroundColor Cyan
Write-Host ""
Write-Host "        cd backend" -ForegroundColor White
Write-Host "        npm run start:dev" -ForegroundColor White
Write-Host ""
Write-Host "        The backend will run on: " -NoNewline -ForegroundColor DarkGray
Write-Host "http://localhost:4000/api/v1" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter when backend is running"

# Check backend
$backendRunning = Test-NetConnection -ComputerName localhost -Port 4000 -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction SilentlyContinue
if ($backendRunning) {
    Write-Host "        ✓ Backend API is responding" -ForegroundColor Green
} else {
    Write-Host "        ⚠️  Backend not responding on port 4000" -ForegroundColor Yellow
}

Write-Host ""

# Step 4
Write-Host "STEP 4: " -ForegroundColor Yellow -NoNewline
Write-Host "Launch Flutter desktop app" -ForegroundColor White
Write-Host "        Run this in ANOTHER new terminal:" -ForegroundColor Cyan
Write-Host ""
Write-Host "        cd client_flutter" -ForegroundColor White
Write-Host "        flutter run -d windows" -ForegroundColor White
Write-Host ""

# Summary
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ You should now have:" -ForegroundColor Green
Write-Host "   1. dev-server.ps1 running (infrastructure services)" -ForegroundColor White
Write-Host "   2. Backend API running (npm run start:dev)" -ForegroundColor White
Write-Host "   3. Flutter app running (flutter run)" -ForegroundColor White
Write-Host ""
Write-Host "🌐 URLs:" -ForegroundColor Cyan
Write-Host "   Backend API:    http://localhost:4000/api/v1" -ForegroundColor White
Write-Host "   MinIO Console:  http://localhost:9001" -ForegroundColor White
Write-Host "   Kratos API:     http://localhost:4433" -ForegroundColor White
Write-Host ""
Write-Host "📝 Logs are in: .\logs\" -ForegroundColor DarkGray
Write-Host ""
Write-Host "To stop everything:" -ForegroundColor Yellow
Write-Host "   1. Ctrl+C in each terminal window" -ForegroundColor White
Write-Host "   2. Run: .\dev-server.ps1 -StopAll" -ForegroundColor White
Write-Host ""
Write-Host "Happy coding! 🎉" -ForegroundColor Green
Write-Host ""
