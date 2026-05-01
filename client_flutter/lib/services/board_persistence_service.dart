import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'vault_storage_service.dart';

/// Service for persisting board state to disk
/// Stores board data in workspace vault under boards/<boardId>/
class BoardPersistenceService {
  /// Save arbitrary board data (canvas state, nodes, strokes, etc.)
  static Future<void> saveBoardData(
    String workspaceId,
    String projectId,
    String boardId,
    Map<String, dynamic> data,
  ) async {
    try {
      final basePath = await VaultStorageService.getBaseVaultPath();
      final boardDir = path.join(
        basePath,
        workspaceId,
        'projects',
        projectId,
        'boards',
        boardId,
      );

      // Create board directory if not exists
      final directory = Directory(boardDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Write board state
      final file = File(path.join(boardDir, 'state.json'));
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
      );

      print('[BoardPersistence] Saved board $boardId state');
    } catch (e) {
      print('[BoardPersistence] ERROR saving board $boardId: $e');
    }
  }

  /// Load board data from disk
  static Future<Map<String, dynamic>?> loadBoardData(
    String workspaceId,
    String projectId,
    String boardId,
  ) async {
    try {
      final basePath = await VaultStorageService.getBaseVaultPath();
      final file = File(path.join(
        basePath,
        workspaceId,
        'projects',
        projectId,
        'boards',
        boardId,
        'state.json',
      ));

      if (!await file.exists()) {
        return null;
      }

      final jsonString = await file.readAsString();
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('[BoardPersistence] ERROR loading board $boardId: $e');
      return null;
    }
  }

  /// Check if board has saved state
  static Future<bool> hasSavedState(
    String workspaceId,
    String projectId,
    String boardId,
  ) async {
    try {
      final basePath = await VaultStorageService.getBaseVaultPath();
      final file = File(path.join(
        basePath,
        workspaceId,
        'projects',
        projectId,
        'boards',
        boardId,
        'state.json',
      ));

      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Delete board data
  static Future<void> deleteBoardData(
    String workspaceId,
    String projectId,
    String boardId,
  ) async {
    try {
      final basePath = await VaultStorageService.getBaseVaultPath();
      final boardDir = Directory(path.join(
        basePath,
        workspaceId,
        'projects',
        projectId,
        'boards',
        boardId,
      ));

      if (await boardDir.exists()) {
        await boardDir.delete(recursive: true);
        print('[BoardPersistence] Deleted board $boardId data');
      }
    } catch (e) {
      print('[BoardPersistence] ERROR deleting board $boardId: $e');
    }
  }
}
