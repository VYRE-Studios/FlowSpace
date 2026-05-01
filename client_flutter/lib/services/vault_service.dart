import 'dart:io';
import 'api_client.dart';
import 'database_service.dart';
import 'file_upload_service.dart';

typedef VaultFilesResult = ({
  List<Map<String, dynamic>> files,
  bool fromCache,
  DateTime? cacheTimestamp,
});

class VaultService {
  static Future<VaultFilesResult> getRecentFiles(String workspaceId) async {
    try {
      final response = await ApiClient.get('vault/$workspaceId/recent');
      final files = (response as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      return (
        files: files,
        fromCache: false,
        cacheTimestamp: DateTime.now(),
      );
    } catch (e) {
      print('VaultService: Error fetching files from API, falling back to cache: $e');
      final files = await DatabaseService.getWorkspaceVaultFiles(workspaceId);

      return (
        files: files,
        fromCache: true,
        cacheTimestamp: DateTime.now(),
      );
    }
  }

  static Future<Map<String, dynamic>> uploadFile(String workspaceId, File file) async {
    return FileUploadService.uploadFile(workspaceId: workspaceId, file: file);
  }

  static Future<void> deleteFile(String fileId) async {
    await ApiClient.post('vault/files/$fileId/delete');
  }
}
