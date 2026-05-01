import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;
import '../services/server_config_service.dart';

class ChatCore {
  ChatCore({
    required this.workspaceId,
    required this.userId,
    String sessionToken = '',
    required this.onMessage,
    required this.onPresence,
    required this.onTyping,
    this.onReactionAdded,
    this.onReactionRemoved,
    this.onMessageEdited,
    this.onMessageDeleted,
    this.onMessageRead,
    this.onMentionReceived,
    this.onMessagePinned,
    this.onMessageUnpinned,
  }) : sessionToken = sessionToken;

  final String workspaceId;
  final String userId;
  final String sessionToken;
  final void Function(Map<String, dynamic>) onMessage;
  final void Function(Map<String, String>) onPresence;
  final void Function(Map<String, dynamic>) onTyping;
  final void Function(Map<String, dynamic>)? onReactionAdded;
  final void Function(Map<String, dynamic>)? onReactionRemoved;
  final void Function(Map<String, dynamic>)? onMessageEdited;
  final void Function(Map<String, dynamic>)? onMessageDeleted;
  final void Function(Map<String, dynamic>)? onMessageRead;
  final void Function(Map<String, dynamic>)? onMentionReceived;
  final void Function(Map<String, dynamic>)? onMessagePinned;
  final void Function(Map<String, dynamic>)? onMessageUnpinned;

  io.Socket? _chatSocket;
  io.Socket? _presenceSocket;
  String? _channelId;
  Timer? _heartbeatTimer;
  final Map<String, String> _presence = {};
  String? _cachedHostBase;

  /// Get the host base URL for WebSocket connections
  /// Uses runtime configuration from ServerConfigService
  Future<String> _getHostBase() async {
    // Check environment variable first (compile-time override)
    const envHostBase = String.fromEnvironment(
      'FLOWSPACE_SOCKET_BASE',
      defaultValue: '',
    );

    if (envHostBase.isNotEmpty) {
      return envHostBase;
    }

    // Use cached value if available
    if (_cachedHostBase != null) {
      return _cachedHostBase!;
    }

    // Get from runtime configuration
    try {
      final hostBase = await ServerConfigService.instance.getServerBaseUrl();
      _cachedHostBase = hostBase;
      return hostBase;
    } catch (e) {
      print('ChatCore: Error getting server config, using default: $e');
      // Default to Render production server
      return 'https://flowspace-backend.onrender.com';
    }
  }

  /// Clear cached host base (call this when server URL changes)
  static void clearCache() {
    // Note: This is a static method for consistency with other services
    // Individual ChatCore instances manage their own cache via _cachedHostBase
    // To fully clear, you need to dispose and recreate ChatCore instances
  }

  Future<void> connect(String channelId) async {
    _channelId = channelId;
    await _setupChatSocket(channelId);
    await _setupPresenceSocket(channelId);
  }

  Future<void> _setupChatSocket(String channelId) async {
    var hostBase = await _getHostBase();
    
    // Convert https:// to wss:// for secure WebSocket connections
    if (hostBase.startsWith('https://')) {
      hostBase = hostBase.replaceFirst('https://', 'wss://');
    } else if (hostBase.startsWith('http://')) {
      hostBase = hostBase.replaceFirst('http://', 'ws://');
    }
    
    print('ChatCore: Attempting Socket Connection to: $hostBase (channel: $channelId)');
    
    var queryParams = {
      'workspaceId': workspaceId,
      'channelId': channelId,
    };
    
    // TEMPORARILY DISABLED - Don't require token for testing
    // if (sessionToken.isNotEmpty) {
    //   queryParams['token'] = sessionToken;
    // }
    
    var builder = io.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setQuery(queryParams);

    if (sessionToken.isNotEmpty) {
      // Backend expects 'token' in auth object (JWT token) - primary method
      // Also in query string as fallback
      builder = builder.setAuth({'token': sessionToken});
      print('ChatCore: Using JWT token for authentication (length: ${sessionToken.length})');
    } else {
      // TEMPORARILY ALLOW CONNECTIONS WITHOUT TOKEN FOR TESTING
      print('ChatCore: No JWT token provided - connecting without auth (testing mode)');
    }

    final socket = io.io(hostBase, builder.build());

    socket
      ..onConnect((_) {
        print('ChatCore: Chat socket connected successfully to: $hostBase');
        print('ChatCore: Emitting channel.join for channel: $channelId');
        socket.emit('channel.join', {'channelId': channelId});
      })
      ..onDisconnect((reason) {
        print('ChatCore: Chat socket disconnected from: $hostBase. Reason: $reason');
        if (reason == 'io server disconnect') {
          print('ChatCore: Server actively disconnected - likely authentication failure. Check if backend is deployed with JWT auth.');
        }
      })
      ..onError((error) {
        print('ChatCore: Chat socket error on $hostBase: $error');
      })
      ..on('connect_error', (error) {
        print('ChatCore: Chat socket connection error: $error');
      })
      ..on('message.new', (data) {
        if (data is Map) {
          onMessage(Map<String, dynamic>.from(data as Map));
        }
      })
      ..on('reaction.added', (data) {
        if (data is Map && onReactionAdded != null) {
          onReactionAdded!(Map<String, dynamic>.from(data as Map));
        }
      })
      ..on('reaction.removed', (data) {
        if (data is Map && onReactionRemoved != null) {
          onReactionRemoved!(Map<String, dynamic>.from(data as Map));
        }
      })
      ..on('message.edited', (data) {
        if (data is Map && onMessageEdited != null) {
          onMessageEdited!(Map<String, dynamic>.from(data as Map));
        }
      })
      ..on('message.deleted', (data) {
        if (data is Map && onMessageDeleted != null) {
          onMessageDeleted!(Map<String, dynamic>.from(data as Map));
        }
      })
      ..on('message.read', (data) {
        if (data is Map && onMessageRead != null) {
          onMessageRead!(Map<String, dynamic>.from(data as Map));
        }
      })
      ..on('mention.received', (data) {
        if (data is Map && onMentionReceived != null) {
          onMentionReceived!(Map<String, dynamic>.from(data as Map));
        }
      })
      ..on('message.pinned', (data) {
        if (data is Map && onMessagePinned != null) {
          onMessagePinned!(Map<String, dynamic>.from(data as Map));
        }
      })
      ..on('message.unpinned', (data) {
        if (data is Map && onMessageUnpinned != null) {
          onMessageUnpinned!(Map<String, dynamic>.from(data as Map));
        }
      });

    try {
      socket.connect();
      _chatSocket = socket;
    } catch (e) {
      print('ChatCore: Error connecting chat socket to $hostBase: $e');
    }
  }

  Future<void> _setupPresenceSocket(String channelId) async {
    var hostBase = await _getHostBase();
    
    // Convert https:// to wss:// for secure WebSocket connections
    if (hostBase.startsWith('https://')) {
      hostBase = hostBase.replaceFirst('https://', 'wss://');
    } else if (hostBase.startsWith('http://')) {
      hostBase = hostBase.replaceFirst('http://', 'ws://');
    }
    
    // Presence uses Socket.IO namespace, not a path
    // The backend defines: @WebSocketGateway({ namespace: 'presence' })
    // So we connect to the base URL and Socket.IO will handle the namespace
    print('ChatCore: Attempting Presence Socket Connection to namespace /presence at: $hostBase (channel: $channelId)');
    
    var queryParams = {
      'workspaceId': workspaceId,
    };
    
    // TEMPORARILY DISABLED - Don't require token for testing
    // if (sessionToken.isNotEmpty) {
    //   queryParams['token'] = sessionToken;
    // }
    
    var builder = io.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setQuery(queryParams);

    if (sessionToken.isNotEmpty) {
      // Backend expects 'token' in auth object (JWT token) - primary method
      // Also in query string as fallback
      builder = builder.setAuth({'token': sessionToken});
      print('ChatCore: Presence socket using JWT token for authentication (length: ${sessionToken.length})');
    } else {
      // TEMPORARILY ALLOW CONNECTIONS WITHOUT TOKEN FOR TESTING
      print('ChatCore: No JWT token for presence socket - connecting without auth (testing mode)');
    }

    // Connect to the namespace /presence
    final socket = io.io('$hostBase/presence', builder.build());

    socket
      ..onConnect((_) {
        print('ChatCore: Presence socket connected successfully to namespace /presence');
        print('ChatCore: Emitting heartbeat and channel.join for channel: $channelId');
        socket.emit('heartbeat', {'status': 'online'});
        socket.emit('channel.join', {'channelId': channelId});
        _heartbeatTimer?.cancel();
        _heartbeatTimer = Timer.periodic(
          const Duration(seconds: 30),
          (_) => socket.emit('heartbeat', {'status': 'online'}),
        );
      })
      ..onDisconnect((reason) {
        print('ChatCore: Presence socket disconnected from namespace /presence. Reason: $reason');
        if (reason == 'io server disconnect') {
          print('ChatCore: Server actively disconnected presence - likely authentication failure. Check if backend is deployed with JWT auth.');
        }
      })
      ..onError((error) {
        print('ChatCore: Presence socket error on namespace /presence: $error');
      })
      ..on('connect_error', (error) {
        print('ChatCore: Presence socket connection error: $error');
      })
      ..on('presence.update', (data) {
        if (data is Map) {
          final payload = Map<String, dynamic>.from(data as Map);
          final user = payload['userId'] as String?;
          final status = payload['status'] as String? ?? 'offline';
          if (user != null) {
            if (status == 'offline') {
              _presence.remove(user);
            } else {
              _presence[user] = status;
            }
            onPresence(Map<String, String>.from(_presence));
          }
        }
      })
      ..on('typing', (data) {
        if (data is Map) {
          onTyping(Map<String, dynamic>.from(data as Map));
        }
      });

    try {
      socket.connect();
      _presenceSocket = socket;
    } catch (e) {
      print('ChatCore: Error connecting presence socket to namespace /presence: $e');
    }
  }

  void switchChannel(String channelId) {
    _channelId = channelId;
    _chatSocket?.emit('channel.join', {'channelId': channelId});
    _presenceSocket?.emit('channel.join', {'channelId': channelId});
  }

  void emitTyping(bool typing) {
    final channelId = _channelId;
    if (channelId == null) return;
    _presenceSocket?.emit('typing', {
      'channelId': channelId,
      'typing': typing,
    });
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _chatSocket
      ?..dispose()
      ..destroy();
    _presenceSocket
      ?..dispose()
      ..destroy();
  }
}
