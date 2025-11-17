import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VaultStorageService {
  static const String _customStoragePathKey = 'custom_vault_storage_path';

  /// Get the custom storage path from preferences, or null if not set
  static Future<String?> getCustomStoragePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customStoragePathKey);
  }

  /// Set a custom storage path
  static Future<void> setCustomStoragePath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.isEmpty) {
      await prefs.remove(_customStoragePathKey);
    } else {
      await prefs.setString(_customStoragePathKey, path);
    }
  }

  /// Get the base vault directory (either custom or default app data)
  static Future<String> getBaseVaultPath() async {
    final customPath = await getCustomStoragePath();
    if (customPath != null && customPath.isNotEmpty) {
      // Validate that the custom path exists and is accessible
      final dir = Directory(customPath);
      if (await dir.exists()) {
        return customPath;
      } else {
        // If custom path doesn't exist, try to create it
        try {
          await dir.create(recursive: true);
          return customPath;
        } catch (e) {
          print('FlowSpace: Failed to create custom storage path: $e');
          // Fall back to default
        }
      }
    }
    
    // Default: use app data directory
    final appDir = await getApplicationSupportDirectory();
    return join(appDir.path, 'Vault');
  }

  static Future<String> getVaultPath(String workspaceId, {String folder = 'shared'}) async {
    final basePath = await getBaseVaultPath();
    final vaultPath = join(basePath, workspaceId, folder);
    
    // Create directory if it doesn't exist
    final directory = Directory(vaultPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
      print('FlowSpace: Created vault directory: $vaultPath');
    }
    
    return vaultPath;
  }

  static Future<File> saveFile(String workspaceId, File sourceFile, {String folder = 'shared'}) async {
    final vaultPath = await getVaultPath(workspaceId, folder: folder);
    final fileName = basename(sourceFile.path);
    final destinationPath = join(vaultPath, fileName);
    
    // Copy file to vault
    final destinationFile = await sourceFile.copy(destinationPath);
    print('FlowSpace: File saved to vault: $destinationPath');
    
    return destinationFile;
  }

  static Future<bool> fileExists(String workspaceId, String fileName, {String folder = 'shared'}) async {
    final vaultPath = await getVaultPath(workspaceId, folder: folder);
    final filePath = join(vaultPath, fileName);
    return await File(filePath).exists();
  }

  static Future<File?> getFile(String workspaceId, String fileName, {String folder = 'shared'}) async {
    final vaultPath = await getVaultPath(workspaceId, folder: folder);
    final filePath = join(vaultPath, fileName);
    final file = File(filePath);
    
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  static Future<void> deleteFile(String workspaceId, String fileName, {String folder = 'shared'}) async {
    final vaultPath = await getVaultPath(workspaceId, folder: folder);
    final filePath = join(vaultPath, fileName);
    final file = File(filePath);
    
    if (await file.exists()) {
      await file.delete();
      print('FlowSpace: File deleted from vault: $filePath');
    }
  }

  static Future<List<File>> listFiles(String workspaceId, {String folder = 'shared'}) async {
    final vaultPath = await getVaultPath(workspaceId, folder: folder);
    final directory = Directory(vaultPath);
    
    if (!await directory.exists()) {
      return [];
    }
    
    final entities = await directory.list().toList();
    final files = entities.whereType<File>().toList();
    
    return files;
  }

  static Future<int> getFileSize(File file) async {
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  static String getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    final mimeTypes = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'zip': 'application/zip',
      '7z': 'application/x-7z-compressed',
      'rar': 'application/x-rar-compressed',
    };
    
    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  static Future<void> clearWorkspaceVault(String workspaceId) async {
    final basePath = await getBaseVaultPath();
    final vaultPath = join(basePath, workspaceId);
    final directory = Directory(vaultPath);
    
    if (await directory.exists()) {
      await directory.delete(recursive: true);
      print('FlowSpace: Cleared vault for workspace: $workspaceId');
    }
  }
}
