# FlowSpace All Systems Green Plan

## Purpose

This document formalizes the path from the current v2.1.0 local-first/server-ready state to a production-ready company collaboration platform. It is meant to sit beside the existing planning and update docs, especially:

- `docs/FLOWSPACE_QA_MODERNIZATION_PLAN.md`
- `documents/IMPLEMENTATION_STATUS.md`
- `documents/IMPLEMENTATION_VERIFICATION.md`
- `documents/WHATS_ACTUALLY_BUILT.md`

The operating rule is simple: a system is not green because a screen exists. It is green only when the feature works with real data, survives restart, handles failure states, is covered by repeatable QA, and is documented.

## Current System Dashboard

| System | Current | Target |
| --- | --- | --- |
| Backend build | Green | Keep green |
| Flutter toolchain | Green | Keep Flutter/Dart discoverable in dev shell |
| Android build | Green | Keep SDK licenses/packages and debug APK build green |
| App boot | Yellow | Session restore or login, no production test picker |
| Auth | Yellow | JWT/refresh/token expiry handled everywhere |
| Workspace | Yellow | Real active workspace across app |
| Streams | Yellow | Real channels/messages/threads/reactions/unreads |
| Realtime | Yellow | Authenticated Socket.IO, reliable event handling |
| Connect | Yellow | LiveKit-backed meetings from workspace/channel |
| Vault | Yellow | Real file upload/list/download/delete UI |
| Presence | Yellow | Heartbeat, broadcast, and UI state |
| Notifications | Yellow | Mention/reply/unread preferences |
| Projects | Yellow | Real project surfaces connected to workspace |
| Search | Red | Global search across messages/files/projects |
| Admin | Red | Member, role, audit, storage, and settings UI |
| Release | Yellow | Repeatable installer/update/smoke workflow |

## Green Definition

Every system must meet these gates before being marked green:

- Real authenticated users and workspaces are used in production paths.
- Local mode and server mode have explicit behavior and do not silently fight each other.
- Empty, loading, error, retry, offline, and success states are visible.
- Data persists after app restart.
- Realtime behavior works between at least two signed-in clients where applicable.
- Backend enforces workspace membership and role permissions.
- Flutter tests, backend build/test, and release smoke checks pass.
- README and relevant docs describe current behavior.

## Completed Updates Since the First QA Pass

- Flutter and Dart are installed/discoverable on the Windows dev station.
- Android SDK is configured and debug APK builds have been validated.
- Windows desktop local-first build is published as v2.0.0 and v2.1.0.
- Organization release exists under `VYRE-Studios/FlowSpace`.
- Local account creation/login works without backend dependency.
- Fresh downloaded builds bootstrap the default local account.
- macOS target exists and local SQLite initialization now includes macOS.
- Root Markdown docs were moved to `documents/`.
- Root PowerShell scripts were moved to `scripts/windows/`.
- README now documents local-first direction, cross-platform intent, server-ready mode, and release links.
- v2.1.0 adds `Settings > Connection` with Local/Self-hosted Server mode, server URL storage, and backend health check.
- Backend now exposes `GET /api/v1/health`.

## Workstreams

### 1. App Boot

Current: Yellow

Goal:
The app starts into a predictable state: restore a valid session, show login/create account when no session exists, and keep test picker/dev bypasses out of production.

Implementation:

- Keep local mode as default for fresh installs.
- Add first-run mode awareness: Local mode creates/uses local account; Server mode requires server URL and server auth.
- Keep development-only user picker behind an explicit compile-time flag.
- Add visible state for invalid/expired session.

Acceptance:

- Fresh install opens local-ready onboarding/login.
- Valid local session opens the app.
- Valid server session opens the app when server mode is selected.
- Invalid token returns to login with a clear message.
- Production build never opens the test picker by default.

### 2. Auth

Current: Yellow

Goal:
Auth handles local credentials, server JWTs, refresh tokens, expiry, logout, and mode switching consistently.

Implementation:

- Separate local auth and server auth service paths internally.
- Persist server mode and server URL before server login.
- Add refresh-token flow coverage for every API path.
- Clear incompatible local/server tokens when switching modes.
- Add auth state model: unauthenticated, localAuthenticated, serverAuthenticated, expired, offline.

Acceptance:

- Local login succeeds without backend.
- Server login fails fast if no server URL or health check fails.
- Server login stores JWT/refresh token.
- Expired access token refreshes or returns to login.
- Logout clears only the correct mode-specific state.

### 3. Workspace

Current: Yellow

Goal:
Every app surface reads a real active workspace from one source of truth.

Implementation:

- Create an `ActiveWorkspaceState` contract used by Streams, Connect, Vault, Projects, Search, Presence, and Settings.
- In local mode, hydrate active workspace from SQLite.
- In server mode, hydrate active workspace from backend `/workspaces`.
- Add switcher for multiple workspaces.
- Remove stale fallback workspace IDs from production paths.

Acceptance:

- Active workspace persists after restart.
- Switching workspace updates all major screens.
- Empty workspace has a guided create/join path.
- Server mode does not show local-only workspace data unless explicitly offline cached.

### 4. Streams

Current: Yellow

Goal:
Streams provide real Slack/Teams-quality channel messaging basics.

Implementation:

- Real channel list from active workspace.
- Message send/load/edit/delete.
- Threads/replies.
- Reactions.
- Pins.
- Mentions.
- Unread counts.
- Typing indicators.
- Channel details and members.
- Local/server mode data source separation.

Acceptance:

- Two users in server mode can exchange messages live.
- Messages persist and reload.
- Thread/reaction/unread state survives restart.
- Permission checks prevent cross-workspace access.

### 5. Realtime

Current: Yellow

Goal:
Authenticated realtime events reliably update the UI.

Implementation:

- Socket.IO auth handshake with current JWT.
- Workspace/channel room subscription.
- Reconnect strategy with backoff.
- Event deduplication and ordering guard.
- Presence and unread updates through realtime events.

Acceptance:

- Client reconnects after temporary network loss.
- Events are not duplicated after reconnect.
- Unauthorized clients cannot subscribe to workspace rooms.
- Realtime message, presence, and unread flows pass two-client smoke test.

### 6. Connect

Current: Yellow

Goal:
Connect uses LiveKit-backed meetings from workspace/channel context.

Implementation:

- Server endpoints issue LiveKit tokens.
- Flutter LiveKit room UI for join/leave/mute/camera/screen share.
- Meeting presence in channels/workspace.
- Meeting lifecycle states: scheduled, active, ended.
- Local mode shows local placeholder or disabled server-required state.

Acceptance:

- User A starts meeting from workspace/channel.
- User B joins from another machine.
- Participants can mute/unmute and leave.
- Meeting state updates in app after ending.

### 7. Vault

Current: Yellow

Goal:
Vault supports real file upload, list, download/open, delete, and permissions.

Implementation:

- Use backend storage APIs in server mode.
- Use local file metadata/storage in local mode.
- Add upload progress and error states.
- Add download/open/delete actions.
- Connect chat attachments to the same storage layer.

Acceptance:

- File uploaded by one server user appears for authorized workspace members.
- Unauthorized users cannot fetch files.
- Delete removes file from UI and backend storage.
- Large upload shows progress and handles failure.

### 8. Presence

Current: Yellow

Goal:
Presence has heartbeat, broadcast, and visible UI states.

Implementation:

- Client heartbeat interval.
- Server stores current presence snapshot.
- UI states: online, away, busy, in meeting, offline.
- Activity timestamps and idle detection.

Acceptance:

- Presence updates across two clients.
- Closing app marks user offline after timeout.
- Meeting participation sets in-meeting state.

### 9. Notifications

Current: Yellow

Goal:
Mention, reply, unread, and preference-driven notifications work predictably.

Implementation:

- Notification preference model.
- Desktop notification integration.
- Channel mute and DND.
- Mention/reply routing.
- Activity inbox.

Acceptance:

- Mentions notify unless muted/DND.
- Replies notify thread participants.
- Clicking notification opens correct workspace/channel/thread.

### 10. Projects

Current: Yellow

Goal:
Projects become real workspace-connected surfaces, not isolated placeholders.

Implementation:

- Create/list/update/archive projects per workspace.
- Link project channels, documents, files, meetings, and tasks.
- Persist project state locally and server-side as appropriate.
- Add project activity feed.

Acceptance:

- Project created in workspace appears after restart.
- Project links to channel/file/meeting context.
- Server users share the same project state.

### 11. Search

Current: Red

Goal:
Global search across messages, files, projects, and later meetings.

Implementation:

- Define search indexing model.
- Add backend search endpoint scoped by workspace permissions.
- Add local search for local mode.
- Add UI with filters: messages, files, projects, people, dates.
- Deep links to result location.

Acceptance:

- User can search and open exact message/file/project.
- Results obey workspace membership.
- Local mode can search local data.

### 12. Admin

Current: Red

Goal:
Admins can manage company workspace without database scripts.

Implementation:

- Invite/member management.
- Roles and permissions.
- Audit log.
- Storage dashboard.
- Server settings/status page.
- Session management.

Acceptance:

- Admin can invite/remove/change role.
- Member cannot access admin actions.
- Audit log records admin changes.
- Storage usage is visible.

### 13. Release

Current: Yellow

Goal:
Release is repeatable, documented, and smoke-tested.

Implementation:

- Define release checklist for Windows, macOS, Linux, Android, and iOS.
- Keep GitHub releases in both personal and organization repos.
- Build release artifact with `README-FIRST.txt`.
- Add smoke script/checklist for local mode and server mode.
- Document checksums.
- Add release notes update step.

Acceptance:

- One command or checklist produces release artifact.
- Release can be installed on a clean machine.
- Local login works from fresh install.
- Server mode can save/test URL.
- README and release notes match the artifact.

## Milestone Plan

### Milestone A: v2.1.x Server-Ready Stabilization

Focus:
- Validate Settings > Connection on clean Windows install.
- Add server-mode smoke checklist.
- Ensure app boot does not regress local-first behavior.
- Update docs after each release.

Exit:
- v2.1.x release installs and local login works.
- Server URL can be saved/tested against `/api/v1/health`.

### Milestone B: v2.2.0 Shared Workspace Pilot

Focus:
- Server auth hardening.
- Active workspace from backend.
- Workspace member invite/join path.
- Basic server channel list.

Exit:
- Three users can log into the same self-hosted server and see the same workspace/channels.

### Milestone C: v2.3.0 Streams Pilot

Focus:
- Server messages.
- Authenticated Socket.IO.
- Reactions/threads/unreads.

Exit:
- Three users can hold a real channel conversation with persistence and realtime updates.

### Milestone D: v2.4.0 Vault And Connect Pilot

Focus:
- File upload/list/download/delete.
- LiveKit meeting start/join/leave.

Exit:
- Three users can share files and join a meeting in the same workspace.

### Milestone E: v2.5.0 Admin/Search/Release Hardening

Focus:
- Admin member/role/storage/audit UI.
- Global search.
- Repeatable multi-platform release workflow.

Exit:
- Admin and Search move from Red to Yellow/Green.
- Release process is documented and repeatable across target platforms.

## Required QA Matrix

| Check | Local Mode | Server Mode |
| --- | --- | --- |
| Fresh install opens app | Required | Required |
| Login/create account | Required | Required |
| Active workspace loads | Required | Required |
| Streams load | Required | Required |
| Message send | Local storage | Backend + realtime |
| File upload | Local storage | Backend storage |
| Meeting join | Disabled/local placeholder until implemented | LiveKit |
| Restart restores state | Required | Required |
| Offline behavior | Required | Graceful error/cache |
| Release smoke | Required | Required when server exists |

## Documentation Policy

Every implementation slice must update at least one of:

- `README.md` for current user-facing behavior.
- `docs/FLOWSPACE_ALL_SYSTEMS_GREEN_PLAN.md` for status/roadmap changes.
- `docs/FLOWSPACE_QA_MODERNIZATION_PLAN.md` if the original QA dashboard changes materially.
- Release notes for shipped artifacts.

Docs are part of the green gate. A feature is not done if the repo still describes old behavior.
