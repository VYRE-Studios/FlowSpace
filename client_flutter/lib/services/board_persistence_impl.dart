// lib/services/board_persistence_impl.dart

import 'dart:convert';
import 'dart:io';
import '../models/board_content.dart';
import 'board_persistence_contract.dart';

class BoardPersistenceImpl implements BoardPersistenceContract {
  final String workspacePath;

  BoardPersistenceImpl({required this.workspacePath});

  String _boardFile(String projectId, String boardId) {
    return '$workspacePath/$projectId/boards/$boardId.json';
  }

  @override
  Future<BoardContent> loadBoard(String projectId, String boardId) async {
    final path = _boardFile(projectId, boardId);
    final file = File(path);

    if (!file.existsSync()) {
      return BoardContent.empty();
    }

    final raw = await file.readAsString();
    final jsonData = jsonDecode(raw);

    return BoardContent.fromJson(jsonData);
  }

  @override
  Future<void> saveBoard(
      String projectId, String boardId, BoardContent content) async {
    final path = _boardFile(projectId, boardId);
    final file = File(path);

    file.createSync(recursive: true);
    await file.writeAsString(jsonEncode(content.toJson()));
  }
}
