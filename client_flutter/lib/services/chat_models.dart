class ChannelSummary {
  const ChannelSummary({
    required this.id,
    required this.name,
    this.description,
    this.updatedAt,
    this.lastMessage,
  });

  final String id;
  final String name;
  final String? description;
  final DateTime? updatedAt;
  final ChannelLastMessage? lastMessage;

  factory ChannelSummary.fromJson(Map<String, dynamic> json) {
    return ChannelSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      lastMessage: json['lastMessage'] != null
          ? ChannelLastMessage.fromJson(
              Map<String, dynamic>.from(json['lastMessage'] as Map),
            )
          : null,
    );
  }
}

class ChannelLastMessage {
  const ChannelLastMessage({
    required this.id,
    required this.senderId,
    this.senderName,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String? senderName;
  final String content;
  final DateTime createdAt;

  factory ChannelLastMessage.fromJson(Map<String, dynamic> json) {
    return ChannelLastMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class MessageReaction {
  const MessageReaction({
    required this.emoji,
    required this.userId,
    required this.timestamp,
  });

  final String emoji;
  final String userId;
  final DateTime timestamp;

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      emoji: json['emoji'] as String,
      userId: json['userId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'emoji': emoji,
    'userId': userId,
    'timestamp': timestamp.toIso8601String(),
  };
}

class MessageAttachment {
  const MessageAttachment({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    this.size,
    this.mimeType,
  });

  final String id;
  final String name;
  final String type; // 'image', 'video', 'audio', 'document', 'file'
  final String url;
  final int? size;
  final String? mimeType;

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      url: json['url'] as String,
      size: json['size'] as int?,
      mimeType: json['mimeType'] as String? ?? json['mime_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'url': url,
    'size': size,
    'mimeType': mimeType,
  };
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.channelId,
    required this.senderId,
    this.senderName,
    required this.content,
    required this.createdAt,
    this.timestamp,
    this.attachments = const [],
    this.parentId,
    this.reactions,
    this.edited = false,
    this.editedAt,
    this.deleted = false,
    this.deletedAt,
    this.threadCount = 0,
    this.isMention = false,
    this.pinned = false,
    this.pinnedAt,
    this.pinnedBy,
  });

  final String id;
  final String channelId;
  final String senderId;
  final String? senderName;
  final String content;
  final DateTime createdAt;
  final DateTime? timestamp;
  final List<MessageAttachment>? attachments;
  final String? parentId;
  final Map<String, List<String>>? reactions; // emoji -> list of userIds
  final bool edited;
  final DateTime? editedAt;
  final bool deleted;
  final DateTime? deletedAt;
  final int? threadCount;
  final bool isMention;
  final bool pinned;
  final DateTime? pinnedAt;
  final String? pinnedBy;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Handle various timestamp field names from backend
    String? timestampStr = json['createdAt'] as String? ?? 
                          json['timestamp'] as String? ?? 
                          json['created_at'] as String?;
    
    // Parse attachments (could be List<String> or List<Map>)
    List<MessageAttachment>? attachments;
    if (json['attachments'] != null) {
      final attachData = json['attachments'] as List<dynamic>;
      if (attachData.isNotEmpty && attachData.first is Map) {
        attachments = attachData
            .map((a) => MessageAttachment.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList();
      } else {
        // Legacy string format - convert to basic attachments
        attachments = attachData.map((url) => MessageAttachment(
          id: url.toString(),
          name: url.toString().split('/').last,
          type: 'file',
          url: url.toString(),
        )).toList();
      }
    }
    
    // Parse reactions (map format: emoji -> list of userIds)
    Map<String, List<String>>? reactions;
    if (json['reactions'] != null) {
      final reactionsData = json['reactions'];
      if (reactionsData is Map) {
        reactions = {};
        reactionsData.forEach((key, value) {
          reactions![key as String] = List<String>.from(value as List);
        });
      }
    }
    
    return ChatMessage(
      id: json['id'] as String? ?? json['messageId'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      channelId: json['channelId'] as String? ?? json['channel_id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? json['sender_id'] as String? ?? json['userId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? json['sender_name'] as String? ?? json['displayName'] as String?,
      content: json['content'] as String? ?? json['message'] as String? ?? '',
      createdAt: timestampStr != null ? DateTime.parse(timestampStr) : DateTime.now(),
      attachments: attachments,
      parentId: json['parentId'] as String? ?? json['parent_id'] as String?,
      reactions: reactions,
      edited: json['edited'] as bool? ?? false,
      editedAt: json['editedAt'] != null ? DateTime.tryParse(json['editedAt'] as String) : null,
      deleted: json['deleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt'] as String) : null,
      threadCount: json['threadCount'] as int? ?? json['replyCount'] as int? ?? 0,
      isMention: json['isMention'] as bool? ?? false,
      pinned: json['pinned'] as bool? ?? false,
      pinnedAt: json['pinnedAt'] != null ? DateTime.tryParse(json['pinnedAt'] as String) : null,
      pinnedBy: json['pinnedBy'] as String?,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? channelId,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? createdAt,
    List<MessageAttachment>? attachments,
    String? parentId,
    Map<String, List<String>>? reactions,
    bool? edited,
    DateTime? editedAt,
    bool? deleted,
    DateTime? deletedAt,
    int? threadCount,
    bool? isMention,
    bool? pinned,
    DateTime? pinnedAt,
    String? pinnedBy,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      attachments: attachments ?? this.attachments,
      parentId: parentId ?? this.parentId,
      reactions: reactions ?? this.reactions,
      edited: edited ?? this.edited,
      editedAt: editedAt ?? this.editedAt,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
      threadCount: threadCount ?? this.threadCount,
      isMention: isMention ?? this.isMention,
      pinned: pinned ?? this.pinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      pinnedBy: pinnedBy ?? this.pinnedBy,
    );
  }
}

class ChannelDetail {
  const ChannelDetail({
    required this.channel,
    required this.messages,
  });

  final ChannelSummary channel;
  final List<ChatMessage> messages;

  factory ChannelDetail.fromJson(Map<String, dynamic> json) {
    return ChannelDetail(
      channel: ChannelSummary.fromJson(
        Map<String, dynamic>.from(json['channel'] as Map),
      ),
      messages: (json['messages'] as List<dynamic>? ?? const [])
          .map(
            (item) => ChatMessage.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}
