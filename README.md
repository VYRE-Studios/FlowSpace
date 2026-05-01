# FlowSpace

FlowSpace is a private company collaboration app aimed at the same day-to-day jobs as Slack, Microsoft Teams, and Zoom: workspace navigation, streams, meetings, calendar, file vault, and project coordination in one desktop experience.

## Current Direction

FlowSpace is staying local-first for now.

The Windows desktop app is the primary product surface. Local accounts, workspaces, starter channels, and offline session state are stored on the machine so the app can be used without standing up the backend stack. The backend services remain in the repository for future hosted sync, production auth, and multi-device infrastructure, but local/offline operation is the baseline until the app experience is stable.

Default seeded local login:

```text
Email: local@flowspace.app
Password: flowspace123
```

You can also create a local account from the app. When the API is unavailable, registration falls back to the local SQLite store and future logins verify against that local account.

## Screenshots

### Workspace Home

![FlowSpace workspace home](docs/screenshots/flowspace-workspace-home.png)

### Streams

![FlowSpace streams view](docs/screenshots/flowspace-streams.png)

### Connect

![FlowSpace connect view](docs/screenshots/flowspace-connect.png)

### Calendar

![FlowSpace calendar view](docs/screenshots/flowspace-calendar.png)

### Vault

![FlowSpace vault view](docs/screenshots/flowspace-vault.png)

### Projects

![FlowSpace projects view](docs/screenshots/flowspace-projects.png)

## What Works Locally

- Local account creation and login
- Local workspace bootstrap
- Starter streams: `general`, `projects`, and `meetings`
- Workspace dashboard shell
- Streams layout and message composer surface
- Connect/meeting entry surface
- Calendar view
- Vault upload surface
- Projects entry surface
- Windows desktop build

## Tech Stack

Frontend:

- Flutter and Dart
- Windows desktop target today
- macOS, Linux, Android, and iOS remain viable Flutter targets as the app matures
- Local SQLite cache/store through `sqflite_common_ffi`
- Secure platform storage through `flutter_secure_storage`

Backend, retained for future hosted mode:

- NestJS
- Prisma
- PostgreSQL
- Redis
- Socket.IO
- MinIO
- LiveKit

## Run Locally

From the Flutter client:

```powershell
cd client_flutter
flutter pub get
flutter run -d windows
```

To build the current Windows desktop app:

```powershell
cd client_flutter
flutter build windows --debug
```

The built executable is created under:

```text
client_flutter/build/windows/x64/runner/Debug/client_flutter.exe
```

## Validation

Useful checks before pushing:

```powershell
cd client_flutter
flutter test --no-pub
flutter analyze --no-fatal-warnings --no-fatal-infos
flutter build windows --debug --no-pub
```

The analyzer currently exits successfully with non-fatal warning/info debt. Treat that lint debt as cleanup work, not as a blocker for the local-first pass.

## Repository Layout

```text
FlowSpace/
  backend/                  NestJS API and future hosted services
  client_flutter/           Flutter desktop/mobile app
  docs/                     Planning docs and screenshots
  infrastructure/           Service configs for hosted development
  service-wrappers/         Windows service helper scripts
```

## Near-Term Focus

1. Keep the desktop app usable in offline/local mode.
2. Fill empty states with real local data flows.
3. Make Streams, Vault, Calendar, Connect, and Projects useful without backend dependencies.
4. Reduce visual/layout issues shown by the current screenshots.
5. Reintroduce hosted backend sync only after the local app feels coherent and reliable.
