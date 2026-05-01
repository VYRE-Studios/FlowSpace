# GitHub Setup Guide

This guide will help you package FlowSpace and push it to your private GitHub repository.

## Prerequisites

- Git installed and configured
- GitHub account
- Flutter SDK installed (for building)

## Step 1: Setup Git Repository

Run the setup script to initialize git and prepare the repository:

```powershell
.\setup-github.ps1
```

This will:
- Initialize a git repository (if not already done)
- Create/update `.gitignore` with appropriate exclusions
- Create an initial commit

## Step 2: Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `FlowSpace` (or your preferred name)
3. Description: "Hybrid collaboration platform: Teams × Slack × Zoom"
4. Set to **Private**
5. **DO NOT** initialize with README, .gitignore, or license (we already have these)
6. Click "Create repository"

## Step 3: Push to GitHub

After creating the repository, GitHub will show you commands. Use these:

```powershell
# Add your GitHub repository as remote (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/FlowSpace.git

# Rename branch to main (if needed)
git branch -M main

# Push to GitHub
git push -u origin main
```

If you need to authenticate:
- Use a Personal Access Token (PAT) instead of password
- Create one at: https://github.com/settings/tokens
- Select scopes: `repo` (full control of private repositories)

## Step 4: Build Release Package

Build the Windows release package:

```powershell
.\package-for-github.ps1
```

This will:
- Clean previous builds
- Get Flutter dependencies
- Build Windows release
- Create a ZIP archive in `releases/` folder

## Step 5: Create GitHub Release

1. Go to your repository on GitHub
2. Click "Releases" → "Draft a new release"
3. Tag version: `v1.0.0`
4. Release title: `FlowSpace v1.0.0`
5. Description:
   ```markdown
   ## FlowSpace v1.0.0 - Initial Release
   
   ### Features
   - Real-time messaging with threading
   - Workspace management
   - Project management with Kanban boards
   - File vault with encryption
   - Settings and preferences
   
   ### Installation
   1. Download `FlowSpace-v1.0.0-Windows-x64.zip`
   2. Extract to a folder
   3. Run `FlowSpace.exe`
   ```
6. Attach the ZIP file from `releases/FlowSpace-v1.0.0-Windows-x64.zip`
7. Click "Publish release"

## Step 6: Future Updates

For future releases:

```powershell
# Make your changes
# ...

# Commit changes
git add .
git commit -m "Description of changes"

# Push to GitHub
git push

# Build new release
.\package-for-github.ps1 -Version "1.0.1" -BuildNumber "2"

# Create new release on GitHub with the new ZIP file
```

## Repository Structure

```
FlowSpace/
├── backend/              # NestJS backend services
├── client_flutter/       # Flutter desktop application
├── service-wrappers/     # Windows service wrappers
├── docs/                 # Documentation
├── releases/             # Built release packages (gitignored)
├── .gitignore           # Git ignore rules
├── README.md            # Main documentation
└── package-for-github.ps1  # Build script
```

## Notes

- The `releases/` folder is gitignored - don't commit built packages
- Build artifacts are excluded from git
- User data and logs are excluded
- Only source code and configuration files are tracked

## Troubleshooting

### Git Authentication Issues
- Use Personal Access Token instead of password
- Or use SSH keys: `git remote set-url origin git@github.com:USERNAME/FlowSpace.git`

### Build Fails
- Ensure Flutter is installed: `flutter doctor`
- Check all dependencies: `flutter pub get`
- Clean build: `flutter clean`

### Large File Issues
- The repository should be < 100MB (excluding releases)
- If too large, check `.gitignore` is working
- Use Git LFS for large assets if needed

