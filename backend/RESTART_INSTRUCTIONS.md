# How to Restart Backend After Schema Changes

## Quick Fix for File Lock Error

If you see `EPERM: operation not permitted` when starting:

### Step 1: Stop All Backend Processes

**Option A: Use the stop script**
```powershell
cd c:\FlowSpace\backend
npm run stop
```

**Option B: Manual (if script doesn't work)**
1. Press `Ctrl+C` in ALL terminal windows running backend
2. Check Task Manager for `node.exe` processes
3. End any that are related to FlowSpace backend

**Option C: PowerShell one-liner**
```powershell
Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*FlowSpace*backend*" } | Stop-Process -Force
```

### Step 2: Wait 2-3 Seconds
Let Windows release the file locks.

### Step 3: Start Backend
```powershell
cd c:\FlowSpace\backend
npm run start:dev
```

The `prestart:dev` script will now generate Prisma Client successfully!

---

## What Happens Automatically

When you run `npm run start:dev`:

1. **prestart:dev** runs → Generates Prisma Client
2. **start:dev** runs → Starts backend with nodemon
3. **PrismaService.onModuleInit** runs → Auto-syncs database schema

All automatic! No manual commands needed (after stopping processes).

---

## If Prisma Generate Still Fails

The PrismaService will try to generate it on startup as a backup. However, TypeScript compilation might still fail if types aren't available.

**Solution:** Make sure to stop all processes first, then restart.

---

## Prevention

To avoid this in the future:
- Always stop the backend (Ctrl+C) before making schema changes
- Or use the stop script: `npm run stop`
- Then restart: `npm run start:dev`

The system is designed to be automatic - just make sure old processes are stopped first!

