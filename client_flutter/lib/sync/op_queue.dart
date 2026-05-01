// lib/sync/op_queue.dart

import 'sync_message.dart';

class OpQueue {
  final List<SyncMessage> _pending = [];
  final List<SyncMessage> _inFlight = [];

  void enqueue(SyncMessage msg) {
    _pending.add(msg);
  }

  bool get hasWork => _pending.isNotEmpty || _inFlight.isNotEmpty;

  SyncMessage? nextToSend() {
    if (_pending.isEmpty) return null;
    final msg = _pending.removeAt(0);
    _inFlight.add(msg);
    return msg;
  }

  void ack(SyncMessage msg) {
    _inFlight.removeWhere((m) =>
        m.boardId == msg.boardId &&
        m.opType == msg.opType &&
        m.timestamp == msg.timestamp);
  }

  void retryUnacked() {
    _pending.insertAll(0, _inFlight);
    _inFlight.clear();
  }
}
