# PowerShell script to run Flutter with error capture
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  FlowSpace - Development Mode" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $PSScriptRoot

Write-Host "Starting Flutter app..." -ForegroundColor Yellow
Write-Host ""

try {
    # Run Flutter and capture output
    flutter run -d windows 2>&1 | Tee-Object -FilePath "flutter-output.log"
    
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Green
    Write-Host "Flutter exited successfully" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Red
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Full error details:" -ForegroundColor Yellow
    Write-Host $_.Exception -ForegroundColor Red
} finally {
    Write-Host ""
    Write-Host "Output saved to: flutter-output.log" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

