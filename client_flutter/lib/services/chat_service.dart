import 'chat_models.dart';
import 'database_service.dart';
import 'api_client.dart';

typedef ChannelListResult = ({
  List<ChannelSummary> channels,
  bool fromCache,
  DateTime? cacheTimestamp,
});

typedef ChannelDetailResult = ({
  ChannelDetail detail,
  bool fromCache,
  DateTime? cacheTimestamp,
});

class ChatService {
  // Instance methods are intentionally disabled until they can receive
  // workspace/channel context from the caller. Production code should use the
  // static methods below with explicit workspaceId and channelId.
  Future<List<ChatMessage>> getChannelMessages(String channelId) async {
    throw UnsupportedError(
      'Use ChatService.getChannelDetail with an explicit workspaceId.',
    );
  }

  Future<void> deleteMessage(String messageId) async {
    throw UnsupportedError(
      'Use ChatService.deleteMessageStatic with explicit workspace/channel context.',
    );
  }

  Future<void> addReaction(String messageId, String emoji) async {
    throw UnsupportedError(
      'Use ChatService.addReactionStatic with explicit workspace/channel context.',
    );
  }

  Future<void> sendMessage({
    required String channelId,
    required String content,
  }) async {
    throw UnsupportedError(
      'Use ChatService.sendMessageStatic with an explicit workspaceId.',
    );
  }

  // Static methods (existing)
  static Future<ChannelListResult> getChannels(String workspaceId) async {
    try {
      // Try to fetch from backend API first
      final response = await ApiClient.get('workspaces/$workspaceId/channels');
      final channelsList = (response as List).map((c) {
        final lastMsg = c['lastMessage'] as Map<String, dynamic>?;
        return ChannelSummary(
          id: c['id'] as String,
          name: c['name'] as String,
          description: c['description'] as String?,
          lastMessage: lastMsg != null ? ChannelLastMessage(
            id: lastMsg['id'] as String,
            senderId: lastMsg['senderId'] as String,
            senderName: lastMsg['senderName'] as String?,
            content: lastMsg['content'] as String,
            createdAt: DateTime.parse(lastMsg['createdAt'] as String),
          ) : null,
        );
      }).toList();
      
      // Sync to local database for offline support
      for (final channel in channelsList) {
        await DatabaseService.insertChannel({
          'id': channel.id,
          'workspace_id': workspaceId,
          'name': channel.name,
          'description': channel.description ?? '',
          'is_private': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      
      return (
        channels: channelsList,
        fromCache: false,
        cacheTimestamp: DateTime.now(),
      );
    } catch (e) {
      print('ChatService: Error fetching channels from API, falling back to local: $e');
      // Fallback to local database
      final channelsData = await DatabaseService.getWorkspaceChannels(workspaceId);
      final channels = channelsData.map((c) => ChannelSummary(
        id: c['id'] as String,
        name: c['name'] as String,
        description: c['description'] as String?,
        lastMessage: null,
      )).toList();
      
      return (
        channels: channels,
        fromCache: true,
        cacheTimestamp: DateTime.now(),
      );
    }
  }

  static Future<ChannelDetailResult> getChannelDetail(
    String workspaceId,
    String channelId, {
    int limit = 200,
  }) async {
    try {
      // Try to fetch from backend API first
      final response = await ApiClient.get(
        'workspaces/$workspaceId/channels/$channelId/messages?limit=$limit',
      );
      final data = response as Map<String, dynamic>;
      final channelData = data['channel'] as Map<String, dynamic>;
      final messagesList = (data['messages'] as List).map((m) {
        return ChatMessage(
          id: m['id'] as String,
          channelId: m['channelId'] as String,
          senderId: m['senderId'] as String,
          senderName: m['senderName'] as String?,
          content: m['content'] as String,
          createdAt: DateTime.parse(m['createdAt'] as String),
          // attachments will be parsed by fromJson if needed
          attachments: (m['attachments'] as List<dynamic>? ?? const []).isNotEmpty
              ? (m['attachments'] as List).map((a) => a is Map
                  ? MessageAttachment.fromJson(a as Map<String, dynamic>)
                  : MessageAttachment(id: a.toString(), name: a.toString().split('/').last, type: 'file', url: a.toString())
                ).toList()
              : null,
          parentId: m['parentId'] as String?,
          reactions: (m['reactions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, List<String>.from(value as List)),
          ),
        );
      }).toList();
      
      // Sync messages to local database for offline support
      for (final message in messagesList) {
        await DatabaseService.insertMessage({
          'id': message.id,
          'channel_id': message.channelId,
          'sender_id': message.senderId,
          'sender_name': message.senderName ?? message.senderId,
          'content': message.content,
          'parent_id': message.parentId,
          'created_at': message.createdAt.toIso8601String(),
          'updated_at': message.createdAt.toIso8601String(),
        });
      }
      
      return (
        detail: ChannelDetail(
          channel: ChannelSummary(
            id: channelData['id'] as String,
            name: channelData['name'] as String,
            description: channelData['description'] as String?,
            lastMessage: null,
          ),
          messages: messagesList,
        ),
        fromCache: false,
        cacheTimestamp: DateTime.now(),
      );
    } catch (e) {
      print('ChatService: Error fetching messages from API, falling back to local: $e');
      // Fallback to local database
      final messagesData = await DatabaseService.getChannelMessages(channelId, limit: limit);
      final messages = messagesData.map((m) => ChatMessage(
        id: m['id'] as String,
        channelId: m['channel_id'] as String,
        senderId: m['sender_id'] as String,
        senderName: m['sender_name'] as String,
        content: m['content'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
        parentId: m['parent_id'] as String?,
      )).toList();
      
      return (
        detail: ChannelDetail(
          channel: ChannelSummary(id: channelId, name: '', description: null, lastMessage: null),
          messages: messages,
        ),
        fromCache: true,
        cacheTimestamp: DateTime.now(),
      );
    }
  }

  static Future<ChatMessage> sendMessageStatic({
    required String workspaceId,
    required String channelId,
    required String content,
    List<String>? attachments,
    String? parentId,
  }) async {
    try {
      print('ChatService: Sending message to channel $channelId');
      print('ChatService: Token present: ${ApiClient.token != null}');
      print('ChatService: Token length: ${ApiClient.token?.length ?? 0}');
      
      // Send to backend API
      final response = await ApiClient.post(
        'workspaces/$workspaceId/channels/$channelId/messages',
        body: {
          'content': content,
          'attachments': attachments ?? [],
          'parentId': parentId,
        },
      );
      
      final messageData = (response as Map<String, dynamic>)['message'] as Map<String, dynamic>;
      final message = ChatMessage(
        id: messageData['id'] as String,
        channelId: messageData['channelId'] as String,
        senderId: messageData['senderId'] as String,
        senderName: messageData['senderName'] as String?,
        content: messageData['content'] as String,
        createdAt: DateTime.parse(messageData['timestamp'] as String),
        // attachments will be parsed appropriately
        attachments: (messageData['attachments'] as List<dynamic>? ?? const []).isNotEmpty
            ? (messageData['attachments'] as List).map((a) => a is Map
                ? MessageAttachment.fromJson(a as Map<String, dynamic>)
                : MessageAttachment(id: a.toString(), name: a.toString().split('/').last, type: 'file', url: a.toString())
              ).toList()
            : null,
        parentId: messageData['parentId'] as String?,
      );
      
      // Also save to local database for offline support
      await DatabaseService.insertMessage({
        'id': message.id,
        'channel_id': message.channelId,
        'sender_id': message.senderId,
        'sender_name': message.senderName ?? message.senderId,
        'content': message.content,
        'parent_id': message.parentId,
        'created_at': message.createdAt.toIso8601String(),
        'updated_at': message.createdAt.toIso8601String(),
      });
      
      return message;
    } catch (e) {
      print('ChatService: Error sending message to API, saving locally: $e');
      // Fallback: save to local database only
      final user = await DatabaseService.getCurrentUser();
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now().toIso8601String();
      
      await DatabaseService.insertMessage({
        'id': messageId,
        'channel_id': channelId,
        'sender_id': user?['id'] ?? '',
        'sender_name': user?['name'] ?? 'User',
        'content': content,
        'parent_id': parentId,
        'created_at': now,
        'updated_at': now,
      });
      
      return ChatMessage(
        id: messageId,
        channelId: channelId,
        senderId: user?['id'] ?? '',
        senderName: user?['name'] ?? 'User',
        content: content,
        createdAt: DateTime.parse(now),
        parentId: parentId,
      );
    }
  }

  static Future<Map<String, dynamic>> addReactionStatic({
    required String workspaceId,
    required String channelId,
    required String messageId,
    required String emoji,
  }) async {
    final response = await ApiClient.post(
      'workspaces/$workspaceId/channels/messages/$messageId/reactions',
      body: {'emoji': emoji},
    );
    return response as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> removeReaction({
    required String workspaceId,
    required String channelId,
    required String messageId,
    required String emoji,
  }) async {
    await ApiClient.delete(
      'workspaces/$workspaceId/channels/messages/$messageId/reactions?emoji=${Uri.encodeComponent(emoji)}',
    );
    return {'success': true};
  }

  static Future<ChatMessage> editMessage({
    required String workspaceId,
    required String channelId,
    required String messageId,
    required String newContent,
  }) async {
    final response = await ApiClient.put(
      'workspaces/$workspaceId/channels/messages/$messageId',
      body: {'content': newContent},
    );
    final messageData = (response as Map<String, dynamic>)['message'] as Map<String, dynamic>;
    return ChatMessage.fromJson(messageData);
  }

  static Future<void> deleteMessageStatic({
    required String workspaceId,
    required String channelId,
    required String messageId,
  }) async {
    await ApiClient.delete(
      'workspaces/$workspaceId/channels/messages/$messageId',
    );
  }

  static Future<Map<String, dynamic>> getThread({
    required String workspaceId,
    required String channelId,
    required String messageId,
  }) async {
    final response = await ApiClient.get(
      'workspaces/$workspaceId/channels/messages/$messageId/thread',
    );
    return response as Map<String, dynamic>;
  }

  static Future<void> markAsRead({
    required String workspaceId,
    required String channelId,
    required String messageId,
  }) async {
    await ApiClient.post(
      'workspaces/$workspaceId/channels/messages/$messageId/read',
      body: {},
    );
  }

  static Future<List<Map<String, dynamic>>> getReadReceipts({
    required String workspaceId,
    required String channelId,
    required String messageId,
  }) async {
    final response = await ApiClient.get(
      'workspaces/$workspaceId/channels/messages/$messageId/reads',
    );
    final data = response as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['reads'] as List);
  }

  static bool detectMention(String content, String username) {
    final pattern = RegExp(r'@' + RegExp.escape(username) + r'\b');
    return pattern.hasMatch(content);
  }

  static List<String> extractMentions(String content) {
    final pattern = RegExp(r'@([a-zA-Z0-9_]+)');
    final matches = pattern.allMatches(content);
    return matches.map((m) => m.group(1)!).toList();
  }

  static Future<void> pinMessage({
    required String workspaceId,
    required String channelId,
    required String messageId,
  }) async {
    await ApiClient.post(
      'workspaces/$workspaceId/channels/messages/$messageId/pin',
      body: {},
    );
  }

  static Future<void> unpinMessage({
    required String workspaceId,
    required String channelId,
    required String messageId,
  }) async {
    await ApiClient.delete(
      'workspaces/$workspaceId/channels/messages/$messageId/pin',
    );
  }

  static Future<List<ChatMessage>> getPinnedMessages({
    required String workspaceId,
    required String channelId,
  }) async {
    final response = await ApiClient.get(
      'workspaces/$workspaceId/channels/$channelId/pinned',
    );
    final messages = (response as List)
        .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList();
    return messages;
  }
}
