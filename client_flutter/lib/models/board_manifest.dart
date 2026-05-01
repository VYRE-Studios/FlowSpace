// lib/models/board_manifest.dart

class BoardManifest {
  final String boardId;
  final String name;
  final String channelId;
  final String moduleType;
  final DateTime createdAt;

  BoardManifest({
    required this.boardId,
    required this.name,
    required this.channelId,
    required this.moduleType,
    required this.createdAt,
  });

  factory BoardManifest.fromJson(Map<String, dynamic> json) {
    return BoardManifest(
      boardId: json['boardId'],
      name: json['name'],
      channelId: json['channelId'],
      moduleType: json['moduleType'] ?? 'standard',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'boardId': boardId,
        'name': name,
        'channelId': channelId,
        'moduleType': moduleType,
        'createdAt': createdAt.toIso8601String(),
      };
}
