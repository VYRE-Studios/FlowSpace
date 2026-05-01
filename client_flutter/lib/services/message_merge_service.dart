import '../models/message_event.dart';

/// Service to handle merging optimistic messages with server-confirmed messages
class MessageMergeService {
  /// Merge optimistic message with confirmed message from server
  /// 
  /// Returns the merged message with real messageId and updated delivery state.
  /// Preserves client-side properties like tempId for tracking.
  MessageEvent mergeOptimisticWithConfirmed({
    required MessageEvent optimisticMessage,
    required String confirmedMessageId,
    DateTime? serverTimestamp,
  }) {
    return optimisticMessage.copyWith(
      messageId: confirmedMessageId,
      deliveryState: DeliveryState.sent,
      timestamp: serverTimestamp ?? optimisticMessage.timestamp,
    );
  }

  /// Find and replace optimistic message in a list with confirmed message
  /// 
  /// Returns updated list with optimistic message replaced by confirmed version.
  /// If tempId not found, appends the confirmed message.
  List<MessageEvent> replaceOptimisticInList({
    required List<MessageEvent> messages,
    required String tempId,
    required String confirmedMessageId,
    DateTime? serverTimestamp,
  }) {
    final index = messages.indexWhere((msg) => msg.tempId == tempId);
    
    if (index == -1) {
      // Optimistic message not found, this shouldn't happen
      // but handle gracefully by not adding duplicate
      print('[MessageMergeService] Warning: Optimistic message with tempId $tempId not found');
      return messages;
    }
    
    final optimisticMessage = messages[index];
    final confirmedMessage = mergeOptimisticWithConfirmed(
      optimisticMessage: optimisticMessage,
      confirmedMessageId: confirmedMessageId,
      serverTimestamp: serverTimestamp,
    );
    
    final updatedMessages = List<MessageEvent>.from(messages);
    updatedMessages[index] = confirmedMessage;
    
    return updatedMessages;
  }

  /// Mark an optimistic message as failed
  List<MessageEvent> markOptimisticAsFailed({
    required List<MessageEvent> messages,
    required String tempId,
  }) {
    final index = messages.indexWhere((msg) => msg.tempId == tempId);
    
    if (index == -1) {
      return messages;
    }
    
    final updatedMessages = List<MessageEvent>.from(messages);
    updatedMessages[index] = messages[index].markFailed();
    
    return updatedMessages;
  }

  /// Update delivery state for a message
  List<MessageEvent> updateDeliveryState({
    required List<MessageEvent> messages,
    required String messageId,
    required DeliveryState newState,
  }) {
    final index = messages.indexWhere((msg) => msg.messageId == messageId);
    
    if (index == -1) {
      return messages;
    }
    
    final updatedMessages = List<MessageEvent>.from(messages);
    updatedMessages[index] = messages[index].copyWith(deliveryState: newState);
    
    return updatedMessages;
  }

  /// Remove duplicate messages (by messageId or tempId)
  /// 
  /// Prefers confirmed messages over optimistic ones.
  List<MessageEvent> deduplicateMessages(List<MessageEvent> messages) {
    final seen = <String>{};
    final deduplicated = <MessageEvent>[];
    
    // First pass: collect all confirmed messages (with messageId)
    for (final msg in messages) {
      if (msg.messageId != null && !seen.contains(msg.messageId)) {
        seen.add(msg.messageId!);
        deduplicated.add(msg);
      }
    }
    
    // Second pass: add optimistic messages that haven't been confirmed
    for (final msg in messages) {
      if (msg.isOptimistic && msg.tempId != null && !seen.contains(msg.tempId)) {
        seen.add(msg.tempId!);
        deduplicated.add(msg);
      }
    }
    
    return deduplicated;
  }

  /// Sort messages by timestamp (oldest first)
  List<MessageEvent> sortByTimestamp(List<MessageEvent> messages) {
    final sorted = List<MessageEvent>.from(messages);
    sorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return sorted;
  }

  /// Merge new message into existing list, maintaining sort order
  /// 
  /// Automatically deduplicates and sorts.
  List<MessageEvent> mergeNewMessage({
    required List<MessageEvent> existingMessages,
    required MessageEvent newMessage,
  }) {
    final updated = [...existingMessages, newMessage];
    final deduplicated = deduplicateMessages(updated);
    return sortByTimestamp(deduplicated);
  }

  /// Update an existing message in the list (for edits)
  List<MessageEvent> updateMessage({
    required List<MessageEvent> messages,
    required MessageEvent updatedMessage,
  }) {
    final index = messages.indexWhere(
      (msg) => msg.messageId == updatedMessage.messageId,
    );
    
    if (index == -1) {
      // Message not found, add it
      return mergeNewMessage(
        existingMessages: messages,
        newMessage: updatedMessage,
      );
    }
    
    final updated = List<MessageEvent>.from(messages);
    updated[index] = updatedMessage;
    
    return updated;
  }

  /// Remove a message from the list (for deletions)
  List<MessageEvent> removeMessage({
    required List<MessageEvent> messages,
    required String messageId,
  }) {
    return messages.where((msg) => msg.messageId != messageId).toList();
  }

  /// Get pending optimistic messages (not yet confirmed by server)
  List<MessageEvent> getPendingMessages(List<MessageEvent> messages) {
    return messages
        .where((msg) => msg.isOptimistic && !msg.isFailed)
        .toList();
  }

  /// Get failed messages
  List<MessageEvent> getFailedMessages(List<MessageEvent> messages) {
    return messages.where((msg) => msg.isFailed).toList();
  }

  /// Retry a failed message (converts back to sending state)
  MessageEvent retryFailedMessage(MessageEvent failedMessage) {
    if (!failedMessage.isFailed) {
      return failedMessage;
    }
    
    // Generate new tempId for retry
    final newTempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_retry';
    
    return failedMessage.copyWith(
      tempId: newTempId,
      deliveryState: DeliveryState.sending,
      timestamp: DateTime.now(),
    );
  }
}
