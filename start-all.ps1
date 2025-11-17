#!/usr/bin/env pwsh
# FlowSpace - Start Everything
# One script to rule them all

param(
    [switch]$StopAll
)

$ErrorActionPreference = "Continue"

# Service definitions
$services = @{
    "PostgreSQL" = @{
        Port = 5432
        Color = "Cyan"
        CheckOnly = $true
        StartCmd = ""
    }
    "Redis" = @{
        Port = 6379
        Color = "Yellow"
        CheckOnly = $false
        StartCmd = "C:\Redis\redis-server.exe"
        Args = @()
        WorkingDir = $null
    }
    "MinIO" = @{
        Port = 9000
        Color = "Green"
        CheckOnly = $false
        StartCmd = "minio.exe"
        Args = @("server", "C:\MinIO\data", "--console-address", ":9001")
        WorkingDir = $null
    }
    "Kratos" = @{
        Port = 4433
        Color = "Magenta"
        CheckOnly = $false
        StartCmd = "kratos.exe"
        Args = @("serve", "-c", "infrastructure/kratos/kratos.yml", "--dev")
        WorkingDir = $null
    }
    "LiveKit" = @{
        Port = 7880
        Color = "Blue"
        CheckOnly = $false
        StartCmd = "livekit-server.exe"
        Args = @("--dev", "--config", "infrastructure/livekit/livekit.yaml")
        WorkingDir = $null
    }
    "Backend" = @{
        Port = 4000
        Color = "White"
        CheckOnly = $false
        StartCmd = "npm"
        Args = @("run", "start:dev")
        WorkingDir = "backend"
    }
}

# Stop all services
if ($StopAll) {
    Write-Host "[STOP] Stopping all FlowSpace services..." -ForegroundColor Red
    
    foreach ($name in $services.Keys) {
        $svc = $services[$name]
        if (-not $svc.CheckOnly) {
            if ($name -eq "Backend") {
                Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*backend*" } | Stop-Process -Force
            } else {
                $processName = [System.IO.Path]::GetFileNameWithoutExtension($svc.StartCmd)
                Get-Process -Name $processName -ErrorAction SilentlyContinue | Stop-Process -Force
            }
            Write-Host "  Stopped $name" -ForegroundColor $svc.Color
        }
    }
    
    Write-Host "`n[DONE] All services stopped" -ForegroundColor Green
    exit 0
}

# Header
Clear-Host
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "              FlowSpace - Start Everything                   " -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

$runningJobs = @()
$failedServices = @()

# Create logs directory
New-Item -ItemType Directory -Path "logs" -Force | Out-Null

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
        Write-Host " [X] Not found: $($svc.StartCmd)" -ForegroundColor Red
        $failedServices += $name
        continue
    }
    
    Write-Host " Starting..." -ForegroundColor Yellow
    
    # Start service as background job
    $scriptBlock = {
        param($cmd, $args, $name, $workingDir)
        
        $startParams = @{
            FilePath = $cmd
            ArgumentList = $args
            PassThru = $true
            NoNewWindow = $true
            RedirectStandardOutput = "logs\$name-stdout.log"
            RedirectStandardError = "logs\$name-stderr.log"
        }
        
        if ($workingDir) {
            $startParams.WorkingDirectory = $workingDir
        }
        
        $process = Start-Process @startParams
        return $process.Id
    }
    
    try {
        $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $svc.StartCmd, $svc.Args, $name, $svc.WorkingDir
        $runningJobs += @{ Name = $name; Job = $job; Color = $svc.Color; Port = $svc.Port }
        
        # Wait and verify
        Start-Sleep -Milliseconds 1500
        $recheckPort = Test-NetConnection -ComputerName localhost -Port $svc.Port -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction SilentlyContinue
        
        if ($recheckPort) {
            Write-Host "[$name] " -NoNewline -ForegroundColor $svc.Color
            Write-Host "[OK] Started on port $($svc.Port)" -ForegroundColor Green
        } else {
            Write-Host "[$name] " -NoNewline -ForegroundColor $svc.Color
            Write-Host "[!] Started but not responding yet (may need more time)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[$name] " -NoNewline -ForegroundColor $svc.Color
        Write-Host "[X] Failed: $_" -ForegroundColor Red
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
    Write-Host "Service logs: .\logs\" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "URLs:" -ForegroundColor Cyan
    Write-Host "  Backend API:    http://localhost:4000/api/v1" -ForegroundColor White
    Write-Host "  MinIO Console:  http://localhost:9001" -ForegroundColor White
    Write-Host "  Kratos API:     http://localhost:4433" -ForegroundColor White
    Write-Host ""
    Write-Host "Press Ctrl+C to stop all services..." -ForegroundColor Yellow
    Write-Host ""
    
    # Monitor jobs
    try {
        while ($true) {
            Start-Sleep -Seconds 5
            
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
        
        foreach ($jobInfo in $runningJobs) {
            Write-Host "  Stopping $($jobInfo.Name)..." -NoNewline -ForegroundColor $jobInfo.Color
            
            Stop-Job -Job $jobInfo.Job -ErrorAction SilentlyContinue
            Remove-Job -Job $jobInfo.Job -Force -ErrorAction SilentlyContinue
            
            # Kill processes
            if ($jobInfo.Name -eq "Backend") {
                Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            } else {
                $processName = [System.IO.Path]::GetFileNameWithoutExtension($services[$jobInfo.Name].StartCmd)
                Get-Process -Name $processName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            }
            
            Write-Host " [OK]" -ForegroundColor Green
        }
        
        Write-Host "`n[DONE] All services stopped" -ForegroundColor Green
    }
} else {
    Write-Host "[X] No services were started" -ForegroundColor Red
    Write-Host ""
    Write-Host "Required:" -ForegroundColor Yellow
    Write-Host "  - PostgreSQL running" -ForegroundColor White
    Write-Host "  - Redis (redis-server)" -ForegroundColor White
    Write-Host "  - MinIO (minio.exe)" -ForegroundColor White
    Write-Host "  - Ory Kratos (kratos.exe)" -ForegroundColor White
    Write-Host "  - LiveKit (livekit-server.exe)" -ForegroundColor White
    Write-Host "  - Node.js + npm (for backend)" -ForegroundColor White
    exit 1
}
