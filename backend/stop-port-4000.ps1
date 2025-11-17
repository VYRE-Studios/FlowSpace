#!/usr/bin/env pwsh
# Stop process using port 4000

Write-Host "Finding process using port 4000..." -ForegroundColor Yellow

# Find process using port 4000
$process = Get-NetTCPConnection -LocalPort 4000 -ErrorAction SilentlyContinue | 
    Select-Object -ExpandProperty OwningProcess -Unique

if ($process) {
    Write-Host "Found process PID: $process" -ForegroundColor Cyan
    
    try {
        $procInfo = Get-Process -Id $process -ErrorAction SilentlyContinue
        if ($procInfo) {
            Write-Host "Process: $($procInfo.ProcessName) | Path: $($procInfo.Path)" -ForegroundColor Gray
        }
        
        Stop-Process -Id $process -Force -ErrorAction Stop
        Write-Host "[OK] Stopped process on port 4000" -ForegroundColor Green
        Write-Host ""
        Write-Host "Waiting 2 seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        Write-Host "[OK] Port 4000 is now free" -ForegroundColor Green
    } catch {
        Write-Host "[!] Could not stop process: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Try:" -ForegroundColor Yellow
        Write-Host "  1. Open Task Manager" -ForegroundColor White
        Write-Host "  2. Find process with PID $process" -ForegroundColor White
        Write-Host "  3. End Task" -ForegroundColor White
    }
} else {
    Write-Host "[OK] No process found on port 4000" -ForegroundColor Green
}

Write-Host ""
Write-Host "You can now run: npm run start:dev" -ForegroundColor Cyan

