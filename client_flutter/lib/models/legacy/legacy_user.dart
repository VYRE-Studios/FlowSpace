/// Legacy compatibility wrapper for User model
/// Provides fallback fields for legacy UI expecting old schema
class LegacyUser {
  final String id;
  final String? displayName;
  final String? username;
  final String? avatarUrl;
  final String? presence;

  LegacyUser({
    required this.id,
    this.displayName,
    this.username,
    this.avatarUrl,
    this.presence,
  });

  // Legacy-compatible getters
  String get name => displayName ?? username ?? 'User';
  String? get avatar => avatarUrl;
  
  // Legacy presence mapping
  bool get isOnline => presence == 'online';
  bool get isAway => presence == 'away';
  bool get isBusy => presence == 'busy';
  bool get isOffline => presence == 'offline' || presence == null;
  
  // Factory from JSON for compatibility
  factory LegacyUser.fromJson(Map<String, dynamic> json) {
    return LegacyUser(
      id: json['id'] as String? ?? json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? json['name'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar'] as String?,
      presence: json['presence'] as String? ?? json['status'] as String?,
    );
  }
}
