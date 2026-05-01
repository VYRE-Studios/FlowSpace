// lib/services/timeline_persistence.dart

import 'dart:convert';
import 'dart:io';

import '../modules/story/timeline_models.dart';

class TimelinePersistenceService {
  final String workspacePath;

  TimelinePersistenceService({required this.workspacePath});

  Future<TimelineStateModel?> load(String projectId, String boardId) async {
    final path = '$workspacePath/$projectId/$boardId/timeline.json';
    final file = File(path);

    if (!file.existsSync()) {
      return null;
    }

    final jsonData = jsonDecode(await file.readAsString());
    return TimelineStateModel.fromJson(jsonData);
  }

  Future<void> save(
      String projectId, String boardId, TimelineStateModel model) async {
    final dir = Directory('$workspacePath/$projectId/$boardId');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final file = File('${dir.path}/timeline.json');
    await file.writeAsString(jsonEncode(model.toJson()));
  }
}
