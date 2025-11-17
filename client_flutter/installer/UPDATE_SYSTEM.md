# FLO Update System

## Overview
FLO now includes an automatic update checking system that notifies users when new versions are available.

## How It Works

### 1. Version Management
- Version is read from `pubspec.yaml` (e.g., `version: 1.0.0+1`)
- The build script automatically updates the NSIS installer with the correct version
- Version is displayed in Settings > About

### 2. Update Checking
- **Automatic**: Checks for updates in the background 5 seconds after app startup (once per 24 hours)
- **Manual**: Users can check for updates in Settings > About > Check for Updates
- Update checks are non-blocking and won't slow down app startup

### 3. Update API
The app checks for updates by calling:
```
GET https://api.flo.app/updates/check?version={current}&build={build}&platform=windows
```

Expected response:
```json
{
  "version": "1.0.1",
  "build": "2",
  "download_url": "https://flo.app/downloads/FLO-1.0.1-Setup.exe",
  "release_notes": "Bug fixes and performance improvements",
  "required": false,
  "size_mb": 450
}
```

### 4. Update Notification
When an update is available:
- A notification appears in the app (non-intrusive)
- User can click "Update" to go to Settings
- Settings shows full update dialog with release notes
- User can download the update installer

### 5. Installing Updates
- User downloads the new installer
- Running the installer will upgrade the existing installation
- User data is preserved during updates

## Setup Instructions

### For Developers

1. **Update Version in pubspec.yaml**:
   ```yaml
   version: 1.0.1+2  # Version + Build number
   ```

2. **Build Installer**:
   ```powershell
   cd C:\FlowSpace\client_flutter\installer
   .\build-installer.ps1
   ```
   The script automatically reads the version from `pubspec.yaml`

3. **Deploy Update API**:
   - Set up API endpoint at `https://api.flo.app/updates/check`
   - Return update information when a newer version is available
   - Host installer files at a public URL

### For Users

1. **Automatic Updates**:
   - App checks for updates automatically
   - Notification appears if update is available

2. **Manual Check**:
   - Go to Settings > About
   - Click "Check for Updates"

3. **Install Update**:
   - Download the new installer
   - Run it to upgrade (preserves all data)

## API Endpoint Requirements

The update API should:
- Accept GET requests with query parameters: `version`, `build`, `platform`
- Return 200 with update info if newer version exists
- Return 200 with no update info if already on latest version
- Handle errors gracefully (app will continue working if API is unavailable)

## Testing

To test the update system:

1. **Change version in pubspec.yaml** to a higher version (e.g., 1.0.1)
2. **Build the app** and installer
3. **Set up a test API** that returns update info for version 1.0.0
4. **Run the app** - it should detect the update after 5 seconds
5. **Check Settings** - version should be displayed correctly

## Notes

- Update checks are rate-limited to once per 24 hours (unless forced)
- Failed update checks don't affect app functionality
- Users can disable update notifications in Settings (future feature)
- Update installer preserves all user data and settings

