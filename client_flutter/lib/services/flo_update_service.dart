import 'dart:io';

class FloUpdateService {
  // Update URL - change this to your production URL after deployment
  // For testing, you can use a local path or test server
  static const String updateUrl = 'https://vyrevault.com/downloads/flowspace/';
  
  // For local testing, uncomment and use:
  // static const String updateUrl = 'file:///C:/path/to/installer/windows/';

  static Future<bool> checkAndApplyUpdates() async {
    if (!Platform.isWindows) return false;

    try {
      final exe = File(Platform.resolvedExecutable);
      final appDir = exe.parent;
      final rootDir = appDir.parent;
      final updateExe = File('${rootDir.path}\\Update.exe');

      if (!updateExe.existsSync()) {
        // Update.exe not found - app may not be installed via Squirrel
        // This is normal during development
        return false;
      }

      final result = await Process.run(
        updateExe.path,
        ['--update', updateUrl],
      );

      return result.exitCode == 0;
    } catch (e) {
      // Silently fail - don't interrupt app startup
      return false;
    }
  }
}

