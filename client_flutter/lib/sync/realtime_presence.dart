// lib/sync/realtime_presence.dart

import 'sync_message.dart';
import 'sync_op_types.dart';

class RealtimePresence {
  final String userId;
  final String boardId;

  RealtimePresence({
    required this.userId,
    required this.boardId,
  });

  SyncMessage buildHeartbeat() {
    return SyncMessage(
      boardId: boardId,
      opType: SyncOp.presence,
      payload: {
        'userId': userId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
