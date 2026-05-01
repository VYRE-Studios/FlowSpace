// lib/sync/merge_engine.dart

import 'sync_message.dart';
import 'sync_op_types.dart';

typedef ApplyFn = void Function(Map<String, dynamic> payload);

class MergeEngine {
  ApplyFn? applyStrokeAdd;
  ApplyFn? applyStrokeModify;

  ApplyFn? applyNodeAdd;
  ApplyFn? applyNodeModify;
  ApplyFn? applyNodeDelete;

  ApplyFn? applyTimelineEventAdd;
  ApplyFn? applyTimelineEventMove;
  ApplyFn? applyTimelineEventResize;

  ApplyFn? applyTimelineMarkerAdd;
  ApplyFn? applyTimelineMarkerMove;

  ApplyFn? applyAssetImported;
  ApplyFn? applyAssetPlaced;
  ApplyFn? applyAssetMoved;

  void apply(SyncMessage msg) {
    switch (msg.opType) {
      case SyncOp.strokeAdd:
        if (applyStrokeAdd != null) applyStrokeAdd!(msg.payload);
        break;

      case SyncOp.strokeModify:
        if (applyStrokeModify != null) applyStrokeModify!(msg.payload);
        break;

      case SyncOp.nodeAdd:
        if (applyNodeAdd != null) applyNodeAdd!(msg.payload);
        break;

      case SyncOp.nodeModify:
        if (applyNodeModify != null) applyNodeModify!(msg.payload);
        break;

      case SyncOp.nodeDelete:
        if (applyNodeDelete != null) applyNodeDelete!(msg.payload);
        break;

      case SyncOp.timelineEventAdd:
        if (applyTimelineEventAdd != null) {
          applyTimelineEventAdd!(msg.payload);
        }
        break;

      case SyncOp.timelineEventMove:
        if (applyTimelineEventMove != null) {
          applyTimelineEventMove!(msg.payload);
        }
        break;

      case SyncOp.timelineEventResize:
        if (applyTimelineEventResize != null) {
          applyTimelineEventResize!(msg.payload);
        }
        break;

      case SyncOp.timelineMarkerAdd:
        if (applyTimelineMarkerAdd != null) {
          applyTimelineMarkerAdd!(msg.payload);
        }
        break;

      case SyncOp.timelineMarkerMove:
        if (applyTimelineMarkerMove != null) {
          applyTimelineMarkerMove!(msg.payload);
        }
        break;

      case SyncOp.assetImported:
        if (applyAssetImported != null) {
          applyAssetImported!(msg.payload);
        }
        break;

      case SyncOp.assetPlaced:
        if (applyAssetPlaced != null) {
          applyAssetPlaced!(msg.payload);
        }
        break;

      case SyncOp.assetMoved:
        if (applyAssetMoved != null) {
          applyAssetMoved!(msg.payload);
        }
        break;
    }
  }
}
