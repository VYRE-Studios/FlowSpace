import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../server_config_service.dart';

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
  String? _cachedSocketUrl;

  Future<String> _getSocketUrl() async {
    // Use cached value if available
    if (_cachedSocketUrl != null) {
      return _cachedSocketUrl!;
    }

    // Get from runtime configuration
    try {
      var hostBase = await ServerConfigService.instance.getServerBaseUrl();
      
      // Parse the base URL to extract host and port properly
      final baseUri = Uri.parse(hostBase);
      
      // Determine WebSocket scheme and port
      final isSecure = baseUri.scheme == 'https' || hostBase.startsWith('https://');
      final wsScheme = isSecure ? 'wss' : 'ws';
      
      // Use default ports if not specified (443 for wss, 80 for ws)
      final port = baseUri.hasPort && baseUri.port != 0 
          ? baseUri.port 
          : (isSecure ? 443 : 80);
      
      // Construct clean WebSocket URL explicitly
      // For Railway/production, don't include port if it's the default (443 for wss, 80 for ws)
      final socketUrl = port == (isSecure ? 443 : 80)
          ? '$wsScheme://${baseUri.host}/ws'
          : '$wsScheme://${baseUri.host}:$port/ws';
      
      // Verify the URL is valid by parsing it back
      final testUri = Uri.parse(socketUrl);
      if (testUri.scheme != wsScheme || testUri.host.isEmpty || testUri.port == 0) {
        // If parsing failed, construct URI explicitly
        final explicitUri = Uri(
          scheme: wsScheme,
          host: baseUri.host,
          port: port,
          path: '/ws',
        );
        _cachedSocketUrl = explicitUri.toString();
        print('SocketService: Constructed explicit URI: ${_cachedSocketUrl}');
        return _cachedSocketUrl!;
      }
      
      _cachedSocketUrl = socketUrl;
      return socketUrl;
    } catch (e) {
      print('SocketService: Error getting server config, using default: $e');
      // Default to Render production server with wss://
      return 'wss://flowspace-backend.onrender.com/ws';
    }
  }

  void clearCache() {
    _cachedSocketUrl = null;
  }

  Future<void> connect() async {
    try {
      final socketUrl = await _getSocketUrl();
      print('SocketService: Attempting Socket Connection to: $socketUrl');
      
      // Parse URI and validate
      var uri = Uri.parse(socketUrl);
      
      // If URI parsing failed (port 0, empty host, wrong scheme), reconstruct explicitly
      if (uri.port == 0 || uri.host.isEmpty || (uri.scheme != 'wss' && uri.scheme != 'ws')) {
        print('SocketService: URI parsing issue detected, reconstructing...');
        print('SocketService: Parsed URI - scheme: ${uri.scheme}, host: ${uri.host}, port: ${uri.port}');
        
        // Extract components manually
        final urlStr = socketUrl.trim();
        final isWss = urlStr.startsWith('wss://');
        final scheme = isWss ? 'wss' : 'ws';
        final withoutScheme = urlStr.substring(isWss ? 6 : 5); // Remove 'wss://' or 'ws://'
        
        // Split host:port from path
        final pathIndex = withoutScheme.indexOf('/');
        final hostPort = pathIndex >= 0 ? withoutScheme.substring(0, pathIndex) : withoutScheme;
        final path = pathIndex >= 0 ? withoutScheme.substring(pathIndex) : '/ws';
        
        // Parse host and port
        String host;
        int port;
        if (hostPort.contains(':')) {
          final parts = hostPort.split(':');
          host = parts[0];
          port = int.tryParse(parts[1]) ?? (isWss ? 443 : 80);
        } else {
          host = hostPort;
          port = isWss ? 443 : 80;
        }
        
        // Construct URI explicitly
        uri = Uri(
          scheme: scheme,
          host: host,
          port: port,
          path: path,
        );
        
        print('SocketService: Reconstructed URI - scheme: ${uri.scheme}, host: ${uri.host}, port: ${uri.port}, path: ${uri.path}');
      } else {
        print('SocketService: Connecting with URI - scheme: ${uri.scheme}, host: ${uri.host}, port: ${uri.port}, path: ${uri.path}');
      }
      
      // Final validation
      if (uri.scheme != 'wss' && uri.scheme != 'ws') {
        throw Exception('Invalid WebSocket scheme: ${uri.scheme}. Expected wss:// or ws://');
      }
      
      if (uri.port == 0) {
        throw Exception('Invalid WebSocket port: 0. Final URI: $uri');
      }
      
      if (uri.host.isEmpty) {
        throw Exception('Invalid WebSocket host: empty. Final URI: $uri');
      }
      
      // Note: Backend uses Socket.IO, not raw WebSockets
      // This service is for raw WebSocket connections, which the backend doesn't support
      // ChatCore handles Socket.IO connections correctly
      // For now, we'll skip the connection attempt to avoid errors
      print('SocketService: Backend uses Socket.IO, not raw WebSockets. Skipping raw WebSocket connection.');
      print('SocketService: ChatCore handles Socket.IO connections for chat and presence.');
      print('SocketService: This service is disabled until raw WebSocket support is added to backend.');
      
      // Don't actually connect - backend doesn't support raw WebSockets
      // Mark as "connected" to prevent reconnect loops, but don't actually connect
      connected.value = false;
      return;
      
      // OLD CODE (commented out - backend doesn't support raw WebSockets):
      /*
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
        print('SocketService: Successfully connected to: $socketUrl');
        _startPing();
        return; // Successfully connected
      */
      } catch (e) {
        // Connection failed
        print('SocketService: Error connecting to socket: $e');
        _channel = null;
        connected.value = false;
        _scheduleReconnect();
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


