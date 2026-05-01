# FlowSpace QA Modernization Plan

## Mission

FlowSpace must become a production-grade internal collaboration platform for company chat, meetings, files, projects, whiteboards, notifications, administration, and company memory.

The goal is not to clone Slack, Microsoft Teams, or Zoom feature-for-feature. The goal is to meet their daily-use quality bar while making FlowSpace better for this company because identity, workspace data, files, meetings, and project context stay connected in one private system.

## Green Standard

Each system is green only when all applicable checks pass:

- Build: backend builds, Flutter analyzes/builds, and no blocking compile errors remain.
- Auth: production flows use real authenticated users.
- Data: no hardcoded users, workspaces, channels, members, or fake counts.
- Realtime: events work across at least two clients.
- Persistence: state survives app restart.
- Security: backend validates workspace membership and permissions.
- UX: loading, empty, error, retry, offline, and success states are visible and usable.
- Regression: core behavior has a smoke test, integration test, or repeatable manual QA script.
- Documentation: docs match current behavior.

## System Dashboard

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

## Implementation Phases

### Phase 1: Foundation

Objectives:
- Replace production test-user startup with real auth/session restore.
- Normalize API route contracts.
- Make active workspace the source of truth.
- Remove hardcoded production data paths.
- Keep backend build green.

Acceptance:
- Fresh install opens login/welcome.
- Valid session opens the app.
- Invalid session returns to login.
- Backend routes map to `/api/v1/*` once.
- No production screen depends on `test_workspace`.

### Phase 2: Streams

Objectives:
- Real channel list, channel creation, message send/receive, edit/delete, reactions, threads, pins, mentions, unread counts, and member details.
- Realtime events update UI without relying on fake fallbacks.

Acceptance:
- Two authenticated users can chat in realtime.
- Threads, reactions, edits, deletes, pins, and unread state persist.
- Production UI has no fake channel/member/pinned counts.

### Phase 3: Connect

Objectives:
- Use one meeting provider for production. Target: LiveKit.
- Wire Flutter meetings to backend meeting endpoints.
- Add prejoin, start, join, leave/end, mic/camera, screen share, participant list, and channel meeting presence.

Acceptance:
- One user starts a meeting and a second user joins.
- Meeting state appears in the workspace/channel.
- Jitsi/local-only meeting behavior is no longer the production path.

### Phase 4: Vault

Objectives:
- Build real Vault UI and connect chat attachments to backend storage.
- Support upload, list, preview, download/open, delete, metadata, permissions, and progress.

Acceptance:
- Files uploaded by one user appear for authorized workspace members.
- Chat attachments use the same storage layer.
- File actions enforce workspace permissions.

### Phase 5: Presence And Notifications

Objectives:
- Presence heartbeat, online/away/busy/in-meeting/offline, desktop notifications, DND, channel preferences, activity inbox, and persisted unread state.

Acceptance:
- Presence updates across clients.
- Mentions and replies notify correctly.
- Muted and DND states are respected.

### Phase 6: Projects And Whiteboards

Objectives:
- Connect projects, boards, whiteboards, files, channels, and meetings into durable project spaces.

Acceptance:
- A project can be created, reopened, modified, and linked to workspace collaboration data.
- Meeting notes and whiteboards persist after the meeting.

### Phase 7: Admin And Governance

Objectives:
- Admin dashboard for users, roles, invites, sessions, audit logs, storage, retention, and feature flags.

Acceptance:
- Admins can manage the company workspace without database scripts.
- Members cannot perform admin actions.

### Phase 8: Search And Company Memory

Objectives:
- Global search across messages, files, meetings, and projects with permissions.
- Add AI summaries only after search and permissions are reliable.

Acceptance:
- Results deep link to the exact item.
- Users only see results they are allowed to access.

### Phase 9: Release Quality

Objectives:
- Flutter analyze/build green.
- Backend tests and smoke checks green.
- Installer/update flow verified.
- Staging and production configs separated.

Acceptance:
- A release can be built, installed, opened, smoke-tested, and rolled forward predictably.

## First Implementation Slice

1. Fix backend route prefix mismatches.
2. Replace production app startup test picker with session restore and welcome/login fallback.
3. Keep test picker only behind an explicit development flag.
4. Run backend build.
5. Attempt Flutter analysis and document toolchain blockers.

## Completed Slices

- Backend route prefix mismatch fixed for Meet.
- Production startup now prefers real session restore and welcome/login fallback.
- Test user picker is behind an explicit development flag.
- App shell routes to real Workspace, Streams, Connect, Calendar, Vault, Projects, and Settings surfaces.
- Streams no longer depends on `test_workspace` or fake channel/member/pinned values.
- Streams supports backend channel creation, message loading, reactions, pinned counts, member counts, and real thread loading.
- Backend chat responses now include client-ready reaction, pinned, edit/delete, and thread-count fields.
- Connect now uses backend Meet/LiveKit endpoints instead of local Jitsi meeting state.
- Backend services use the shared `PrismaService`; direct ad-hoc Prisma clients have been removed.
- Vault now has backend-backed list, upload, open, and delete flows.
- Backend `npm run build` is green; backend `npm test` now runs the build smoke check until dedicated tests are added.
- Flutter 3.41.9 and Dart 3.11.5 are installed at `C:\Dev\flutter`.
- `C:\Dev\flutter\bin` is prepended to the persisted user PATH for fresh terminals; the current Codex process also has `C:\Dev\tools\bin` shims so `flutter` and `dart` work immediately without restarting Codex.
- Flutter `pub get`, smoke tests, analyzer-with-no-fatal-warnings, and Windows debug build are green.
- Android SDK is now configured at `C:\Users\jwhit\AppData\Local\Android\Sdk`, all SDK licenses are accepted, Flutter Doctor is green, and `flutter build apk --debug` produces `build\app\outputs\flutter-apk\app-debug.apk`.
- The stale Windows CMake cache was cleared so Flutter now uses the installed Visual Studio 2022 compiler.
- Legacy `ChatView` now routes to the maintained `StreamsScreen` instead of compiling a stale duplicate chat surface.
- Basic Flutter smoke tests now cover backend chat payload parsing, legacy message adaptation, and the compatibility chat route.
- Removed the stale Jitsi Flutter dependency from the Android app path now that Connect is wired through backend meeting endpoints.
- Android Gradle config now enables core library desugaring for notification plugins.
- Android launcher icon resource is present and resolves from the manifest.

## Remaining Blockers

- iOS builds still require macOS with Xcode; they cannot be produced on this Windows host.
- Standard `flutter analyze` still reports warning/lint debt in older code; `flutter analyze --no-fatal-warnings --no-fatal-infos` passes with no analyzer errors.
- LiveKit token retrieval is wired, but the Flutter room UI still needs a LiveKit client screen.
- Search, admin hardening, presence/notification persistence, and project/whiteboard backend integration remain yellow/red systems.
