import 'chat_models.dart';
import 'database_service.dart';

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
  static Future<ChannelListResult> getChannels(String workspaceId) async {
    // Load from SQLite database
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

  static Future<ChannelDetailResult> getChannelDetail(
    String workspaceId,
    String channelId, {
    int limit = 200,
  }) async {
    // Load messages from SQLite
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

  static Future<ChatMessage> sendMessage({
    required String workspaceId,
    required String channelId,
    required String content,
    List<String>? attachments,
    String? parentId,
  }) async {
    // Save to SQLite
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
