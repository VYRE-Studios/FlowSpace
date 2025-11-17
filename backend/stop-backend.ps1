#!/usr/bin/env pwsh
# Stop all backend Node.js processes

Write-Host "Stopping backend processes..." -ForegroundColor Yellow
Write-Host ""

# Find node processes
$processes = Get-Process -Name "node" -ErrorAction SilentlyContinue

if (-not $processes) {
    Write-Host "[OK] No node processes found" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now run: npm run start:dev" -ForegroundColor Cyan
    exit 0
}

Write-Host "Found $($processes.Count) node process(es):" -ForegroundColor White
foreach ($proc in $processes) {
    Write-Host "  - PID: $($proc.Id) | Path: $($proc.Path)" -ForegroundColor Gray
}
Write-Host ""

# Try to stop processes
$stopped = 0
$failed = 0

foreach ($proc in $processes) {
    Write-Host "Attempting to stop PID $($proc.Id)..." -ForegroundColor Cyan
    try {
        Stop-Process -Id $proc.Id -Force -ErrorAction Stop
        Write-Host "  [OK] Stopped successfully" -ForegroundColor Green
        $stopped++
    } catch {
        $errorMsg = $_.Exception.Message
        if ($errorMsg -like "*Access is denied*") {
            Write-Host "  [!] Access denied - Process may need admin rights" -ForegroundColor Yellow
            Write-Host "      Try: Right-click PowerShell → Run as Administrator" -ForegroundColor Yellow
            Write-Host "      Or: Close the terminal window running the backend (Ctrl+C)" -ForegroundColor Yellow
        } else {
            Write-Host "  [!] Could not stop: $errorMsg" -ForegroundColor Yellow
        }
        $failed++
    }
}

Write-Host ""

if ($stopped -gt 0) {
    Write-Host "Waiting 2 seconds for files to unlock..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    Write-Host "[OK] Files should be unlocked now" -ForegroundColor Green
}

if ($failed -gt 0) {
    Write-Host ""
    Write-Host "Some processes could not be stopped." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternative solutions:" -ForegroundColor Cyan
    Write-Host "  1. Close the terminal window where backend is running (Ctrl+C)" -ForegroundColor White
    Write-Host "  2. Open Task Manager → Find 'node.exe' → End Task" -ForegroundColor White
    Write-Host "  3. Run PowerShell as Administrator and try again" -ForegroundColor White
    Write-Host ""
    Write-Host "After stopping processes, wait 2 seconds, then run:" -ForegroundColor Cyan
    Write-Host "  npm run start:dev" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "Done! You can now run: npm run start:dev" -ForegroundColor Cyan
}

