import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing the user's workspace root location on disk.
/// This is where VyreVault/projects/ folders are created and stored locally.
class WorkspaceLocationService {
  static const String _key = 'workspace_location';

  /// Get the saved workspace path, or null if not yet selected
  static Future<String?> getWorkspacePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  /// Set the workspace path and create the folder structure
  /// 
  /// Structure created:
  /// <workspace>/
  ///   VyreVault/
  ///     projects/
  ///     vault/
  ///     ProjectRegistry/
  static Future<void> setWorkspacePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, path);

    // Create root workspace folder
    final root = Directory(path);
    if (!root.existsSync()) {
      root.createSync(recursive: true);
    }

    // Create VyreVault folder
    final vv = Directory('$path/VyreVault');
    if (!vv.existsSync()) {
      vv.createSync(recursive: true);
    }

    // Create projects folder
    final projects = Directory('$path/VyreVault/projects');
    if (!projects.existsSync()) {
      projects.createSync(recursive: true);
    }

    // Create vault folder (for file storage)
    final vault = Directory('$path/VyreVault/vault');
    if (!vault.existsSync()) {
      vault.createSync(recursive: true);
    }

    // Create ProjectRegistry folder
    final registry = Directory('$path/VyreVault/ProjectRegistry');
    if (!registry.existsSync()) {
      registry.createSync(recursive: true);
    }

    print('[WorkspaceLocationService] Created folder structure at: $path');
  }

  /// Clear the stored workspace path
  static Future<void> clearWorkspacePath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Check if workspace path is configured
  static Future<bool> hasWorkspacePath() async {
    final path = await getWorkspacePath();
    return path != null && path.isNotEmpty;
  }
}
