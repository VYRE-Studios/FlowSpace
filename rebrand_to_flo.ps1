# FLŌ Rebranding Script - PowerShell
# This script updates all FlowSpace references to FLŌ

param(
    [string]$ProjectPath = "C:\FlowSpace\client_flutter"
)

Write-Host "Starting FLŌ rebranding process..." -ForegroundColor Green

# Step 1: Create core/theme directories if they don't exist
New-Item -ItemType Directory -Force -Path "$ProjectPath\lib\core\theme"
New-Item -ItemType Directory -Force -Path "$ProjectPath\lib\ui\widgets"

# Step 2: Copy theme files
Write-Host "Copying FLŌ theme files..." -ForegroundColor Yellow
Copy-Item "C:\Users\jwhit\flo_theme.dart" "$ProjectPath\lib\core\theme\" -Force
Copy-Item "C:\Users\jwhit\flo_brand.dart" "$ProjectPath\lib\core\theme\" -Force
Copy-Item "C:\Users\jwhit\flo_components.dart" "$ProjectPath\lib\ui\widgets\" -Force

# Step 3: Update main.dart
Write-Host "Updating main.dart..." -ForegroundColor Yellow
$mainContent = Get-Content "$ProjectPath\lib\main.dart" -Raw
$mainContent = $mainContent -replace "title: 'Flowspace'", "title: 'FLŌ'"
$mainContent = $mainContent -replace "title: 'FlowSpace'", "title: 'FLŌ'"
Set-Content "$ProjectPath\lib\main.dart" $mainContent

# Step 4: Update pubspec.yaml
Write-Host "Updating pubspec.yaml..." -ForegroundColor Yellow
$pubspecContent = Get-Content "$ProjectPath\pubspec.yaml" -Raw
$pubspecContent = $pubspecContent -replace "name: client_flutter", "name: flo_app"
$pubspecContent = $pubspecContent -replace "description: `"A new Flutter project.`"", "description: `"FLŌ - The Unified Operations Core`""
Set-Content "$ProjectPath\pubspec.yaml" $pubspecContent

# Step 5: Create assets directories
New-Item -ItemType Directory -Force -Path "$ProjectPath\assets\images"
New-Item -ItemType Directory -Force -Path "$ProjectPath\assets\fonts"

# Step 6: Update Windows app name
Write-Host "Updating Windows app configuration..." -ForegroundColor Yellow
$windowsConfig = "$ProjectPath\windows\runner\Runner.rc"
if (Test-Path $windowsConfig) {
    $content = Get-Content $windowsConfig -Raw
    $content = $content -replace "FlowSpace", "FLŌ"
    $content = $content -replace "Flowspace", "FLŌ"
    Set-Content $windowsConfig $content
}

# Step 7: Update all Dart files
Write-Host "Updating all Dart files..." -ForegroundColor Yellow
Get-ChildItem -Path "$ProjectPath\lib" -Filter "*.dart" -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    
    # Replace FlowSpace/Flowspace with FLŌ
    $content = $content -replace "FlowSpace", "FLŌ"
    $content = $content -replace "Flowspace", "FLŌ"
    $content = $content -replace "flowspace", "flo"
    
    # Replace old theme imports
    $content = $content -replace "import '.*theme\.dart';", "import '../../core/theme/flo_theme.dart';"
    
    # Replace old color references
    $content = $content -replace "flowCyan", "FloTheme.floPrimary"
    $content = $content -replace "flowBlue", "FloTheme.floPrimary"
    $content = $content -replace "Colors\.cyan", "FloTheme.floAccent"
    
    Set-Content $_.FullName $content
}

# Step 8: Create FLŌ icon as placeholder
Write-Host "Creating placeholder FLŌ icon..." -ForegroundColor Yellow
@"
// Placeholder for FLŌ icon
// Replace with actual FLŌ logo files:
// - assets/images/flo_logo.png (512x512)
// - assets/images/flo_logo_white.png
// - windows/runner/resources/app_icon.ico
"@ | Out-File "$ProjectPath\assets\images\README_ICONS.txt"

# Step 9: Update NSIS installer script
Write-Host "Updating NSIS installer configuration..." -ForegroundColor Yellow
$nsisPath = "$ProjectPath\installer\flowspace-installer.nsi"
if (Test-Path $nsisPath) {
    $nsisContent = Get-Content $nsisPath -Raw
    $nsisContent = $nsisContent -replace "Flowspace", "FLŌ"
    $nsisContent = $nsisContent -replace "FlowSpace", "FLŌ"
    $nsisContent = $nsisContent -replace "PRODUCT_NAME `".*`"", 'PRODUCT_NAME "FLŌ"'
    Set-Content $nsisPath $nsisContent
}

Write-Host "`nFLŌ rebranding complete!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Add Inter font files to assets/fonts/"
Write-Host "2. Create FLŌ logo files:"
Write-Host "   - assets/images/flo_logo.png"
Write-Host "   - windows/runner/resources/app_icon.ico"
Write-Host "3. Update pubspec.yaml to include fonts and assets"
Write-Host "4. Run: flutter pub get"
Write-Host "5. Run: flutter build windows --release"
Write-Host "6. Build NSIS installer"