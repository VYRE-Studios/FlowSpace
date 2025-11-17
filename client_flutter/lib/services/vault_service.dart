import 'dart:io';
import 'database_service.dart';
import 'vault_storage_service.dart';

typedef VaultFilesResult = ({
  List<Map<String, dynamic>> files,
  bool fromCache,
  DateTime? cacheTimestamp,
});

class VaultService {
  static Future<VaultFilesResult> getRecentFiles(String workspaceId) async {
    // Load from SQLite database
    final files = await DatabaseService.getWorkspaceVaultFiles(workspaceId);
    
    return (
      files: files,
      fromCache: true,
      cacheTimestamp: DateTime.now(),
    );
  }

  static Future<void> uploadFile(String workspaceId, File file) async {
    // Save file to vault storage
    final savedFile = await VaultStorageService.saveFile(workspaceId, file);
    final size = await VaultStorageService.getFileSize(savedFile);
    final mimeType = VaultStorageService.getMimeType(savedFile.path);
    
    // Save metadata to database
    final user = await DatabaseService.getCurrentUser();
    await DatabaseService.insertVaultFile({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'workspace_id': workspaceId,
      'name': savedFile.path.split('/').last.split('\\\\').last,
      'file_path': savedFile.path,
      'size': size,
      'mime_type': mimeType,
      'folder': 'shared',
      'uploaded_by': user?['id'] ?? '',
      'uploaded_at': DateTime.now().toIso8601String(),
    });
  }
}
