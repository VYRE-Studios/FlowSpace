/// Represents a bulletin/announcement in a workspace
class Bulletin {
  final String id;
  final String workspaceId;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final BulletinPriority priority;
  final BulletinType type;
  final DateTime? expiresAt;
  final List<String> tags;
  final bool isPinned;
  final int viewCount;
  final List<String> attachmentUrls;

  const Bulletin({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.updatedAt,
    required this.priority,
    required this.type,
    this.expiresAt,
    required this.tags,
    required this.isPinned,
    required this.viewCount,
    required this.attachmentUrls,
  });

  factory Bulletin.fromJson(Map<String, dynamic> json) {
    return Bulletin(
      id: json['id'] as String,
      workspaceId: json['workspaceId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      priority: BulletinPriority.values.firstWhere(
        (p) => p.toString() == 'BulletinPriority.${json['priority']}',
        orElse: () => BulletinPriority.normal,
      ),
      type: BulletinType.values.firstWhere(
        (t) => t.toString() == 'BulletinType.${json['type']}',
        orElse: () => BulletinType.announcement,
      ),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      isPinned: json['isPinned'] as bool? ?? false,
      viewCount: json['viewCount'] as int? ?? 0,
      attachmentUrls: (json['attachmentUrls'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'workspaceId': workspaceId,
        'title': title,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': createdAt.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        'priority': priority.toString().split('.').last,
        'type': type.toString().split('.').last,
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
        'tags': tags,
        'isPinned': isPinned,
        'viewCount': viewCount,
        'attachmentUrls': attachmentUrls,
      };

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isActive => !isExpired;

  Bulletin copyWith({
    String? id,
    String? workspaceId,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    BulletinPriority? priority,
    BulletinType? type,
    DateTime? expiresAt,
    List<String>? tags,
    bool? isPinned,
    int? viewCount,
    List<String>? attachmentUrls,
  }) {
    return Bulletin(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      priority: priority ?? this.priority,
      type: type ?? this.type,
      expiresAt: expiresAt ?? this.expiresAt,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      viewCount: viewCount ?? this.viewCount,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bulletin &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId;

  @override
  int get hashCode => id.hashCode ^ workspaceId.hashCode;
}

enum BulletinPriority {
  low,
  normal,
  high,
  urgent,
}

enum BulletinType {
  announcement, // General announcements
  update, // Product updates
  event, // Events
  policy, // Policy changes
  maintenance, // Scheduled maintenance
  alert, // Alerts/warnings
  news, // Company news
  other, // Other
}

/// Event for real-time bulletin updates
class BulletinEvent {
  final String bulletinId;
  final String workspaceId;
  final BulletinAction action;
  final Bulletin? bulletin;
  final DateTime timestamp;

  const BulletinEvent({
    required this.bulletinId,
    required this.workspaceId,
    required this.action,
    this.bulletin,
    required this.timestamp,
  });

  factory BulletinEvent.fromJson(Map<String, dynamic> json) {
    return BulletinEvent(
      bulletinId: json['bulletinId'] as String,
      workspaceId: json['workspaceId'] as String,
      action: BulletinAction.values.firstWhere(
        (a) => a.toString() == 'BulletinAction.${json['action']}',
        orElse: () => BulletinAction.created,
      ),
      bulletin: json['bulletin'] != null
          ? Bulletin.fromJson(json['bulletin'] as Map<String, dynamic>)
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'bulletinId': bulletinId,
        'workspaceId': workspaceId,
        'action': action.toString().split('.').last,
        if (bulletin != null) 'bulletin': bulletin!.toJson(),
        'timestamp': timestamp.toIso8601String(),
      };
}

enum BulletinAction {
  created,
  updated,
  deleted,
  pinned,
  unpinned,
}

/// Request to create/update a bulletin
class BulletinRequest {
  final String? id;
  final String workspaceId;
  final String title;
  final String content;
  final BulletinPriority priority;
  final BulletinType type;
  final DateTime? expiresAt;
  final List<String> tags;
  final List<String> attachmentUrls;

  const BulletinRequest({
    this.id,
    required this.workspaceId,
    required this.title,
    required this.content,
    this.priority = BulletinPriority.normal,
    this.type = BulletinType.announcement,
    this.expiresAt,
    this.tags = const [],
    this.attachmentUrls = const [],
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'workspaceId': workspaceId,
        'title': title,
        'content': content,
        'priority': priority.toString().split('.').last,
        'type': type.toString().split('.').last,
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
        'tags': tags,
        'attachmentUrls': attachmentUrls,
      };
}
