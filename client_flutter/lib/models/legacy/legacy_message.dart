import '../../services/chat_models.dart';

/// Legacy compatibility wrapper for ChatMessage
/// Maps Phase 4 modern message fields to legacy field names
class LegacyMessage {
  final ChatMessage modern;

  LegacyMessage(this.modern);

  // Legacy-compatible fields
  String get id => modern.id;
  String get text => modern.content;
  String get userId => modern.senderId;
  DateTime get createdAt => modern.createdAt;
  String get channelId => modern.channelId;

  // Optional fields for old widgets
  bool get isEdited => modern.edited;
  DateTime? get editedAt => modern.editedAt;
  bool get deleted => modern.deleted;
  String? get parentId => modern.parentId;
  List<String> get attachments =>
      modern.attachments?.map((attachment) => attachment.url).toList() ??
      const [];

  // Fallbacks for unknown legacy references
  String get username => modern.senderName ?? 'Unknown';
  String get authorName => modern.senderName ?? 'Unknown';
  DateTime get timestamp => modern.createdAt;
  String? get imageUrl => attachments.isNotEmpty ? attachments.first : null;
  String? get fileUrl => attachments.isNotEmpty ? attachments.first : null;
  
  // Thread/reply support
  int get replyCount => modern.threadCount ?? 0;
  bool get isMention => modern.isMention;
  
  // Reactions (for widgets that expect simple format)
  List<dynamic> get reactions =>
      modern.reactions?.entries
          .map((entry) => {
                'emoji': entry.key,
                'users': entry.value,
                'count': entry.value.length,
              })
          .toList() ??
      const [];
  
  // Pin state
  bool get pinned => modern.pinned;
  DateTime? get pinnedAt => modern.pinnedAt;
  String? get pinnedBy => modern.pinnedBy;
}
