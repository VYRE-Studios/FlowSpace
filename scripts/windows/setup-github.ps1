# FlowSpace - Setup GitHub Repository
# This script initializes git and prepares the repository for GitHub

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FlowSpace - GitHub Repository Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if git is installed
Write-Host "Checking Git installation..." -ForegroundColor Yellow
$gitPath = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitPath) {
    Write-Host "ERROR: Git is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Git from https://git-scm.com/" -ForegroundColor Yellow
    exit 1
}

# Check if already a git repository
if (Test-Path ".git") {
    Write-Host "Git repository already initialized." -ForegroundColor Yellow
    $response = Read-Host "Do you want to reinitialize? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "Skipping git initialization." -ForegroundColor Yellow
    } else {
        Write-Host "Reinitializing git repository..." -ForegroundColor Yellow
        Remove-Item -Path ".git" -Recurse -Force -ErrorAction SilentlyContinue
        git init
    }
} else {
    Write-Host "Initializing git repository..." -ForegroundColor Yellow
    git init
}

# Create/update .gitignore
Write-Host "Updating .gitignore..." -ForegroundColor Yellow
$gitignoreContent = @"
# Service logs
logs/
*.log
backend-startup.log
backend-test.log
flutter_debug.log

# Node
node_modules/
dist/
.env
.env.local
.env.*.local

# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
build/
*.iml

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
desktop.ini

# Database
*.db
*.sqlite
*.sqlite3

# Prisma
prisma/migrations/.migration_lock
backend/prisma/migrations/

# Build artifacts
releases/
*.zip
*.exe
!installer/*.exe
!service-wrappers/*.exe

# Temp
tmp/
temp/
*.tmp

# User data
FlowSpaceApp/
FlowSpace-USB-Installer/

# Screenshots
*.png
!assets/**/*.png
!docs/**/*.png

# Installer builds (keep scripts, ignore outputs)
installer/*.exe
installer/FLO-Portable/
installer/deps/

# Backend builds
backend/dist/
backend/build/
backend/startup.log

# Test outputs
test-results/
coverage/
"@

Set-Content -Path ".gitignore" -Value $gitignoreContent

# Create initial commit
Write-Host "Creating initial commit..." -ForegroundColor Yellow
git add .
git commit -m "Initial commit: FlowSpace v1.0.0" -m "Complete FlowSpace application with Flutter client and NestJS backend" 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "Initial commit created successfully." -ForegroundColor Green
} else {
    Write-Host "Note: No changes to commit or commit already exists." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Git Repository Ready!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps to push to GitHub:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Create a new private repository on GitHub:" -ForegroundColor White
Write-Host "   - Go to https://github.com/new" -ForegroundColor Gray
Write-Host "   - Name it 'FlowSpace' (or your preferred name)" -ForegroundColor Gray
Write-Host "   - Set it to Private" -ForegroundColor Gray
Write-Host "   - DO NOT initialize with README, .gitignore, or license" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Add the remote and push:" -ForegroundColor White
Write-Host "   git remote add origin https://github.com/YOUR_USERNAME/FlowSpace.git" -ForegroundColor Cyan
Write-Host "   git branch -M main" -ForegroundColor Cyan
Write-Host "   git push -u origin main" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Create a release:" -ForegroundColor White
Write-Host "   - Run: .\package-for-github.ps1" -ForegroundColor Cyan
Write-Host "   - Go to GitHub > Releases > Draft a new release" -ForegroundColor Gray
Write-Host "   - Upload the ZIP file from releases/ folder" -ForegroundColor Gray
Write-Host ""

