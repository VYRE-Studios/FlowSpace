import 'dart:ui';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/workspace_service.dart';

class DashboardView extends StatefulWidget {
  final ValueChanged<int>? onTabSwitch;
  final ValueChanged<Map<String, dynamic>>? onWorkspaceSelected;
  
  const DashboardView({super.key, this.onTabSwitch, this.onWorkspaceSelected});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

enum _DashboardState { idle, loading, active }

class _DashboardViewState extends State<DashboardView> {
  _DashboardState _state = _DashboardState.loading;
  List<Map<String, dynamic>> _spaces = const [];
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _team;

  @override
  void initState() {
    super.initState();
    _fetchSpaces();
  }

  Future<void> _fetchSpaces() async {
    setState(() {
      _state = _DashboardState.loading;
    });

    try {
      // Load from local storage
      print('Dashboard: Loading user...');
      final user = await AuthService.getCurrentUser();
      print('Dashboard: User = $user');
      
      if (user == null) {
        print('Dashboard: No user found');
        if (!mounted) return;
        setState(() => _state = _DashboardState.idle);
        return;
      }

      final userId = user['id'] as String;
      print('Dashboard: UserId = $userId');
      
      // Load user's team
      final team = await DatabaseService.getUserTeam(userId);
      print('Dashboard: Team = ${team?['name']}');
      
      // Load workspaces from SQLite
      final workspaces = await DatabaseService.getUserWorkspaces(userId);
      print('Dashboard: Loaded ${workspaces.length} workspaces from database');
      
      for (final workspace in workspaces) {
        print('Dashboard: Workspace: ${workspace['name']}');
        
        // Load channels
        final channels = await DatabaseService.getWorkspaceChannels(workspace['id']);
        print('Dashboard: Channels: ${channels.map((c) => c['name']).join(', ')}');
        
        // Load members
        final members = await DatabaseService.getWorkspaceMembers(workspace['id']);
        print('Dashboard: Members: ${members.length}');
      }

      print('Dashboard: Total workspaces loaded: ${workspaces.length}');
      if (!mounted) return;

      setState(() {
        _spaces = workspaces;
        _user = user;
        _team = team;
        _state = _spaces.isEmpty ? _DashboardState.idle : _DashboardState.active;
      });
    } catch (e, stack) {
      print('Dashboard: Error loading spaces: $e');
      print('Dashboard: Stack trace: $stack');
      if (!mounted) return;
      setState(() => _state = _DashboardState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSpaces = _state == _DashboardState.active && _spaces.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: hasSpaces
                  ? _buildSpaceGrid()
                  : _buildGhostState(
                      state: _state,
                      onCreate: () {},
                    ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSpaceGrid() {
    final teamName = _team?['name'] ?? 'Team';

    return RefreshIndicator(
      key: const ValueKey('space-grid'),
      onRefresh: _fetchSpaces,
      color: const Color(0xFF0066FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              children: [
                Text(
                  teamName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _showCreateWorkspaceDialog,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Workspace', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _spaces.length,
              itemBuilder: (context, index) {
                final space = _spaces[index];
                final name = space['name'] as String? ?? 'Workspace ${index + 1}';
                final description = space['description'] as String? ?? '';
                final workspaceType = space['workspace_type'] as String? ?? 'project';
                final updatedAt = space['updatedAt'] as String?;

                return GestureDetector(
                  onDoubleTap: () => _openWorkspace(space),
                  onSecondaryTapDown: (details) => _showWorkspaceContextMenu(context, space, details.globalPosition),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openWorkspace(space),
                          borderRadius: BorderRadius.circular(16),
                          splashColor: const Color(0xFF0066FF).withValues(alpha: 0.2),
                          highlightColor: const Color(0xFF0066FF).withValues(alpha: 0.1),
                          child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getWorkspaceIcon(workspaceType),
                                    color: const Color(0xFF0066FF),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getWorkspaceTypeLabel(workspaceType),
                                style: TextStyle(
                                  color: const Color(0xFF0066FF).withValues(alpha: 0.7),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              if (updatedAt != null)
                                Text(
                                  'Updated ${updatedAt.split("T").first}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 9,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openWorkspace(Map<String, dynamic> workspace) {
    // Notify parent (shell) about workspace selection FIRST
    // This updates the workspace state in the shell
    widget.onWorkspaceSelected?.call(workspace);
    
    // Navigate to workspace - switch to appropriate view based on type
    final workspaceType = workspace['workspace_type'] as String? ?? 'project';
    final workspaceName = workspace['name'] as String? ?? 'Workspace';
    
    // Switch to the appropriate tab based on workspace type
    // Projects tab is at index 1, Chat is at index 2
    if (workspaceType == 'project' || workspaceType == 'whiteboard' || workspaceType == 'document') {
      // Switch to Projects tab (index 1) to show workspace content
      widget.onTabSwitch?.call(1);
    } else {
      // Default to chat for other types
      widget.onTabSwitch?.call(2);
    }
    
    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening workspace: $workspaceName'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showWorkspaceContextMenu(BuildContext context, Map<String, dynamic> workspace, Offset tapPosition) {
    final workspaceName = workspace['name'] as String? ?? 'Workspace';
    final workspaceId = workspace['id'] as String?;
    
    if (workspaceId == null) return;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        tapPosition.dx,
        tapPosition.dy,
        MediaQuery.of(context).size.width - tapPosition.dx,
        MediaQuery.of(context).size.height - tapPosition.dy,
      ),
      color: const Color(0xFF1E1E1E),
      items: [
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.open_in_new, size: 18, color: Colors.white70),
              SizedBox(width: 8),
              Text('Open', style: TextStyle(color: Colors.white)),
            ],
          ),
          onTap: () => Future.delayed(const Duration(milliseconds: 100), () => _openWorkspace(workspace)),
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
          onTap: () => Future.delayed(
            const Duration(milliseconds: 100),
            () => _confirmDeleteWorkspace(context, workspaceId, workspaceName),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteWorkspace(BuildContext context, String workspaceId, String workspaceName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Delete Workspace',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "$workspaceName"?\n\nThis action cannot be undone and will delete all associated data.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await WorkspaceService.deleteWorkspace(workspaceId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Workspace "$workspaceName" deleted'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          // Refresh the list immediately
          await _fetchSpaces();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting workspace: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildGhostState({
    required _DashboardState state,
    required VoidCallback onCreate,
  }) {
    final isLoading = state == _DashboardState.loading;

    return Center(
      key: const ValueKey('space-ghost'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: isLoading ? 0.25 : 0.35,
            child: Icon(
              Icons.dashboard_outlined,
              size: 72,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isLoading ? 'Syncing your spaces…' : 'No spaces active',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          if (isLoading)
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            FilledButton.icon(
              onPressed: _showCreateWorkspaceDialog,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('New Space'),
            ),
          if (!isLoading)
            TextButton(
              onPressed: _fetchSpaces,
              child: const Text('Refresh'),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    return '${local.month}/${local.day}/${local.year} ${TimeOfDay.fromDateTime(local).format(context)}';
  }

  void _showCreateWorkspaceDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'project';

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Create Workspace',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Workspace Name',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Workspace Type',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTypeChip('project', 'Project', Icons.dashboard, selectedType, (type) {
                    setState(() => selectedType = type);
                  }),
                  _buildTypeChip('whiteboard', 'Whiteboard', Icons.draw, selectedType, (type) {
                    setState(() => selectedType = type);
                  }),
                  _buildTypeChip('document', 'Document', Icons.description, selectedType, (type) {
                    setState(() => selectedType = type);
                  }),
                  _buildTypeChip('brainstorm', 'Brainstorm', Icons.lightbulb, selectedType, (type) {
                    setState(() => selectedType = type);
                  }),
                  _buildTypeChip('design', 'Design', Icons.palette, selectedType, (type) {
                    setState(() => selectedType = type);
                  }),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name is required')),
                  );
                  return;
                }
                Navigator.pop(context);
                
                try {
                  await WorkspaceService.createWorkspace(
                    name: name,
                    description: descController.text.trim(),
                    workspaceType: selectedType,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Workspace created!')),
                    );
                    _fetchSpaces();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e')),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon, String selectedType, Function(String) onSelect) {
    final isSelected = type == selectedType;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.white70),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (_) => onSelect(type),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      selectedColor: const Color(0xFF0066FF),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF0066FF) : Colors.white.withValues(alpha: 0.2),
      ),
    );
  }

  IconData _getWorkspaceIcon(String type) {
    switch (type) {
      case 'project':
        return Icons.dashboard;
      case 'whiteboard':
        return Icons.draw;
      case 'document':
        return Icons.description;
      case 'brainstorm':
        return Icons.lightbulb;
      case 'design':
        return Icons.palette;
      default:
        return Icons.dashboard;
    }
  }

  String _getWorkspaceTypeLabel(String type) {
    switch (type) {
      case 'project':
        return 'PROJECT';
      case 'whiteboard':
        return 'WHITEBOARD';
      case 'document':
        return 'DOCUMENT';
      case 'brainstorm':
        return 'BRAINSTORM';
      case 'design':
        return 'DESIGN';
      default:
        return 'PROJECT';
    }
  }
}
