// lib/models/project_root.dart

import 'board_manifest.dart';
import 'timeline_manifest.dart';
import 'asset_manifest.dart';
import 'channel_model.dart';

class ProjectRoot {
  final String projectId;
  final List<BoardManifest> boards;
  final List<TimelineManifest> timelines;
  final List<ChannelModel> channels;
  final List<AssetManifest> assets;
  final DateTime updatedAt;

  ProjectRoot({
    required this.projectId,
    required this.boards,
    required this.timelines,
    required this.channels,
    required this.assets,
    required this.updatedAt,
  });

  factory ProjectRoot.fromJson(Map<String, dynamic> json) {
    return ProjectRoot(
      projectId: json['projectId'],
      boards: (json['boards'] as List)
          .map((j) => BoardManifest.fromJson(j))
          .toList(),
      timelines: (json['timelines'] as List)
          .map((j) => TimelineManifest.fromJson(j))
          .toList(),
      channels: (json['channels'] as List)
          .map((j) => ChannelModel.fromJson(j))
          .toList(),
      assets: (json['assets'] as List)
          .map((j) => AssetManifest.fromJson(j))
          .toList(),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'boards': boards.map((b) => b.toJson()).toList(),
        'timelines': timelines.map((t) => t.toJson()).toList(),
        'channels': channels.map((c) => c.toJson()).toList(),
        'assets': assets.map((a) => a.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
