import 'dart:convert';
import 'dart:io';
import 'change_tracking_service.dart';
import 'local_project_loader.dart';
import 'api_client.dart';

/// Manages synchronization between local changes and backend
/// Optional backend sync - app works fully offline
class SyncManager {
  /// Push local changes to backend
  static Future<bool> pushChangesToBackend(
    String workspacePath,
    String projectId,
  ) async {
    try {
      final changes = ChangeTrackingService.listChanges(workspacePath, projectId);
      if (changes.isEmpty) {
        print('[SyncManager] No changes to push for project $projectId');
        return true;
      }

      print('[SyncManager] Pushing ${changes.length} changes for project $projectId');

      for (final changeFile in changes) {
        try {
          final jsonString = changeFile.readAsStringSync();
          final data = jsonDecode(jsonString) as Map<String, dynamic>;
          final event = data['event'] as Map<String, dynamic>;

          // Push to backend
          await ApiClient.post('/projects/$projectId/events', body: event);

          // Delete change file after successful push
          await ChangeTrackingService.deleteChange(changeFile);
        } catch (e) {
          print('[SyncManager] Failed to push change: $e');
          // Continue with next change
        }
      }

      print('[SyncManager] Successfully pushed changes');
      return true;
    } catch (e) {
      print('[SyncManager] Error pushing changes: $e');
      return false;
    }
  }

  /// Pull remote updates from backend
  static Future<bool> pullRemoteUpdates(String projectId) async {
    try {
      print('[SyncManager] Pulling updates for project $projectId');

      final response = await ApiClient.get('/projects/$projectId/events');
      if (response is List) {
        for (final event in response) {
          if (event is Map<String, dynamic>) {
            await _applyEvent(projectId, event);
          }
        }
      }

      print('[SyncManager] Successfully pulled updates');
      return true;
    } catch (e) {
      print('[SyncManager] Error pulling updates: $e');
      return false;
    }
  }

  /// Apply a remote event to local project
  static Future<void> _applyEvent(
    String projectId,
    Map<String, dynamic> event,
  ) async {
    try {
      final eventType = event['type'] as String?;

      switch (eventType) {
        case 'manifest_update':
          await _applyManifestUpdate(projectId, event);
          break;
        case 'board_added':
          await _applyBoardAdded(projectId, event);
          break;
        case 'board_removed':
          await _applyBoardRemoved(projectId, event);
          break;
        default:
          print('[SyncManager] Unknown event type: $eventType');
      }
    } catch (e) {
      print('[SyncManager] Error applying event: $e');
    }
  }

  static Future<void> _applyManifestUpdate(
    String projectId,
    Map<String, dynamic> event,
  ) async {
    // Load manifest, merge updates, save
    final manifest = await LocalProjectLoader.loadProjectManifest(projectId);
    if (manifest != null) {
      final updates = event['data'] as Map<String, dynamic>?;
      if (updates != null) {
        // Apply updates to manifest
        // This would need more sophisticated merge logic
        await LocalProjectLoader.updateProjectManifest(manifest);
      }
    }
  }

  static Future<void> _applyBoardAdded(
    String projectId,
    Map<String, dynamic> event,
  ) async {
    // Add board to manifest
    print('[SyncManager] Applying board added event');
  }

  static Future<void> _applyBoardRemoved(
    String projectId,
    Map<String, dynamic> event,
  ) async {
    // Remove board from manifest
    print('[SyncManager] Applying board removed event');
  }

  /// Sync project (bidirectional)
  static Future<bool> syncProject(
    String workspacePath,
    String projectId,
  ) async {
    // Push local changes first
    final pushed = await pushChangesToBackend(workspacePath, projectId);
    
    // Then pull remote updates
    final pulled = await pullRemoteUpdates(projectId);

    return pushed && pulled;
  }
}
