import 'dart:io';
import 'dart:convert';
import 'safe_writer.dart';

/// Tracks changes to projects for eventual backend sync
/// Stores change events in <workspace>/VyreVault/project-changes/<projectId>/
class ChangeTrackingService {
  /// Record a change event for a project
  static Future<void> recordChange(
    String workspacePath,
    String projectId,
    Map<String, dynamic> event,
  ) async {
    final dir = Directory('$workspacePath/VyreVault/project-changes/$projectId');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/$timestamp.event.json');

    final eventData = {
      'timestamp': timestamp,
      'projectId': projectId,
      'event': event,
    };

    await SafeWriter.writeAtomic(file, jsonEncode(eventData));
    print('[ChangeTracking] Recorded change for project $projectId');
  }

  /// List all change events for a project (sorted by timestamp)
  static List<File> listChanges(String workspacePath, String projectId) {
    final dir = Directory('$workspacePath/VyreVault/project-changes/$projectId');
    if (!dir.existsSync()) {
      return [];
    }

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.event.json'))
        .toList();

    // Sort by filename (timestamp)
    files.sort((a, b) => a.path.compareTo(b.path));

    return files;
  }

  /// Get count of pending changes
  static int getPendingChangeCount(String workspacePath, String projectId) {
    return listChanges(workspacePath, projectId).length;
  }

  /// Clear all changes for a project (after successful sync)
  static Future<void> clearChanges(String workspacePath, String projectId) async {
    final dir = Directory('$workspacePath/VyreVault/project-changes/$projectId');
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
      print('[ChangeTracking] Cleared changes for project $projectId');
    }
  }

  /// Delete a specific change file
  static Future<void> deleteChange(File changeFile) async {
    if (changeFile.existsSync()) {
      changeFile.deleteSync();
    }
  }
}
