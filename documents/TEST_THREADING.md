# Testing Message Threading Feature

## Quick Test Checklist

### 1. Verify Auto-Migration Works ✅

**What to check:**
- Backend starts without errors
- Database schema is automatically updated
- No manual migration commands needed

**How to test:**
1. Start the backend: `cd backend && npm run start:dev`
2. Check the logs - you should see:
   ```
   [PrismaService] Auto-syncing database schema...
   [PrismaService] Database schema synchronized
   [PrismaService] Database ready
   ```
3. If you see "Already in sync" - that's also good!

**✅ Success:** Backend starts and logs show database is ready

---

### 2. Test Sending Regular Messages ✅

**What to check:**
- Messages send normally (no parentId)
- Existing functionality still works

**How to test:**
1. Open Flutter app
2. Select a channel
3. Send a message: "Hello, this is a test message"
4. Message should appear normally

**✅ Success:** Message appears in chat, no errors

---

### 3. Test Replying to Messages ✅

**What to check:**
- Reply button appears on messages
- Clicking reply shows "Replying to..." in composer
- Sending reply creates threaded message

**How to test:**
1. Find a message in the chat
2. Click the **reply icon** (↩️) on the message
3. You should see:
   - "Replying to [sender name]" banner above composer
   - Composer hint changes to "Reply to [sender]..."
4. Type a reply: "This is a reply"
5. Send the message
6. Reply should appear **indented** under the original message

**✅ Success:** Reply appears indented under parent message

---

### 4. Test Thread Collapse/Expand ✅

**What to check:**
- Threads with replies show reply count
- Clicking collapses/expands the thread
- UI updates correctly

**How to test:**
1. Find a message that has replies
2. You should see: "X replies" button with expand/collapse icon
3. Click it - replies should hide
4. Click again - replies should show
5. Icon should change (↑ when expanded, ↓ when collapsed)

**✅ Success:** Threads collapse and expand correctly

---

### 5. Test Multiple Replies ✅

**What to check:**
- Multiple replies to same message work
- All replies appear under parent
- Replies are sorted by time

**How to test:**
1. Send a message: "What do you think?"
2. Reply to it: "I think option A"
3. Reply to it again: "Actually, option B is better"
4. Reply to it again: "Let's go with B"
5. All 3 replies should appear indented under the parent
6. They should be in chronological order

**✅ Success:** All replies appear correctly under parent

---

### 6. Test Nested Replies (Reply to Reply) ✅

**What to check:**
- Can reply to a reply (creates nested thread)
- Nested replies appear correctly

**How to test:**
1. Send message: "Main topic"
2. Reply: "First reply"
3. Click reply icon on "First reply"
4. Send: "Reply to the reply"
5. Should appear indented under "First reply"

**✅ Success:** Nested replies work correctly

---

### 7. Test Real-time Updates ✅

**What to check:**
- Replies appear instantly in other clients
- WebSocket updates work with threading

**How to test:**
1. Open Flutter app in two windows (or two devices)
2. In Window 1: Send a message
3. In Window 2: Reply to that message
4. In Window 1: Reply should appear instantly
5. In Window 2: Original message should show updated reply count

**✅ Success:** Real-time threading updates work across clients

---

### 8. Test Database Persistence ✅

**What to check:**
- Threading data persists after restart
- Messages reload correctly

**How to test:**
1. Create some threaded messages
2. Restart the backend
3. Restart the Flutter app
4. Open the same channel
5. All messages and threads should still be there
6. Thread structure should be preserved

**✅ Success:** Threading persists after restart

---

## Common Issues & Solutions

### Issue: "Database sync failed"
**Solution:** 
- Check PostgreSQL is running
- Check DATABASE_URL in `.env` is correct
- Restart backend - it will retry automatically

### Issue: Replies not appearing
**Solution:**
- Check backend logs for errors
- Verify `parentId` is being sent in request
- Check Flutter console for errors

### Issue: UI not updating
**Solution:**
- Hot reload Flutter app (press `r` in terminal)
- Check that `parentId` is in ChatMessage model
- Verify message list is using `_buildThreadedMessageList()`

### Issue: "No pending migrations" error
**Solution:**
- This is normal! It means schema is already synced
- The app will continue normally

---

## Automated Test Script

Run this in PowerShell to test the API directly:

```powershell
# Test 1: Send a message
$workspaceId = "your-workspace-id"
$channelId = "your-channel-id"
$token = "your-session-token"

$body = @{
    content = "Test message for threading"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:4000/api/v1/workspaces/$workspaceId/channels/$channelId/messages" `
    -Method POST `
    -Body $body `
    -ContentType "application/json" `
    -Headers @{ "Cookie" = "session=$token" }

# Test 2: Reply to that message
$parentId = "message-id-from-above"
$replyBody = @{
    content = "This is a reply"
    parentId = $parentId
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:4000/api/v1/workspaces/$workspaceId/channels/$channelId/messages" `
    -Method POST `
    -Body $replyBody `
    -ContentType "application/json" `
    -Headers @{ "Cookie" = "session=$token" }
```

---

## Success Criteria

✅ All 8 tests pass  
✅ No errors in backend logs  
✅ No errors in Flutter console  
✅ UI looks correct (indented replies, collapsible threads)  
✅ Real-time updates work  
✅ Data persists after restart  

If all tests pass, **Phase 1 is complete and working!** 🎉

