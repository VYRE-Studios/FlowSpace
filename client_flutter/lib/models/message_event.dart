enum DeliveryState {
  sending,
  sent,
  delivered,
  failed,
}

class MessageEvent {
  final String? messageId; // Null for optimistic rendering (tempId used instead)
  final String? tempId; // Temporary ID for optimistic rendering
  final String channelId;
  final String userId;
  final String content;
  final DateTime timestamp;
  final DeliveryState deliveryState;
  final Map<String, dynamic>? metadata;
  final List<String>? attachments;
  final String? threadId; // For threaded replies

  MessageEvent({
    this.messageId,
    this.tempId,
    required this.channelId,
    required this.userId,
    required this.content,
    required this.timestamp,
    this.deliveryState = DeliveryState.sending,
    this.metadata,
    this.attachments,
    this.threadId,
  });

  factory MessageEvent.fromJson(Map<String, dynamic> json) {
    // Handle backend ChatMessagePayload format (uses 'id' and 'senderId')
    // and frontend MessageEvent format (uses 'messageId' and 'userId')
    final messageId = json['messageId'] as String? ?? json['id'] as String?;
    final userId = json['userId'] as String? ?? json['senderId'] as String;
    
    // Parse timestamp - could be int (milliseconds) or ISO string
    DateTime timestamp;
    if (json['timestamp'] is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int);
    } else if (json['timestamp'] is String) {
      timestamp = DateTime.parse(json['timestamp'] as String);
    } else {
      timestamp = DateTime.now();
    }
    
    return MessageEvent(
      messageId: messageId,
      tempId: json['tempId'] as String?,
      channelId: json['channelId'] as String,
      userId: userId,
      content: json['content'] as String,
      timestamp: timestamp,
      deliveryState: _parseDeliveryState(json['deliveryState'] as String?),
      metadata: json['metadata'] as Map<String, dynamic>?,
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'] as List)
          : null,
      threadId: json['threadId'] as String? ?? json['parentId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (messageId != null) 'messageId': messageId,
      if (tempId != null) 'tempId': tempId,
      'channelId': channelId,
      'userId': userId,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'deliveryState': deliveryState.name,
      if (metadata != null) 'metadata': metadata,
      if (attachments != null) 'attachments': attachments,
      if (threadId != null) 'threadId': threadId,
    };
  }

  static DeliveryState _parseDeliveryState(String? stateStr) {
    if (stateStr == null) return DeliveryState.sending;
    
    switch (stateStr.toLowerCase()) {
      case 'sent':
        return DeliveryState.sent;
      case 'delivered':
        return DeliveryState.delivered;
      case 'failed':
        return DeliveryState.failed;
      case 'sending':
      default:
        return DeliveryState.sending;
    }
  }

  /// Get unique identifier (tempId for optimistic, messageId for confirmed)
  String get id => messageId ?? tempId ?? '';

  /// Check if message is from current user
  bool isFromUser(String currentUserId) => userId == currentUserId;

  /// Check if message is optimistic (not yet confirmed by server)
  bool get isOptimistic => messageId == null && tempId != null;

  /// Check if message failed to send
  bool get isFailed => deliveryState == DeliveryState.failed;

  MessageEvent copyWith({
    String? messageId,
    String? tempId,
    String? channelId,
    String? userId,
    String? content,
    DateTime? timestamp,
    DeliveryState? deliveryState,
    Map<String, dynamic>? metadata,
    List<String>? attachments,
    String? threadId,
  }) {
    return MessageEvent(
      messageId: messageId ?? this.messageId,
      tempId: tempId ?? this.tempId,
      channelId: channelId ?? this.channelId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      deliveryState: deliveryState ?? this.deliveryState,
      metadata: metadata ?? this.metadata,
      attachments: attachments ?? this.attachments,
      threadId: threadId ?? this.threadId,
    );
  }

  /// Confirm optimistic message with real ID from server
  MessageEvent confirm(String realMessageId) {
    return copyWith(
      messageId: realMessageId,
      deliveryState: DeliveryState.sent,
    );
  }

  /// Mark message as failed
  MessageEvent markFailed() {
    return copyWith(deliveryState: DeliveryState.failed);
  }

  /// Mark message as delivered
  MessageEvent markDelivered() {
    return copyWith(deliveryState: DeliveryState.delivered);
  }
}
