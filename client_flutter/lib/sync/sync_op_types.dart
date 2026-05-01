// lib/sync/sync_op_types.dart

class SyncOp {
  static const strokeAdd = 'stroke_add';
  static const strokeModify = 'stroke_modify';

  static const nodeAdd = 'node_add';
  static const nodeModify = 'node_modify';
  static const nodeDelete = 'node_delete';

  static const timelineEventAdd = 'timeline_event_add';
  static const timelineEventMove = 'timeline_event_move';
  static const timelineEventResize = 'timeline_event_resize';

  static const timelineMarkerAdd = 'timeline_marker_add';
  static const timelineMarkerMove = 'timeline_marker_move';

  static const assetImported = 'asset_imported';
  static const assetPlaced = 'asset_placed';
  static const assetMoved = 'asset_moved';

  static const presence = 'presence';
  static const cursor = 'cursor';
}
