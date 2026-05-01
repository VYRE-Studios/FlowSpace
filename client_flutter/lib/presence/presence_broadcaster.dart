// lib/presence/presence_broadcaster.dart

import 'dart:async';
import 'package:flutter/material.dart';

import '../sync/sync_manager.dart';
import '../sync/sync_op_types.dart';

class PresenceBroadcaster {
  final String boardId;
  Timer? _timer;
  Offset _cursor = Offset.zero;

  PresenceBroadcaster({required this.boardId});

  void updateCursor(Offset pos) {
    _cursor = pos;
  }

  void start() {
    _timer = Timer.periodic(const Duration(milliseconds: 180), (_) {
      SyncManager.instance.send(
        boardId,
        SyncOp.cursor,
        {
          'userId': SyncManager.instance.clientId,
          'x': _cursor.dx,
          'y': _cursor.dy,
        },
      );
    });
  }

  void stop() {
    _timer?.cancel();
  }
}
