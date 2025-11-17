#!/usr/bin/env pwsh
# FlowSpace Service Manager
# Manages all backend services (Redis, MinIO, Kratos, LiveKit, Backend API)

param(
    [ValidateSet("Start", "Stop", "Status", "Restart")]
    [string]$Action = "Start",
    [string]$InstallPath = "C:\Users\$env:USERNAME\FlowSpace"
)

$ErrorActionPreference = "Stop"

# Service definitions
$services = @{
    "Redis" = @{
        Path = "$InstallPath\bin\Redis\redis-server.exe"
        Args = "--port 6379"
        Port = 6379
    }
    "MinIO" = @{
        Path = "$InstallPath\bin\MinIO\minio.exe"
        Args = "server $InstallPath\data\minio --address :9000 --console-address :9001"
        Port = 9000
    }
    "Kratos" = @{
        Path = "$InstallPath\bin\Kratos\kratos.exe"
        Args = "serve -c $InstallPath\config\kratos.yaml --dev"
        Port = 4433
    }
    "LiveKit" = @{
        Path = "$InstallPath\bin\LiveKit\livekit-server.exe"
        Args = "--dev --config $InstallPath\config\livekit.yaml"
        Port = 7880
    }
    "Backend" = @{
        Path = "node"
        Args = "$InstallPath\backend\dist\main.js"
        Port = 4000
        WorkingDir = "$InstallPath\backend"
    }
}

function Test-ServiceRunning {
    param([int]$Port, [string]$ServiceName)
    
    try {
        $connection = Test-NetConnection -ComputerName localhost -Port $Port -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        return $connection.TcpTestSucceeded
    } catch {
        return $false
    }
}

function Start-FlowSpaceService {
    param([string]$Name, [hashtable]$Config)
    
    if (-not (Test-Path $Config.Path)) {
        Write-Host "  ⚠️  $Name binary not found at $($Config.Path)" -ForegroundColor Yellow
        return $false
    }
    
    # Check if already running
    if (Test-ServiceRunning -Port $Config.Port -ServiceName $Name) {
        Write-Host "  ✓ $Name already running on port $($Config.Port)" -ForegroundColor Green
        return $true
    }
    
    # Start service hidden
    try {
        $processArgs = @{
            FilePath = $Config.Path
            ArgumentList = $Config.Args
            WindowStyle = "Hidden"
            PassThru = $true
        }
        
        if ($Config.WorkingDir) {
            $processArgs.WorkingDirectory = $Config.WorkingDir
        }
        
        $process = Start-Process @processArgs
        
        # Wait for service to start
        Start-Sleep -Seconds 2
        
        if (Test-ServiceRunning -Port $Config.Port -ServiceName $Name) {
            Write-Host "  ✓ $Name started (PID: $($process.Id))" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  ✗ $Name failed to start" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  ✗ Error starting $Name : $_" -ForegroundColor Red
        return $false
    }
}

function Stop-FlowSpaceService {
    param([string]$Name, [hashtable]$Config)
    
    $processName = Split-Path $Config.Path -Leaf
    $processName = $processName -replace '\.exe$', ''
    
    $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
    
    if ($processes) {
        foreach ($proc in $processes) {
            try {
                Stop-Process -Id $proc.Id -Force
                Write-Host "  ✓ $Name stopped (PID: $($proc.Id))" -ForegroundColor Green
            } catch {
                Write-Host "  ⚠️  Could not stop $Name (PID: $($proc.Id))" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "  - $Name not running" -ForegroundColor Gray
    }
}

function Get-FlowSpaceStatus {
    Write-Host "`nFlowSpace Services Status:" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────" -ForegroundColor Cyan
    
    foreach ($serviceName in $services.Keys) {
        $config = $services[$serviceName]
        $running = Test-ServiceRunning -Port $config.Port -ServiceName $serviceName
        
        if ($running) {
            Write-Host "  ✓ $serviceName" -ForegroundColor Green -NoNewline
            Write-Host " (port $($config.Port))" -ForegroundColor Gray
        } else {
            Write-Host "  ✗ $serviceName" -ForegroundColor Red -NoNewline
            Write-Host " (port $($config.Port) - not responding)" -ForegroundColor Gray
        }
    }
    Write-Host ""
}

# Main execution
switch ($Action) {
    "Start" {
        Write-Host "`nStarting FlowSpace Services..." -ForegroundColor Cyan
        
        foreach ($serviceName in $services.Keys) {
            Start-FlowSpaceService -Name $serviceName -Config $services[$serviceName]
        }
        
        Write-Host "`n✓ FlowSpace services started" -ForegroundColor Green
        Get-FlowSpaceStatus
    }
    
    "Stop" {
        Write-Host "`nStopping FlowSpace Services..." -ForegroundColor Cyan
        
        foreach ($serviceName in $services.Keys) {
            Stop-FlowSpaceService -Name $serviceName -Config $services[$serviceName]
        }
        
        Write-Host "`n✓ FlowSpace services stopped" -ForegroundColor Green
    }
    
    "Status" {
        Get-FlowSpaceStatus
    }
    
    "Restart" {
        & $PSCommandPath -Action Stop -InstallPath $InstallPath
        Start-Sleep -Seconds 2
        & $PSCommandPath -Action Start -InstallPath $InstallPath
    }
}
