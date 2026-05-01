import 'package:flutter/foundation.dart';
import '../models/presence_event.dart';

class PresenceProvider extends ChangeNotifier {
  final Map<String, PresenceEvent> _users = {};

  /// Get all users with their presence status
  Map<String, PresenceEvent> get users => Map.unmodifiable(_users);

  /// Get presence for specific user
  PresenceEvent? getPresence(String userId) => _users[userId];

  /// Check if user is online
  bool isOnline(String userId) {
    final presence = _users[userId];
    return presence?.isOnline ?? false;
  }

  /// Get online user count
  int get onlineCount => _users.values.where((p) => p.isOnline).length;

  /// Get users by state
  List<PresenceEvent> getUsersByState(PresenceState state) {
    return _users.values.where((p) => p.state == state).toList();
  }

  /// Update presence for a user
  void update(PresenceEvent event) {
    final existingEvent = _users[event.userId];
    
    // Only update if state changed or timestamp is newer
    if (existingEvent == null ||
        existingEvent.state != event.state ||
        event.timestamp.isAfter(existingEvent.timestamp)) {
      _users[event.userId] = event;
      notifyListeners();
    }
  }

  /// Batch update multiple presence events
  void batchUpdate(List<PresenceEvent> events) {
    bool hasChanges = false;

    for (final event in events) {
      final existingEvent = _users[event.userId];
      
      if (existingEvent == null ||
          existingEvent.state != event.state ||
          event.timestamp.isAfter(existingEvent.timestamp)) {
        _users[event.userId] = event;
        hasChanges = true;
      }
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  /// Remove user presence (when they disconnect)
  void remove(String userId) {
    if (_users.remove(userId) != null) {
      notifyListeners();
    }
  }

  /// Clear all presence data
  void clear() {
    if (_users.isNotEmpty) {
      _users.clear();
      notifyListeners();
    }
  }

  /// Mark stale presence events as offline
  void cleanupStale({Duration threshold = const Duration(minutes: 2)}) {
    final now = DateTime.now();
    bool hasChanges = false;

    _users.forEach((userId, event) {
      if (event.isOnline &&
          now.difference(event.timestamp) > threshold) {
        _users[userId] = event.copyWith(
          state: PresenceState.offline,
          timestamp: now,
        );
        hasChanges = true;
      }
    });

    if (hasChanges) {
      notifyListeners();
    }
  }
}
