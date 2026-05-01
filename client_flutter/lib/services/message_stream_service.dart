import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/message_event.dart';
import '../models/typing_event.dart';
import '../models/reaction.dart';
import '../models/pinned_message.dart';
import '../models/bulletin.dart';
import 'auth_service.dart';

class MessageStreamService {
  io.Socket? _socket;
  final String _baseUrl;
  
  // Stream controllers for different message events
  final _messageController = StreamController<MessageEvent>.broadcast();
  final _messageEditedController = StreamController<MessageEvent>.broadcast();
  final _messageDeletedController = StreamController<String>.broadcast();
  final _messageReadController = StreamController<Map<String, dynamic>>.broadcast();
  final _deliveryStateController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();
  final _reactionController = StreamController<ReactionEvent>.broadcast();
  final _pinController = StreamController<PinEvent>.broadcast();
  final _bulletinController = StreamController<BulletinEvent>.broadcast();
  
  // Public streams
  Stream<MessageEvent> get messageStream => _messageController.stream;
  Stream<MessageEvent> get messageEditedStream => _messageEditedController.stream;
  Stream<String> get messageDeletedStream => _messageDeletedController.stream;
  Stream<Map<String, dynamic>> get messageReadStream => _messageReadController.stream;
  Stream<Map<String, dynamic>> get deliveryStateStream => _deliveryStateController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  Stream<TypingEvent> get typingStream => _typingController.stream;
  Stream<ReactionEvent> get reactionStream => _reactionController.stream;
  Stream<PinEvent> get pinStream => _pinController.stream;
  Stream<BulletinEvent> get bulletinStream => _bulletinController.stream;
  
  bool get isConnected => _socket?.connected ?? false;
  
  MessageStreamService(this._baseUrl);
  
  /// Connect to WebSocket server for a specific workspace
  Future<void> connect(String workspaceId, {String? channelId}) async {
    if (_socket?.connected ?? false) {
      print('[MessageStreamService] Already connected');
      return;
    }
    
    final token = await AuthService.getToken();
    if (token == null) {
      print('[MessageStreamService] No auth token available');
      return;
    }
    
    _socket = io.io(
      _baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .setQuery({
            'workspaceId': workspaceId,
            if (channelId != null) 'channelId': channelId,
          })
          .build(),
    );
    
    _setupEventHandlers();
    
    _socket!.connect();
    print('[MessageStreamService] Connecting to $workspaceId${channelId != null ? " channel $channelId" : ""}');
  }
  
  /// Disconnect from WebSocket server
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _connectionStateController.add(false);
      print('[MessageStreamService] Disconnected');
    }
  }
  
  /// Join a specific channel
  void joinChannel(String channelId) {
    if (_socket?.connected ?? false) {
      _socket!.emit('channel.join', {'channelId': channelId});
      print('[MessageStreamService] Joined channel: $channelId');
    }
  }
  
  /// Leave a specific channel
  void leaveChannel(String channelId) {
    if (_socket?.connected ?? false) {
      _socket!.emit('channel.leave', {'channelId': channelId});
      print('[MessageStreamService] Left channel: $channelId');
    }
  }
  
  /// Send a message (returns tempId for optimistic rendering)
  String sendMessage({
    required String channelId,
    required String content,
    List<String>? attachments,
    String? threadId,
  }) {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    if (_socket?.connected ?? false) {
      _socket!.emit('message.send', {
        'tempId': tempId,
        'channelId': channelId,
        'content': content,
        if (attachments != null) 'attachments': attachments,
        if (threadId != null) 'threadId': threadId,
      });
      print('[MessageStreamService] Sent message with tempId: $tempId');
    }
    
    return tempId;
  }
  
  /// Edit a message
  void editMessage({
    required String messageId,
    required String content,
  }) {
    if (_socket?.connected ?? false) {
      _socket!.emit('message.edit', {
        'messageId': messageId,
        'content': content,
      });
      print('[MessageStreamService] Edited message: $messageId');
    }
  }
  
  /// Delete a message
  void deleteMessage(String messageId) {
    if (_socket?.connected ?? false) {
      _socket!.emit('message.delete', {
        'messageId': messageId,
      });
      print('[MessageStreamService] Deleted message: $messageId');
    }
  }
  
  /// Mark message as read
  void markAsRead(String messageId) {
    if (_socket?.connected ?? false) {
      _socket!.emit('message.read', {
        'messageId': messageId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }
  
  /// Send typing indicator
  void sendTypingIndicator(String channelId, bool isTyping) {
    if (_socket?.connected ?? false) {
      _socket!.emit('typing', {
        'channelId': channelId,
        'typing': isTyping,
      });
    }
  }
  
  /// Send a reaction to a message
  Future<void> sendReaction({
    required String channelId,
    required String messageId,
    required String emoji,
    required ReactionAction action,
  }) async {
    if (_socket?.connected ?? false) {
      _socket!.emit('reaction.${action == ReactionAction.add ? 'add' : 'remove'}', {
        'channelId': channelId,
        'messageId': messageId,
        'emoji': emoji,
      });
      print('[MessageStreamService] ${action == ReactionAction.add ? 'Added' : 'Removed'} reaction $emoji on message $messageId');
    }
  }
  
  /// Pin a message
  Future<void> pinMessage({
    required String channelId,
    required String messageId,
    String? reason,
  }) async {
    if (_socket?.connected ?? false) {
      _socket!.emit('message.pin', {
        'channelId': channelId,
        'messageId': messageId,
        if (reason != null) 'reason': reason,
      });
      print('[MessageStreamService] Pinned message $messageId');
    }
  }
  
  /// Unpin a message
  Future<void> unpinMessage({
    required String channelId,
    required String messageId,
  }) async {
    if (_socket?.connected ?? false) {
      _socket!.emit('message.unpin', {
        'channelId': channelId,
        'messageId': messageId,
      });
      print('[MessageStreamService] Unpinned message $messageId');
    }
  }
  
  /// Create a bulletin
  Future<void> createBulletin(BulletinRequest request) async {
    if (_socket?.connected ?? false) {
      _socket!.emit('bulletin.create', request.toJson());
      print('[MessageStreamService] Creating bulletin: ${request.title}');
    }
  }
  
  /// Update a bulletin
  Future<void> updateBulletin(BulletinRequest request) async {
    if (_socket?.connected ?? false) {
      _socket!.emit('bulletin.update', request.toJson());
      print('[MessageStreamService] Updating bulletin: ${request.id}');
    }
  }
  
  /// Delete a bulletin
  Future<void> deleteBulletin(String workspaceId, String bulletinId) async {
    if (_socket?.connected ?? false) {
      _socket!.emit('bulletin.delete', {
        'workspaceId': workspaceId,
        'bulletinId': bulletinId,
      });
      print('[MessageStreamService] Deleting bulletin: $bulletinId');
    }
  }
  
  /// Pin a bulletin
  Future<void> pinBulletin(String workspaceId, String bulletinId) async {
    if (_socket?.connected ?? false) {
      _socket!.emit('bulletin.pin', {
        'workspaceId': workspaceId,
        'bulletinId': bulletinId,
      });
      print('[MessageStreamService] Pinning bulletin: $bulletinId');
    }
  }
  
  /// Unpin a bulletin
  Future<void> unpinBulletin(String workspaceId, String bulletinId) async {
    if (_socket?.connected ?? false) {
      _socket!.emit('bulletin.unpin', {
        'workspaceId': workspaceId,
        'bulletinId': bulletinId,
      });
      print('[MessageStreamService] Unpinning bulletin: $bulletinId');
    }
  }
  
  /// Setup event handlers for incoming WebSocket events
  void _setupEventHandlers() {
    _socket!.onConnect((_) {
      print('[MessageStreamService] Connected');
      _connectionStateController.add(true);
    });
    
    _socket!.onDisconnect((_) {
      print('[MessageStreamService] Disconnected');
      _connectionStateController.add(false);
    });
    
    _socket!.onConnectError((data) {
      print('[MessageStreamService] Connection error: $data');
      _connectionStateController.add(false);
    });
    
    // New message received
    _socket!.on('message.new', (data) {
      try {
        final message = MessageEvent.fromJson(data as Map<String, dynamic>);
        _messageController.add(message);
      } catch (e) {
        print('[MessageStreamService] Error parsing message.new: $e');
      }
    });
    
    // Message sent confirmation (server acknowledged our optimistic message)
    _socket!.on('message.sent', (data) {
      try {
        final tempId = data['tempId'] as String?;
        final messageId = data['messageId'] as String;
        final timestamp = data['timestamp'] as int?;
        
        _deliveryStateController.add({
          'tempId': tempId,
          'messageId': messageId,
          'state': 'sent',
          if (timestamp != null) 'timestamp': timestamp,
        });
      } catch (e) {
        print('[MessageStreamService] Error parsing message.sent: $e');
      }
    });
    
    // Message send failed
    _socket!.on('message.failed', (data) {
      try {
        final tempId = data['tempId'] as String?;
        final error = data['error'] as String?;
        
        _deliveryStateController.add({
          'tempId': tempId,
          'state': 'failed',
          'error': error,
        });
      } catch (e) {
        print('[MessageStreamService] Error parsing message.failed: $e');
      }
    });
    
    // Message delivered to recipient
    _socket!.on('message.delivered', (data) {
      try {
        final messageId = data['messageId'] as String;
        
        _deliveryStateController.add({
          'messageId': messageId,
          'state': 'delivered',
        });
      } catch (e) {
        print('[MessageStreamService] Error parsing message.delivered: $e');
      }
    });
    
    // Message edited
    _socket!.on('message.edited', (data) {
      try {
        final message = MessageEvent.fromJson(data as Map<String, dynamic>);
        _messageEditedController.add(message);
      } catch (e) {
        print('[MessageStreamService] Error parsing message.edited: $e');
      }
    });
    
    // Message deleted
    _socket!.on('message.deleted', (data) {
      try {
        final messageId = data['messageId'] as String;
        _messageDeletedController.add(messageId);
      } catch (e) {
        print('[MessageStreamService] Error parsing message.deleted: $e');
      }
    });
    
    // Message read receipt
    _socket!.on('message.read', (data) {
      try {
        _messageReadController.add(data as Map<String, dynamic>);
      } catch (e) {
        print('[MessageStreamService] Error parsing message.read: $e');
      }
    });
    
    // Typing indicator
    _socket!.on('typing', (data) {
      try {
        final typingEvent = TypingEvent.fromJson(data as Map<String, dynamic>);
        _typingController.add(typingEvent);
      } catch (e) {
        print('[MessageStreamService] Error parsing typing: $e');
      }
    });
    
    // Reaction added
    _socket!.on('reaction.added', (data) {
      try {
        final reactionEvent = ReactionEvent.fromJson(data as Map<String, dynamic>);
        _reactionController.add(reactionEvent);
      } catch (e) {
        print('[MessageStreamService] Error parsing reaction.added: $e');
      }
    });
    
    // Reaction removed
    _socket!.on('reaction.removed', (data) {
      try {
        final reactionEvent = ReactionEvent.fromJson(data as Map<String, dynamic>);
        _reactionController.add(reactionEvent);
      } catch (e) {
        print('[MessageStreamService] Error parsing reaction.removed: $e');
      }
    });
    
    // Message pinned
    _socket!.on('message.pinned', (data) {
      try {
        final pinEvent = PinEvent.fromJson(data as Map<String, dynamic>);
        _pinController.add(pinEvent);
      } catch (e) {
        print('[MessageStreamService] Error parsing message.pinned: $e');
      }
    });
    
    // Message unpinned
    _socket!.on('message.unpinned', (data) {
      try {
        final pinEvent = PinEvent.fromJson(data as Map<String, dynamic>);
        _pinController.add(pinEvent);
      } catch (e) {
        print('[MessageStreamService] Error parsing message.unpinned: $e');
      }
    });
    
    // Bulletin created
    _socket!.on('bulletin.created', (data) {
      try {
        final bulletinEvent = BulletinEvent.fromJson(data as Map<String, dynamic>);
        _bulletinController.add(bulletinEvent);
      } catch (e) {
        print('[MessageStreamService] Error parsing bulletin.created: $e');
      }
    });
    
    // Bulletin updated
    _socket!.on('bulletin.updated', (data) {
      try {
        final bulletinEvent = BulletinEvent.fromJson(data as Map<String, dynamic>);
        _bulletinController.add(bulletinEvent);
      } catch (e) {
        print('[MessageStreamService] Error parsing bulletin.updated: $e');
      }
    });
    
    // Bulletin deleted
    _socket!.on('bulletin.deleted', (data) {
      try {
        final bulletinEvent = BulletinEvent.fromJson(data as Map<String, dynamic>);
        _bulletinController.add(bulletinEvent);
      } catch (e) {
        print('[MessageStreamService] Error parsing bulletin.deleted: $e');
      }
    });
    
    // Bulletin pinned
    _socket!.on('bulletin.pinned', (data) {
      try {
        final bulletinEvent = BulletinEvent.fromJson(data as Map<String, dynamic>);
        _bulletinController.add(bulletinEvent);
      } catch (e) {
        print('[MessageStreamService] Error parsing bulletin.pinned: $e');
      }
    });
    
    // Bulletin unpinned
    _socket!.on('bulletin.unpinned', (data) {
      try {
        final bulletinEvent = BulletinEvent.fromJson(data as Map<String, dynamic>);
        _bulletinController.add(bulletinEvent);
      } catch (e) {
        print('[MessageStreamService] Error parsing bulletin.unpinned: $e');
      }
    });
  }
  
  /// Dispose all resources
  void dispose() {
    disconnect();
    _messageController.close();
    _messageEditedController.close();
    _messageDeletedController.close();
    _messageReadController.close();
    _deliveryStateController.close();
    _connectionStateController.close();
    _typingController.close();
    _reactionController.close();
    _pinController.close();
    _bulletinController.close();
  }
}
