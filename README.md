# FlowSpace 🚀

**The hybrid collaboration platform: Teams × Slack × Zoom**

FlowSpace combines enterprise team management, real-time messaging, and video conferencing into one unified workspace.

---

## ⚡ Quick Start (Windows)

### 🚀 New: P2P Messaging Setup

**One-click P2P setup (for peer-to-peer chat between devices):**
```powershell
cd client_flutter
.\setup_p2p.ps1
```

This automatically:
- ✅ Requests admin privileges
- ✅ Adds firewall rule (UDP port 33445)
- ✅ Installs P2P dependencies
- ✅ Configures network
- ✅ Asks if you want to test immediately

**Test P2P between two devices:**
```powershell
cd client_flutter
.\test_p2p.ps1
```

Run on both desktop and laptop (same WiFi) - they'll discover each other and exchange encrypted messages!

---

### 🏃 Development Mode

**First time? Run the interactive guide:**
```powershell
.\START_HERE.ps1
```

**Or manually:**
```powershell
# 1. Verify environment
.\verify.ps1

# 2. Start all services in ONE window (Redis, MinIO, Kratos, LiveKit)
.\dev-server.ps1

# 3. Backend setup (new terminal)
cd backend
npm install
npx prisma migrate dev
npm run start:dev

# 4. Frontend (new terminal)
cd client_flutter
flutter pub get
flutter run -d windows
```

**Stop all services:**
```powershell
.\dev-server.ps1 -StopAll
```

---

## 🏗️ Architecture

### Tech Stack

**Backend**
- NestJS (Node.js framework)
- PostgreSQL (primary database)
- Prisma ORM
- Redis (caching & pub/sub)
- Socket.IO (WebSocket)
- **Ory Kratos** (identity & auth)
- **MinIO** (S3-compatible vault storage)
- LiveKit (video/audio)

**Frontend**
- Flutter (cross-platform)
- Hive (local storage)
- socket_io_client
- LiveKit Flutter SDK
- **P2P Messaging** (Dart + X25519 + ChaCha20-Poly1305)

**Infrastructure**
- PostgreSQL (native Windows install)
- Redis (native Windows install or WSL)
- MinIO (native binary)
- LiveKit (native binary)

---

## 📦 Project Structure

```
FlowSpace/
├── backend/                 # NestJS API server
│   ├── src/
│   │   ├── auth/           # Authentication (JWT)
│   │   ├── chat/           # Real-time messaging
│   │   ├── workspaces/     # Workspace management
│   │   ├── vault/          # File storage
│   │   ├── meet/           # Video conferencing
│   │   ├── presence/       # Online status
│   │   ├── signaling/      # WebRTC signaling
│   │   ├── system/         # Task scheduling
│   │   └── database/       # Prisma client
│   └── prisma/
│       └── schema.prisma   # Database schema
├── client_flutter/          # Flutter desktop/mobile app
│   └── lib/
│       ├── core/           # Theme & shared logic
│       ├── services/       # API clients & business logic
│       ├── ui/             # Shell & navigation
│       └── views/          # Feature screens
└── infrastructure/          # Docker configs & deployment
```

---

## 🚀 Quick Start

### Prerequisites

- **Node.js** 18+
- **PostgreSQL** 15+ (native Windows install)
- **Redis** 7+ (Windows binary or WSL)
- **MinIO** (Windows binary)
- **Ory Kratos** (Windows binary)
- **LiveKit** (Windows binary)
- **Flutter** 3.24+

### Backend Setup

```powershell
cd backend

# Install dependencies
npm install

# Set up environment
cp .env.example .env
# Edit .env with your database credentials

# Run database migrations
npx prisma migrate dev

# Seed initial data (optional)
npx prisma db seed

# Start development server
npm run start:dev
```

Backend runs on **http://localhost:4000/api/v1**

### Frontend Setup

```powershell
cd client_flutter

# Install dependencies
flutter pub get

# Run on desktop
flutter run -d windows
# Or: flutter run -d macos / -d linux
```

### Infrastructure Setup

**PostgreSQL:**
```powershell
# Download from https://www.postgresql.org/download/windows/
# Or use: winget install PostgreSQL.PostgreSQL
# Create database:
psql -U postgres -c "CREATE DATABASE flowspace;"
```

**Redis:**
```powershell
# Download from https://github.com/tporadowski/redis/releases
# Or run in WSL: wsl redis-server
# Start Redis:
redis-server
```

**MinIO:**
```powershell
# Download from https://min.io/download
# Start MinIO:
minio.exe server C:\MinIO\data --console-address :9001
# Access console at http://localhost:9001
```

**Ory Kratos:**
```powershell
# Download from https://github.com/ory/kratos/releases
# Run migrations:
kratos.exe -c infrastructure/kratos/kratos.yml migrate sql -e --yes
# Start Kratos:
kratos.exe serve -c infrastructure/kratos/kratos.yml --dev
```

**LiveKit:**
```powershell
# Download from https://github.com/livekit/livekit/releases
# Start LiveKit:
livekit-server.exe --dev --config infrastructure/livekit/livekit.yaml
```

---

## 🎯 Core Features

### ✅ Implemented
- [x] Modular NestJS backend architecture
- [x] Prisma database schema
- [x] WebSocket gateway for real-time chat
- [x] **Ory Kratos integration** for session-based auth
- [x] **MinIO S3 vault** with upload/download service
- [x] Workspace & channel models
- [x] File vault structure
- [x] Flutter navigation shell
- [x] Multi-view UI framework
- [x] **🆕 P2P Messaging System** (Phase 1 Complete!)
  - [x] LAN peer discovery (2-second broadcast)
  - [x] X25519 + ChaCha20-Poly1305 encryption
  - [x] Sub-10ms message latency
  - [x] Automated setup with firewall configuration
  - [x] Test framework for verification
  - [x] Zero server infrastructure

### 🔨 In Progress
- [ ] End-to-end authentication flow
- [ ] Real-time chat UI & backend integration
- [ ] Video conferencing with LiveKit
- [ ] File upload/download with S3
- [ ] Presence tracking & online status
- [ ] Workspace member management

### 🎨 Planned
- [ ] **P2P Phase 2:** NAT traversal (STUN + UDP hole-punching)
- [ ] **P2P Phase 3:** TCP relay fallback for strict firewalls
- [ ] **P2P Phase 4:** Production hardening (reliability + recovery)
- [ ] Screen sharing
- [ ] Threaded conversations
- [ ] @mentions & notifications
- [ ] Search across messages & files
- [ ] Mobile responsive design
- [ ] Dark/light theme toggle
- [ ] Emoji reactions
- [ ] Calendar integration

---

## 🗄️ Database Models

**Core entities:**
- `User` - Authentication & profile
- `Workspace` - Team/organization container
- `WorkspaceMember` - User↔Workspace association (with roles)
- `Channel` - Chat channels within workspaces
- `ChatMessage` - Individual messages
- `VaultFile` - Uploaded files metadata
- `PresenceSnapshot` - Real-time online status

**Roles:** `OWNER`, `ADMIN`, `MEMBER`

---

## 🔌 API Endpoints

All endpoints prefixed with `/api/v1`

### Auth (Ory Kratos)
FlowSpace uses **Ory Kratos** for identity management with session-based authentication.

- **Kratos Public API:** `http://localhost:4433`
- **Kratos Admin API:** `http://localhost:4434`

Authentication flows:
- Registration: Self-service flow via Kratos
- Login: Session cookies or `X-Session-Token` header
- Session validation: `KratosSessionGuard` extracts identity from session

Backend endpoints:
- Protected routes use `@UseGuards(KratosSessionGuard)`
- User identity available via `req.user` (id, email, displayName)

### Workspaces
- `GET /workspaces` - List user's workspaces
- `POST /workspaces` - Create workspace
- `GET /workspaces/:slug` - Get workspace details
- `POST /workspaces/:slug/members` - Add member

### Chat
- `GET /chat/channels/:channelId/messages` - Get message history
- WebSocket gateway at `/chat` for real-time messaging

### Vault (MinIO S3 Storage)
FlowSpace uses **MinIO** as S3-compatible object storage for the file vault.

- **MinIO Console:** `http://localhost:9000`
- **Access Key:** `flowspace`
- **Secret Key:** `flowspace123`
- **Bucket:** `flowspace`

Backend endpoints:
- `POST /vault/upload` - Upload file to workspace vault
  - Requires authentication
  - Validates workspace membership
  - Stores metadata in PostgreSQL, binary in MinIO
- `GET /vault/:workspaceId/files` - List recent files (limit 20)
- `DELETE /vault/:fileId` - Delete file (not yet implemented)

File metadata tracked:
- name, url, size, contentType, uploaderId, createdAt

### Meet
- `POST /meet/create-room` - Create video room
- WebSocket at `/signaling` for WebRTC

---

## 🛠️ Development Workflow

### Infrastructure
```powershell
.\dev-server.ps1         # Start all services (one window)
.\dev-server.ps1 -StopAll # Stop all services
.\start-services.ps1     # Check service status
.\verify.ps1             # Verify environment
```

The `dev-server.ps1` starts:
- Redis (port 6379)
- MinIO (port 9000, console 9001)
- Ory Kratos (port 4433)
- LiveKit (port 7880)

All output is logged to `logs/` directory.

### Backend
```powershell
npm run start:dev      # Hot-reload dev server
npm run build          # Compile TypeScript
npm run test           # Run tests (when added)
npx prisma studio      # Open database GUI
```

### Frontend
```powershell
flutter run            # Hot-reload on desktop
flutter test           # Run widget tests
flutter build windows  # Build production executable
```

---

## 🔐 Environment Variables

**Backend (.env):**
```
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/flowspace

REDIS_URL=redis://localhost:6379
REDIS_CLUSTER_NODES=redis://localhost:6379

# MinIO (S3-compatible vault storage)
MINIO_ENDPOINT=http://localhost:9000
MINIO_ACCESS_KEY=flowspace
MINIO_SECRET_KEY=flowspace123
MINIO_BUCKET=flowspace
MINIO_PUBLIC_ENDPOINT=http://localhost:9000

# LiveKit (video/audio conferencing)
LIVEKIT_URL=http://localhost:7880
LIVEKIT_WS_URL=ws://localhost:7880
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=devsecret

# Ory Kratos (identity management)
KRATOS_PUBLIC_URL=http://localhost:4433
KRATOS_ADMIN_URL=http://localhost:4434

JWT_SECRET=supersecretjwtkey
```

---

## 📝 Contributing

1. Create feature branch: `git checkout -b feature/amazing-feature`
2. Follow existing code patterns (NestJS modules, Flutter BLoC/Provider)
3. Update schema if database changes: `npx prisma migrate dev`
4. Test locally before committing
5. Create PR with clear description

---

## 📄 License

Proprietary - All rights reserved

---

## 🐛 Troubleshooting

**Backend won't start:**
- Check PostgreSQL is running: `Test-NetConnection localhost -Port 5432`
- Verify DATABASE_URL in backend/.env
- Run migrations: `npx prisma migrate deploy`
- Check all services: `.\start-services.ps1`

**Flutter build errors:**
- Clean build: `flutter clean && flutter pub get`
- Check Flutter version: `flutter doctor`
- Ensure Windows development tools installed

**WebSocket connection fails:**
- Ensure CORS enabled in main.ts
- Check Redis running: `Test-NetConnection localhost -Port 6379`
- Verify Socket.IO versions match (client & server)

**Services not connecting:**
- Run verification: `.\verify.ps1`
- Check firewall settings
- Ensure correct ports in .env files

**MinIO upload fails:**
- Check MinIO running: `Test-NetConnection localhost -Port 9000`
- Verify MINIO_ACCESS_KEY and MINIO_SECRET_KEY in .env
- Create bucket if missing via MinIO console

**Kratos authentication fails:**
- Check Kratos running: `Test-NetConnection localhost -Port 4433`
- Verify KRATOS_PUBLIC_URL in .env
- Run Kratos migrations first

---

**Built with ❤️ for seamless collaboration**
