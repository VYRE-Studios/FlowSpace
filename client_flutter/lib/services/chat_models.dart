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

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.channelId,
    required this.senderId,
    this.senderName,
    required this.content,
    required this.createdAt,
    this.attachments = const [],
    this.parentId,
  });

  final String id;
  final String channelId;
  final String senderId;
  final String? senderName;
  final String content;
  final DateTime createdAt;
  final List<String> attachments;
  final String? parentId;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      channelId: json['channelId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      attachments: List<String>.from(
        (json['attachments'] as List<dynamic>? ?? const [])
            .map((value) => value.toString()),
      ),
      parentId: json['parentId'] as String?,
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
