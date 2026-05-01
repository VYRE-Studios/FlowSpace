import 'package:flutter/foundation.dart';
import '../models/reaction.dart';
import '../services/message_stream_service.dart';

/// Provider for managing message reactions with real-time updates
class ReactionProvider with ChangeNotifier {
  final MessageStreamService _streamService;
  
  // channelId -> messageId -> MessageReactions
  final Map<String, Map<String, MessageReactions>> _reactions = {};

  ReactionProvider(this._streamService) {
    _streamService.reactionStream.listen(_handleReactionEvent);
  }

  /// Get reactions for a specific message
  MessageReactions getReactions(String channelId, String messageId) {
    return _reactions[channelId]?[messageId] ??
        MessageReactions.empty(messageId);
  }

  /// Get all reactions for a channel
  Map<String, MessageReactions> getChannelReactions(String channelId) {
    return _reactions[channelId] ?? {};
  }

  /// Add or update a reaction (optimistic update)
  Future<void> addReaction({
    required String channelId,
    required String messageId,
    required String emoji,
    required String userId,
    required String displayName,
  }) async {
    final reaction = Reaction(
      userId: userId,
      displayName: displayName,
      emoji: emoji,
      timestamp: DateTime.now(),
    );

    // Optimistic update
    _updateReaction(channelId, messageId, reaction, ReactionAction.add);

    // Send to server
    try {
      await _streamService.sendReaction(
        channelId: channelId,
        messageId: messageId,
        emoji: emoji,
        action: ReactionAction.add,
      );
    } catch (e) {
      // Rollback on error
      _updateReaction(channelId, messageId, reaction, ReactionAction.remove);
      rethrow;
    }
  }

  /// Remove a reaction (optimistic update)
  Future<void> removeReaction({
    required String channelId,
    required String messageId,
    required String emoji,
    required String userId,
    required String displayName,
  }) async {
    final reaction = Reaction(
      userId: userId,
      displayName: displayName,
      emoji: emoji,
      timestamp: DateTime.now(),
    );

    // Optimistic update
    _updateReaction(channelId, messageId, reaction, ReactionAction.remove);

    // Send to server
    try {
      await _streamService.sendReaction(
        channelId: channelId,
        messageId: messageId,
        emoji: emoji,
        action: ReactionAction.remove,
      );
    } catch (e) {
      // Rollback on error
      _updateReaction(channelId, messageId, reaction, ReactionAction.add);
      rethrow;
    }
  }

  /// Toggle a reaction (add if not present, remove if present)
  Future<void> toggleReaction({
    required String channelId,
    required String messageId,
    required String emoji,
    required String userId,
    required String displayName,
  }) async {
    final currentReactions = getReactions(channelId, messageId);
    final hasReacted = currentReactions.hasUserReacted(userId, emoji);

    if (hasReacted) {
      await removeReaction(
        channelId: channelId,
        messageId: messageId,
        emoji: emoji,
        userId: userId,
        displayName: displayName,
      );
    } else {
      await addReaction(
        channelId: channelId,
        messageId: messageId,
        emoji: emoji,
        userId: userId,
        displayName: displayName,
      );
    }
  }

  /// Load initial reactions for a message (from server/cache)
  void setMessageReactions(String channelId, MessageReactions reactions) {
    _reactions.putIfAbsent(channelId, () => {});
    _reactions[channelId]![reactions.messageId] = reactions;
    notifyListeners();
  }

  /// Load reactions for multiple messages
  void setChannelReactions(
    String channelId,
    Map<String, MessageReactions> reactions,
  ) {
    _reactions[channelId] = reactions;
    notifyListeners();
  }

  /// Clear reactions for a channel
  void clearChannelReactions(String channelId) {
    _reactions.remove(channelId);
    notifyListeners();
  }

  /// Clear all reactions
  void clearAll() {
    _reactions.clear();
    notifyListeners();
  }

  /// Handle incoming reaction events from WebSocket
  void _handleReactionEvent(ReactionEvent event) {
    final reaction = Reaction(
      userId: event.userId,
      displayName: event.displayName,
      emoji: event.emoji,
      timestamp: event.timestamp,
    );

    _updateReaction(
      event.channelId,
      event.messageId,
      reaction,
      event.action,
    );
  }

  /// Update reaction state
  void _updateReaction(
    String channelId,
    String messageId,
    Reaction reaction,
    ReactionAction action,
  ) {
    _reactions.putIfAbsent(channelId, () => {});
    final channelReactions = _reactions[channelId]!;

    final currentReactions =
        channelReactions[messageId] ?? MessageReactions.empty(messageId);

    final updatedReactions = action == ReactionAction.add
        ? currentReactions.addReaction(reaction)
        : currentReactions.removeReaction(reaction.userId, reaction.emoji);

    channelReactions[messageId] = updatedReactions;
    notifyListeners();
  }

  /// Get popular emojis (most used across all messages in channel)
  List<String> getPopularEmojis(String channelId, {int limit = 8}) {
    final channelReactions = _reactions[channelId];
    if (channelReactions == null) return [];

    final emojiCounts = <String, int>{};
    for (final messageReactions in channelReactions.values) {
      for (final emoji in messageReactions.emojis) {
        emojiCounts[emoji] = (emojiCounts[emoji] ?? 0) +
            messageReactions.getEmojiCount(emoji);
      }
    }

    final sortedEmojis = emojiCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEmojis.take(limit).map((e) => e.key).toList();
  }
}
