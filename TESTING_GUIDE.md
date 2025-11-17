# FlowSpace Multi-Workstation Testing Guide

## Overview

This guide explains how to test FlowSpace across two or more workstations to verify real-time collaboration features.

## Deployment Package

The deployment package `FlowSpace-Deployment-*.zip` contains:
- Complete backend (NestJS + Prisma)
- Flutter Windows app (release build)
- Configuration scripts
- Setup instructions
- Kratos configuration templates

## Deployment Scenarios

### Scenario 1: Single Machine (Development/Testing)

**Use Case:** Test all features on one machine  
**Setup Time:** 10 minutes  
**Requirements:** All dependencies on one machine

Run: `.\start-dev.ps1`

### Scenario 2: Server + Multiple Clients

**Use Case:** Production-like setup with central server  
**Setup Time:** 30 minutes  
**Requirements:** Network connectivity between machines

**Server Machine:**
- Runs backend, PostgreSQL, Redis, Kratos
- IP: `192.168.1.100` (example)

**Client Machines:**
- Run Flutter app only
- Connect to server's IP

## Step-by-Step: Two Workstation Setup

### Workstation A (Server + Client)

1. **Install Prerequisites:**
   ```powershell
   # Check installations
   node --version      # Should be v18+
   psql --version      # Should be 14+
   ```

2. **Extract Deployment Package:**
   ```powershell
   # Extract FlowSpace-Deployment-*.zip to C:\FlowSpace
   Expand-Archive -Path .\FlowSpace-Deployment-*.zip -DestinationPath C:\
   cd C:\FlowSpace
   ```

3. **Run Deployment Script:**
   ```powershell
   .\DEPLOY.ps1
   # Answer 'y' when prompted for database setup
   ```

4. **Get Server IP Address:**
   ```powershell
   ipconfig
   # Note the IPv4 Address (e.g., 192.168.1.100)
   ```

5. **Configure Firewall:**
   ```powershell
   # Open PowerShell as Administrator
   New-NetFirewallRule -DisplayName "FlowSpace Backend" -Direction Inbound -LocalPort 4000 -Protocol TCP -Action Allow
   ```

6. **Start Services:**
   ```powershell
   .\start-dev.ps1
   # Wait for all services to start
   ```

7. **Launch Flutter App:**
   - Double-click Desktop shortcut OR
   - Run `C:\FlowSpace\FlowSpaceApp\client_flutter.exe`

8. **Login:**
   - Email: `ava@vyrevault.studio`
   - Password: `flowspace123`

### Workstation B (Client Only)

1. **Install Prerequisites:**
   - Only Flutter app dependencies (automatically included in exe)

2. **Get FlowSpaceApp:**
   - Copy `FlowSpaceApp` folder from Workstation A OR
   - Extract from deployment package

3. **Configure Connection:**
   
   **Option A - Quick Test (no rebuild):**
   - Just run the app
   - If it doesn't connect, you'll need Option B

   **Option B - Configure for Remote Server:**
   
   a. On development machine, edit:
   `client_flutter\lib\services\api_client.dart`
   
   ```dart
   static const String baseUrl = String.fromEnvironment(
     'FLOWSPACE_API_BASE',
     defaultValue: 'http://192.168.1.100:4000/api/v1', // <-- Change to server IP
   );
   ```
   
   b. Rebuild:
   ```powershell
   cd client_flutter
   flutter build windows --release
   ```
   
   c. Copy rebuilt app to Workstation B

4. **Launch App:**
   - Run `client_flutter.exe`

5. **Login:**
   - Email: `toren@vyrevault.studio`
   - Password: `flowspace123`

## Testing Checklist

### ✅ Real-Time Chat
- [ ] User A creates a new channel
- [ ] User B sees the new channel appear
- [ ] User A sends a message
- [ ] User B receives it instantly
- [ ] User B types - User A sees "typing..." indicator
- [ ] Both users see each other's presence status

### ✅ Workspace Management
- [ ] User A creates a new workspace
- [ ] User A invites User B (via email in future - not wired yet)
- [ ] Both users can see workspace list
- [ ] User A can manage workspace settings

### ✅ File Vault
- [ ] User A uploads a file
- [ ] User B can see the uploaded file
- [ ] Both users can download files
- [ ] File list updates in real-time

### ✅ Video Meetings (Future)
- [ ] User A creates a meeting
- [ ] User B sees meeting in Meet view
- [ ] Both users can join
- [ ] WebRTC signaling works

### ✅ Profile Management
- [ ] User A updates display name
- [ ] User B sees updated name in messages
- [ ] Profile changes persist

## Network Troubleshooting

### Can't Connect from Workstation B

1. **Verify Services Running on Server:**
   ```powershell
   Test-NetConnection localhost -Port 4000
   Test-NetConnection localhost -Port 4433
   Test-NetConnection localhost -Port 6379
   Test-NetConnection localhost -Port 5432
   ```

2. **Test Network Connectivity:**
   ```powershell
   # From Workstation B
   Test-NetConnection 192.168.1.100 -Port 4000
   ```

3. **Check Firewall:**
   ```powershell
   # On Server
   Get-NetFirewallRule -DisplayName "FlowSpace Backend"
   ```

4. **Verify Backend is Listening:**
   ```powershell
   # On Server
   netstat -an | findstr ":4000"
   # Should show LISTENING
   ```

### Chat Messages Not Syncing

1. **Check WebSocket Connection:**
   - Open browser DevTools (F12)
   - Look for WebSocket connection to `localhost:4000` or server IP

2. **Verify Redis:**
   ```powershell
   Test-NetConnection localhost -Port 6379
   ```

3. **Check Backend Logs:**
   ```powershell
   Get-Content C:\FlowSpace\logs\backend-output.log -Tail 50
   ```

## Performance Benchmarks

### Expected Performance
- **Message Latency:** < 100ms local network
- **File Upload:** Depends on network speed
- **Workspace List:** < 1 second
- **Channel Load:** < 2 seconds

### Resource Usage (Per Machine)
- **Backend:** ~200MB RAM
- **PostgreSQL:** ~100MB RAM  
- **Redis:** ~50MB RAM
- **Kratos:** ~50MB RAM
- **Flutter App:** ~150MB RAM

**Total Server:** ~550MB RAM  
**Total Client:** ~150MB RAM

## Production Considerations

Before using in production:

1. **Security**
   - [ ] Change all default passwords
   - [ ] Set up SSL/TLS certificates
   - [ ] Configure proper Kratos secrets
   - [ ] Enable authentication on Redis
   - [ ] Restrict PostgreSQL access

2. **Scalability**
   - [ ] Set up MinIO/S3 for file storage
   - [ ] Configure Redis for session storage
   - [ ] Set up database backups
   - [ ] Consider load balancing

3. **Monitoring**
   - [ ] Set up logging infrastructure
   - [ ] Configure health checks
   - [ ] Monitor resource usage
   - [ ] Set up alerting

4. **Network**
   - [ ] Configure proper DNS
   - [ ] Set up reverse proxy (nginx)
   - [ ] Enable HTTPS
   - [ ] Configure CORS properly

## Common Issues

### "Cannot sync workspace" Error
- Ensure backend is running on port 4000
- Check database is accessible
- Verify seed data exists: `npx prisma db seed`

### "File upload failed"
- MinIO/S3 must be configured
- Check backend `.env` for MINIO_* variables
- Verify file size limits

### App crashes on startup
- Check Flutter app can reach backend
- Verify all services are running
- Check logs in `C:\FlowSpace\logs\`

### Database connection errors
- Ensure PostgreSQL is running
- Verify database exists: `psql -U postgres -l | findstr flowspace`
- Check DATABASE_URL in backend `.env`

## Getting Help

1. Check `IMPLEMENTATION_STATUS.md` for feature status
2. Review `DEPLOYMENT_GUIDE.md` for detailed setup
3. Check logs in `C:\FlowSpace\logs\`
4. Verify all services: `.\start-dev.ps1`

## Next Features to Test

After basic deployment works:

1. **Activity Logging** - View user actions in Activity tab
2. **Workspace Invites** - Add team members
3. **Channel Permissions** - Control access
4. **File Sharing** - Share vault files in chat
5. **Video Calls** - Real-time video conferencing
6. **Mobile App** - iOS/Android clients (future)

## Success Criteria

✅ FlowSpace is fully deployed when:
- [x] Both workstations can access the app
- [x] Real-time chat works bidirectionally
- [x] Files can be uploaded and viewed
- [x] Workspaces and channels can be created
- [x] User profiles can be updated
- [ ] Video calls connect (future)
- [ ] All features work without errors

---

**Deployment Package Version:** 1.0  
**Last Updated:** 2025-01-15  
**Tested On:** Windows 10/11
