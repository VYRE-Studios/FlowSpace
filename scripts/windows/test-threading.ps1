#!/usr/bin/env pwsh
# Quick Test Script for Message Threading
# This tests the backend API directly

Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "         Testing Message Threading Feature                  " -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

# Check if backend is running
Write-Host "Checking if backend is running..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:4000/api/v1" -Method GET -TimeoutSec 2 -ErrorAction Stop
    Write-Host "[OK] Backend is running" -ForegroundColor Green
} catch {
    Write-Host "[X] Backend is not running on port 4000" -ForegroundColor Red
    Write-Host "    Start it with: cd backend && npm run start:dev" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "Test 1: Check Database Schema" -ForegroundColor Yellow
Write-Host "=============================================================" -ForegroundColor Cyan

# Check if we can connect to database (indirect test)
Write-Host "Backend should have auto-synced the schema on startup." -ForegroundColor White
Write-Host "Check the backend logs for:" -ForegroundColor White
Write-Host "  - 'Auto-syncing database schema...'" -ForegroundColor Cyan
Write-Host "  - 'Database schema synchronized' OR 'Already in sync'" -ForegroundColor Cyan
Write-Host "  - 'Database ready'" -ForegroundColor Cyan
Write-Host ""

$check = Read-Host "Did you see those messages in backend logs? (y/n)"
if ($check -eq "y" -or $check -eq "Y") {
    Write-Host "[OK] Database schema sync working" -ForegroundColor Green
} else {
    Write-Host "[!] Check backend logs - schema sync might have issues" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "Test 2: Manual UI Testing" -ForegroundColor Yellow
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Now test in the Flutter app:" -ForegroundColor White
Write-Host ""
Write-Host "1. Open Flutter app" -ForegroundColor Cyan
Write-Host "2. Select a channel" -ForegroundColor Cyan
Write-Host "3. Send a message: 'Hello, testing threading'" -ForegroundColor Cyan
Write-Host "4. Click the REPLY icon (↩️) on that message" -ForegroundColor Cyan
Write-Host "5. You should see 'Replying to [sender]' banner" -ForegroundColor Cyan
Write-Host "6. Type: 'This is a reply' and send" -ForegroundColor Cyan
Write-Host "7. Reply should appear INDENTED under the original" -ForegroundColor Cyan
Write-Host "8. Original message should show '1 reply' button" -ForegroundColor Cyan
Write-Host "9. Click the button to collapse/expand the thread" -ForegroundColor Cyan
Write-Host ""

$test = Read-Host "Did the reply appear indented? (y/n)"
if ($test -eq "y" -or $test -eq "Y") {
    Write-Host "[OK] Threading UI working!" -ForegroundColor Green
} else {
    Write-Host "[X] Threading UI not working - check:" -ForegroundColor Red
    Write-Host "    - Backend logs for errors" -ForegroundColor Yellow
    Write-Host "    - Flutter console for errors" -ForegroundColor Yellow
    Write-Host "    - Hot reload Flutter app (press 'r')" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "Test 3: Multiple Replies" -ForegroundColor Yellow
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Test multiple replies:" -ForegroundColor White
Write-Host "1. Reply to the same message 2-3 more times" -ForegroundColor Cyan
Write-Host "2. All replies should appear under the parent" -ForegroundColor Cyan
Write-Host "3. Reply count should update (e.g., '3 replies')" -ForegroundColor Cyan
Write-Host ""

$multi = Read-Host "Do multiple replies work? (y/n)"
if ($multi -eq "y" -or $multi -eq "Y") {
    Write-Host "[OK] Multiple replies working!" -ForegroundColor Green
} else {
    Write-Host "[!] Multiple replies not working" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "Test 4: Persistence" -ForegroundColor Yellow
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Test that threads persist:" -ForegroundColor White
Write-Host "1. Create some threaded messages" -ForegroundColor Cyan
Write-Host "2. Close and restart Flutter app" -ForegroundColor Cyan
Write-Host "3. Open the same channel" -ForegroundColor Cyan
Write-Host "4. Threads should still be there" -ForegroundColor Cyan
Write-Host ""

$persist = Read-Host "Do threads persist after restart? (y/n)"
if ($persist -eq "y" -or $persist -eq "Y") {
    Write-Host "[OK] Persistence working!" -ForegroundColor Green
} else {
    Write-Host "[!] Persistence might have issues" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Yellow
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

$allTests = @(
    @{Name="Database Sync"; Result=$check},
    @{Name="Threading UI"; Result=$test},
    @{Name="Multiple Replies"; Result=$multi},
    @{Name="Persistence"; Result=$persist}
)

$passed = 0
$total = $allTests.Count

foreach ($testItem in $allTests) {
    if ($testItem.Result -eq "y" -or $testItem.Result -eq "Y") {
        Write-Host "[OK] $($testItem.Name)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "[!] $($testItem.Name)" -ForegroundColor Yellow
    }
}

Write-Host ""
if ($passed -eq $total) {
    Write-Host "🎉 ALL TESTS PASSED! Phase 1 is complete!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some tests need attention. Check the issues above." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "For detailed testing guide, see: TEST_THREADING.md" -ForegroundColor Cyan
Write-Host ""

