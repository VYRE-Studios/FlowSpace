🛰 **FLOWSPACE Δ-14 — VERIFICATION REPORT TEMPLATE**

**Purpose:** Document validation of the Δ-14 multi-user environment before progressing to Δ-15.

---

## 🧱 System Versions

| Component  | Version       | Notes |
| ---------- | ------------- | ----- |
| Flutter    | 3.24.x        |       |
| NestJS     | 10.x          |       |
| PostgreSQL | 16.x          |       |
| Redis      | 7.x (Cluster) |       |
| LiveKit    | Latest        |       |

---

## 🧩 Verification Checklist

### 1. Database

- [ ] Migration applied (`npx prisma migrate dev`)
- [ ] Seed executed (`npm run prisma:seed`)
- [ ] Workspaces, members, channels populated as expected

### 2. Presence

- [ ] Both users appear online
- [ ] Typing indicator broadcast between clients
- [ ] Redis TTL refreshes within 60 seconds (`TTL presence:*`)

### 3. Chat Messaging

- [ ] Messages mirror instantly between clients
- [ ] Channel switching maintains correct history
- [ ] No duplicate or missing events in logs

### 4. Vault Sync

- [ ] Upload succeeds to MinIO (workspace-scoped path)
- [ ] Peer client sees file in recent list
- [ ] Download hash matches uploader’s original

### 5. LiveKit

- [ ] Room creation succeeds via API
- [ ] Second client receives join notification
- [ ] Two-way audio/video stable (< 250 ms latency)

### 6. Auth & Session

- [ ] JWT issued via `/auth/login`
- [ ] Token validated on REST + WebSocket
- [ ] Session persists across app restart

---

## 🧠 Cross-Machine Test Log

| Step | Action                  | Result | Latency (ms) |
| ---- | ----------------------- | ------ | ------------ |
| 1    | User A sends message    |        |              |
| 2    | User B receives message |        |              |
| 3    | File upload/download    |        |              |
| 4    | Presence update         |        |              |
| 5    | Video join              |        |              |

---

## 📊 Metrics

- Service CPU / Memory usage
- Redis ops/sec snapshot
- Average message latency
- WebSocket connection uptime

---

## 🧩 Findings / Issues

- [ ] Bugs or missing functionality
- [ ] Attach relevant logs / screenshots
- [ ] Stability rating (1–10)

---

## ✅ Verification Outcome

- [ ] Passed
- [ ] Requires fixes before Δ-15

**Verifier:** ______________________

**Date:** __________________________

---
