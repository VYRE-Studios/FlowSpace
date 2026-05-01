param([switch]$Uninstall)

$ErrorActionPreference = "Stop"

Write-Host "FlowSpace Service Manager" -ForegroundColor Cyan
Write-Host ""

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script requires Administrator privileges" -ForegroundColor Red
    exit 1
}

if ($Uninstall) {
    Write-Host "Uninstalling FlowSpace services..." -ForegroundColor Yellow
    $services = @("FlowSpaceRedis", "FlowSpaceKratos", "FlowSpaceBackend")
    foreach ($svc in $services) {
        if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
            Write-Host "Removing service: $svc" -ForegroundColor Cyan
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            sc.exe delete $svc | Out-Null
            Write-Host "  OK: $svc removed" -ForegroundColor Green
        }
    }
    Write-Host ""
    Write-Host "Services uninstalled" -ForegroundColor Green
    exit 0
}

Write-Host "Installing FlowSpace as Windows Services..." -ForegroundColor Cyan
Write-Host ""

$wrapperDir = "C:\FlowSpace\service-wrappers"
New-Item -ItemType Directory -Path $wrapperDir -Force | Out-Null

$redisWrapper = "@echo off`r`n`"C:\Redis\redis-server.exe`""
Set-Content -Path "$wrapperDir\redis-wrapper.bat" -Value $redisWrapper

$kratosWrapper = "@echo off`r`ncd /d C:\Kratos`r`nkratos.exe serve -c kratos.yaml"
Set-Content -Path "$wrapperDir\kratos-wrapper.bat" -Value $kratosWrapper

$backendWrapper = "@echo off`r`ncd /d C:\FlowSpace\backend`r`nnode dist/main.js"
Set-Content -Path "$wrapperDir\backend-wrapper.bat" -Value $backendWrapper

function New-FlowSpaceService {
    param([string]$Name, [string]$DisplayName, [string]$Description, [string]$BinaryPath, [string[]]$DependsOn = @())
    
    Write-Host "Creating service: $DisplayName" -ForegroundColor Cyan
    
    if (Get-Service -Name $Name -ErrorAction SilentlyContinue) {
        Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue
        sc.exe delete $Name | Out-Null
        Start-Sleep -Seconds 1
    }
    
    if ($DependsOn.Count -gt 0) {
        $depString = $DependsOn -join "/"
        sc.exe create $Name binPath= $BinaryPath start= auto DisplayName= $DisplayName depend= $depString | Out-Null
    } else {
        sc.exe create $Name binPath= $BinaryPath start= auto DisplayName= $DisplayName | Out-Null
    }
    
    sc.exe description $Name $Description | Out-Null
    sc.exe failure $Name reset= 86400 actions= restart/5000/restart/10000/restart/30000 | Out-Null
    
    Write-Host "  OK: $DisplayName created" -ForegroundColor Green
}

Write-Host "[1/3] Installing Redis service..." -ForegroundColor Cyan
if (Test-Path "C:\Redis\redis-server.exe") {
    New-FlowSpaceService -Name "FlowSpaceRedis" -DisplayName "FlowSpace Redis" -Description "Redis cache for FlowSpace" -BinaryPath "C:\FlowSpace\service-wrappers\redis-wrapper.bat"
} else {
    Write-Host "  WARNING: Redis not found at C:\Redis\redis-server.exe" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[2/3] Installing Kratos service..." -ForegroundColor Cyan
if (Test-Path "C:\Kratos\kratos.exe") {
    New-FlowSpaceService -Name "FlowSpaceKratos" -DisplayName "FlowSpace Kratos" -Description "Authentication service for FlowSpace" -BinaryPath "C:\FlowSpace\service-wrappers\kratos-wrapper.bat" -DependsOn @("FlowSpaceRedis")
} else {
    Write-Host "  WARNING: Kratos not found at C:\Kratos\kratos.exe" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[3/3] Installing Backend service..." -ForegroundColor Cyan
if (Test-Path "C:\FlowSpace\backend") {
    New-FlowSpaceService -Name "FlowSpaceBackend" -DisplayName "FlowSpace Backend" -Description "Backend API for FlowSpace" -BinaryPath "C:\FlowSpace\service-wrappers\backend-wrapper.bat" -DependsOn @("FlowSpaceRedis", "FlowSpaceKratos")
} else {
    Write-Host "  WARNING: Backend not found at C:\FlowSpace\backend" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Starting services..." -ForegroundColor Cyan
$services = @("FlowSpaceRedis", "FlowSpaceKratos", "FlowSpaceBackend")
foreach ($svc in $services) {
    if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
        Start-Service -Name $svc -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        $status = (Get-Service -Name $svc).Status
        if ($status -eq "Running") {
            Write-Host "  OK: $svc started" -ForegroundColor Green
        } else {
            Write-Host "  WARNING: $svc failed to start (status: $status)" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "FlowSpace services installed!" -ForegroundColor Green
Write-Host ""
Write-Host "Services will now start automatically with Windows." -ForegroundColor White
Write-Host ""
Write-Host "To manage services:" -ForegroundColor Cyan
Write-Host "  View: services.msc" -ForegroundColor White
Write-Host "  Uninstall: .\install-services.ps1 -Uninstall" -ForegroundColor White
Write-Host ""
