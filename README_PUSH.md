# Push FlowSpace to GitHub - Quick Guide

## Step 1: Create Repository on GitHub

**IMPORTANT: Do this first!**

1. Go to: **https://github.com/new**
2. Repository name: `FlowSpace`
3. Description: "Hybrid collaboration platform: Teams × Slack × Zoom"
4. Set to **Private** ⚠️
5. **DO NOT** check any boxes (no README, .gitignore, or license)
6. Click **"Create repository"**

## Step 2: Push to GitHub

After creating the repository, run:

```powershell
cd c:\FlowSpace
.\PUSH_TO_GITHUB.ps1
```

Or manually:

```powershell
cd c:\FlowSpace

# Add remote
git remote add origin https://github.com/RedWoodOG/FlowSpace.git

# Ensure branch is main
git branch -M main

# Push to GitHub
git push -u origin main
```

**When prompted for credentials:**
- Username: `RedWoodOG`
- Password: Use a **Personal Access Token** (not your GitHub password)
  - Create token: https://github.com/settings/tokens
  - Click "Generate new token (classic)"
  - Select scope: `repo` (full control of private repositories)
  - Copy the token and use it as the password

## Step 3: Build Release Package

```powershell
cd c:\FlowSpace
.\package-for-github.ps1
```

## Step 4: Create GitHub Release

1. Go to: https://github.com/RedWoodOG/FlowSpace/releases/new
2. Tag: `v1.0.0`
3. Title: `FlowSpace v1.0.0 - Initial Release`
4. Upload: `releases/FlowSpace-v1.0.0-Windows-x64.zip`
5. Click **"Publish release"**

---

**That's it!** Your code will be on GitHub and ready to download. 🚀

