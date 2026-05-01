// lib/sync/realtime_socket.dart

import 'dart:async';
import 'dart:io';

import 'sync_message.dart';

typedef SyncMessageHandler = void Function(SyncMessage msg);

class RealtimeSocket {
  final String url;
  final SyncMessageHandler onMessage;

  WebSocket? _socket;
  Timer? _reconnectTimer;
  bool _connecting = false;

  RealtimeSocket({
    required this.url,
    required this.onMessage,
  });

  Future<void> connect() async {
    if (_connecting) return;
    _connecting = true;

    try {
      _socket = await WebSocket.connect(url);
      _socket!.listen(
        _handleMessage,
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
      );
    } catch (_) {
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  void _handleMessage(dynamic data) {
    if (data is String) {
      final msg = SyncMessage.decode(data);
      onMessage(msg);
    }
  }

  void send(SyncMessage msg) {
    if (_socket == null || _socket!.readyState != WebSocket.open) {
      return;
    }
    _socket!.add(msg.encode());
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;

    _reconnectTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        if (_socket == null || _socket!.readyState != WebSocket.open) {
          connect();
        } else {
          _reconnectTimer?.cancel();
          _reconnectTimer = null;
        }
      },
    );
  }

  void disconnect() {
    _socket?.close();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _socket = null;
  }

  void dispose() {
    disconnect();
  }
}
