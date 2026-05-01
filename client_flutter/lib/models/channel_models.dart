/// Channel member information for displaying in Teams-style UI
class ChannelMember {
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final String? role; // 'owner', 'admin', 'member'
  final bool isOnline;
  final DateTime? lastSeen;

  const ChannelMember({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.role,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ChannelMember.fromJson(Map<String, dynamic> json) {
    return ChannelMember(
      userId: json['userId'] as String? ?? json['user_id'] as String,
      displayName: json['displayName'] as String? ?? json['display_name'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      role: json['role'] as String?,
      isOnline: json['isOnline'] as bool? ?? json['is_online'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'] as String)
          : (json['last_seen'] != null
              ? DateTime.tryParse(json['last_seen'] as String)
              : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'role': role,
        'isOnline': isOnline,
        'lastSeen': lastSeen?.toIso8601String(),
      };
}
