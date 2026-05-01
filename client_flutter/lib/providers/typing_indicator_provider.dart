import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/typing_event.dart';

class TypingIndicatorProvider extends ChangeNotifier {
  // Track who is typing in each channel: channelId -> Set of TypingEvents
  final Map<String, Map<String, TypingEvent>> _typingUsers = {};
  
  // Cleanup timer for stale typing indicators
  Timer? _cleanupTimer;
  
  // Duration to consider typing indicator stale
  final Duration staleThreshold;
  
  // Current user ID (to exclude from typing indicators)
  String? _currentUserId;
  
  TypingIndicatorProvider({
    this.staleThreshold = const Duration(seconds: 5),
  }) {
    _startCleanupTimer();
  }
  
  /// Set the current user ID to exclude from typing indicators
  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }
  
  /// Get list of users typing in a channel (excluding current user)
  List<TypingEvent> getTypingUsers(String channelId) {
    final users = _typingUsers[channelId];
    if (users == null) return [];
    
    return users.values
        .where((event) => 
            event.isTyping && 
            event.userId != _currentUserId &&
            !event.isStale(threshold: staleThreshold))
        .toList();
  }
  
  /// Get count of users typing in a channel
  int getTypingCount(String channelId) {
    return getTypingUsers(channelId).length;
  }
  
  /// Check if any users are typing in a channel
  bool isAnyoneTyping(String channelId) {
    return getTypingCount(channelId) > 0;
  }
  
  /// Get formatted typing indicator text
  /// 
  /// Examples:
  /// - "Alice is typing..."
  /// - "Alice and Bob are typing..."
  /// - "Alice, Bob and 2 others are typing..."
  String getTypingText(String channelId, {int maxNames = 2}) {
    final typingUsers = getTypingUsers(channelId);
    
    if (typingUsers.isEmpty) return '';
    
    final names = typingUsers
        .map((e) => e.displayName ?? 'Someone')
        .take(maxNames)
        .toList();
    
    if (typingUsers.length == 1) {
      return '${names[0]} is typing...';
    } else if (typingUsers.length == 2) {
      return '${names[0]} and ${names[1]} are typing...';
    } else if (typingUsers.length <= maxNames) {
      final allButLast = names.sublist(0, names.length - 1).join(', ');
      return '$allButLast and ${names.last} are typing...';
    } else {
      final displayedNames = names.join(', ');
      final othersCount = typingUsers.length - maxNames;
      return '$displayedNames and $othersCount ${othersCount == 1 ? 'other' : 'others'} are typing...';
    }
  }
  
  /// Update typing status for a user
  void updateTypingStatus(TypingEvent event) {
    _typingUsers[event.channelId] ??= {};
    
    if (event.isTyping) {
      // Add or update typing user
      _typingUsers[event.channelId]![event.userId] = event;
    } else {
      // Remove typing user
      _typingUsers[event.channelId]!.remove(event.userId);
      
      // Clean up empty channel maps
      if (_typingUsers[event.channelId]!.isEmpty) {
        _typingUsers.remove(event.channelId);
      }
    }
    
    notifyListeners();
  }
  
  /// Batch update typing statuses
  void batchUpdateTypingStatus(List<TypingEvent> events) {
    bool hasChanges = false;
    
    for (final event in events) {
      _typingUsers[event.channelId] ??= {};
      
      if (event.isTyping) {
        _typingUsers[event.channelId]![event.userId] = event;
        hasChanges = true;
      } else {
        if (_typingUsers[event.channelId]!.remove(event.userId) != null) {
          hasChanges = true;
        }
        
        if (_typingUsers[event.channelId]!.isEmpty) {
          _typingUsers.remove(event.channelId);
        }
      }
    }
    
    if (hasChanges) {
      notifyListeners();
    }
  }
  
  /// Stop typing for a specific user in a channel
  void stopTyping(String channelId, String userId) {
    final users = _typingUsers[channelId];
    if (users != null && users.remove(userId) != null) {
      if (users.isEmpty) {
        _typingUsers.remove(channelId);
      }
      notifyListeners();
    }
  }
  
  /// Clear all typing indicators for a channel
  void clearChannel(String channelId) {
    if (_typingUsers.remove(channelId) != null) {
      notifyListeners();
    }
  }
  
  /// Clear all typing indicators
  void clearAll() {
    if (_typingUsers.isNotEmpty) {
      _typingUsers.clear();
      notifyListeners();
    }
  }
  
  /// Clean up stale typing indicators
  void cleanupStale() {
    bool hasChanges = false;
    
    final channelsToRemove = <String>[];
    
    for (final entry in _typingUsers.entries) {
      final channelId = entry.key;
      final users = entry.value;
      
      final usersToRemove = <String>[];
      
      for (final userEntry in users.entries) {
        if (userEntry.value.isStale(threshold: staleThreshold)) {
          usersToRemove.add(userEntry.key);
          hasChanges = true;
        }
      }
      
      for (final userId in usersToRemove) {
        users.remove(userId);
      }
      
      if (users.isEmpty) {
        channelsToRemove.add(channelId);
      }
    }
    
    for (final channelId in channelsToRemove) {
      _typingUsers.remove(channelId);
    }
    
    if (hasChanges) {
      notifyListeners();
    }
  }
  
  /// Start periodic cleanup of stale typing indicators
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      cleanupStale();
    });
  }
  
  @override
  void dispose() {
    _cleanupTimer?.cancel();
    super.dispose();
  }
}
