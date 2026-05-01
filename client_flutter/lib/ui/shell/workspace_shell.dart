import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';
import '../constants/text_styles.dart';
import '../widgets/sidebar/sidebar.dart';
import '../widgets/channel/message_panel.dart';
import '../widgets/workspace_empty_state.dart';
import '../screens/conversations_screen.dart';
import '../screens/launch_pad_screen.dart';
import '../dialogs/workspace_setup_dialog.dart';
import '../../state/project_state.dart';
import '../../state/active_workspace_state.dart';
import '../../state/channel_context.dart';
import '../../services/api_client.dart';
import '../modules/module_registry.dart';
import '../../services/workspace_location_service.dart';
import '../../services/project_registry_service.dart';
import '../../services/local_project_loader.dart';
import '../../models/project_manifest.dart';
import '../dialogs/create_project_dialog_new.dart';
import '../widgets/board_tabs.dart';
import '../widgets/tool_palette.dart';

/// Unified workspace shell - implements complete launch sequence
/// 
/// NEW USER: Shows LaunchPad → Create Workspace → Empty State → Create Project
/// RETURNING USER: Auto-loads workspace → Auto-loads projects → Opens last project
class WorkspaceShell extends StatefulWidget {
  final Widget? rightPanel;
  final String? channelName;

  const WorkspaceShell({
    super.key,
    this.rightPanel,
    this.channelName,
  });

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  bool _initialized = false;
  bool _loading = true;
  bool _hasWorkspaces = false;
  Map<String, dynamic>? _activeWorkspace;
  List<dynamic> _projects = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initializeWorkspace();
    }
  }

  /// WORKSPACE INITIALIZATION: Check for workspace location, then load projects
  Future<void> _initializeWorkspace() async {
    try {
      // Step 1: Check if workspace location is configured
      final hasWorkspacePath = await WorkspaceLocationService.hasWorkspacePath();
      
      if (!hasWorkspacePath) {
        print('[WorkspaceShell] No workspace location configured - showing setup dialog');
        
        if (mounted) {
          final configured = await WorkspaceSetupDialog.show(context);
          if (!configured) {
            // User didn't select workspace - use default location
            print('[WorkspaceShell] No workspace selected - using default location');
            final defaultPath = '${Platform.environment['USERPROFILE']}\\Documents\\FlowSpace';
            await WorkspaceLocationService.setWorkspacePath(defaultPath);
            print('[WorkspaceShell] Default workspace created at: $defaultPath');
          }
        }
      }

      // Step 2: Load project registry
      await ProjectRegistryService.instance.loadRegistry();

      // Step 3: Load local projects from disk
      final localProjects = await LocalProjectLoader.loadLocalProjects();
      print('[WorkspaceShell] Loaded ${localProjects.length} projects from disk');

      // Step 4: Convert to UI format and populate
      setState(() {
        _projects = localProjects.map((m) => {
          'id': m.projectId,
          'name': m.name,
          'templateId': m.templateId,
          'workspaceId': m.workspaceId,
        }).toList();
        _loading = false;
        _hasWorkspaces = true;
      });

      // Step 5: Auto-open first project if any exist
      if (localProjects.isNotEmpty) {
        final firstProject = localProjects.first;
        print('[WorkspaceShell] Auto-opening project: ${firstProject.name}');
        await _loadLocalProject(firstProject);
      }

    } catch (e, stackTrace) {
      print('[WorkspaceShell] ERROR in initialization: $e');
      print('[WorkspaceShell] Stack trace: $stackTrace');
      setState(() {
        _loading = false;
        _hasWorkspaces = true;
      });
    }
  }

  /// Load a project from local manifest into ProjectState
  Future<void> _loadLocalProject(ProjectManifest manifest) async {
    try {
      print('[WorkspaceShell] Loading local project into state: ${manifest.name}');
      
      // Load into ProjectState using the new local loader
      if (mounted) {
        await context.read<ProjectState>().loadLocalProject(manifest);
      }
      
      // Update lastOpened in registry
      await ProjectRegistryService.instance.updateLastOpened(manifest.projectId);
      
      print('[WorkspaceShell] Project loaded locally: ${manifest.name}');
    } catch (e) {
      print('[WorkspaceShell] ERROR loading local project: $e');
    }
  }

  // OLD BACKEND CODE REMOVED - now using local-first loading

  /// Handle project creation from empty state
  Future<void> _onCreateProject() async {
    final manifest = await showDialog<ProjectManifest>(
      context: context,
      builder: (context) => const CreateProjectDialog(),
    );

    if (manifest != null && mounted) {
      print('[WorkspaceShell] Project created: ${manifest.name}');
      
      // Reload registry and project list
      await ProjectRegistryService.instance.loadRegistry();
      final localProjects = await LocalProjectLoader.loadLocalProjects();
      
      setState(() {
        _projects = localProjects.map((m) => {
          'id': m.projectId,
          'name': m.name,
          'templateId': m.templateId,
          'workspaceId': m.workspaceId,
        }).toList();
      });
      
      // Load the newly created project
      await _loadLocalProject(manifest);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectState>(
      builder: (context, projectState, _) {
        // Loading state
        if (_loading || projectState.loading) {
          return Scaffold(
            backgroundColor: AppColors.backgroundPrimary,
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Workspace exists but no projects - Show empty state
        if (_projects.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.backgroundPrimary,
            body: Row(
              children: [
                const Sidebar(),
                Expanded(
                  child: WorkspaceEmptyState(
                    onCreateProject: _onCreateProject,
                  ),
                ),
              ],
            ),
          );
        }

        // Project loaded - Show module routing workspace
        if (projectState.currentProject != null) {
          return Consumer2<ActiveWorkspaceState, ChannelContext>(
            builder: (context, activeWorkspace, channelContext, _) {
              final project = activeWorkspace.activeProject;
              final board = activeWorkspace.activeBoard;

              if (project == null) {
                return const Scaffold(
                  backgroundColor: AppColors.backgroundPrimary,
                  body: Center(child: Text('No project loaded')),
                );
              }

              // Determine what to show in main area
              final activeChannel = channelContext.activeChannel;
              final showChannelView = activeChannel != null;
              final backgroundModuleId = project.backgroundModuleId;
              final mainModuleId = board?.moduleId ?? backgroundModuleId;

              return Scaffold(
                backgroundColor: AppColors.backgroundPrimary,
                body: Row(
                  children: [
                    const Sidebar(),
                    Expanded(
                      child: showChannelView
                          ? // Stream view: Show messages for active stream
                          const MessagePanel()
                          : // Board view: Show modules and boards
                          Stack(
                              children: [
                                // Background module
                                Positioned.fill(
                                  child: ModuleRegistry.buildBackground(backgroundModuleId),
                                ),
                                // Main content area
                                Positioned.fill(
                                  child: Column(
                                    children: [
                                      // Toolbar area
                                      Container(
                                        height: 56,
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.white.withOpacity(0.1),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              project.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Spacer(),
                                            const ToolPalette(),
                                          ],
                                        ),
                                      ),
                                      // Board tabs
                                      const BoardTabs(),
                                      // Main module content
                                      Expanded(
                                        child: ModuleRegistry.buildMain(mainModuleId),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        }

        // Fallback: Projects exist but none loaded yet
        return Scaffold(
          backgroundColor: AppColors.backgroundPrimary,
          body: Row(
            children: [
              const Sidebar(),
              Expanded(
                child: Center(
                  child: Text(
                    'Select a project to get started',
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textTertiary),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
