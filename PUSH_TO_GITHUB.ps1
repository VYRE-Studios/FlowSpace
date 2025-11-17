# FlowSpace - Push to GitHub
# This script helps you push FlowSpace to your GitHub repository

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FlowSpace - Push to GitHub" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if git is installed
$gitPath = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitPath) {
    Write-Host "ERROR: Git is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check git config
$gitEmail = git config user.email
$gitName = git config user.name
if (-not $gitEmail -or -not $gitName) {
    Write-Host "Git user identity not configured." -ForegroundColor Yellow
    Write-Host "Setting up git config for this repository..." -ForegroundColor Yellow
    git config user.email "jwhite3321@live.com"
    git config user.name "RedWoodOG"
    Write-Host "Git config set!" -ForegroundColor Green
}

# Check if already has remote
$remote = $null
try {
    $remote = git remote get-url origin 2>$null
} catch {
    $remote = $null
}
if ($remote) {
    Write-Host "Current remote: $remote" -ForegroundColor Yellow
    $response = Read-Host "Do you want to change it? (y/N)"
    if ($response -eq "y" -or $response -eq "Y") {
        git remote remove origin
    } else {
        Write-Host "Using existing remote." -ForegroundColor Green
        $skipRemote = $true
    }
}

if (-not $skipRemote) {
    # Add remote
    $username = "RedWoodOG"
    $repoName = Read-Host "Repository name (default: FlowSpace)"
    if ([string]::IsNullOrWhiteSpace($repoName)) {
        $repoName = "FlowSpace"
    }
    
    $remoteUrl = "https://github.com/$username/$repoName.git"
    Write-Host "Adding remote: $remoteUrl" -ForegroundColor Yellow
    git remote add origin $remoteUrl
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to add remote" -ForegroundColor Red
        exit 1
    }
}

# Check current branch
$currentBranch = git branch --show-current
Write-Host "Current branch: $currentBranch" -ForegroundColor Yellow

# Rename to main if needed
if ($currentBranch -ne "main") {
    Write-Host "Renaming branch to 'main'..." -ForegroundColor Yellow
    git branch -M main
}

# Check if there are uncommitted changes
$status = git status --porcelain
if ($status) {
    Write-Host "Warning: You have uncommitted changes:" -ForegroundColor Yellow
    Write-Host $status -ForegroundColor Gray
    $response = Read-Host "Do you want to commit them first? (y/N)"
    if ($response -eq "y" -or $response -eq "Y") {
        $message = Read-Host "Commit message (default: Update)"
        if ([string]::IsNullOrWhiteSpace($message)) {
            $message = "Update"
        }
        git add .
        git commit -m $message
    }
}

# Push to GitHub
Write-Host ""
Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
Write-Host "Note: You may be prompted for credentials." -ForegroundColor Cyan
Write-Host "Use a Personal Access Token (not password) if prompted." -ForegroundColor Cyan
Write-Host ""

git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Successfully pushed to GitHub!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Repository URL: https://github.com/RedWoodOG/$repoName" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Build release package: .\package-for-github.ps1" -ForegroundColor White
    Write-Host "2. Create a release on GitHub and upload the ZIP file" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "ERROR: Failed to push to GitHub" -ForegroundColor Red
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "- Authentication failed: Use Personal Access Token" -ForegroundColor White
    Write-Host "  Create one at: https://github.com/settings/tokens" -ForegroundColor Gray
    Write-Host "- Repository doesn't exist: Create it at https://github.com/new" -ForegroundColor White
    Write-Host "- Network issues: Check your internet connection" -ForegroundColor White
    Write-Host ""
}

