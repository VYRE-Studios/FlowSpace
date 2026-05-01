import 'dart:io';

/// Vault lock service to prevent concurrent FlowSpace instances
/// Ensures only one instance can access the workspace at a time
class VaultLockService {
  static File? _lockFile;

  /// Attempt to acquire lock for workspace
  /// Returns true if lock acquired, false if already locked
  static Future<bool> acquireLock(String workspacePath) async {
    final file = File('$workspacePath/VyreVault/vault.lock');
    
    // Check if already locked
    if (file.existsSync()) {
      // Check if lock is stale (older than 1 hour)
      final lockAge = DateTime.now().difference(file.lastModifiedSync());
      if (lockAge.inHours < 1) {
        print('[VaultLock] Workspace is locked by another instance');
        return false;
      } else {
        print('[VaultLock] Removing stale lock file');
        file.deleteSync();
      }
    }

    // Create lock file
    try {
      _lockFile = file;
      await file.writeAsString('LOCKED:${DateTime.now().toIso8601String()}');
      print('[VaultLock] Lock acquired');
      return true;
    } catch (e) {
      print('[VaultLock] Failed to acquire lock: $e');
      return false;
    }
  }

  /// Release lock when app closes
  static void releaseLock() {
    if (_lockFile != null && _lockFile!.existsSync()) {
      try {
        _lockFile!.deleteSync();
        print('[VaultLock] Lock released');
      } catch (e) {
        print('[VaultLock] Failed to release lock: $e');
      }
      _lockFile = null;
    }
  }

  /// Check if workspace is locked
  static bool isLocked(String workspacePath) {
    final file = File('$workspacePath/VyreVault/vault.lock');
    return file.existsSync();
  }
}
