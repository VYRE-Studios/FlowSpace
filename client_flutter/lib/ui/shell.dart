import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/workspace_service.dart';
import '../services/realtime/socket_service.dart';
import '../services/presence/presence_service.dart';
import '../services/workspaces/workspace_activity_service.dart';
import '../services/p2p_gateway_client.dart';
import '../services/update_service.dart';

import 'app_header.dart';
import 'navigation/flow_nav_rail.dart';
import 'widgets/header/presence_selector.dart';
import 'widgets/sidebar/right_sidebar.dart';
import 'views/activity_view.dart';
import 'views/chat_view.dart';
import 'views/dashboard_view.dart';
import 'views/document_view.dart';
import 'views/meet_view.dart';
import 'views/profile_view.dart';
import 'views/projects_view.dart';
import 'views/vault_view.dart';
import 'views/whiteboard_view.dart';
import 'views/settings_view.dart';

class FlowShell extends StatefulWidget {
  const FlowShell({super.key});

  @override
  State<FlowShell> createState() => _FlowShellState();
}

class _FlowShellState extends State<FlowShell> {
  int _selectedIndex = 0;
  String _workspaceName = 'FlowSpace';
  String? _currentWorkspaceId;
  List<String> _workspaceNames = const [];
  String _userName = '';
  String? _currentWorkspaceType;
  UserPresence _presence = UserPresence.online;
  late WorkspaceMetadata _workspaceMetadata;
  List<MemberInfo> _members = const [];
  List<ActivityEvent> _recentActivity = const [];
  CallStatus? _callStatus;

  // P2P Gateway Client (replaces direct P2P)
  // No need to store instance - using singleton

  Widget _getWorkspaceView() {
    switch (_currentWorkspaceType) {
      case 'whiteboard':
        return const WhiteboardView();
      case 'document':
        return const DocumentView();
      case 'project':
      default:
        return ProjectsView(
          key: ValueKey('projects-${_currentWorkspaceId}'),
          workspaceId: _currentWorkspaceId,
        );
    }
  }

  List<Widget> get _views => [
    DashboardView(
      onTabSwitch: (index) {
        setState(() {
          _selectedIndex = index;
        });
        // Don't reload workspace data on every tab switch - it's expensive
        // Only reload when workspace actually changes
      },
      onWorkspaceSelected: (workspace) {
        // Update shell's workspace state when a workspace is selected
        final workspaceName = workspace['name'] as String? ?? 'Workspace';
        final workspaceId = workspace['id'] as String?;
        final workspaceType = workspace['workspace_type'] as String? ?? 'project';
        final createdAt = DateTime.tryParse(workspace['created_at'] as String? ?? '') ?? DateTime.now();
        final createdBy = (workspace['created_by'] as String?) ?? (_userName.isNotEmpty ? _userName : 'You');
        
        setState(() {
          _workspaceName = workspaceName;
          _currentWorkspaceId = workspaceId;
          _currentWorkspaceType = workspaceType;
          _workspaceMetadata = WorkspaceMetadata(
            name: workspaceName,
            type: workspaceType,
            createdBy: createdBy,
            createdAt: createdAt,
          );
        });
        
        // Update workspace names list
        AuthService.getCurrentUser().then((user) {
          if (user != null) {
            DatabaseService.getUserWorkspaces(user['id'] as String).then((workspaces) {
              if (mounted) {
                setState(() {
                  _workspaceNames = workspaces
                      .map<String>((w) => (w['name'] as String?) ?? 'Workspace')
                      .toList();
                });
              }
            });
          }
        });
        
        // Notify socket service about workspace switch
        SocketService.instance.send(<String, dynamic>{
          'type': 'workspace_switch',
          'workspace_id': workspace['id'] as String? ?? '',
          'workspace_name': workspaceName,
        });
      },
    ),
    _getWorkspaceView(), // Dynamic based on workspace type
    const ChatView(),
    const MeetView(),
    const VaultView(),
    const ActivityView(),
    SettingsView(
      key: ValueKey('settings-${_workspaceName}'),
      workspaceName: _workspaceName,
    ), // Combined settings (app + workspace)
    const ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    // Bring realtime services online.
    SocketService.instance.connect().catchError((e) {
      // Silently handle - backend might not be running
    });
    PresenceService.instance.init();
    WorkspaceActivityService.instance.init();

    // Connect to P2P gateway (replaces direct UDP P2P)
    // The gateway client automatically handles peer discovery and updates presence service
    P2PGatewayClient.instance.connect().catchError((e) {
      // Silently handle - backend might not be running
    });
    
    // Check for updates in the background (non-blocking)
    _checkForUpdatesInBackground();

    _workspaceMetadata = WorkspaceMetadata(
      name: _workspaceName,
      type: 'project',
      createdBy: 'You',
      createdAt: DateTime.now(),
    );
    _loadWorkspaceData();
  }

  /// Check for updates in the background (non-blocking)
  void _checkForUpdatesInBackground() {
    // Check for updates after a short delay to not block startup
    Future.delayed(const Duration(seconds: 5), () async {
      try {
        final updateInfo = await UpdateService.checkForUpdates(force: false);
        if (updateInfo != null && mounted) {
          // Show update notification
          _showUpdateNotification(updateInfo);
        }
      } catch (e) {
        // Silently fail - updates are not critical for startup
        print('UpdateService: Background check failed: $e');
      }
    });
  }

  /// Show update notification
  void _showUpdateNotification(UpdateInfo updateInfo) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.system_update, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Update Available',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Version ${updateInfo.latestVersion} is now available',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0066FF),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'Update',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to Settings > About > Check for Updates
            setState(() => _selectedIndex = 6); // Settings tab
            // The settings view will show the update dialog
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Gateway client is a singleton, no need to dispose
    // It will disconnect when app closes
    super.dispose();
  }

  Future<void> _loadWorkspaceData() async {
    print('FlowShell: Loading workspace data...');
    final user = await AuthService.getCurrentUser();
    print('FlowShell: User = $user');
    
    if (user != null) {
      final userId = user['id'] as String;
      print('FlowShell: UserId = $userId');
      
      final workspaces = await DatabaseService.getUserWorkspaces(userId);
      print('FlowShell: Loaded ${workspaces.length} workspaces');
      
      if (workspaces.isNotEmpty && mounted) {
        final workspace = workspaces.first;
        final name = workspace['name'] ?? 'FlowSpace';
        final workspaceType = workspace['workspace_type'] as String? ?? 'project';
        final userName = user['name'] ?? '';
        print('FlowShell: Setting workspace name = $name, type = $workspaceType, user name = $userName');
        
        setState(() {
          _workspaceName = name;
          _currentWorkspaceId = workspace['id'] as String?;
          _workspaceNames = workspaces
              .map<String>((w) => (w['name'] as String?) ?? 'Workspace')
              .toList();
          _userName = userName;
          _currentWorkspaceType = workspaceType;
          _workspaceMetadata = WorkspaceMetadata(
            name: name,
            type: workspaceType,
            createdBy: userName.isNotEmpty ? userName : 'Unknown',
            createdAt: DateTime.now(),
          );
          _members = [
            MemberInfo(
              name: userName.isNotEmpty ? userName : 'You',
              avatarUrl: '',
              online: true,
            ),
          ];
          _recentActivity = WorkspaceActivityService.instance.events.value;
          _callStatus = CallStatus(active: false, participants: 0);
        });
      } else {
        print('FlowShell: ERROR - no workspaces found');
      }
    } else {
      print('FlowShell: ERROR - no user found');
    }
  }

  List<String> get _titles => [
    _workspaceName,
    'Projects',
    'Conversations',
    'Meet',
    'Vault',
    'Activity',
    'Settings',
    _userName.isNotEmpty ? _userName : 'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: flowTheme,
      child: Scaffold(
        body: Row(
          children: [
            FlowNavRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                final wasProjectsTab = _selectedIndex == 1 && _currentWorkspaceType == 'project';
                final isProjectsTab = index == 1 && _currentWorkspaceType == 'project';
                
                setState(() => _selectedIndex = index);
                
                // Reload projects view when switching to it
                if (isProjectsTab && !wasProjectsTab) {
                  // Force reload of projects view by rebuilding it
                  // The view will reload via didChangeDependencies
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      // Trigger rebuild to reload projects
                    });
                  });
                }
              },
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        AppHeader(
                          title: _titles[_selectedIndex],
                          currentWorkspace: _workspaceName,
                          workspaces: _workspaceNames,
                          onWorkspaceSelect: (name) async {
                            final workspace = await WorkspaceService
                                .selectWorkspaceByName(name);
                            if (!mounted || workspace == null) return;
                            setState(() {
                              _workspaceName =
                                  workspace['name'] as String? ?? name;
                              _currentWorkspaceType =
                                  workspace['workspace_type'] as String? ??
                                      'project';
                              _workspaceMetadata = WorkspaceMetadata(
                                name: _workspaceName,
                                type: _currentWorkspaceType ?? 'project',
                                createdBy:
                                    _userName.isNotEmpty ? _userName : 'You',
                                createdAt: DateTime.now(),
                              );
                            });
                            SocketService.instance.send(<String, dynamic>{
                              'type': 'workspace_switch',
                              'workspace_name': _workspaceName,
                            });
                          },
                          onCreateWorkspace: () async {
                            final created =
                                await WorkspaceService.createWorkspace(
                              name: 'New Workspace',
                            );
                            if (!mounted || created.isEmpty) return;
                            final String name =
                                created['name'] as String? ?? 'New Workspace';
                            setState(() {
                              _workspaceName = name;
                              _workspaceNames = [..._workspaceNames, name];
                              _workspaceMetadata = WorkspaceMetadata(
                                name: name,
                                type: 'project',
                                createdBy:
                                    _userName.isNotEmpty ? _userName : 'You',
                                createdAt: DateTime.now(),
                              );
                            });
                            SocketService.instance.send(<String, dynamic>{
                              'type': 'workspace_created',
                              'workspace_name': _workspaceName,
                            });
                          },
                          presence: _presence,
                          onPresenceChange: (UserPresence p) {
                            setState(() => _presence = p);
                            final String status = switch (p) {
                              UserPresence.online => 'online',
                              UserPresence.away => 'away',
                              UserPresence.busy => 'busy',
                              UserPresence.offline => 'offline',
                            };
                            PresenceService.instance.setPresence(status);
                          },
                        ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _views[_selectedIndex],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ValueListenableBuilder<List<ActivityEvent>>(
                    valueListenable:
                        WorkspaceActivityService.instance.events,
                    builder: (context, value, _) {
                      _recentActivity = value;
                      return ValueListenableBuilder<Map<String, PresenceStatus>>(
                        valueListenable: PresenceService.instance.peerStatus,
                        builder: (context, peerStatusMap, __) {
                          // Build member list from P2P peers tracked in presence service
                          // The gateway client automatically updates peerStatus when peers are discovered
                          final p2pMembers = peerStatusMap.entries.map((entry) {
                            final peerId = entry.key;
                            final status = entry.value;
                            final isOnline = status == PresenceStatus.online;
                            // Use first 8 chars of peer ID as display name
                            final displayName = 'Peer ${peerId.length > 8 ? peerId.substring(0, 8) : peerId}...';
                            return MemberInfo(
                              name: displayName,
                              avatarUrl: '',
                              online: isOnline,
                            );
                          }).toList();

                          // Combine P2P members with local user
                          final allMembers = [
                            MemberInfo(
                              name: _userName.isNotEmpty ? _userName : 'You',
                              avatarUrl: '',
                              online: true,
                            ),
                            ...p2pMembers,
                          ];

                          return RightSidebar(
                            members: allMembers,
                            recentActivity: _recentActivity,
                            metadata: _workspaceMetadata,
                            callStatus: _callStatus,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

