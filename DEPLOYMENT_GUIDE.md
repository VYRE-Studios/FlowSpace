# FlowSpace Deployment Guide

## Prerequisites

Before deploying FlowSpace to another workstation, ensure the target machine has:

### Required Software
1. **Node.js** (v18 or later) - https://nodejs.org/
2. **PostgreSQL** (v14 or later) - https://www.postgresql.org/download/
3. **Redis** - https://github.com/microsoftarchive/redis/releases
4. **Ory Kratos** - Download from https://github.com/ory/kratos/releases
5. **PowerShell 7+** (recommended) - https://github.com/PowerShell/PowerShell

### Installation Locations
- Redis: `C:\Redis\redis-server.exe`
- Kratos: `C:\Kratos\kratos.exe`
- Kratos Config: `C:\Kratos\kratos.yaml`
- Kratos Identity Schema: `C:\Kratos\identity.schema.json`

## Quick Deployment

### Option 1: Automated Deployment (Recommended)

1. Copy the entire `C:\FlowSpace` directory to the target machine
2. Open PowerShell as Administrator
3. Navigate to the FlowSpace directory:
   ```powershell
   cd C:\FlowSpace
   ```
4. Run the deployment script:
   ```powershell
   .\DEPLOY.ps1
   ```
5. Follow the prompts to complete setup

### Option 2: Manual Deployment

#### Step 1: Build the Application (On Development Machine)

```powershell
cd C:\FlowSpace\client_flutter
flutter build windows --release
```

#### Step 2: Package for Deployment

Create a deployment package containing:
- `backend/` - Complete backend directory
- `client_flutter/build/windows/x64/runner/Release/` - Built Flutter app
- `start-dev.ps1` - Startup script
- `DEPLOYMENT_GUIDE.md` - This file

#### Step 3: Transfer to Target Machine

Copy the deployment package to `C:\FlowSpace` on the target machine.

#### Step 4: Install Dependencies

On the target machine, install:
1. Node.js from https://nodejs.org/
2. PostgreSQL with a database named `flowspace`
3. Redis to `C:\Redis\`
4. Ory Kratos to `C:\Kratos\`

#### Step 5: Configure Kratos

Create `C:\Kratos\kratos.yaml`:
```yaml
dsn: postgres://postgres:postgres@localhost:5432/flowspace_identity?sslmode=disable

serve:
  public:
    base_url: http://localhost:4433/
    host: 0.0.0.0
    port: 4433
  admin:
    base_url: http://localhost:4456/
    host: 0.0.0.0
    port: 4456

identity:
  default_schema_id: default
  schemas:
    - id: default
      url: file://C:/Kratos/identity.schema.json

selfservice:
  default_browser_return_url: http://localhost:4000
  methods:
    password:
      enabled: true
  flows:
    login:
      ui_url: http://localhost:4000/auth/login
    registration:
      ui_url: http://localhost:4000/auth/register

log:
  level: info

secrets:
  cookie:
    - flowspace_super_secret_cookie_key
```

Create `C:\Kratos\identity.schema.json`:
```json
{
  "$id": "https://schemas.flowspace.io/user-v0.json",
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "User",
  "type": "object",
  "properties": {
    "traits": {
      "type": "object",
      "properties": {
        "email": {
          "type": "string",
          "format": "email",
          "title": "Email",
          "minLength": 3,
          "ory.sh/kratos": {
            "credentials": {
              "password": {
                "identifier": true
              }
            },
            "verification": {
              "via": "email"
            },
            "recovery": {
              "via": "email"
            }
          }
        }
      },
      "required": ["email"],
      "additionalProperties": false
    }
  }
}
```

#### Step 6: Setup Database

```powershell
cd C:\FlowSpace\backend

# Install dependencies
npm install --production

# Setup environment
# Create .env file with:
# DATABASE_URL=postgresql://postgres:postgres@localhost:5432/flowspace
# MINIO_ENDPOINT=http://localhost:9000
# MINIO_ACCESS_KEY=minioadmin
# MINIO_SECRET_KEY=minioadmin
# MINIO_BUCKET=flowspace

# Run migrations
npx prisma migrate deploy

# Seed database
npx prisma db seed
```

#### Step 7: Start Services

```powershell
cd C:\FlowSpace
.\start-dev.ps1
```

## Environment Configuration

### Backend Environment Variables (.env)

Create `C:\FlowSpace\backend\.env`:

```env
# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/flowspace

# MinIO/S3 Storage
MINIO_ENDPOINT=http://localhost:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_BUCKET=flowspace
MINIO_PUBLIC_ENDPOINT=http://localhost:9000

# Kratos
KRATOS_PUBLIC_URL=http://localhost:4433
KRATOS_ADMIN_URL=http://localhost:4456

# Server
PORT=4000
NODE_ENV=production
```

## Network Configuration

### Firewall Rules

If testing across multiple workstations, open these ports:

```powershell
# Backend API
New-NetFirewallRule -DisplayName "FlowSpace Backend" -Direction Inbound -LocalPort 4000 -Protocol TCP -Action Allow

# PostgreSQL
New-NetFirewallRule -DisplayName "PostgreSQL" -Direction Inbound -LocalPort 5432 -Protocol TCP -Action Allow

# Redis
New-NetFirewallRule -DisplayName "Redis" -Direction Inbound -LocalPort 6379 -Protocol TCP -Action Allow

# Kratos Public
New-NetFirewallRule -DisplayName "Kratos Public" -Direction Inbound -LocalPort 4433 -Protocol TCP -Action Allow
```

### Remote Access Setup

To access FlowSpace from another workstation:

1. On the server machine, get the IP address:
   ```powershell
   ipconfig
   ```

2. On the client machine, update Flutter's API base URL:
   - Edit `client_flutter/lib/services/api_client.dart`
   - Change `defaultValue: 'http://localhost:4000/api/v1'`
   - To: `defaultValue: 'http://SERVER_IP:4000/api/v1'`
   - Rebuild: `flutter build windows --release`

## Default Credentials

**Email:** ava@vyrevault.studio  
**Password:** flowspace123

Additional test user:
- **Email:** toren@vyrevault.studio
- **Password:** flowspace123

## Service Management

### Start All Services
```powershell
cd C:\FlowSpace
.\start-dev.ps1
```

### Stop All Services
```powershell
cd C:\FlowSpace
.\start-dev.ps1 -StopAll
```

### Skip Flutter (backend only)
```powershell
.\start-dev.ps1 -SkipFlutter
```

### Check Service Status

```powershell
# Backend
Test-NetConnection localhost -Port 4000

# Kratos
Test-NetConnection localhost -Port 4433

# Redis
Test-NetConnection localhost -Port 6379

# PostgreSQL
Test-NetConnection localhost -Port 5432
```

## Troubleshooting

### Backend Won't Start
1. Check Node.js is installed: `node --version`
2. Check dependencies: `cd backend && npm install`
3. Check database connection: `psql -U postgres -d flowspace`
4. Check logs: `C:\FlowSpace\logs\backend-output.log`

### Kratos Won't Start
1. Verify `C:\Kratos\kratos.yaml` exists
2. Verify `C:\Kratos\identity.schema.json` exists
3. Check logs: `C:\FlowSpace\logs\kratos-stderr.log`

### Flutter App Won't Connect
1. Ensure backend is running on port 4000
2. Check firewall isn't blocking connections
3. Verify API base URL in `api_client.dart`

### Database Errors
1. Ensure PostgreSQL is running
2. Create database: `createdb -U postgres flowspace`
3. Run migrations: `cd backend && npx prisma migrate deploy`
4. Reseed: `npx prisma db seed`

## Production Deployment Checklist

- [ ] Change default database passwords
- [ ] Update Kratos secrets in kratos.yaml
- [ ] Set up proper SSL/TLS certificates
- [ ] Configure MinIO/S3 for file storage
- [ ] Set NODE_ENV=production
- [ ] Enable firewall rules
- [ ] Set up automated backups
- [ ] Configure monitoring/logging
- [ ] Create service accounts (don't run as Administrator)
- [ ] Document network topology

## Architecture

```
┌─────────────────┐
│  Flutter Client │ (Windows Desktop App)
│  Port: N/A      │
└────────┬────────┘
         │
         │ HTTP/WebSocket
         ▼
┌─────────────────┐
│  NestJS Backend │
│  Port: 4000     │
└────┬───┬───┬────┘
     │   │   │
     │   │   └──────► Redis (Port 6379)
     │   │
     │   └──────────► Ory Kratos (Port 4433/4456)
     │
     └──────────────► PostgreSQL (Port 5432)
                      ├── flowspace (main DB)
                      └── flowspace_identity (Kratos DB)
```

## Support

For issues or questions:
1. Check `IMPLEMENTATION_STATUS.md` for feature status
2. Review logs in `C:\FlowSpace\logs\`
3. Verify all services are running with `start-dev.ps1`

## Next Steps After Deployment

1. Create additional user accounts
2. Set up workspaces for your team
3. Create channels for communication
4. Upload files to vault
5. Test video calls between workstations
6. Configure user roles and permissions
