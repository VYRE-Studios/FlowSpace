# FlowSpace USB Installer - Quick Reference

## 📦 Package Created Successfully!

**Location:** `C:\FlowSpace\FlowSpace-USB-Installer`  
**Size:** ~446 MB (25,111 files)  
**Status:** ✅ Ready for USB deployment

---

## 🚀 Quick Deploy Workflow

### Step 1: Prepare USB Drive
```powershell
# Insert USB drive (e.g., D:)
Copy-Item -Path "C:\FlowSpace\FlowSpace-USB-Installer\*" -Destination "D:\" -Recurse
```

### Step 2: On Target Machine
```powershell
# Open PowerShell as Administrator
D:
.\INSTALL.ps1
```

### Step 3: Follow Prompts
- Install dependencies if prompted
- Confirm installation locations
- Let script handle setup

### Step 4: Launch FlowSpace
```powershell
cd C:\FlowSpace
.\start-dev.ps1
```

---

## 📋 What's Included

```
FlowSpace-USB-Installer/
├── INSTALL.ps1              # Main installer (7.6 KB)
├── README.txt               # User instructions (2.5 KB)
├── FlowSpace/               # Application files
│   ├── backend/             # NestJS API server
│   ├── FlowSpaceApp/        # Flutter desktop client
│   ├── start-dev.ps1        # Service startup script
│   ├── DEPLOY.ps1           # Alternative deploy script
│   └── DEPLOYMENT_GUIDE.md  # Full documentation
├── Config/                  # Kratos configuration
│   ├── kratos.yaml          # Kratos server config
│   └── identity.schema.json # Identity schema
└── Dependencies/            # Dependency info
    └── README.txt           # Download links
```

---

## 🔧 Prerequisites (Target Machine)

### Required Software
1. **Node.js** v18+ → https://nodejs.org/
2. **PostgreSQL** v14+ → https://www.postgresql.org/download/
3. **Redis** → https://github.com/microsoftarchive/redis/releases
4. **Ory Kratos** → https://github.com/ory/kratos/releases

### Installation Order
1. Node.js (run installer)
2. PostgreSQL (run installer, create databases)
3. Redis (extract to `C:\Redis`)
4. Kratos (extract to `C:\Kratos`)

---

## ⚡ One-Command Install (After Prerequisites)

```powershell
# From USB drive root
.\INSTALL.ps1

# Custom paths
.\INSTALL.ps1 -InstallPath "D:\Apps\FlowSpace" -KratosPath "D:\Apps\Kratos"
```

---

## 🔍 Verification Commands

### Check Package Before USB Copy
```powershell
cd C:\FlowSpace\FlowSpace-USB-Installer

# Verify structure
Test-Path INSTALL.ps1
Test-Path README.txt
Test-Path FlowSpace\backend
Test-Path FlowSpace\FlowSpaceApp\client_flutter.exe
Test-Path Config\kratos.yaml

# Check size
Get-ChildItem -Recurse | Measure-Object -Property Length -Sum
```

### After Installation on Target
```powershell
# Verify installation
Test-Path C:\FlowSpace\backend
Test-Path C:\FlowSpace\FlowSpaceApp\client_flutter.exe
Test-Path C:\Kratos\kratos.yaml

# Verify services
Test-NetConnection localhost -Port 6379  # Redis
Test-NetConnection localhost -Port 5432  # PostgreSQL
Test-NetConnection localhost -Port 4433  # Kratos
Test-NetConnection localhost -Port 4000  # Backend
```

---

## 🎯 Testing Plan

### Test 1: Build Installer
```powershell
cd C:\FlowSpace
.\prepare-usb-installer.ps1
```
**Verify:** Package created at `.\FlowSpace-USB-Installer`

### Test 2: Copy to USB
```powershell
Copy-Item -Path ".\FlowSpace-USB-Installer\*" -Destination "D:\" -Recurse
```
**Verify:** All files copied, no errors

### Test 3: Run on Clean Machine
```powershell
D:
.\INSTALL.ps1
```
**Verify:** 
- Prerequisites detected
- Installation completes
- Services start
- Login works

### Test 4: Verify Functionality
- [ ] Backend API responds
- [ ] Kratos authentication works
- [ ] Flutter app launches
- [ ] Can login with default credentials
- [ ] Dashboard loads

---

## 🔐 Default Credentials

**Primary User:**
- Email: `ava@vyrevault.studio`
- Password: `flowspace123`

**Test User:**
- Email: `toren@vyrevault.studio`
- Password: `flowspace123`

---

## 🐛 Quick Troubleshooting

### Script Won't Run
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Missing Dependencies
Check `Dependencies\README.txt` for download links

### Database Errors
```powershell
# Create databases manually
psql -U postgres
CREATE DATABASE flowspace;
CREATE DATABASE flowspace_identity;
\q
```

### Service Won't Start
```powershell
# Check logs
Get-Content C:\FlowSpace\logs\backend-output.log -Tail 50
Get-Content C:\FlowSpace\logs\kratos-stderr.log -Tail 50
```

### Port Conflicts
```powershell
# Check what's using ports
Get-NetTCPConnection -LocalPort 4000,4433,5432,6379
```

---

## 📊 Package Statistics

| Metric | Value |
|--------|-------|
| Total Files | 25,111 |
| Total Size | 446 MB |
| Backend Files | ~24,500 |
| Flutter App | ~500 files |
| Scripts | 4 |
| Configs | 2 |
| Docs | 3 |

**USB Requirements:**
- Minimum: 512 MB
- Recommended: 2 GB (with dependency installers)
- Format: FAT32 or NTFS

---

## 🎬 Next Steps

### For Development Machine
1. ✅ Package created - `.\prepare-usb-installer.ps1`
2. ⏭️ Test locally first (optional)
3. ⏭️ Copy to USB drive
4. ⏭️ Test on clean VM or machine
5. ⏭️ Deploy to production machines

### For Target Machine
1. ⏭️ Install prerequisites
2. ⏭️ Run `INSTALL.ps1` from USB
3. ⏭️ Follow prompts
4. ⏭️ Run `start-dev.ps1`
5. ⏭️ Login and verify

---

## 📞 Support

**Documentation:**
- `README.txt` - Quick start guide
- `DEPLOYMENT_GUIDE.md` - Detailed deployment
- `USB_INSTALLER_TEST_CHECKLIST.md` - Testing procedures

**Logs Location:**
- `C:\FlowSpace\logs\`

**Common Paths:**
- FlowSpace: `C:\FlowSpace`
- Kratos: `C:\Kratos`
- Redis: `C:\Redis`

---

## ✅ Pre-Deployment Checklist

Before copying to USB and deploying:

- [x] Installer package built successfully
- [x] All required files present
- [x] INSTALL.ps1 script created
- [x] Documentation included
- [x] Config files copied
- [ ] Tested on clean machine (see USB_INSTALLER_TEST_CHECKLIST.md)
- [ ] Copied to USB drive
- [ ] USB drive labeled properly
- [ ] Backup created

---

## 🔄 Rebuild Installer (If Needed)

```powershell
cd C:\FlowSpace

# Full rebuild with Flutter
.\prepare-usb-installer.ps1

# Skip Flutter build (faster for testing)
.\prepare-usb-installer.ps1 -SkipBuild

# Custom output location
.\prepare-usb-installer.ps1 -OutputPath "D:\MyInstaller"
```

---

## 💡 Pro Tips

1. **Offline Installation:** Download dependency installers and place in `Dependencies\` folder
2. **Multiple Machines:** Copy USB contents to network share for easy access
3. **Version Control:** Add date/version to USB label
4. **Testing:** Test on VM before deploying to production
5. **Backups:** Keep copy of working installer package
6. **Documentation:** Print `README.txt` for non-technical users
7. **Support Package:** Include `USB_INSTALLER_TEST_CHECKLIST.md` for troubleshooting

---

**Ready to Deploy!** 🎉

Your standalone USB installer is prepared and ready for testing.
