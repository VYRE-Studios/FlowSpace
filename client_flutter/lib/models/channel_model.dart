// lib/models/channel_model.dart
import 'channel_models.dart';

class ChannelModel {
  final String channelId;
  final String name;
  final String? description;
  final DateTime createdAt;
  final bool isPrivate;
  final List<ChannelMember>? members;

  // Convenience getters
  String get id => channelId;

  ChannelModel({
    required this.channelId,
    required this.name,
    this.description,
    required this.createdAt,
    this.isPrivate = false,
    this.members,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    final membersList = json['members'] as List<dynamic>?;
    return ChannelModel(
      channelId: json['channelId'] ?? json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      isPrivate: json['isPrivate'] ?? json['is_private'] ?? false,
      members: membersList?.map((m) => ChannelMember.fromJson(m as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'channelId': channelId,
        'name': name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'isPrivate': isPrivate,
        'members': members?.map((m) => m.toJson()).toList(),
      };
}
