import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message_event.dart';
import '../models/typing_event.dart';
import '../models/read_receipt_event.dart';
import '../services/message_stream_service.dart';
import '../services/message_merge_service.dart';
import '../services/typing_indicator_service.dart';
import '../services/network_quality_service.dart';
import '../services/offline_message_queue.dart';

class MessageProvider extends ChangeNotifier {
  final MessageStreamService _streamService;
  final MessageMergeService _mergeService;
  late final TypingIndicatorService _typingService;
  late final NetworkQualityService _networkQualityService;
  late final OfflineMessageQueue _offlineQueue;
  
  // Messages organized by channel
  final Map<String, List<MessageEvent>> _messagesByChannel = {};
  
  // Read receipts: channelId -> messageId -> Set of userIds who read it
  final Map<String, Map<String, Set<String>>> _readReceipts = {};
  
  // Connection state
  bool _isConnected = false;
  
  // Stream subscriptions
  StreamSubscription<MessageEvent>? _messageSubscription;
  StreamSubscription<MessageEvent>? _messageEditedSubscription;
  StreamSubscription<String>? _messageDeletedSubscription;
  StreamSubscription<Map<String, dynamic>>? _messageReadSubscription;
  StreamSubscription<Map<String, dynamic>>? _deliveryStateSubscription;
  StreamSubscription<bool>? _connectionStateSubscription;
  StreamSubscription<TypingEvent>? _typingSubscription;
  
  // Current user ID (for determining message ownership)
  String? _currentUserId;
  
  // Typing indicator callback
  void Function(TypingEvent)? onTypingEvent;
  
  // Read receipt callback
  void Function(ReadReceiptEvent)? onReadReceiptEvent;
  
  MessageProvider(this._streamService, this._mergeService) {
    // Initialize typing service with callback to emit typing events
    _typingService = TypingIndicatorService(
      (channelId, isTyping) {
        _streamService.sendTypingIndicator(channelId, isTyping);
      },
    );
    
    // Initialize network quality service
    _networkQualityService = NetworkQualityService();
    
    // Initialize offline message queue
    _offlineQueue = OfflineMessageQueue();
    _offlineQueue.initialize();
  }
  
  // Getters
  bool get isConnected => _isConnected;
  NetworkQualityService get networkQualityService => _networkQualityService;
  OfflineMessageQueue get offlineQueue => _offlineQueue;
  NetworkQualityMetrics get networkQuality => _networkQualityService.currentMetrics;
  
  List<MessageEvent> getChannelMessages(String channelId) {
    return _messagesByChannel[channelId] ?? [];
  }
  
  Set<String> getReadReceipts(String channelId, String messageId) {
    return _readReceipts[channelId]?[messageId] ?? {};
  }
  
  int getUnreadCount(String channelId, String? lastReadMessageId) {
    final messages = getChannelMessages(channelId);
    if (lastReadMessageId == null) return messages.length;
    
    final lastReadIndex = messages.indexWhere(
      (msg) => msg.messageId == lastReadMessageId,
    );
    
    if (lastReadIndex == -1) return messages.length;
    
    return messages.length - lastReadIndex - 1;
  }
  
  /// Initialize provider with current user ID
  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }
  
  /// Start listening to message streams
  void startListening() {
    _messageSubscription = _streamService.messageStream.listen(_handleNewMessage);
    _messageEditedSubscription = _streamService.messageEditedStream.listen(_handleMessageEdited);
    _messageDeletedSubscription = _streamService.messageDeletedStream.listen(_handleMessageDeleted);
    _messageReadSubscription = _streamService.messageReadStream.listen(_handleMessageRead);
    _deliveryStateSubscription = _streamService.deliveryStateStream.listen(_handleDeliveryState);
    _connectionStateSubscription = _streamService.connectionStateStream.listen(_handleConnectionState);
    _typingSubscription = _streamService.typingStream.listen(_handleTypingEvent);
    
    // Start network quality monitoring
    _networkQualityService.startMonitoring(() async {
      // Ping implementation - could emit a ping event to server
      // For now, we'll rely on connection state and message delivery times
    });
  }
  
  /// Stop listening to message streams
  void stopListening() {
    _messageSubscription?.cancel();
    _messageEditedSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _messageReadSubscription?.cancel();
    _deliveryStateSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _typingSubscription?.cancel();
  }
  
  /// Called when user types in a channel (triggers debounced typing indicator)
  void onUserTyping(String channelId) {
    _typingService.onUserTyping(channelId);
  }
  
  /// Stop typing indicator for a channel
  void stopTypingIndicator(String channelId) {
    _typingService.stopTyping(channelId);
  }
  
  /// Send a message with optimistic UI update and offline queuing
  Future<void> sendMessage({
    required String channelId,
    required String content,
    List<String>? attachments,
    String? threadId,
  }) async {
    if (_currentUserId == null) {
      print('[MessageProvider] Cannot send message: current user ID not set');
      return;
    }
    
    final sendTimestamp = DateTime.now();
    
    // If offline, queue the message
    if (!_isConnected) {
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      
      await _offlineQueue.enqueue(QueuedMessage(
        tempId: tempId,
        channelId: channelId,
        content: content,
        attachments: attachments,
        threadId: threadId,
        queuedAt: DateTime.now(),
      ));
      
      // Create optimistic message with queued state
      final optimisticMessage = MessageEvent(
        tempId: tempId,
        channelId: channelId,
        userId: _currentUserId!,
        content: content,
        timestamp: DateTime.now(),
        deliveryState: DeliveryState.sending,
        attachments: attachments,
        threadId: threadId,
      );
      
      final existingMessages = _messagesByChannel[channelId] ?? [];
      _messagesByChannel[channelId] = _mergeService.mergeNewMessage(
        existingMessages: existingMessages,
        newMessage: optimisticMessage,
      );
      
      _typingService.onMessageSent(channelId);
      notifyListeners();
      return;
    }
    
    // Send via WebSocket
    final tempId = _streamService.sendMessage(
      channelId: channelId,
      content: content,
      attachments: attachments,
      threadId: threadId,
    );
    
    // Create optimistic message
    final optimisticMessage = MessageEvent(
      tempId: tempId,
      channelId: channelId,
      userId: _currentUserId!,
      content: content,
      timestamp: DateTime.now(),
      deliveryState: DeliveryState.sending,
      attachments: attachments,
      threadId: threadId,
    );
    
    // Add optimistically to UI
    final existingMessages = _messagesByChannel[channelId] ?? [];
    _messagesByChannel[channelId] = _mergeService.mergeNewMessage(
      existingMessages: existingMessages,
      newMessage: optimisticMessage,
    );
    
    // Stop typing indicator when message is sent
    _typingService.onMessageSent(channelId);
    
    // Record send time for network quality tracking
    optimisticMessage.metadata?['sendTimestamp'] = sendTimestamp.millisecondsSinceEpoch;
    
    notifyListeners();
  }
  
  /// Edit a message
  Future<void> editMessage({
    required String messageId,
    required String content,
  }) async {
    _streamService.editMessage(messageId: messageId, content: content);
  }
  
  /// Delete a message
  Future<void> deleteMessage(String messageId, String channelId) async {
    _streamService.deleteMessage(messageId);
    
    // Optimistically remove from UI
    final existingMessages = _messagesByChannel[channelId] ?? [];
    _messagesByChannel[channelId] = _mergeService.removeMessage(
      messages: existingMessages,
      messageId: messageId,
    );
    
    notifyListeners();
  }
  
  /// Mark a message as read
  Future<void> markAsRead(String messageId) async {
    _streamService.markAsRead(messageId);
  }
  
  /// Retry a failed message
  Future<void> retryMessage(MessageEvent failedMessage) async {
    if (!failedMessage.isFailed) return;
    
    // Remove the failed message
    final existingMessages = _messagesByChannel[failedMessage.channelId] ?? [];
    final withoutFailed = _mergeService.removeMessage(
      messages: existingMessages,
      messageId: failedMessage.id,
    );
    
    _messagesByChannel[failedMessage.channelId] = withoutFailed;
    notifyListeners();
    
    // Resend
    await sendMessage(
      channelId: failedMessage.channelId,
      content: failedMessage.content,
      attachments: failedMessage.attachments,
      threadId: failedMessage.threadId,
    );
  }
  
  /// Load historical messages for a channel
  Future<void> loadChannelMessages(String channelId, List<MessageEvent> messages) async {
    _messagesByChannel[channelId] = _mergeService.sortByTimestamp(messages);
    notifyListeners();
  }
  
  /// Clear messages for a channel
  void clearChannel(String channelId) {
    _messagesByChannel.remove(channelId);
    _readReceipts.remove(channelId);
    notifyListeners();
  }
  
  /// Clear all messages
  void clearAll() {
    _messagesByChannel.clear();
    _readReceipts.clear();
    notifyListeners();
  }
  
  // Private event handlers
  
  void _handleNewMessage(MessageEvent message) {
    final existingMessages = _messagesByChannel[message.channelId] ?? [];
    
    _messagesByChannel[message.channelId] = _mergeService.mergeNewMessage(
      existingMessages: existingMessages,
      newMessage: message,
    );
    
    notifyListeners();
  }
  
  void _handleMessageEdited(MessageEvent updatedMessage) {
    final existingMessages = _messagesByChannel[updatedMessage.channelId] ?? [];
    
    _messagesByChannel[updatedMessage.channelId] = _mergeService.updateMessage(
      messages: existingMessages,
      updatedMessage: updatedMessage,
    );
    
    notifyListeners();
  }
  
  void _handleMessageDeleted(String messageId) {
    // Find which channel this message belongs to
    for (final channelId in _messagesByChannel.keys) {
      final messages = _messagesByChannel[channelId]!;
      final messageIndex = messages.indexWhere((msg) => msg.messageId == messageId);
      
      if (messageIndex != -1) {
        _messagesByChannel[channelId] = _mergeService.removeMessage(
          messages: messages,
          messageId: messageId,
        );
        notifyListeners();
        break;
      }
    }
  }
  
  
  void _handleDeliveryState(Map<String, dynamic> data) {
    final tempId = data['tempId'] as String?;
    final messageId = data['messageId'] as String?;
    final state = data['state'] as String?;
    final timestamp = data['timestamp'] as int?;
    
    if (state == null) return;
    
    // Find the channel containing this message
    for (final channelId in _messagesByChannel.keys) {
      final messages = _messagesByChannel[channelId]!;
      
      if (state == 'sent' && tempId != null && messageId != null) {
        // Replace optimistic message with confirmed one
        final hasOptimistic = messages.any((msg) => msg.tempId == tempId);
        
        if (hasOptimistic) {
          _messagesByChannel[channelId] = _mergeService.replaceOptimisticInList(
            messages: messages,
            tempId: tempId,
            confirmedMessageId: messageId,
            serverTimestamp: timestamp != null 
                ? DateTime.fromMillisecondsSinceEpoch(timestamp)
                : null,
          );
          notifyListeners();
          break;
        }
      } else if (state == 'failed' && tempId != null) {
        // Mark optimistic message as failed
        final hasOptimistic = messages.any((msg) => msg.tempId == tempId);
        
        if (hasOptimistic) {
          _messagesByChannel[channelId] = _mergeService.markOptimisticAsFailed(
            messages: messages,
            tempId: tempId,
          );
          notifyListeners();
          break;
        }
      } else if (state == 'delivered' && messageId != null) {
        // Update delivery state to delivered
        final hasMessage = messages.any((msg) => msg.messageId == messageId);
        
        if (hasMessage) {
          _messagesByChannel[channelId] = _mergeService.updateDeliveryState(
            messages: messages,
            messageId: messageId,
            newState: DeliveryState.delivered,
          );
          notifyListeners();
          break;
        }
      }
    }
  }
  
  void _handleConnectionState(bool connected) {
    final wasConnected = _isConnected;
    _isConnected = connected;
    
    // Update network quality
    _networkQualityService.updateConnectionState(connected);
    
    // Process offline queue when reconnected
    if (connected && !wasConnected && _offlineQueue.hasQueuedMessages) {
      print('[MessageProvider] Reconnected, processing offline queue');
      _processOfflineQueue();
    }
    
    notifyListeners();
  }
  
  void _handleTypingEvent(TypingEvent event) {
    // Forward to external handler if provided (e.g. TypingIndicatorProvider)
    onTypingEvent?.call(event);
  }
  
  void _handleMessageRead(Map<String, dynamic> data) {
    final channelId = data['channelId'] as String?;
    final messageId = data['messageId'] as String?;
    final userId = data['userId'] as String?;
    final displayName = data['displayName'] as String?;
    final avatarUrl = data['avatarUrl'] as String?;
    
    if (channelId == null || messageId == null || userId == null) return;
    
    // Create read receipt event
    final receipt = ReadReceiptEvent(
      messageId: messageId,
      userId: userId,
      channelId: channelId,
      timestamp: DateTime.now(),
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
    
    // Forward to external handler if provided (e.g. ReadReceiptProvider)
    onReadReceiptEvent?.call(receipt);
    
    // Update local read receipts storage
    _readReceipts[channelId] ??= {};
    _readReceipts[channelId]![messageId] ??= {};
    _readReceipts[channelId]![messageId]!.add(userId);
    
    notifyListeners();
  }
  
  /// Process offline message queue
  Future<void> _processOfflineQueue() async {
    await _offlineQueue.processQueue((queuedMsg) async {
      try {
        // Send the queued message
        final tempId = _streamService.sendMessage(
          channelId: queuedMsg.channelId,
          content: queuedMsg.content,
          attachments: queuedMsg.attachments,
          threadId: queuedMsg.threadId,
        );
        
        // Update the message in UI with new tempId
        final messages = _messagesByChannel[queuedMsg.channelId] ?? [];
        final index = messages.indexWhere((m) => m.tempId == queuedMsg.tempId);
        
        if (index != -1) {
          _messagesByChannel[queuedMsg.channelId]![index] = messages[index].copyWith(
            tempId: tempId,
            deliveryState: DeliveryState.sending,
          );
          notifyListeners();
        }
        
        return true;
      } catch (e) {
        print('[MessageProvider] Error processing queued message: $e');
        return false;
      }
    });
  }
  
  @override
  void dispose() {
    stopListening();
    _typingService.dispose();
    _networkQualityService.dispose();
    _offlineQueue.dispose();
    super.dispose();
  }
}
