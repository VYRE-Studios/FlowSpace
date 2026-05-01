import '../../services/chat_models.dart';

/// Legacy compatibility wrapper for Channel/ChannelSummary
/// Maps Phase 4 channel fields to legacy field names
class LegacyChannel {
  final ChannelSummary modern;

  LegacyChannel(this.modern);

  // Legacy-compatible fields
  String get id => modern.id;
  String get title => modern.name;
  String get name => modern.name;
  String? get description => modern.description;
  DateTime? get updatedAt => modern.updatedAt;

  // Legacy UI expectations
  int get unreadCount => 0; // Phase 4 doesn't track per-channel, returns safe default
  
  // Last message compatibility
  String? get lastMessageText => modern.lastMessage?.content;
  DateTime? get lastMessageTime => modern.lastMessage?.createdAt;
  String? get lastMessageSender => modern.lastMessage?.senderName;
  
  // Safe defaults for fields that may have been removed
  List<String> get userIds => []; // Stub - legacy may expect member list
  int get memberCount => 0; // Stub - safe default
}
