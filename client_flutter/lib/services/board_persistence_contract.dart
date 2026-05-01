// lib/services/board_persistence_contract.dart

import '../models/board_content.dart';

abstract class BoardPersistenceContract {
  Future<BoardContent> loadBoard(String projectId, String boardId);
  Future<void> saveBoard(String projectId, String boardId, BoardContent content);
}
