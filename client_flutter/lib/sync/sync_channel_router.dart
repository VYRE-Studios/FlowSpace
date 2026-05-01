// lib/sync/sync_channel_router.dart

import 'package:flutter/material.dart';
import 'sync_message.dart';
import 'sync_op_types.dart';
import '../presence/presence_store.dart';

typedef BoardOpHandler = void Function(SyncMessage msg);

class SyncChannelRouter {
  BoardOpHandler? onStroke;
  BoardOpHandler? onNode;
  BoardOpHandler? onTimeline;
  BoardOpHandler? onPresence;
  PresenceStore? presenceStore;

  void attachPresenceStore(PresenceStore store) {
    presenceStore = store;
  }

  void route(SyncMessage msg) {
    switch (msg.opType) {
      case SyncOp.strokeAdd:
      case SyncOp.strokeModify:
        if (onStroke != null) onStroke!(msg);
        break;

      case SyncOp.nodeAdd:
      case SyncOp.nodeModify:
      case SyncOp.nodeDelete:
        if (onNode != null) onNode!(msg);
        break;

      case SyncOp.timelineEventAdd:
      case SyncOp.timelineEventMove:
      case SyncOp.timelineEventResize:
      case SyncOp.timelineMarkerAdd:
      case SyncOp.timelineMarkerMove:
        if (onTimeline != null) onTimeline!(msg);
        break;

      case SyncOp.presence:
      case SyncOp.cursor:
        if (presenceStore != null) {
          final user = msg.payload['userId'];
          final x = msg.payload['x']?.toDouble() ?? 0;
          final y = msg.payload['y']?.toDouble() ?? 0;

          presenceStore!.updatePresence(
            userId: user,
            cursor: Offset(x, y),
          );
        }
        if (onPresence != null) onPresence!(msg);
        break;

      default:
        break;
    }
  }
}
