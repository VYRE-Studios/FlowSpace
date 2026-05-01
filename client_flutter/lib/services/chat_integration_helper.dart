import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'chat_events_service.dart';
import 'offline_queue_service.dart';
import 'notification_service.dart';
import 'sound_service.dart';
import 'chat_models.dart';

/// Helper class to integrate all Phase 2-4 features into existing chat UI
class ChatIntegrationHelper {
  static bool _initialized = false;

  /// Initialize all services - call this once at app startup
  static Future<void> initialize({
    required String userId,
    required String username,
  }) async {
    if (_initialized) return;

    // Initialize services
    await NotificationService.instance.init();
    await OfflineQueueService.instance.init();
    ChatEventsService.instance.init(userId: userId, username: username);

    _initialized = true;
    print('[ChatIntegration] All services initialized');
  }

  /// Show toast notification for user join/leave
  static void showUserJoinedToast(String displayName) {
    showSimpleNotification(
      Text('$displayName joined'),
      background: Colors.green,
      duration: const Duration(seconds: 2),
    );
  }

  static void showUserLeftToast(String displayName) {
    showSimpleNotification(
      Text('$displayName left'),
      background: Colors.orange,
      duration: const Duration(seconds: 2),
    );
  }

  /// Show toast for mention
  static void showMentionToast(String senderName, String content) {
    showSimpleNotification(
      Text('$senderName mentioned you'),
      subtitle: Text(
        content.length > 50 ? '${content.substring(0, 50)}...' : content,
      ),
      background: Colors.amber,
      duration: const Duration(seconds: 3),
    );
  }

  /// Get typing users for a channel
  static List<String> getTypingUsers(String channelId) {
    return ChatEventsService.instance.getTypingUsers(channelId);
  }

  /// Check if message was updated
  static ChatMessage? getUpdatedMessage(String messageId) {
    return ChatEventsService.instance.messageUpdates.value[messageId];
  }

  /// Check if message was deleted
  static bool isMessageDeleted(String messageId) {
    return ChatEventsService.instance.deletedMessages.value.contains(messageId);
  }

  /// Send message with offline queue support
  static Future<void> sendMessageWithOfflineSupport({
    required String workspaceId,
    required String channelId,
    required String content,
    required Future<ChatMessage> Function() sendFunction,
  }) async {
    try {
      await sendFunction();
    } catch (e) {
      print('[ChatIntegration] Message send failed, adding to offline queue: $e');
      await OfflineQueueService.instance.queueMessage(
        workspaceId: workspaceId,
        channelId: channelId,
        content: content,
      );
    }
  }

  /// Get pending message count for a channel
  static int getPendingMessageCount(String channelId) {
    return OfflineQueueService.instance.pendingMessages.value
        .where((m) => m.channelId == channelId)
        .length;
  }

  /// Listen to message updates
  static void addMessageUpdateListener(VoidCallback listener) {
    ChatEventsService.instance.messageUpdates.addListener(listener);
  }

  static void removeMessageUpdateListener(VoidCallback listener) {
    ChatEventsService.instance.messageUpdates.removeListener(listener);
  }

  /// Listen to typing updates
  static void addTypingUpdateListener(VoidCallback listener) {
    ChatEventsService.instance.typingUsers.addListener(listener);
  }

  static void removeTypingUpdateListener(VoidCallback listener) {
    ChatEventsService.instance.typingUsers.removeListener(listener);
  }

  /// Dispose all services
  static void dispose() {
    ChatEventsService.instance.dispose();
    OfflineQueueService.instance.dispose();
    SoundService.instance.dispose();
    _initialized = false;
  }
}
