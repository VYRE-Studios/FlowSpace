# Quick Push to GitHub - RedWoodOG

## Step 1: Create Repository on GitHub

1. Go to: https://github.com/new
2. Repository name: `FlowSpace`
3. Description: "Hybrid collaboration platform: Teams × Slack × Zoom"
4. Set to **Private** ⚠️
5. **DO NOT** initialize with README, .gitignore, or license
6. Click "Create repository"

## Step 2: Push to GitHub

Run this command in PowerShell:

```powershell
.\PUSH_TO_GITHUB.ps1
```

Or manually:

```powershell
# Add remote
git remote add origin https://github.com/RedWoodOG/FlowSpace.git

# Ensure branch is main
git branch -M main

# Push to GitHub
git push -u origin main
```

**Authentication:**
- When prompted, use a **Personal Access Token** (not password)
- Create token at: https://github.com/settings/tokens
- Select scope: `repo` (full control of private repositories)

## Step 3: Build Release Package

```powershell
.\package-for-github.ps1
```

## Step 4: Create GitHub Release

1. Go to: https://github.com/RedWoodOG/FlowSpace/releases/new
2. Tag: `v1.0.0`
3. Title: `FlowSpace v1.0.0 - Initial Release`
4. Upload: `releases/FlowSpace-v1.0.0-Windows-x64.zip`
5. Publish release

---

**That's it!** Your code will be on GitHub and ready to download. 🚀

