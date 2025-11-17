# Add Windows Firewall rule for FLO P2P
# This allows UDP traffic on port 33445 for P2P messaging

Write-Host "Adding Windows Firewall rule for FLO P2P..." -ForegroundColor Cyan

# Check if rule already exists
$existingRule = Get-NetFirewallRule -DisplayName "FLO P2P" -ErrorAction SilentlyContinue

if ($existingRule) {
    Write-Host "Firewall rule 'FLO P2P' already exists." -ForegroundColor Green
    Write-Host "Rule details:" -ForegroundColor Yellow
    Get-NetFirewallRule -DisplayName "FLO P2P" | Format-List DisplayName, Direction, Action, Enabled
} else {
    # Add inbound rule for UDP port 33445
    New-NetFirewallRule `
        -DisplayName "FLO P2P" `
        -Direction Inbound `
        -Protocol UDP `
        -LocalPort 33445 `
        -Action Allow `
        -Profile Any `
        -Description "Allow FLO peer-to-peer messaging on UDP port 33445"
    
    Write-Host "✅ Firewall rule added successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "FLO P2P can now communicate on UDP port 33445" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "You can now run: dart run lib/test/p2p_test_main.dart" -ForegroundColor Yellow
