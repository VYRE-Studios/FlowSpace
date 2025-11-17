#!/usr/bin/env pwsh
# Kill SYSTEM-level node process (requires admin)

Write-Host "Attempting to kill SYSTEM-level node process..." -ForegroundColor Yellow
Write-Host "This requires Administrator privileges." -ForegroundColor Yellow
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[!] This script must be run as Administrator" -ForegroundColor Red
    Write-Host ""
    Write-Host "Right-click PowerShell → Run as Administrator" -ForegroundColor Yellow
    Write-Host "Then run this script again" -ForegroundColor Yellow
    exit 1
}

# Find node processes
$processes = Get-Process -Name "node" -ErrorAction SilentlyContinue

if (-not $processes) {
    Write-Host "[OK] No node processes found" -ForegroundColor Green
    exit 0
}

Write-Host "Found $($processes.Count) node process(es):" -ForegroundColor White
foreach ($proc in $processes) {
    $owner = (Get-WmiObject Win32_Process -Filter "ProcessId = $($proc.Id)").GetOwner()
    Write-Host "  - PID: $($proc.Id) | Owner: $($owner.Domain)\$($owner.User)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Attempting to kill all node processes..." -ForegroundColor Cyan

foreach ($proc in $processes) {
    try {
        Write-Host "Killing PID $($proc.Id)..." -ForegroundColor Yellow
        taskkill /F /PID $proc.Id
        Write-Host "  [OK] Killed" -ForegroundColor Green
    } catch {
        Write-Host "  [!] Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Waiting 3 seconds for ports to be released..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

Write-Host ""
Write-Host "Done! You can now run: npm run start:dev" -ForegroundColor Cyan

