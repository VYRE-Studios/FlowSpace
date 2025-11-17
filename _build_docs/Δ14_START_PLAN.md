🛰 **FLOWSPACE Δ-14 — MULTI-USER LIVE OPERATION START PACKAGE**

**Phase:** Δ-14 — Multi-User Live Operation

**Objective:** Expand Flowspace from a single-instance prototype to a real multi-user system with persistent workspaces, presence, vault sync, and LiveKit integration.

---

## ⚙️ Scope

**Stack:** Flutter • NestJS • PostgreSQL • Redis Cluster • MinIO • LiveKit

**Duration:** 7–10 build days

**Output:** Two-user functional test demonstrating real-time collaboration.

---

## 🧩 1. Core Deliverables

| Area                        | Deliverable                                                                                                 |
| --------------------------- | ----------------------------------------------------------------------------------------------------------- |
| **Presence Service**        | WebSocket gateway backed by Redis keys (`presence:<workspace>:<user>`). Emits presence & typing events.     |
| **Workspace Registry**      | Persistent `workspaces`, `workspace_members`, `channels` tables with Prisma migrations.                     |
| **Redis Cluster**           | Add `redis-node2`, update `REDIS_CLUSTER_NODES`, and bootstrap `Redis.Cluster` client.                      |
| **Auth & Session**          | Replace hard-coded user bootstrap with JWT auth flow across REST + WebSockets.                             |
| **Vault Sync**              | Workspace-scoped file namespace `/vault/<workspaceId>/<filename>`.                                         |
| **LiveKit Multi-User Join** | Test LiveKit meeting join flow across two authenticated clients.                                            |

---

## 🧱 2. Tasks

### Database

```bash
cd backend
npx prisma migrate dev --name init_multi_workspace
npm run prisma:seed
```

### Presence Service

* Directory: `backend/services/presence`
* Gateway handles `online/offline` and `typing`
* Docker Compose snippet:

  ```yaml
  presence:
    build: ./backend/services/presence
    ports: ["4004:4004"]
    depends_on: [redis]
  ```

### Redis Cluster

```yaml
  redis-node2:
    image: redis:7
    command: ["redis-server", "--port", "6379"]
    ports: ["6380:6379"]
```

Env entry:

```
REDIS_CLUSTER_NODES=redis://redis:6379,redis://redis-node2:6379
```

Client init:

```ts
const nodes = process.env.REDIS_CLUSTER_NODES.split(',').map((url) => ({ url }));
const redis = new Redis.Cluster(nodes);
```

### Auth Workflow

* Frontend: call `/auth/login`, cache JWT (`SharedPreferences` / secure storage).
* Backend: add guards to REST + WS, inject user/workspace context after token validation.

### Vault Integration

* Ensure uploads scoped by workspace ID.
* Verify cross-user visibility within the same workspace and isolation across workspaces.

### LiveKit Setup

```
LIVEKIT_WS_URL=ws://localhost:7880
LIVEKIT_API_KEY=flowspace
LIVEKIT_API_SECRET=supersecret
```

### Flutter UI

* Workspace dropdown in header.
* Presence indicator + typing banner.
* Replace bootstrap email with authenticated session context.

---

## 🧠 3. Milestone Tests

1. Two clients online → both visible in presence list.
2. User A message → User B receives instantly.
3. User A upload → User B sees in Vault.
4. User A starts meeting → User B joins LiveKit session.

---

## ✅ 4. Completion Criteria

| Test            | Result                                |
| --------------- | ------------------------------------- |
| Multi-User Chat | Real-time messages visible both sides |
| Presence        | Status updates + typing indicator     |
| Vault           | File replication confirmed            |
| LiveKit         | 2-way audio/video session stable      |
| Auth            | JWT propagation works                 |
| Logs            | No unhandled exceptions               |

---

## 📦 5. Artifacts

* Screenshots of dual clients
* Prisma schema snapshot
* Redis key dump & TTL output
* Backend service logs (presence/workspace/vault)
* `flutter analyze` output

