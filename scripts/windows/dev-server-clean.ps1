#!/usr/bin/env pwsh
# FlowSpace Unified Development Server
# Runs all services in one window with colored output

param(
    [switch]$StopAll
)

$ErrorActionPreference = "Continue"

# Service definitions
$services = @{
    "PostgreSQL" = @{
        Port = 5432
        Color = "Cyan"
        CheckOnly = $true  # Assume running as Windows service
        StartCmd = ""
    }
    "Redis" = @{
        Port = 6379
        Color = "Yellow"
        CheckOnly = $false
        StartCmd = "redis-server"
        Args = @()
    }
    "MinIO" = @{
        Port = 9000
        Color = "Green"
        CheckOnly = $false
        StartCmd = "minio.exe"
        Args = @("server", "C:\MinIO\data", "--console-address", ":9001")
    }
    "Kratos" = @{
        Port = 4433
        Color = "Magenta"
        CheckOnly = $false
        StartCmd = "kratos.exe"
        Args = @("serve", "-c", "infrastructure/kratos/kratos.yml", "--dev")
    }
    "LiveKit" = @{
        Port = 7880
        Color = "Blue"
        CheckOnly = $false
        StartCmd = "livekit-server.exe"
        Args = @("--dev", "--config", "infrastructure/livekit/livekit.yaml")
    }
}

# Stop all services
if ($StopAll) {
    Write-Host "[STOP] Stopping all FlowSpace services..." -ForegroundColor Red
    
    foreach ($name in $services.Keys) {
        $svc = $services[$name]
        if (-not $svc.CheckOnly) {
            $processName = [System.IO.Path]::GetFileNameWithoutExtension($svc.StartCmd)
            Get-Process -Name $processName -ErrorAction SilentlyContinue | Stop-Process -Force
            Write-Host "  Stopped $name" -ForegroundColor $svc.Color
        }
    }
    
    Write-Host "`n[DONE] All services stopped" -ForegroundColor Green
    exit 0
}

# Header
Clear-Host
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "           FlowSpace Development Server                      " -ForegroundColor Cyan
Write-Host "                                                             " -ForegroundColor Cyan
Write-Host "  All background services in one window                     " -ForegroundColor Cyan
Write-Host "  Press Ctrl+C to stop all services                         " -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

$runningJobs = @()
$failedServices = @()

# Check and start each service
foreach ($name in $services.Keys) {
    $svc = $services[$name]
    
    Write-Host "[$name] " -NoNewline -ForegroundColor $svc.Color
    Write-Host "Checking port $($svc.Port)..." -NoNewline
    
    $portCheck = Test-NetConnection -ComputerName localhost -Port $svc.Port -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction SilentlyContinue
    
    if ($portCheck) {
        Write-Host " [OK] Already running" -ForegroundColor Green
        continue
    }
    
    if ($svc.CheckOnly) {
        Write-Host " [X] Not running (start manually)" -ForegroundColor Yellow
        $failedServices += $name
        continue
    }
    
    # Check if executable exists
    $exePath = Get-Command $svc.StartCmd -ErrorAction SilentlyContinue
    if (-not $exePath) {
        Write-Host " [X] Not found" -ForegroundColor Red
        $failedServices += $name
        continue
    }
    
    Write-Host " Starting..." -ForegroundColor Yellow
    
    # Start service as background job
    $scriptBlock = {
        param($cmd, $args, $name, $color)
        
        $process = Start-Process -FilePath $cmd -ArgumentList $args -PassThru -NoNewWindow -RedirectStandardOutput "logs\$name-stdout.log" -RedirectStandardError "logs\$name-stderr.log"
        
        return $process.Id
    }
    
    # Create logs directory
    New-Item -ItemType Directory -Path "logs" -Force | Out-Null
    
    try {
        $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $svc.StartCmd, $svc.Args, $name, $svc.Color
        $runningJobs += @{ Name = $name; Job = $job; Color = $svc.Color; Port = $svc.Port }
        
        # Wait a moment and verify
        Start-Sleep -Milliseconds 500
        $recheckPort = Test-NetConnection -ComputerName localhost -Port $svc.Port -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction SilentlyContinue
        
        if ($recheckPort) {
            Write-Host "[$name] " -NoNewline -ForegroundColor $svc.Color
            Write-Host "[OK] Started successfully on port $($svc.Port)" -ForegroundColor Green
        } else {
            Write-Host "[$name] " -NoNewline -ForegroundColor $svc.Color
            Write-Host "[!] Started but port not responding yet" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[$name] " -NoNewline -ForegroundColor $svc.Color
        Write-Host "[X] Failed to start: $_" -ForegroundColor Red
        $failedServices += $name
    }
}

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan

if ($failedServices.Count -gt 0) {
    Write-Host "[!] Some services could not start:" -ForegroundColor Yellow
    foreach ($failed in $failedServices) {
        Write-Host "   - $failed" -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($runningJobs.Count -gt 0) {
    Write-Host "[OK] Active services: $($runningJobs.Count)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Service logs are in: .\logs\" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "You can now start the backend:" -ForegroundColor Cyan
    Write-Host "  cd backend" -ForegroundColor White
    Write-Host "  npm run start:dev" -ForegroundColor White
    Write-Host ""
    Write-Host "Press Ctrl+C to stop all services..." -ForegroundColor Yellow
    
    # Monitor jobs
    try {
        while ($true) {
            Start-Sleep -Seconds 5
            
            # Check if jobs are still running
            foreach ($jobInfo in $runningJobs) {
                if ($jobInfo.Job.State -ne "Running") {
                    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] " -NoNewline -ForegroundColor DarkGray
                    Write-Host "$($jobInfo.Name) " -NoNewline -ForegroundColor $jobInfo.Color
                    Write-Host "stopped unexpectedly" -ForegroundColor Red
                }
            }
        }
    } finally {
        Write-Host "`n`n[STOP] Shutting down services..." -ForegroundColor Red
        
        # Stop all jobs
        foreach ($jobInfo in $runningJobs) {
            Write-Host "  Stopping $($jobInfo.Name)..." -NoNewline -ForegroundColor $jobInfo.Color
            
            # Stop the job
            Stop-Job -Job $jobInfo.Job -ErrorAction SilentlyContinue
            Remove-Job -Job $jobInfo.Job -Force -ErrorAction SilentlyContinue
            
            # Kill any remaining processes
            $processName = [System.IO.Path]::GetFileNameWithoutExtension($services[$jobInfo.Name].StartCmd)
            Get-Process -Name $processName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            
            Write-Host " [OK]" -ForegroundColor Green
        }
        
        Write-Host "`n[DONE] All services stopped" -ForegroundColor Green
    }
} else {
    Write-Host "[X] No services were started" -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure you have installed:" -ForegroundColor Yellow
    Write-Host "  - Redis (redis-server)" -ForegroundColor White
    Write-Host "  - MinIO (minio.exe)" -ForegroundColor White
    Write-Host "  - Ory Kratos (kratos.exe)" -ForegroundColor White
    Write-Host "  - LiveKit (livekit-server.exe)" -ForegroundColor White
    exit 1
}
