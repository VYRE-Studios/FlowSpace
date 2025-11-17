import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Thin WebSocket bridge for FLŌ.
///
/// This is intentionally minimal: it exposes connection state, a broadcast
/// event stream, and a send method. Higher-level services (presence,
/// activity, calls) subscribe and interpret events.
class SocketService {
  SocketService._();

  static final SocketService instance = SocketService._();

  WebSocketChannel? _channel;
  final ValueNotifier<bool> connected = ValueNotifier<bool>(false);
  final ValueNotifier<Duration> latency =
      ValueNotifier<Duration>(Duration.zero);

  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _events.stream;

  Timer? _pingTimer;

  Future<void> connect() async {
    // Basic local gateway URL; can be made configurable later.
    // Try multiple ports in case backend auto-selected a different port
    final ports = [4000, 4001, 4002, 4003, 4004];
    
    for (final port in ports) {
      try {
        final uri = Uri.parse('ws://localhost:$port/ws');
        _channel = WebSocketChannel.connect(uri);
        
        // Set up listeners before marking as connected
        _channel!.stream.listen(
          (data) {
            try {
              final decoded = json.decode(data as String)
                  as Map<String, dynamic>;
              _events.add(decoded);
            } catch (_) {
              // Ignore malformed messages for now.
            }
          },
          onDone: () {
            connected.value = false;
            _scheduleReconnect();
          },
          onError: (error) {
            // Silently handle connection errors - backend might not be running
            connected.value = false;
            _scheduleReconnect();
          },
          cancelOnError: true,
        );

        // Only mark as connected if we got here without exception
        connected.value = true;
        _startPing();
        return; // Successfully connected
      } catch (e) {
        // Try next port - don't log errors, backend might not be running
        _channel = null;
        if (port == ports.last) {
          // All ports failed, schedule reconnect
          connected.value = false;
          _scheduleReconnect();
        }
      }
    }
  }

  void _scheduleReconnect() {
    _pingTimer?.cancel();
    // Only reconnect if we're not already trying to connect
    // Increase delay to reduce spam - backend might not be running
    if (!connected.value) {
      Future.delayed(const Duration(seconds: 10), () {
        if (!connected.value && mounted) {
          try {
            connect();
          } catch (e) {
            // Silently fail - backend might not be running
          }
        }
      });
    }
  }
  
  bool mounted = true; // Track if service is still active

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer =
        Timer.periodic(const Duration(seconds: 2), (Timer timer) {
      final sent = DateTime.now().millisecondsSinceEpoch;
      send(<String, dynamic>{
        'type': 'ping',
        'sent': sent,
      });
    });

    events.listen((Map<String, dynamic> event) {
      if (event['type'] == 'pong' && event['sent'] is int) {
        final sent = event['sent'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        final diff = now - sent;
        latency.value = Duration(milliseconds: diff);
      }
    });
  }

  void send(Map<String, dynamic> data) {
    if (connected.value) {
      _channel?.sink.add(json.encode(data));
    }
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    await _channel?.sink.close();
    connected.value = false;
  }
}


