import 'package:flutter/foundation.dart';
import '../models/pinned_message.dart';
import '../services/message_stream_service.dart';

/// Provider for managing pinned messages with real-time updates
class PinProvider with ChangeNotifier {
  final MessageStreamService _streamService;

  // channelId -> list of pinned messages (ordered by pinnedAt desc)
  final Map<String, List<PinnedMessage>> _pinnedMessages = {};

  // Track pin limits per channel (default: 50)
  static const int maxPinsPerChannel = 50;

  PinProvider(this._streamService) {
    _streamService.pinStream.listen(_handlePinEvent);
  }

  /// Get all pinned messages for a channel
  List<PinnedMessage> getPinnedMessages(String channelId) {
    return _pinnedMessages[channelId] ?? [];
  }

  /// Get a specific pinned message
  PinnedMessage? getPinnedMessage(String channelId, String messageId) {
    final pins = _pinnedMessages[channelId] ?? [];
    try {
      return pins.firstWhere((pin) => pin.messageId == messageId);
    } catch (e) {
      return null;
    }
  }

  /// Check if a message is pinned
  bool isPinned(String channelId, String messageId) {
    return getPinnedMessage(channelId, messageId) != null;
  }

  /// Get pin count for a channel
  int getPinCount(String channelId) {
    return _pinnedMessages[channelId]?.length ?? 0;
  }

  /// Check if channel has reached pin limit
  bool hasReachedPinLimit(String channelId) {
    return getPinCount(channelId) >= maxPinsPerChannel;
  }

  /// Get most recently pinned message
  PinnedMessage? getMostRecentPin(String channelId) {
    final pins = _pinnedMessages[channelId];
    if (pins == null || pins.isEmpty) return null;
    return pins.first; // Already sorted by pinnedAt desc
  }

  /// Pin a message (optimistic update)
  Future<void> pinMessage({
    required String channelId,
    required String messageId,
    required String content,
    required String authorId,
    required String authorName,
    required DateTime messageTimestamp,
    required String userId,
    required String userName,
    String? reason,
  }) async {
    // Check pin limit
    if (hasReachedPinLimit(channelId)) {
      throw Exception('Channel has reached maximum pin limit ($maxPinsPerChannel)');
    }

    // Create optimistic pinned message
    final pinnedMessage = PinnedMessage(
      messageId: messageId,
      channelId: channelId,
      content: content,
      authorId: authorId,
      authorName: authorName,
      messageTimestamp: messageTimestamp,
      pinnedAt: DateTime.now(),
      pinnedBy: userId,
      pinnedByName: userName,
      pinnedReason: reason,
    );

    // Optimistic update
    _addPin(channelId, pinnedMessage);

    // Send to server
    try {
      await _streamService.pinMessage(
        channelId: channelId,
        messageId: messageId,
        reason: reason,
      );
    } catch (e) {
      // Rollback on error
      _removePin(channelId, messageId);
      rethrow;
    }
  }

  /// Unpin a message (optimistic update)
  Future<void> unpinMessage({
    required String channelId,
    required String messageId,
  }) async {
    // Store for rollback
    final originalPin = getPinnedMessage(channelId, messageId);
    if (originalPin == null) return;

    // Optimistic update
    _removePin(channelId, messageId);

    // Send to server
    try {
      await _streamService.unpinMessage(
        channelId: channelId,
        messageId: messageId,
      );
    } catch (e) {
      // Rollback on error
      _addPin(channelId, originalPin);
      rethrow;
    }
  }

  /// Load pinned messages for a channel (from server/cache)
  void setPinnedMessages(String channelId, List<PinnedMessage> pins) {
    // Sort by pinnedAt descending (most recent first)
    final sortedPins = List<PinnedMessage>.from(pins)
      ..sort((a, b) => b.pinnedAt.compareTo(a.pinnedAt));
    _pinnedMessages[channelId] = sortedPins;
    notifyListeners();
  }

  /// Clear pins for a channel
  void clearChannelPins(String channelId) {
    _pinnedMessages.remove(channelId);
    notifyListeners();
  }

  /// Clear all pins
  void clearAll() {
    _pinnedMessages.clear();
    notifyListeners();
  }

  /// Handle incoming pin events from WebSocket
  void _handlePinEvent(PinEvent event) {
    if (event.action == PinAction.pin && event.pinnedMessage != null) {
      _addPin(event.channelId, event.pinnedMessage!);
    } else if (event.action == PinAction.unpin) {
      _removePin(event.channelId, event.messageId);
    }
  }

  /// Add a pin to the list
  void _addPin(String channelId, PinnedMessage pin) {
    _pinnedMessages.putIfAbsent(channelId, () => []);
    final pins = _pinnedMessages[channelId]!;

    // Remove if already exists
    pins.removeWhere((p) => p.messageId == pin.messageId);

    // Add at the beginning (most recent)
    pins.insert(0, pin);

    // Enforce limit
    if (pins.length > maxPinsPerChannel) {
      pins.removeRange(maxPinsPerChannel, pins.length);
    }

    notifyListeners();
  }

  /// Remove a pin from the list
  void _removePin(String channelId, String messageId) {
    final pins = _pinnedMessages[channelId];
    if (pins != null) {
      pins.removeWhere((p) => p.messageId == messageId);
      notifyListeners();
    }
  }

  /// Search pinned messages by content
  List<PinnedMessage> searchPins(String channelId, String query) {
    final pins = _pinnedMessages[channelId] ?? [];
    if (query.isEmpty) return pins;

    final lowerQuery = query.toLowerCase();
    return pins.where((pin) {
      return pin.content.toLowerCase().contains(lowerQuery) ||
          pin.authorName.toLowerCase().contains(lowerQuery) ||
          (pin.pinnedReason?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Get pins by a specific user
  List<PinnedMessage> getPinsByUser(String channelId, String userId) {
    final pins = _pinnedMessages[channelId] ?? [];
    return pins.where((pin) => pin.pinnedBy == userId).toList();
  }

  /// Get pins within a date range
  List<PinnedMessage> getPinsByDateRange(
    String channelId,
    DateTime start,
    DateTime end,
  ) {
    final pins = _pinnedMessages[channelId] ?? [];
    return pins.where((pin) {
      return pin.pinnedAt.isAfter(start) && pin.pinnedAt.isBefore(end);
    }).toList();
  }
}
