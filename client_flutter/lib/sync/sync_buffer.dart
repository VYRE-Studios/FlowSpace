// lib/sync/sync_buffer.dart

import 'sync_message.dart';

class SyncBuffer {
  final List<SyncMessage> _queue = [];

  void push(SyncMessage msg) {
    _queue.add(msg);
  }

  bool get hasPending => _queue.isNotEmpty;

  List<SyncMessage> drain() {
    final pending = List<SyncMessage>.from(_queue);
    _queue.clear();
    return pending;
  }
}
