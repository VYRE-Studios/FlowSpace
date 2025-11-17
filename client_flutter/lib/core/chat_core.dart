import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

class ChatCore {
  ChatCore({
    required this.workspaceId,
    required this.userId,
    String sessionToken = '',
    required this.onMessage,
    required this.onPresence,
    required this.onTyping,
  }) : sessionToken = sessionToken;

  final String workspaceId;
  final String userId;
  final String sessionToken;
  final void Function(Map<String, dynamic>) onMessage;
  final void Function(Map<String, String>) onPresence;
  final void Function(Map<String, dynamic>) onTyping;

  io.Socket? _chatSocket;
  io.Socket? _presenceSocket;
  String? _channelId;
  Timer? _heartbeatTimer;
  final Map<String, String> _presence = {};

  static const String _hostBase = String.fromEnvironment(
    'FLOWSPACE_SOCKET_BASE',
    defaultValue: 'http://localhost:4000',
  );

  void connect(String channelId) {
    _channelId = channelId;
    _setupChatSocket(channelId);
    _setupPresenceSocket(channelId);
  }

  void _setupChatSocket(String channelId) {
    var builder = io.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setQuery({
          'workspaceId': workspaceId,
          'channelId': channelId,
        });

    if (sessionToken.isNotEmpty) {
      builder = builder.setAuth({'sessionToken': sessionToken});
    }

    final socket = io.io(_hostBase, builder.build());

    socket
      ..onConnect((_) {
        socket.emit('channel.join', {'channelId': channelId});
      })
      ..on('message.new', (data) {
        if (data is Map) {
          onMessage(Map<String, dynamic>.from(data as Map));
        }
      });

    try {
      socket.connect();
      _chatSocket = socket;
    } catch (e) {
      // Silently handle - backend might not be running
      print('ChatCore: Error connecting chat socket: $e');
    }
  }

  void _setupPresenceSocket(String channelId) {
    var builder = io.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setQuery({
          'workspaceId': workspaceId,
        });

    if (sessionToken.isNotEmpty) {
      builder = builder.setAuth({'sessionToken': sessionToken});
    }

    final socket = io.io('$_hostBase/presence', builder.build());

    socket
      ..onConnect((_) {
        socket.emit('heartbeat', {'status': 'online'});
        socket.emit('channel.join', {'channelId': channelId});
        _heartbeatTimer?.cancel();
        _heartbeatTimer = Timer.periodic(
          const Duration(seconds: 30),
          (_) => socket.emit('heartbeat', {'status': 'online'}),
        );
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
      // Silently handle - backend might not be running
      print('ChatCore: Error connecting presence socket: $e');
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