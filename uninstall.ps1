#!/usr/bin/env pwsh
# FlowSpace Uninstaller
# Removes FlowSpace services and files

param(
    [switch]$KeepData
)

$ErrorActionPreference = "Stop"

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "║           FlowSpace Uninstaller                          ║" -ForegroundColor Red
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""

# Check Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ This script requires Administrator privileges" -ForegroundColor Red
    exit 1
}

Write-Host "⚠️  WARNING: This will remove FlowSpace from your system" -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "Are you sure you want to uninstall FlowSpace? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Uninstall cancelled" -ForegroundColor Green
    exit 0
}

Write-Host ""
Write-Host "[1/5] Stopping FlowSpace services..." -ForegroundColor Cyan

# Stop services
$services = @("FlowSpaceBackend", "FlowSpaceKratos", "FlowSpaceRedis")
foreach ($svc in $services) {
    if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
        Write-Host "      Stopping $svc..." -ForegroundColor Yellow
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Write-Host "      ✓ $svc stopped" -ForegroundColor Green
    }
}

# Stop any remaining processes
Write-Host ""
Write-Host "[2/5] Stopping FlowSpace processes..." -ForegroundColor Cyan
$processes = @("node", "redis-server", "kratos", "client_flutter")
foreach ($proc in $processes) {
    $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
    if ($running) {
        Write-Host "      Stopping $proc..." -ForegroundColor Yellow
        Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
        Write-Host "      ✓ $proc stopped" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "[3/5] Removing Windows Services..." -ForegroundColor Cyan
foreach ($svc in $services) {
    if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
        Write-Host "      Removing $svc..." -ForegroundColor Yellow
        sc.exe delete $svc | Out-Null
        Write-Host "      ✓ $svc removed" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "[4/5] Removing desktop shortcuts..." -ForegroundColor Cyan
$shortcuts = @(
    "$env:USERPROFILE\Desktop\FlowSpace.lnk",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\FlowSpace.lnk"
)
foreach ($shortcut in $shortcuts) {
    if (Test-Path $shortcut) {
        Remove-Item -Path $shortcut -Force
        Write-Host "      ✓ Removed shortcut" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "[5/5] Removing FlowSpace files..." -ForegroundColor Cyan

if ($KeepData) {
    Write-Host "      ⊗ Keeping data (use -KeepData:$false to remove)" -ForegroundColor Yellow
} else {
    # Remove FlowSpace directory
    if (Test-Path "C:\FlowSpace") {
        Write-Host "      Removing C:\FlowSpace..." -ForegroundColor Yellow
        Remove-Item -Path "C:\FlowSpace" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "      ✓ FlowSpace directory removed" -ForegroundColor Green
    }
    
    # Remove Kratos config
    $removeKratos = Read-Host "      Remove Kratos config (C:\Kratos)? (y/n)"
    if ($removeKratos -eq 'y') {
        if (Test-Path "C:\Kratos") {
            Remove-Item -Path "C:\Kratos" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "      ✓ Kratos config removed" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ FlowSpace uninstalled successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Note: Database data in PostgreSQL was NOT removed." -ForegroundColor Yellow
Write-Host "To remove databases manually:" -ForegroundColor Yellow
Write-Host "  psql -U postgres -c 'DROP DATABASE flowspace;'" -ForegroundColor White
Write-Host "  psql -U postgres -c 'DROP DATABASE flowspace_identity;'" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to exit"
