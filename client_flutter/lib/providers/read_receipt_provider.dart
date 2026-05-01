import 'package:flutter/foundation.dart';
import '../models/read_receipt_event.dart';

class ReadReceiptProvider extends ChangeNotifier {
  // Track read receipts: channelId -> messageId -> Set of userId who read it
  final Map<String, Map<String, Map<String, ReadReceiptEvent>>> _receipts = {};
  
  // Track last read message per user per channel: channelId -> userId -> lastMessageId
  final Map<String, Map<String, String>> _lastReadMessage = {};
  
  // Current user ID (to exclude from read counts)
  String? _currentUserId;
  
  /// Set the current user ID
  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }
  
  /// Add a read receipt
  void addReadReceipt(ReadReceiptEvent receipt) {
    _receipts[receipt.channelId] ??= {};
    _receipts[receipt.channelId]![receipt.messageId] ??= {};
    _receipts[receipt.channelId]![receipt.messageId]![receipt.userId] = receipt;
    
    // Update last read message for this user
    _lastReadMessage[receipt.channelId] ??= {};
    _lastReadMessage[receipt.channelId]![receipt.userId] = receipt.messageId;
    
    notifyListeners();
  }
  
  /// Batch add read receipts
  void batchAddReadReceipts(List<ReadReceiptEvent> receipts) {
    bool hasChanges = false;
    
    for (final receipt in receipts) {
      _receipts[receipt.channelId] ??= {};
      _receipts[receipt.channelId]![receipt.messageId] ??= {};
      
      if (!_receipts[receipt.channelId]![receipt.messageId]!.containsKey(receipt.userId)) {
        _receipts[receipt.channelId]![receipt.messageId]![receipt.userId] = receipt;
        hasChanges = true;
      }
      
      // Update last read message
      _lastReadMessage[receipt.channelId] ??= {};
      final currentLastRead = _lastReadMessage[receipt.channelId]![receipt.userId];
      if (currentLastRead == null || _isMessageNewer(receipt.messageId, currentLastRead)) {
        _lastReadMessage[receipt.channelId]![receipt.userId] = receipt.messageId;
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      notifyListeners();
    }
  }
  
  /// Get read receipts for a specific message (excluding current user)
  List<ReadReceiptEvent> getReadReceipts(String channelId, String messageId) {
    final channelReceipts = _receipts[channelId];
    if (channelReceipts == null) return [];
    
    final messageReceipts = channelReceipts[messageId];
    if (messageReceipts == null) return [];
    
    return messageReceipts.values
        .where((receipt) => receipt.userId != _currentUserId)
        .toList();
  }
  
  /// Get count of users who read a message (excluding current user)
  int getReadCount(String channelId, String messageId) {
    return getReadReceipts(channelId, messageId).length;
  }
  
  /// Check if a specific user has read a message
  bool hasUserReadMessage(String channelId, String messageId, String userId) {
    return _receipts[channelId]?[messageId]?.containsKey(userId) ?? false;
  }
  
  /// Get all users who read a message
  Set<String> getUsersWhoRead(String channelId, String messageId) {
    final messageReceipts = _receipts[channelId]?[messageId];
    if (messageReceipts == null) return {};
    
    return messageReceipts.keys
        .where((userId) => userId != _currentUserId)
        .toSet();
  }
  
  /// Get formatted read receipt text
  /// 
  /// Examples:
  /// - "Read by Alice"
  /// - "Read by Alice and Bob"
  /// - "Read by Alice, Bob and 2 others"
  String getReadReceiptText(String channelId, String messageId, {int maxNames = 2}) {
    final receipts = getReadReceipts(channelId, messageId);
    
    if (receipts.isEmpty) return '';
    
    final names = receipts
        .map((r) => r.displayName ?? 'Someone')
        .take(maxNames)
        .toList();
    
    if (receipts.length == 1) {
      return 'Read by ${names[0]}';
    } else if (receipts.length == 2) {
      return 'Read by ${names[0]} and ${names[1]}';
    } else if (receipts.length <= maxNames) {
      final allButLast = names.sublist(0, names.length - 1).join(', ');
      return 'Read by $allButLast and ${names.last}';
    } else {
      final displayedNames = names.join(', ');
      final othersCount = receipts.length - maxNames;
      return 'Read by $displayedNames and $othersCount ${othersCount == 1 ? 'other' : 'others'}';
    }
  }
  
  /// Calculate unread count for a channel
  /// 
  /// Returns number of messages after the last message read by current user
  int getUnreadCount(String channelId, List<String> messageIds) {
    if (_currentUserId == null) return 0;
    
    final lastReadId = _lastReadMessage[channelId]?[_currentUserId!];
    if (lastReadId == null) return messageIds.length;
    
    final lastReadIndex = messageIds.indexOf(lastReadId);
    if (lastReadIndex == -1) return messageIds.length;
    
    // Count messages after the last read message
    return messageIds.length - lastReadIndex - 1;
  }
  
  /// Mark a message as read by current user
  void markAsRead(String channelId, String messageId, {String? displayName, String? avatarUrl}) {
    if (_currentUserId == null) return;
    
    final receipt = ReadReceiptEvent(
      messageId: messageId,
      userId: _currentUserId!,
      channelId: channelId,
      timestamp: DateTime.now(),
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
    
    addReadReceipt(receipt);
  }
  
  /// Mark all messages in a channel as read by current user
  void markAllAsRead(String channelId, List<String> messageIds, {String? displayName, String? avatarUrl}) {
    if (_currentUserId == null || messageIds.isEmpty) return;
    
    final receipts = messageIds.map((messageId) => ReadReceiptEvent(
      messageId: messageId,
      userId: _currentUserId!,
      channelId: channelId,
      timestamp: DateTime.now(),
      displayName: displayName,
      avatarUrl: avatarUrl,
    )).toList();
    
    batchAddReadReceipts(receipts);
  }
  
  /// Clear read receipts for a channel
  void clearChannel(String channelId) {
    if (_receipts.remove(channelId) != null || _lastReadMessage.remove(channelId) != null) {
      notifyListeners();
    }
  }
  
  /// Clear all read receipts
  void clearAll() {
    if (_receipts.isNotEmpty || _lastReadMessage.isNotEmpty) {
      _receipts.clear();
      _lastReadMessage.clear();
      notifyListeners();
    }
  }
  
  /// Helper to determine if one message is newer than another
  /// (This is a simple string comparison - in production you'd use proper ordering)
  bool _isMessageNewer(String messageId1, String messageId2) {
    // Assumes messageIds are chronologically ordered strings or timestamps
    // For UUIDs or random IDs, you'd need a proper timestamp comparison
    return messageId1.compareTo(messageId2) > 0;
  }
  
  /// Get the last message read by a specific user in a channel
  String? getLastReadMessage(String channelId, String userId) {
    return _lastReadMessage[channelId]?[userId];
  }
  
  /// Check if a message has been read by anyone (excluding sender)
  bool hasBeenRead(String channelId, String messageId, {String? senderId}) {
    final receipts = getReadReceipts(channelId, messageId);
    if (senderId != null) {
      return receipts.any((r) => r.userId != senderId);
    }
    return receipts.isNotEmpty;
  }
}
