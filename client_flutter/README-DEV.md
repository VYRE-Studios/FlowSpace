# Development Mode vs Production Build

## Hot Reload Support

**Hot reload ONLY works in development mode**, not when running from a desktop icon (compiled executable).

### Option 1: Run in Development Mode (Recommended for Development)

Use the `run-dev.bat` script or run manually:

```bash
cd c:\FlowSpace\client_flutter
flutter run -d windows
```

**Benefits:**
- ✅ Hot reload works (press `R` in terminal or save in IDE)
- ✅ Hot restart works (press `R` in terminal)
- ✅ Fast iteration during development
- ✅ Debugging tools available

**How to use:**
1. Double-click `run-dev.bat` or run `flutter run -d windows`
2. Make code changes
3. Press `R` in the terminal window to hot reload
4. Or just save files in your IDE (if configured for auto-reload)

### Option 2: Rebuild After Changes (For Desktop Icon)

If you want to use the desktop icon, you need to rebuild after each change:

```bash
cd c:\FlowSpace\client_flutter
flutter build windows
```

Then run the executable from:
- `build\windows\x64\runner\Release\client_flutter.exe`
- Or your desktop icon (if it points to the built executable)

**Note:** This is slower and not recommended during active development.

## Quick Reference

| Method | Hot Reload | Speed | Use Case |
|--------|-----------|-------|----------|
| `flutter run` | ✅ Yes | Fast | Development |
| Desktop Icon (compiled) | ❌ No | Slow | Production/Testing |

## Creating a Desktop Shortcut for Dev Mode

You can create a desktop shortcut that points to `run-dev.bat` for easy access to development mode.

