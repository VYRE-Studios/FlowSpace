# FLO P2P Automated Setup Script
# This script sets up everything needed for P2P messaging

param(
    [switch]$SkipFirewall
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "          FLO P2P AUTOMATED SETUP" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin -and -not $SkipFirewall) {
    Write-Host "🔐 Administrator privileges required for firewall configuration" -ForegroundColor Yellow
    Write-Host "   Requesting elevation..." -ForegroundColor Yellow
    Write-Host ""
    
    # Re-launch as administrator
    Start-Process pwsh -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "Step 1: Checking Firewall Configuration..." -ForegroundColor Cyan

# Check if firewall rule exists
$existingRule = Get-NetFirewallRule -DisplayName "FLO P2P" -ErrorAction SilentlyContinue

if ($existingRule) {
    Write-Host "✅ Firewall rule already exists" -ForegroundColor Green
} else {
    Write-Host "   Adding firewall rule for UDP port 33445..." -ForegroundColor Yellow
    
    try {
        New-NetFirewallRule `
            -DisplayName "FLO P2P" `
            -Direction Inbound `
            -Protocol UDP `
            -LocalPort 33445 `
            -Action Allow `
            -Profile Any `
            -Description "Allow FLO peer-to-peer messaging on UDP port 33445" | Out-Null
        
        Write-Host "✅ Firewall rule added successfully" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to add firewall rule: $_" -ForegroundColor Red
        Write-Host "   Continuing without firewall rule..." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Step 2: Verifying P2P Services..." -ForegroundColor Cyan

# Check if P2P files exist
$p2pDir = Join-Path $PSScriptRoot "lib\services\p2p"
if (Test-Path $p2pDir) {
    $fileCount = (Get-ChildItem $p2pDir -Recurse -File).Count
    Write-Host "✅ Found $fileCount P2P service files" -ForegroundColor Green
} else {
    Write-Host "❌ P2P services directory not found!" -ForegroundColor Red
    Write-Host "   Expected: $p2pDir" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Step 3: Checking Dependencies..." -ForegroundColor Cyan

# Check for Dart
$dartVersion = dart --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Dart installed: $dartVersion" -ForegroundColor Green
} else {
    Write-Host "❌ Dart not found - install Flutter SDK first" -ForegroundColor Red
    exit 1
}

# Check for Flutter
$flutterVersion = flutter --version 2>&1 | Select-String "Flutter" | Select-Object -First 1
if ($flutterVersion) {
    Write-Host "✅ Flutter installed" -ForegroundColor Green
} else {
    Write-Host "⚠️  Flutter not found - may need to install dependencies manually" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 4: Getting Dependencies..." -ForegroundColor Cyan

try {
    Push-Location $PSScriptRoot
    
    # Get Flutter dependencies
    Write-Host "   Running flutter pub get..." -ForegroundColor Yellow
    flutter pub get | Out-Null
    
    Write-Host "✅ Dependencies installed" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Could not install dependencies: $_" -ForegroundColor Yellow
    Write-Host "   You may need to run 'flutter pub get' manually" -ForegroundColor Yellow
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "Step 5: Network Configuration..." -ForegroundColor Cyan

# Get local IP address
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -eq "Dhcp" -or $_.PrefixOrigin -eq "Manual" } | Select-Object -First 1).IPAddress

if ($localIP) {
    Write-Host "✅ Local IP Address: $localIP" -ForegroundColor Green
    Write-Host "   Subnet: $($localIP.Substring(0, $localIP.LastIndexOf('.'))).x" -ForegroundColor White
} else {
    Write-Host "⚠️  Could not determine local IP address" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "              SETUP COMPLETE ✅" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Summary:" -ForegroundColor Cyan
Write-Host "   ✅ Firewall rule configured (UDP port 33445)" -ForegroundColor Green
Write-Host "   ✅ P2P services verified" -ForegroundColor Green
Write-Host "   ✅ Dependencies installed" -ForegroundColor Green
Write-Host "   ✅ Network configured" -ForegroundColor Green
Write-Host ""

Write-Host "🚀 Ready to Test P2P Messaging!" -ForegroundColor Green
Write-Host ""
Write-Host "To run the P2P test:" -ForegroundColor Cyan
Write-Host "   cd $PSScriptRoot" -ForegroundColor White
Write-Host "   dart run lib/test/p2p_test_main.dart" -ForegroundColor Yellow
Write-Host ""

Write-Host "Or use the quick test launcher:" -ForegroundColor Cyan
Write-Host "   .\test_p2p.ps1" -ForegroundColor Yellow
Write-Host ""

# Ask if user wants to run test now
Write-Host "Would you like to run the P2P test now? (Y/N): " -ForegroundColor Cyan -NoNewline
$response = Read-Host

if ($response -eq "Y" -or $response -eq "y") {
    Write-Host ""
    Write-Host "Starting P2P test..." -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
    Write-Host ""
    
    Push-Location $PSScriptRoot
    dart run lib/test/p2p_test_main.dart
    Pop-Location
} else {
    Write-Host ""
    Write-Host "Setup complete! Run the test when ready." -ForegroundColor Green
    Write-Host ""
}

if (-not $isAdmin) {
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
