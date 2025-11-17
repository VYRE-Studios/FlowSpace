# USB Installer Testing Checklist

## Pre-Testing Setup

### 1. Build the USB Installer Package
```powershell
cd C:\FlowSpace
.\prepare-usb-installer.ps1
```

**Expected Output:**
- ✓ Flutter release built or already exists
- ✓ USB installer structure created
- ✓ Application files copied
- ✓ Kratos configuration copied
- ✓ INSTALL.ps1 created
- ✓ README.txt created

**Verify Package Location:**
- [ ] `.\FlowSpace-USB-Installer` directory exists
- [ ] Size is reasonable (check with `Get-ChildItem -Recurse | Measure-Object -Property Length -Sum`)

### 2. Verify Package Contents

```powershell
cd .\FlowSpace-USB-Installer
Get-ChildItem -Recurse | Select-Object FullName
```

**Required Files:**
- [ ] `INSTALL.ps1` (main installer script)
- [ ] `README.txt` (user instructions)
- [ ] `FlowSpace\backend\` (backend source files)
- [ ] `FlowSpace\FlowSpaceApp\client_flutter.exe` (desktop app)
- [ ] `FlowSpace\start-dev.ps1` (startup script)
- [ ] `FlowSpace\DEPLOYMENT_GUIDE.md` (detailed guide)
- [ ] `Config\kratos.yaml` (Kratos config)
- [ ] `Config\identity.schema.json` (identity schema)
- [ ] `Dependencies\README.txt` (dependency guide)

### 3. Copy to USB Drive

```powershell
# Replace D: with your USB drive letter
Copy-Item -Path ".\FlowSpace-USB-Installer\*" -Destination "D:\" -Recurse -Force
```

**Verify:**
- [ ] All files copied successfully
- [ ] No errors during copy
- [ ] USB drive has sufficient space

---

## Test Scenario 1: Fresh Install (Clean Machine)

### Prerequisites
- Clean Windows 10/11 machine
- No existing FlowSpace installation
- Administrator access

### Test Steps

#### 1. Check Prerequisites Detection
```powershell
D:
.\INSTALL.ps1
```

**Expected Behavior:**
- [ ] Script runs as Administrator (or prompts to re-run)
- [ ] Detects missing Node.js
- [ ] Detects missing PostgreSQL
- [ ] Detects missing Redis
- [ ] Detects missing Kratos
- [ ] Lists download links for missing dependencies
- [ ] Offers to continue anyway

**Action:** Cancel install, install prerequisites

#### 2. Install Dependencies
Install in order:
1. [ ] Node.js v18+ from https://nodejs.org/
2. [ ] PostgreSQL v14+ from https://www.postgresql.org/download/
   - [ ] Default port 5432
   - [ ] Remember postgres password
   - [ ] Create `flowspace` database
   - [ ] Create `flowspace_identity` database
3. [ ] Redis to `C:\Redis` from https://github.com/microsoftarchive/redis/releases
4. [ ] Kratos to `C:\Kratos` from https://github.com/ory/kratos/releases

#### 3. Verify Dependencies
```powershell
node --version
psql --version
Test-Path C:\Redis\redis-server.exe
Test-Path C:\Kratos\kratos.exe
```

**All checks should pass:**
- [ ] Node.js version displayed
- [ ] PostgreSQL version displayed
- [ ] Redis exe exists
- [ ] Kratos exe exists

#### 4. Run Installer
```powershell
D:
.\INSTALL.ps1
```

**Expected Behavior:**
- [ ] All prerequisites detected (✓ green checks)
- [ ] FlowSpace copied to `C:\FlowSpace`
- [ ] Kratos configs copied to `C:\Kratos`
- [ ] Prompts to install Node dependencies
- [ ] Prompts to initialize database
- [ ] Desktop shortcut created

**Verify Installation:**
```powershell
Test-Path C:\FlowSpace\backend
Test-Path C:\FlowSpace\FlowSpaceApp\client_flutter.exe
Test-Path C:\FlowSpace\start-dev.ps1
Test-Path C:\Kratos\kratos.yaml
Test-Path C:\Kratos\identity.schema.json
Test-Path "$env:USERPROFILE\Desktop\FlowSpace.lnk"
```

#### 5. Test Startup
```powershell
cd C:\FlowSpace
.\start-dev.ps1
```

**Expected Services:**
- [ ] Redis starts on port 6379
- [ ] PostgreSQL running on port 5432
- [ ] Kratos starts on ports 4433/4456
- [ ] Backend starts on port 4000
- [ ] Flutter app launches

**Verify Ports:**
```powershell
Test-NetConnection localhost -Port 6379
Test-NetConnection localhost -Port 5432
Test-NetConnection localhost -Port 4433
Test-NetConnection localhost -Port 4000
```

#### 6. Test Login
- [ ] Flutter app opens
- [ ] Login screen displays
- [ ] Can login with `ava@vyrevault.studio` / `flowspace123`
- [ ] Dashboard loads

---

## Test Scenario 2: Existing Installation (Update)

### Prerequisites
- Machine with existing FlowSpace installation
- Services not running

### Test Steps

#### 1. Backup Existing Installation
```powershell
Rename-Item C:\FlowSpace C:\FlowSpace.backup
```

#### 2. Run USB Installer
```powershell
D:
.\INSTALL.ps1
```

**Expected Behavior:**
- [ ] Detects existing prerequisites
- [ ] Overwrites installation
- [ ] Prompts for database setup (can skip if DB already seeded)

#### 3. Test Update
- [ ] New files deployed
- [ ] Old settings preserved (if .env exists)
- [ ] Services start correctly

---

## Test Scenario 3: Custom Installation Paths

### Test Custom Paths
```powershell
.\INSTALL.ps1 -InstallPath "D:\MyApps\FlowSpace" -KratosPath "D:\MyApps\Kratos"
```

**Verify:**
- [ ] FlowSpace installs to custom path
- [ ] Kratos configs copy to custom path
- [ ] Shortcut points to correct location

---

## Test Scenario 4: Network Installation

### Prerequisites
- Two Windows machines on same network
- FlowSpace installed on Machine A (server)
- Machine B (client) with USB installer

### Test Steps

#### 1. Configure Server (Machine A)
```powershell
# Get IP address
ipconfig

# Open firewall ports
New-NetFirewallRule -DisplayName "FlowSpace" -Direction Inbound -LocalPort 4000 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "Kratos" -Direction Inbound -LocalPort 4433,4456 -Protocol TCP -Action Allow
```

#### 2. Install Client (Machine B)
- [ ] Run USB installer
- [ ] Install dependencies
- [ ] Install FlowSpace

#### 3. Configure Client to Connect to Server
```powershell
# Edit backend .env on Machine B
# Change DATABASE_URL to point to Machine A IP
# Change KRATOS URLs to Machine A IP
```

**Update Flutter API endpoint** (requires rebuild):
- Edit `client_flutter\lib\services\api_client.dart`
- Change localhost to Machine A IP
- Rebuild Flutter app

#### 4. Test Network Connection
- [ ] Machine B can reach Machine A services
- [ ] Login works from Machine B
- [ ] Data syncs between machines

---

## Post-Testing Validation

### Documentation Review
- [ ] README.txt is clear and accurate
- [ ] DEPLOYMENT_GUIDE.md is up-to-date
- [ ] Dependencies\README.txt has correct links
- [ ] All download links work

### Script Review
- [ ] INSTALL.ps1 has no errors
- [ ] prepare-usb-installer.ps1 completed successfully
- [ ] All paths are correct
- [ ] No hardcoded machine-specific paths

### Size Check
```powershell
$size = (Get-ChildItem -Path ".\FlowSpace-USB-Installer" -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB
Write-Host "Package size: $([math]::Round($size, 2)) GB"
```

**Expected Size:**
- [ ] < 2 GB (without dependencies)
- [ ] Fits on typical USB drive

---

## Common Issues & Solutions

### Issue: "Script execution is disabled"
**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue: PostgreSQL connection fails
**Solution:**
- Verify postgres service is running
- Check credentials in .env
- Ensure databases exist: `flowspace`, `flowspace_identity`

### Issue: Kratos won't start
**Solution:**
- Verify kratos.yaml exists at C:\Kratos
- Check DSN points to correct database
- Ensure identity.schema.json path is correct

### Issue: Backend won't start
**Solution:**
- Check node_modules installed: `cd backend && npm install`
- Verify .env file exists
- Check all services (Redis, Postgres, Kratos) are running

### Issue: Flutter app can't connect
**Solution:**
- Verify backend is running: `Test-NetConnection localhost -Port 4000`
- Check firewall settings
- Verify API endpoint in Flutter app

---

## Final Checklist Before Distribution

- [ ] All test scenarios pass
- [ ] Documentation is accurate
- [ ] No sensitive data in configs
- [ ] No hardcoded passwords (except defaults)
- [ ] README.txt is in root of USB
- [ ] INSTALL.ps1 is executable
- [ ] All dependencies documented
- [ ] Version/date stamped on package
- [ ] Backup of working installer saved

---

## USB Drive Label

**Recommended Label:**
```
FlowSpace Installer v1.0
Date: [Current Date]
For Windows 10/11 64-bit
```

---

## Support Information

If testing reveals issues, check:
1. `C:\FlowSpace\logs\` for service logs
2. `DEPLOYMENT_GUIDE.md` for troubleshooting
3. Run `.\verify.ps1` to check system state

For each failed test, document:
- What step failed
- Error message
- System state when failed
- Resolution steps taken
