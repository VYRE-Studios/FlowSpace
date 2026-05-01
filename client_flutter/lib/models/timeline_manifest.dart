// lib/models/timeline_manifest.dart

class TimelineManifest {
  final String timelineId;
  final String name;
  final String channelId;
  final DateTime createdAt;

  TimelineManifest({
    required this.timelineId,
    required this.name,
    required this.channelId,
    required this.createdAt,
  });

  factory TimelineManifest.fromJson(Map<String, dynamic> json) {
    return TimelineManifest(
      timelineId: json['timelineId'],
      name: json['name'],
      channelId: json['channelId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'timelineId': timelineId,
        'name': name,
        'channelId': channelId,
        'createdAt': createdAt.toIso8601String(),
      };
}
