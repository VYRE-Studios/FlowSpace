import 'dart:async';
import 'package:flutter/foundation.dart';
import 'realtime/socket_service.dart';
import 'notification_service.dart';
import 'sound_service.dart';
import 'chat_models.dart';
import 'chat_integration_helper.dart';

class ChatEventsService {
  static final ChatEventsService instance = ChatEventsService._();
  ChatEventsService._();

  final ValueNotifier<Map<String, ChatMessage>> messageUpdates = ValueNotifier({});
  final ValueNotifier<Map<String, List<String>>> typingUsers = ValueNotifier({});
  final ValueNotifier<Set<String>> deletedMessages = ValueNotifier({});
  
  StreamSubscription? _socketSubscription;
  String? _currentUserId;
  String? _currentUsername;

  void init({required String userId, required String username}) {
    _currentUserId = userId;
    _currentUsername = username;
    
    _socketSubscription = SocketService.instance.events.listen(_handleSocketEvent);
    print('[ChatEvents] Service initialized for user: $username');
  }

  void _handleSocketEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    
    switch (type) {
      case 'message.new':
        _handleNewMessage(event);
        break;
      case 'reaction.added':
      case 'reaction.removed':
        _handleReactionUpdate(event);
        break;
      case 'message.edited':
        _handleMessageEdited(event);
        break;
      case 'message.deleted':
        _handleMessageDeleted(event);
        break;
      case 'mention.received':
        _handleMentionReceived(event);
        break;
      case 'typing':
        _handleTyping(event);
        break;
      case 'user_joined':
        _handleUserJoined(event);
        break;
      case 'user_left':
        _handleUserLeft(event);
        break;
    }
  }

  void _handleNewMessage(Map<String, dynamic> event) {
    try {
      final message = ChatMessage.fromJson(event);
      
      // Check if it's a mention
      final isMention = _checkMention(message.content);
      final updatedMessage = message.copyWith(isMention: isMention);
      
      messageUpdates.value = {...messageUpdates.value, message.id: updatedMessage};
      
      // Trigger notifications if not own message
      if (message.senderId != _currentUserId) {
        // Play sound from backend URL if provided, otherwise use local fallback
        final soundUrl = event['soundUrl'] as String?;
        
        if (isMention) {
          NotificationService.instance.showMentionNotification(
            senderName: message.senderName ?? 'Someone',
            messageText: message.content,
          );
          if (soundUrl != null) {
            SoundService.instance.playFromUrl(soundUrl);
          } else {
            SoundService.instance.playMention();
          }
        } else {
          NotificationService.instance.showMessageNotification(
            senderName: message.senderName ?? 'Someone',
            messageText: message.content,
          );
          if (soundUrl != null) {
            SoundService.instance.playFromUrl(soundUrl);
          } else {
            SoundService.instance.playMessage();
          }
        }
      }
    } catch (e) {
      print('[ChatEvents] Error handling new message: $e');
    }
  }

  void _handleReactionUpdate(Map<String, dynamic> event) {
    final messageId = event['messageId'] as String?;
    final reactions = event['reactions'];
    
    if (messageId == null || reactions == null) return;
    
    // reactions can be either List<Map> or Map<String, List>
    Map<String, List<String>>? reactionMap;
    if (reactions is Map) {
      reactionMap = {};
      reactions.forEach((key, value) {
        reactionMap![key as String] = List<String>.from(value as List);
      });
    } else if (reactions is List) {
      // Legacy format - convert to map
      reactionMap = {};
      for (final r in reactions) {
        final reaction = r as Map<String, dynamic>;
        final emoji = reaction['emoji'] as String;
        final userId = reaction['userId'] as String;
        reactionMap[emoji] = [...(reactionMap[emoji] ?? []), userId];
      }
    }
    
    final currentMessage = messageUpdates.value[messageId];
    if (currentMessage != null) {
      final updated = currentMessage.copyWith(reactions: reactionMap);
      messageUpdates.value = {...messageUpdates.value, messageId: updated};
    }
  }

  void _handleMessageEdited(Map<String, dynamic> event) {
    final messageId = event['id'] as String?;
    final newContent = event['content'] as String?;
    final editedAt = event['editedAt'] as String?;
    
    if (messageId == null) return;
    
    final currentMessage = messageUpdates.value[messageId];
    if (currentMessage != null) {
      final updated = currentMessage.copyWith(
        content: newContent,
        edited: true,
        editedAt: editedAt != null ? DateTime.tryParse(editedAt) : DateTime.now(),
      );
      messageUpdates.value = {...messageUpdates.value, messageId: updated};
    }
  }

  void _handleMessageDeleted(Map<String, dynamic> event) {
    final messageId = event['messageId'] as String?;
    if (messageId == null) return;
    
    deletedMessages.value = {...deletedMessages.value, messageId};
    
    final currentMessage = messageUpdates.value[messageId];
    if (currentMessage != null) {
      final updated = currentMessage.copyWith(
        deleted: true,
        deletedAt: DateTime.now(),
        content: '',
      );
      messageUpdates.value = {...messageUpdates.value, messageId: updated};
    }
  }

  void _handleMentionReceived(Map<String, dynamic> event) {
    final messageId = event['messageId'] as String?;
    final senderName = event['senderName'] as String?;
    final content = event['content'] as String?;
    final soundUrl = event['soundUrl'] as String?;
    
    if (messageId == null) return;
    
    // Mark message as mention
    final currentMessage = messageUpdates.value[messageId];
    if (currentMessage != null) {
      final updated = currentMessage.copyWith(isMention: true);
      messageUpdates.value = {...messageUpdates.value, messageId: updated};
    }
    
    // Show mention notification
    NotificationService.instance.showMentionNotification(
      senderName: senderName ?? 'Someone',
      messageText: content ?? '',
    );
    
    // Play sound from backend URL if provided
    if (soundUrl != null) {
      SoundService.instance.playFromUrl(soundUrl);
    } else {
      SoundService.instance.playMention();
    }
  }

  void _handleTyping(Map<String, dynamic> event) {
    final userId = event['userId'] as String?;
    final channelId = event['channelId'] as String?;
    final isTyping = event['typing'] as bool? ?? false;
    
    if (userId == null || channelId == null || userId == _currentUserId) return;
    
    final current = Map<String, List<String>>.from(typingUsers.value);
    final channelTyping = List<String>.from(current[channelId] ?? []);
    
    if (isTyping) {
      if (!channelTyping.contains(userId)) {
        channelTyping.add(userId);
      }
    } else {
      channelTyping.remove(userId);
    }
    
    if (channelTyping.isEmpty) {
      current.remove(channelId);
    } else {
      current[channelId] = channelTyping;
    }
    
    typingUsers.value = current;
  }

  void _handleUserJoined(Map<String, dynamic> event) {
    final displayName = event['displayName'] as String?;
    final soundUrl = event['soundUrl'] as String?;
    
    if (displayName != null) {
      print('[ChatEvents] User joined: $displayName');
      if (soundUrl != null) {
        SoundService.instance.playFromUrl(soundUrl);
      } else {
        SoundService.instance.playOnline();
      }
      ChatIntegrationHelper.showUserJoinedToast(displayName);
    }
  }

  void _handleUserLeft(Map<String, dynamic> event) {
    final displayName = event['displayName'] as String?;
    final soundUrl = event['soundUrl'] as String?;
    
    if (displayName != null) {
      print('[ChatEvents] User left: $displayName');
      if (soundUrl != null) {
        SoundService.instance.playFromUrl(soundUrl);
      } else {
        SoundService.instance.playOffline();
      }
      ChatIntegrationHelper.showUserLeftToast(displayName);
    }
  }

  bool _checkMention(String content) {
    if (_currentUsername == null) return false;
    final pattern = RegExp(r'@' + RegExp.escape(_currentUsername!) + r'\\b');
    return pattern.hasMatch(content);
  }

  List<String> getTypingUsers(String channelId) {
    return typingUsers.value[channelId] ?? [];
  }

  void clearChannelTyping(String channelId) {
    final current = Map<String, List<String>>.from(typingUsers.value);
    current.remove(channelId);
    typingUsers.value = current;
  }

  void dispose() {
    _socketSubscription?.cancel();
    messageUpdates.dispose();
    typingUsers.dispose();
    deletedMessages.dispose();
  }
}
