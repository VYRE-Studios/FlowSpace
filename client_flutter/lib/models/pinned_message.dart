/// Represents a pinned message in a channel
class PinnedMessage {
  final String messageId;
  final String channelId;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime messageTimestamp;
  final DateTime pinnedAt;
  final String pinnedBy;
  final String pinnedByName;
  final String? pinnedReason;

  const PinnedMessage({
    required this.messageId,
    required this.channelId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.messageTimestamp,
    required this.pinnedAt,
    required this.pinnedBy,
    required this.pinnedByName,
    this.pinnedReason,
  });

  factory PinnedMessage.fromJson(Map<String, dynamic> json) {
    return PinnedMessage(
      messageId: json['messageId'] as String,
      channelId: json['channelId'] as String,
      content: json['content'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      messageTimestamp: DateTime.parse(json['messageTimestamp'] as String),
      pinnedAt: DateTime.parse(json['pinnedAt'] as String),
      pinnedBy: json['pinnedBy'] as String,
      pinnedByName: json['pinnedByName'] as String,
      pinnedReason: json['pinnedReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'channelId': channelId,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        'messageTimestamp': messageTimestamp.toIso8601String(),
        'pinnedAt': pinnedAt.toIso8601String(),
        'pinnedBy': pinnedBy,
        'pinnedByName': pinnedByName,
        if (pinnedReason != null) 'pinnedReason': pinnedReason,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PinnedMessage &&
          runtimeType == other.runtimeType &&
          messageId == other.messageId &&
          channelId == other.channelId;

  @override
  int get hashCode => messageId.hashCode ^ channelId.hashCode;
}

/// Event for real-time pin updates
class PinEvent {
  final String messageId;
  final String channelId;
  final PinAction action;
  final PinnedMessage? pinnedMessage;
  final DateTime timestamp;

  const PinEvent({
    required this.messageId,
    required this.channelId,
    required this.action,
    this.pinnedMessage,
    required this.timestamp,
  });

  factory PinEvent.fromJson(Map<String, dynamic> json) {
    return PinEvent(
      messageId: json['messageId'] as String,
      channelId: json['channelId'] as String,
      action: PinAction.values.firstWhere(
        (a) => a.toString() == 'PinAction.${json['action']}',
        orElse: () => PinAction.pin,
      ),
      pinnedMessage: json['pinnedMessage'] != null
          ? PinnedMessage.fromJson(json['pinnedMessage'] as Map<String, dynamic>)
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'channelId': channelId,
        'action': action.toString().split('.').last,
        if (pinnedMessage != null) 'pinnedMessage': pinnedMessage!.toJson(),
        'timestamp': timestamp.toIso8601String(),
      };
}

enum PinAction { pin, unpin }

/// Pin request with optional reason
class PinRequest {
  final String messageId;
  final String channelId;
  final String? reason;

  const PinRequest({
    required this.messageId,
    required this.channelId,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'channelId': channelId,
        if (reason != null) 'reason': reason,
      };
}
