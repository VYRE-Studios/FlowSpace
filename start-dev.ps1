#!/usr/bin/env pwsh
# FlowSpace Development Startup
# Starts services in the correct order: Redis -> Kratos -> Backend -> Flutter

param(
    [switch]$StopAll,
    [switch]$SkipFlutter
)

$ErrorActionPreference = "Continue"

# Service paths
$REDIS_PATH = "C:\Redis\redis-server.exe"
$KRATOS_PATH = "C:\Kratos\kratos.exe"
$BACKEND_DIR = "C:\FlowSpace\backend"
$FLUTTER_DIR = "C:\FlowSpace\client_flutter"
$KRATOS_CONFIG = "C:\Kratos\kratos.yaml"
$LOGS_DIR = "C:\FlowSpace\logs"

# Stop all services
if ($StopAll) {
    Write-Host "🛑 Stopping FlowSpace services..." -ForegroundColor Red
    Write-Host ""
    
    # Stop processes
    Get-Process -Name "flutter" -ErrorAction SilentlyContinue | Stop-Process -Force
    Write-Host "  ✓ Stopped Flutter" -ForegroundColor Green
    
    Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
    Write-Host "  ✓ Stopped Backend" -ForegroundColor Green
    
    Get-Process -Name "kratos" -ErrorAction SilentlyContinue | Stop-Process -Force
    Write-Host "  ✓ Stopped Kratos" -ForegroundColor Green
    
    Get-Process -Name "redis-server" -ErrorAction SilentlyContinue | Stop-Process -Force
    Write-Host "  ✓ Stopped Redis" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "✅ All services stopped" -ForegroundColor Green
    exit 0
}

# Create logs directory
New-Item -ItemType Directory -Path $LOGS_DIR -Force | Out-Null

# Header
Clear-Host
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              🚀 FlowSpace Development Setup              ║" -ForegroundColor Cyan
Write-Host "║                                                            ║" -ForegroundColor Cyan
Write-Host "║  Starting services in order:                              ║" -ForegroundColor Cyan
Write-Host "║    1. Redis                                               ║" -ForegroundColor Cyan
Write-Host "║    2. Kratos                                              ║" -ForegroundColor Cyan
Write-Host "║    3. Backend                                             ║" -ForegroundColor Cyan
Write-Host "║    4. Flutter                                             ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$failed = $false

# 1. Start Redis
Write-Host "[1/4] Redis..." -NoNewline -ForegroundColor Yellow
$redisCheck = Test-NetConnection -ComputerName localhost -Port 6379 -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction SilentlyContinue

if ($redisCheck) {
    Write-Host " ✓ Already running" -ForegroundColor Green
} else {
    if (Test-Path $REDIS_PATH) {
        Start-Process -FilePath $REDIS_PATH -WindowStyle Hidden
        Start-Sleep -Seconds 2
        
        $redisRecheck = Test-NetConnection -ComputerName localhost -Port 6379 -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction SilentlyContinue
        if ($redisRecheck) {
            Write-Host " ✓ Started on port 6379" -ForegroundColor Green
        } else {
            Write-Host " ✗ Failed to start" -ForegroundColor Red
            $failed = $true
        }
    } else {
        Write-Host " ✗ Not found at $REDIS_PATH" -ForegroundColor Red
        $failed = $true
    }
}

if ($failed) {
    Write-Host ""
    Write-Host "❌ Cannot continue without Redis" -ForegroundColor Red
    exit 1
}

# 2. Start Kratos
Write-Host "[2/4] Kratos..." -NoNewline -ForegroundColor Magenta
$kratosCheck = Test-NetConnection -ComputerName localhost -Port 4433 -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction SilentlyContinue

if ($kratosCheck) {
    Write-Host " ✓ Already running" -ForegroundColor Green
} else {
    if (Test-Path $KRATOS_PATH) {
        $kratosArgs = @("serve", "-c", $KRATOS_CONFIG, "--dev")
        Start-Process -FilePath $KRATOS_PATH -ArgumentList $kratosArgs -WindowStyle Hidden -RedirectStandardOutput "$LOGS_DIR\kratos-stdout.log" -RedirectStandardError "$LOGS_DIR\kratos-stderr.log"
        Start-Sleep -Seconds 3
        
        $kratosRecheck = Test-NetConnection -ComputerName localhost -Port 4433 -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction SilentlyContinue
        if ($kratosRecheck) {
            Write-Host " ✓ Started on port 4433" -ForegroundColor Green
        } else {
            Write-Host " ⚠️  Started but not responding yet" -ForegroundColor Yellow
        }
    } else {
        Write-Host " ✗ Not found at $KRATOS_PATH" -ForegroundColor Red
        $failed = $true
    }
}

if ($failed) {
    Write-Host ""
    Write-Host "❌ Cannot continue without Kratos" -ForegroundColor Red
    exit 1
}

# 3. Start Backend
Write-Host "[3/4] Backend..." -NoNewline -ForegroundColor White
$backendCheck = Test-NetConnection -ComputerName localhost -Port 4000 -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction SilentlyContinue

if ($backendCheck) {
    Write-Host " ✓ Already running" -ForegroundColor Green
} else {
    if (Test-Path "$BACKEND_DIR\package.json") {
        $job = Start-Job -ScriptBlock {
            param($dir, $logFile)
            Set-Location $dir
            npm run start:dev 2>&1 | Out-File $logFile
        } -ArgumentList $BACKEND_DIR, "$LOGS_DIR\backend-output.log"
        
        # Wait for backend to start
        $attempts = 0
        $maxAttempts = 15
        $backendStarted = $false
        
        while ($attempts -lt $maxAttempts) {
            Start-Sleep -Seconds 2
            $backendRecheck = Test-NetConnection -ComputerName localhost -Port 4000 -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction SilentlyContinue
            if ($backendRecheck) {
                Write-Host " ✓ Started on port 4000" -ForegroundColor Green
                $backendStarted = $true
                break
            }
            $attempts++
        }
        
        if (-not $backendStarted) {
            Write-Host " ⚠️  Started but not responding yet (check logs)" -ForegroundColor Yellow
        }
    } else {
        Write-Host " ✗ Not found at $BACKEND_DIR" -ForegroundColor Red
        $failed = $true
    }
}

# 4. Flutter (optional)
if (-not $SkipFlutter) {
    Write-Host "[4/4] Flutter..." -NoNewline -ForegroundColor Cyan
    
    # Check if Flutter is already running
    $flutterProcess = Get-Process -Name "client_flutter" -ErrorAction SilentlyContinue
    if ($flutterProcess) {
        Write-Host " ✓ Already running" -ForegroundColor Green
    } elseif (Test-Path "$FLUTTER_DIR\pubspec.yaml") {
        Write-Host " Starting in new window..." -ForegroundColor Yellow
        Start-Process pwsh -ArgumentList "-NoExit", "-Command", "cd '$FLUTTER_DIR'; flutter run -d windows"
        Write-Host "       ✓ Flutter window opened" -ForegroundColor Green
    } else {
        Write-Host " ✗ Not found at $FLUTTER_DIR" -ForegroundColor Red
    }
}

# Summary
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ FlowSpace is starting!" -ForegroundColor Green
Write-Host ""
Write-Host "📍 Service URLs:" -ForegroundColor Cyan
Write-Host "   Backend API:  http://localhost:4000/api/v1" -ForegroundColor White
Write-Host "   Kratos API:   http://localhost:4433" -ForegroundColor White
Write-Host "   Redis:        localhost:6379" -ForegroundColor White
Write-Host ""
Write-Host "📋 Logs:" -ForegroundColor Cyan
Write-Host "   Backend:      $LOGS_DIR\backend-output.log" -ForegroundColor DarkGray
Write-Host "   Kratos:       $LOGS_DIR\kratos-stderr.log" -ForegroundColor DarkGray
Write-Host ""
Write-Host "🛑 To stop all services:" -ForegroundColor Yellow
Write-Host "   .\start-dev.ps1 -StopAll" -ForegroundColor White
Write-Host ""
