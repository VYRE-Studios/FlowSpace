class Mention {
  final String userId;
  final String displayName;
  final int startIndex;
  final int endIndex;
  final String? avatarUrl;

  Mention({
    required this.userId,
    required this.displayName,
    required this.startIndex,
    required this.endIndex,
    this.avatarUrl,
  });

  factory Mention.fromJson(Map<String, dynamic> json) {
    return Mention(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      startIndex: json['startIndex'] as int,
      endIndex: json['endIndex'] as int,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'startIndex': startIndex,
      'endIndex': endIndex,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }

  Mention copyWith({
    String? userId,
    String? displayName,
    int? startIndex,
    int? endIndex,
    String? avatarUrl,
  }) {
    return Mention(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      startIndex: startIndex ?? this.startIndex,
      endIndex: endIndex ?? this.endIndex,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Mention &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          startIndex == other.startIndex &&
          endIndex == other.endIndex;

  @override
  int get hashCode => userId.hashCode ^ startIndex.hashCode ^ endIndex.hashCode;

  @override
  String toString() {
    return 'Mention{userId: $userId, displayName: $displayName, range: $startIndex-$endIndex}';
  }
}

class MentionNotification {
  final String messageId;
  final String channelId;
  final String mentionedUserId;
  final String senderUserId;
  final String senderName;
  final String messageContent;
  final DateTime timestamp;
  final bool isRead;

  MentionNotification({
    required this.messageId,
    required this.channelId,
    required this.mentionedUserId,
    required this.senderUserId,
    required this.senderName,
    required this.messageContent,
    required this.timestamp,
    this.isRead = false,
  });

  factory MentionNotification.fromJson(Map<String, dynamic> json) {
    DateTime timestamp;
    if (json['timestamp'] is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int);
    } else if (json['timestamp'] is String) {
      timestamp = DateTime.parse(json['timestamp'] as String);
    } else {
      timestamp = DateTime.now();
    }

    return MentionNotification(
      messageId: json['messageId'] as String,
      channelId: json['channelId'] as String,
      mentionedUserId: json['mentionedUserId'] as String,
      senderUserId: json['senderUserId'] as String,
      senderName: json['senderName'] as String,
      messageContent: json['messageContent'] as String,
      timestamp: timestamp,
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'channelId': channelId,
      'mentionedUserId': mentionedUserId,
      'senderUserId': senderUserId,
      'senderName': senderName,
      'messageContent': messageContent,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
    };
  }

  MentionNotification copyWith({
    String? messageId,
    String? channelId,
    String? mentionedUserId,
    String? senderUserId,
    String? senderName,
    String? messageContent,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return MentionNotification(
      messageId: messageId ?? this.messageId,
      channelId: channelId ?? this.channelId,
      mentionedUserId: mentionedUserId ?? this.mentionedUserId,
      senderUserId: senderUserId ?? this.senderUserId,
      senderName: senderName ?? this.senderName,
      messageContent: messageContent ?? this.messageContent,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
