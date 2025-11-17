#!/usr/bin/env pwsh
# FlowSpace Silent Service Launcher
# Starts all backend services in the background without visible windows

$ErrorActionPreference = "SilentlyContinue"

$LogDir = "C:\FlowSpace\logs"
if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# Function to start process hidden
function Start-HiddenProcess {
    param(
        [string]$FilePath,
        [string]$Arguments,
        [string]$WorkingDirectory,
        [string]$LogFile
    )
    
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    $psi.Arguments = $Arguments
    $psi.WorkingDirectory = $WorkingDirectory
    $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $process.Start() | Out-Null
    
    # Capture output to log file
    if ($LogFile) {
        Start-Job -ScriptBlock {
            param($proc, $log)
            while (!$proc.HasExited) {
                $output = $proc.StandardOutput.ReadLine()
                if ($output) {
                    Add-Content -Path $log -Value $output
                }
            }
        } -ArgumentList $process, $LogFile | Out-Null
    }
    
    return $process
}

# Check if services are already running
$redisRunning = Get-Process -Name "redis-server" -ErrorAction SilentlyContinue
$kratosRunning = Get-Process -Name "kratos" -ErrorAction SilentlyContinue
$backendRunning = Get-NetTCPConnection -LocalPort 4000 -State Listen -ErrorAction SilentlyContinue

# Start Redis if not running
if (!$redisRunning) {
    if (Test-Path "C:\Redis\redis-server.exe") {
        Start-HiddenProcess -FilePath "C:\Redis\redis-server.exe" `
                           -WorkingDirectory "C:\Redis" `
                           -LogFile "$LogDir\redis.log"
        Start-Sleep -Seconds 2
    }
}

# Start Kratos if not running
if (!$kratosRunning) {
    if (Test-Path "C:\Kratos\kratos.exe") {
        Start-HiddenProcess -FilePath "C:\Kratos\kratos.exe" `
                           -Arguments "serve -c C:\Kratos\kratos.yaml" `
                           -WorkingDirectory "C:\Kratos" `
                           -LogFile "$LogDir\kratos.log"
        Start-Sleep -Seconds 3
    }
}

# Start Backend if not running
if (!$backendRunning) {
    if (Test-Path "C:\FlowSpace\backend") {
        Start-HiddenProcess -FilePath "node" `
                           -Arguments "dist/main.js" `
                           -WorkingDirectory "C:\FlowSpace\backend" `
                           -LogFile "$LogDir\backend.log"
        Start-Sleep -Seconds 3
    }
}

# Wait a moment for all services to stabilize
Start-Sleep -Seconds 2

exit 0
