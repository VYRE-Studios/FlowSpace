class ReadReceiptEvent {
  final String messageId;
  final String userId;
  final String channelId;
  final DateTime timestamp;
  final String? displayName;
  final String? avatarUrl;

  ReadReceiptEvent({
    required this.messageId,
    required this.userId,
    required this.channelId,
    required this.timestamp,
    this.displayName,
    this.avatarUrl,
  });

  factory ReadReceiptEvent.fromJson(Map<String, dynamic> json) {
    // Parse timestamp - could be int (milliseconds) or ISO string
    DateTime timestamp;
    if (json['timestamp'] is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int);
    } else if (json['timestamp'] is String) {
      timestamp = DateTime.parse(json['timestamp'] as String);
    } else {
      timestamp = DateTime.now();
    }

    return ReadReceiptEvent(
      messageId: json['messageId'] as String,
      userId: json['userId'] as String,
      channelId: json['channelId'] as String,
      timestamp: timestamp,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'userId': userId,
      'channelId': channelId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      if (displayName != null) 'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }

  ReadReceiptEvent copyWith({
    String? messageId,
    String? userId,
    String? channelId,
    DateTime? timestamp,
    String? displayName,
    String? avatarUrl,
  }) {
    return ReadReceiptEvent(
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      channelId: channelId ?? this.channelId,
      timestamp: timestamp ?? this.timestamp,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadReceiptEvent &&
          runtimeType == other.runtimeType &&
          messageId == other.messageId &&
          userId == other.userId;

  @override
  int get hashCode => messageId.hashCode ^ userId.hashCode;

  @override
  String toString() {
    return 'ReadReceiptEvent{messageId: $messageId, userId: $userId, channelId: $channelId, displayName: $displayName}';
  }
}
