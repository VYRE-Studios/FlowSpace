import 'package:flutter/foundation.dart';
import '../models/channel_model.dart';
import '../services/project_channel_service.dart';
import '../sync/sync_manager.dart';

/// Manages active channel and project-scoped channel list
class ChannelContext extends ChangeNotifier {
  String? _activeChannelId;
  String? _activeProjectId;
  List<ChannelModel> _channels = [];
  bool _loading = false;

  String? get activeChannelId => _activeChannelId;
  String? get activeProjectId => _activeProjectId;
  List<ChannelModel> get channels => _channels;
  bool get loading => _loading;

  /// Load channels for a project
  Future<void> loadProjectChannels(String projectId) async {
    if (_activeProjectId == projectId && _channels.isNotEmpty) {
      print('[ChannelContext] Channels already loaded for project $projectId');
      return;
    }

    print('[ChannelContext] Loading channels for project: $projectId');
    _loading = true;
    _activeProjectId = projectId;
    notifyListeners();

    try {
      _channels = await ProjectChannelService.loadProjectChannels(projectId);
      
      // If no channels exist for this project, initialize them
      if (_channels.isEmpty) {
        print('[ChannelContext] No channels found, initializing for project...');
        _channels = await ProjectChannelService.initializeProjectChannels(
          projectId: projectId,
          boardNames: ['Main', 'Planning', 'Archive'], // Default boards
        );
      }
      
      // Don't auto-select - user must click a channel (Teams-style)
      _activeChannelId = null;
      print('[ChannelContext] Loaded ${_channels.length} channels (none selected)');
    } catch (e) {
      print('[ChannelContext] ERROR loading channels: $e');
      _channels = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setActiveChannel(String channelId) {
    // Handle deselection (empty string means go back to boards)
    if (channelId.isEmpty) {
      _activeChannelId = null;
      print('[ChannelContext] Channel deselected - returning to boards');
      notifyListeners();
      return;
    }
    
    if (_activeChannelId == channelId) return;
    _activeChannelId = channelId;
    print('[ChannelContext] Active channel: $channelId');
    
    // Update SyncManager scope to current project/channel
    if (_activeProjectId != null) {
      SyncManager.instance.setScope(
        projectId: _activeProjectId,
        channelId: channelId,
      );
    }
    
    notifyListeners();
  }

  /// Get active channel model
  ChannelModel? get activeChannel {
    if (_activeChannelId == null) return null;
    try {
      return _channels.firstWhere((c) => c.channelId == _activeChannelId);
    } catch (e) {
      return null;
    }
  }

  void clear() {
    _activeChannelId = null;
    _activeProjectId = null;
    _channels = [];
    notifyListeners();
  }
}
