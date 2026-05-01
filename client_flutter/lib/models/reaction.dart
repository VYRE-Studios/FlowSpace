/// Represents a single user's reaction to a message
class Reaction {
  final String userId;
  final String displayName;
  final String emoji;
  final DateTime timestamp;

  const Reaction({
    required this.userId,
    required this.displayName,
    required this.emoji,
    required this.timestamp,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      emoji: json['emoji'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'emoji': emoji,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reaction &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          emoji == other.emoji;

  @override
  int get hashCode => userId.hashCode ^ emoji.hashCode;
}

/// Aggregated reactions for a message
class MessageReactions {
  final String messageId;
  final Map<String, List<Reaction>> reactions; // emoji -> list of reactions

  const MessageReactions({
    required this.messageId,
    required this.reactions,
  });

  factory MessageReactions.empty(String messageId) {
    return MessageReactions(
      messageId: messageId,
      reactions: {},
    );
  }

  factory MessageReactions.fromJson(Map<String, dynamic> json) {
    final reactionsMap = <String, List<Reaction>>{};
    final reactionsJson = json['reactions'] as Map<String, dynamic>? ?? {};

    for (final entry in reactionsJson.entries) {
      final emoji = entry.key;
      final reactionsList = (entry.value as List)
          .map((r) => Reaction.fromJson(r as Map<String, dynamic>))
          .toList();
      reactionsMap[emoji] = reactionsList;
    }

    return MessageReactions(
      messageId: json['messageId'] as String,
      reactions: reactionsMap,
    );
  }

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'reactions': reactions.map(
          (emoji, reactionsList) => MapEntry(
            emoji,
            reactionsList.map((r) => r.toJson()).toList(),
          ),
        ),
      };

  /// Add a reaction from a user
  MessageReactions addReaction(Reaction reaction) {
    final newReactions = Map<String, List<Reaction>>.from(reactions);
    final emojiReactions = List<Reaction>.from(newReactions[reaction.emoji] ?? []);
    
    // Remove existing reaction from this user for this emoji (if any)
    emojiReactions.removeWhere((r) => r.userId == reaction.userId);
    
    // Add new reaction
    emojiReactions.add(reaction);
    newReactions[reaction.emoji] = emojiReactions;

    return MessageReactions(
      messageId: messageId,
      reactions: newReactions,
    );
  }

  /// Remove a reaction from a user
  MessageReactions removeReaction(String userId, String emoji) {
    final newReactions = Map<String, List<Reaction>>.from(reactions);
    final emojiReactions = newReactions[emoji];

    if (emojiReactions != null) {
      emojiReactions.removeWhere((r) => r.userId == userId);
      
      if (emojiReactions.isEmpty) {
        newReactions.remove(emoji);
      } else {
        newReactions[emoji] = emojiReactions;
      }
    }

    return MessageReactions(
      messageId: messageId,
      reactions: newReactions,
    );
  }

  /// Check if a user has reacted with a specific emoji
  bool hasUserReacted(String userId, String emoji) {
    final emojiReactions = reactions[emoji];
    return emojiReactions?.any((r) => r.userId == userId) ?? false;
  }

  /// Get all emojis used in reactions
  List<String> get emojis => reactions.keys.toList()..sort();

  /// Get total reaction count
  int get totalCount =>
      reactions.values.fold(0, (sum, list) => sum + list.length);

  /// Get count for a specific emoji
  int getEmojiCount(String emoji) => reactions[emoji]?.length ?? 0;

  /// Get all users who reacted with a specific emoji
  List<Reaction> getEmojiReactions(String emoji) =>
      reactions[emoji] ?? [];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageReactions &&
          runtimeType == other.runtimeType &&
          messageId == other.messageId &&
          _mapsEqual(reactions, other.reactions);

  @override
  int get hashCode => messageId.hashCode ^ reactions.hashCode;

  static bool _mapsEqual(
    Map<String, List<Reaction>> a,
    Map<String, List<Reaction>> b,
  ) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      final aList = a[key]!;
      final bList = b[key];
      if (bList == null || aList.length != bList.length) return false;
      for (var i = 0; i < aList.length; i++) {
        if (aList[i] != bList[i]) return false;
      }
    }
    return true;
  }
}

/// Event for real-time reaction updates
class ReactionEvent {
  final String messageId;
  final String channelId;
  final String userId;
  final String displayName;
  final String emoji;
  final ReactionAction action;
  final DateTime timestamp;

  const ReactionEvent({
    required this.messageId,
    required this.channelId,
    required this.userId,
    required this.displayName,
    required this.emoji,
    required this.action,
    required this.timestamp,
  });

  factory ReactionEvent.fromJson(Map<String, dynamic> json) {
    return ReactionEvent(
      messageId: json['messageId'] as String,
      channelId: json['channelId'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      emoji: json['emoji'] as String,
      action: ReactionAction.values.firstWhere(
        (a) => a.toString() == 'ReactionAction.${json['action']}',
        orElse: () => ReactionAction.add,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'channelId': channelId,
        'userId': userId,
        'displayName': displayName,
        'emoji': emoji,
        'action': action.toString().split('.').last,
        'timestamp': timestamp.toIso8601String(),
      };
}

enum ReactionAction { add, remove }
