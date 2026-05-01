class TypingEvent {
  final String userId;
  final String channelId;
  final bool isTyping;
  final DateTime timestamp;
  final String? displayName;

  TypingEvent({
    required this.userId,
    required this.channelId,
    required this.isTyping,
    required this.timestamp,
    this.displayName,
  });

  factory TypingEvent.fromJson(Map<String, dynamic> json) {
    // Parse timestamp - could be int (milliseconds) or ISO string
    DateTime timestamp;
    if (json['timestamp'] is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int);
    } else if (json['timestamp'] is String) {
      timestamp = DateTime.parse(json['timestamp'] as String);
    } else {
      timestamp = DateTime.now();
    }

    return TypingEvent(
      userId: json['userId'] as String,
      channelId: json['channelId'] as String,
      isTyping: json['typing'] as bool? ?? json['isTyping'] as bool? ?? false,
      timestamp: timestamp,
      displayName: json['displayName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'channelId': channelId,
      'typing': isTyping,
      'timestamp': timestamp.millisecondsSinceEpoch,
      if (displayName != null) 'displayName': displayName,
    };
  }

  TypingEvent copyWith({
    String? userId,
    String? channelId,
    bool? isTyping,
    DateTime? timestamp,
    String? displayName,
  }) {
    return TypingEvent(
      userId: userId ?? this.userId,
      channelId: channelId ?? this.channelId,
      isTyping: isTyping ?? this.isTyping,
      timestamp: timestamp ?? this.timestamp,
      displayName: displayName ?? this.displayName,
    );
  }

  /// Check if typing event is stale (older than threshold)
  bool isStale({Duration threshold = const Duration(seconds: 5)}) {
    return DateTime.now().difference(timestamp) > threshold;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypingEvent &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          channelId == other.channelId;

  @override
  int get hashCode => userId.hashCode ^ channelId.hashCode;

  @override
  String toString() {
    return 'TypingEvent{userId: $userId, channelId: $channelId, isTyping: $isTyping, displayName: $displayName}';
  }
}
