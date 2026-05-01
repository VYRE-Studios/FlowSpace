import 'dart:io';
import 'dart:convert';
import '../models/channel_model.dart';
import 'workspace_location_service.dart';

/// Service for managing project-scoped channels
/// Each project gets:
/// - #general channel (always present)
/// - One channel per board
class ProjectChannelService {
  /// Get channels file path for a project
  static Future<File?> _getChannelsFile(String projectId) async {
    final workspacePath = await WorkspaceLocationService.getWorkspacePath();
    if (workspacePath == null) return null;

    final channelsFile = File('$workspacePath/$projectId/channels.json');
    return channelsFile;
  }

  /// Initialize channels for a new project
  /// Creates #general and board-specific channels
  static Future<List<ChannelModel>> initializeProjectChannels({
    required String projectId,
    required List<String> boardNames,
  }) async {
    print('[ProjectChannelService] Initializing channels for project $projectId');

    final channels = <ChannelModel>[];

    // Always create #general channel
    final generalChannel = ChannelModel(
      channelId: '$projectId-general',
      name: 'general',
      description: 'General discussion for this project',
      createdAt: DateTime.now(),
    );
    channels.add(generalChannel);

    // Create channel for each board
    for (final boardName in boardNames) {
      final channelId = '$projectId-${boardName.toLowerCase().replaceAll(' ', '-')}';
      final channel = ChannelModel(
        channelId: channelId,
        name: boardName,
        description: 'Discussion for $boardName board',
        createdAt: DateTime.now(),
      );
      channels.add(channel);
    }

    // Save to disk
    await _saveChannels(projectId, channels);

    print('[ProjectChannelService] Created ${channels.length} channels');
    return channels;
  }

  /// Load channels for a project
  static Future<List<ChannelModel>> loadProjectChannels(String projectId) async {
    final file = await _getChannelsFile(projectId);
    if (file == null || !file.existsSync()) {
      print('[ProjectChannelService] No channels file found for project $projectId');
      return [];
    }

    try {
      final jsonString = file.readAsStringSync();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final channelsList = (data['channels'] as List<dynamic>)
          .map((c) => ChannelModel.fromJson(c as Map<String, dynamic>))
          .toList();

      print('[ProjectChannelService] Loaded ${channelsList.length} channels');
      return channelsList;
    } catch (e) {
      print('[ProjectChannelService] ERROR loading channels: $e');
      return [];
    }
  }

  /// Save channels to disk
  static Future<void> _saveChannels(String projectId, List<ChannelModel> channels) async {
    final file = await _getChannelsFile(projectId);
    if (file == null) return;

    // Ensure parent directory exists
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }

    final data = {
      'version': '1.0.0',
      'projectId': projectId,
      'channels': channels.map((c) => c.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    file.writeAsStringSync(jsonString);

    print('[ProjectChannelService] Saved ${channels.length} channels to disk');
  }

  /// Add a new channel to a project
  static Future<ChannelModel> addChannel({
    required String projectId,
    required String name,
    String? description,
  }) async {
    final channels = await loadProjectChannels(projectId);
    
    final newChannel = ChannelModel(
      channelId: '$projectId-${name.toLowerCase().replaceAll(' ', '-')}',
      name: name,
      description: description ?? 'Channel for $name',
      createdAt: DateTime.now(),
    );

    channels.add(newChannel);
    await _saveChannels(projectId, channels);

    print('[ProjectChannelService] Added channel: $name');
    return newChannel;
  }

  /// Remove a channel (except #general)
  static Future<void> removeChannel({
    required String projectId,
    required String channelId,
  }) async {
    final channels = await loadProjectChannels(projectId);
    
    // Prevent removing #general
    if (channelId.endsWith('-general')) {
      print('[ProjectChannelService] Cannot remove #general channel');
      return;
    }

    channels.removeWhere((c) => c.channelId == channelId);
    await _saveChannels(projectId, channels);

    print('[ProjectChannelService] Removed channel: $channelId');
  }

  /// Get channel messages directory path
  static Future<String?> getChannelMessagesPath({
    required String projectId,
    required String channelId,
  }) async {
    final workspacePath = await WorkspaceLocationService.getWorkspacePath();
    if (workspacePath == null) return null;

    final messagesDir = '$workspacePath/$projectId/messages/$channelId';
    final dir = Directory(messagesDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    return messagesDir;
  }
}
