# Quick Test Guide - Message Threading

## 30-Second Visual Test

### Step 1: Start Everything
```powershell
# Terminal 1: Start backend
cd c:\FlowSpace\backend
npm run start:dev

# Terminal 2: Start Flutter
cd c:\FlowSpace\client_flutter
flutter run -d windows
```

### Step 2: Watch Backend Logs
Look for these messages when backend starts:
```
[PrismaService] Auto-syncing database schema...
[PrismaService] Database schema synchronized  (or "Already in sync")
[PrismaService] Database ready
```

✅ **If you see these → Database auto-sync is working!**

---

### Step 3: Visual Test in Flutter App

1. **Send a message:**
   - Type: "Testing threading feature"
   - Send it

2. **Reply to it:**
   - Click the **↩️ reply icon** on your message
   - You should see: "Replying to [your name]" banner
   - Type: "This is a reply"
   - Send it

3. **Check the result:**
   - ✅ Reply should be **indented** under the original
   - ✅ Original message should show **"1 reply"** button
   - ✅ Reply should have a **smaller, indented appearance**

4. **Test collapse/expand:**
   - Click the **"1 reply"** button
   - Replies should hide/show
   - Icon should change (↑/↓)

---

## What Success Looks Like

### ✅ Working Correctly:
```
┌─────────────────────────────────┐
│ You: Testing threading feature  │
│ [1 reply] [↩️]                   │
│   └─ You: This is a reply       │
└─────────────────────────────────┘
```

### ❌ Not Working:
```
┌─────────────────────────────────┐
│ You: Testing threading feature  │
│ You: This is a reply            │  ← Not indented!
└─────────────────────────────────┘
```

---

## Quick Fixes

### If replies aren't indented:
1. **Hot reload Flutter:** Press `r` in Flutter terminal
2. **Check backend logs:** Look for errors
3. **Restart backend:** It will auto-sync schema again

### If "1 reply" button doesn't appear:
1. **Check message has parentId:** Look in backend logs when sending
2. **Verify UI code:** Make sure using `_buildThreadedMessageList()`
3. **Hot reload:** Press `r` in Flutter terminal

### If database sync fails:
1. **Check PostgreSQL is running**
2. **Check DATABASE_URL in .env**
3. **Restart backend** - it will retry automatically

---

## Run Automated Test

```powershell
.\test-threading.ps1
```

This will guide you through all tests interactively!

---

## Full Test Guide

See `TEST_THREADING.md` for comprehensive testing checklist.

