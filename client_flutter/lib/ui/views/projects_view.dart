import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/workspace_service.dart';
import '../../services/project_templates_service.dart' as pt;
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../state/project_state.dart';

class ProjectsView extends StatefulWidget {
  final String? workspaceId;
  final Map<String, dynamic>? openProject;
  final Function(Map<String, dynamic>)? onProjectOpen;
  final Function(String)? onProjectClose;

  const ProjectsView({
    super.key,
    this.workspaceId,
    this.openProject,
    this.onProjectOpen,
    this.onProjectClose,
  });

  @override
  State<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<ProjectsView> {
  bool _loading = true;
  bool _hasTimeoutTimer = false;
  String? _workspaceId;
  List<Map<String, dynamic>> _projects = [];
  Map<String, dynamic>? _selectedProject;
  Map<String, List<Map<String, dynamic>>> _tasksByStatus = {};

  final List<String> _statuses = ['backlog', 'todo', 'in_progress', 'done'];
  final Map<String, String> _statusLabels = {
    'backlog': 'Backlog',
    'todo': 'To Do',
    'in_progress': 'In Progress',
    'done': 'Done',
  };

  // Track last load time to avoid excessive reloads
  DateTime? _lastLoadTime;
  String? _lastWorkspaceId;

  @override
  void initState() {
    super.initState();
    _lastWorkspaceId = widget.workspaceId;
    // Only load if we don't have data already
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _projects.isEmpty) {
        _loadProjects();
      } else if (mounted && !_loading) {
        // We have data, just ensure loading is false
        setState(() {
          _loading = false;
        });
      }
    });
  }

  @override
  void didUpdateWidget(ProjectsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when workspace ID changes
    if (widget.workspaceId != oldWidget.workspaceId &&
        widget.workspaceId != null) {
      _lastWorkspaceId = widget.workspaceId;
      _loadProjects();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only reload if workspace actually changed AND we don't have data for it
    if (widget.workspaceId != _lastWorkspaceId) {
      print(
        'Projects: Workspace changed from $_lastWorkspaceId to ${widget.workspaceId}',
      );
      _lastWorkspaceId = widget.workspaceId;
      // Only reload if we don't have projects or the workspace ID doesn't match
      if (_projects.isEmpty || _workspaceId != widget.workspaceId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_loading) {
            _loadProjects();
          }
        });
      } else {
        // We already have data for this workspace, just ensure loading is false
        if (mounted && _loading) {
          setState(() {
            _loading = false;
          });
        }
      }
    } else if (_projects.isEmpty && !_loading && _workspaceId != null) {
      // Only reload if we have a workspace but no projects
      print('Projects: No projects but have workspace, reloading...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_loading) {
          _loadProjects();
        }
      });
    } else if (!_loading && _projects.isNotEmpty) {
      // We have data, ensure loading is false
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadProjects() async {
    if (_loading) {
      print('Projects: Already loading, skipping...');
      return; // Prevent concurrent loads
    }

    print('Projects: Starting load...');
    setState(() => _loading = true);

    try {
      String? workspaceId = widget.workspaceId;
      print('Projects: WorkspaceId from widget: $workspaceId');

      // If workspaceId not provided, get current workspace
      if (workspaceId == null || workspaceId.isEmpty) {
        print('Projects: No workspaceId, fetching user workspaces...');
        final user = await AuthService.getCurrentUser();
        if (user == null) {
          print('Projects: No user found');
          if (!mounted) return;
          setState(() {
            _workspaceId = null;
            _projects = [];
            _selectedProject = null;
            _loading = false;
            _lastLoadTime = DateTime.now();
          });
          return;
        }

        var workspaces = await DatabaseService.getUserWorkspaces(
          user['id'] as String,
        );
        print('Projects: Found ${workspaces.length} workspaces');
        if (workspaces.isEmpty) {
          print('Projects: No workspaces found - creating default workspace');
          // Auto-create a default workspace for the user
          try {
            final defaultWorkspace = await WorkspaceService.createWorkspace(
              name: 'General',
              description: 'General workspace for team collaboration',
              workspaceType: 'project',
            );
            workspaceId = defaultWorkspace['id'] as String?;
            print('Projects: Created default workspace: $workspaceId');
            // Reload workspaces to get the new one
            workspaces = await DatabaseService.getUserWorkspaces(
              user['id'] as String,
            );
            print(
              'Projects: After creation, found ${workspaces.length} workspaces',
            );
          } catch (e) {
            print('Projects: Error creating default workspace: $e');
            // Continue without workspace - we'll handle this in create project dialog
            if (!mounted) return;
            setState(() {
              _workspaceId = null;
              _projects = [];
              _selectedProject = null;
              _loading = false;
              _lastLoadTime = DateTime.now();
            });
            return;
          }
        }

        // Get the most recently updated workspace (likely the current one)
        if (workspaces.isNotEmpty) {
          final workspace = workspaces.reduce((a, b) {
            final aUpdated =
                DateTime.tryParse(a['updated_at'] as String? ?? '') ??
                DateTime(1970);
            final bUpdated =
                DateTime.tryParse(b['updated_at'] as String? ?? '') ??
                DateTime(1970);
            return bUpdated.isAfter(aUpdated) ? b : a;
          });

          workspaceId = workspace['id'] as String?;
        } else if (workspaceId == null) {
          // Still no workspace after creation attempt
          print('Projects: Still no workspace after creation attempt');
          if (!mounted) return;
          setState(() {
            _workspaceId = null;
            _projects = [];
            _selectedProject = null;
            _loading = false;
            _lastLoadTime = DateTime.now();
          });
          return;
        }
        print('Projects: Selected workspace ID: $workspaceId');
        if (workspaceId == null || workspaceId.isEmpty) {
          print('Projects: Workspace ID is null or empty');
          if (!mounted) return;
          setState(() {
            _workspaceId = null;
            _projects = [];
            _selectedProject = null;
            _loading = false;
            _lastLoadTime = DateTime.now();
          });
          return;
        }
      }

      // Ensure we have a valid workspaceId before querying
      if (workspaceId == null || workspaceId.isEmpty) {
        print('Projects: Invalid workspaceId, aborting');
        if (!mounted) return;
        setState(() {
          _workspaceId = null;
          _projects = [];
          _selectedProject = null;
          _loading = false;
          _lastLoadTime = DateTime.now();
        });
        return;
      }

      print('Projects: Loading projects for workspace: $workspaceId');
      // Fetch projects from backend API
      final apiProjects = await ApiClient.get('/projects/workspace/$workspaceId').timeout(
        const Duration(seconds: 15),
      );
      final projects = (apiProjects as List<dynamic>).map<Map<String, dynamic>>((p) => p as Map<String, dynamic>).toList();
      
      print('Projects: Loaded ${projects.length} projects for workspace $workspaceId');
      print(
        'Projects: Loaded ${projects.length} projects for workspace $workspaceId',
      );
      for (final project in projects) {
        print('Projects: - ${project['name']} (${project['id']})');
      }

      if (!mounted) {
        print('Projects: Widget not mounted, aborting');
        return;
      }

      setState(() {
        _workspaceId = workspaceId;
        _projects = projects;
        _selectedProject = projects.isNotEmpty ? projects.first : null;
        _loading = false;
        _hasTimeoutTimer = false;
        _lastLoadTime = DateTime.now();
      });
      
      print('Projects: State updated, loading tasks + opening project...');
      
      // Auto-open the first project and render its background module
      if (_selectedProject != null && _selectedProject!['id'] != null) {
        final projectId = _selectedProject!['id'] as String;
        // Load project into global state so the shell renders the module overlay
        await context.read<ProjectState>().loadProject(projectId);
        // Load tasks in the background
        _loadTasks(projectId).catchError((e) {
          print('Projects: Error loading tasks: $e');
        });
        // Notify parent callback
        widget.onProjectOpen?.call(_selectedProject!);
      } else {
        // Clear tasks if no project selected
        if (mounted) {
          setState(() {
            _tasksByStatus = {};
          });
        }
      }
      
      print('Projects: Load complete');
    } catch (e, stack) {
      print('Projects: Error loading: $e');
      print('Projects: Stack: $stack');
      if (!mounted) return;
      // Always ensure loading is set to false
      setState(() {
        _loading = false;
        // Keep existing state if available
        if (_projects.isEmpty) {
          _projects = [];
          _selectedProject = null;
          _tasksByStatus = {};
        }
      });
    } finally {
      // Ensure loading is always false
      if (mounted) {
        print('Projects: Finally block - ensuring loading is false');
        setState(() {
          _loading = false;
          _hasTimeoutTimer = false;
        });
      }
    }
  }

  Future<void> _loadTasks(String projectId) async {
    try {
      final tasksByStatus = <String, List<Map<String, dynamic>>>{};

      for (final status in _statuses) {
        final tasks = await DatabaseService.getTasksByStatus(projectId, status);
        tasksByStatus[status] = tasks;
      }

      if (!mounted) return;
      setState(() {
        _tasksByStatus = tasksByStatus;
      });
    } catch (e) {
      print('Projects: Error loading tasks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show loading if we actually don't have any data
    if (_loading && _projects.isEmpty && _workspaceId == null) {
      // Add a timeout fallback - if loading for more than 10 seconds, show error
      // Use a one-time timer, not repeated
      if (!_hasTimeoutTimer) {
        _hasTimeoutTimer = true;
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && _loading) {
            print('Projects: Loading timeout - forcing stop');
            setState(() {
              _loading = false;
              _hasTimeoutTimer = false;
            });
          }
        });
      }

      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Loading projects...',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _loading = false;
                  _hasTimeoutTimer = false;
                });
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }

    if (_projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.dashboard_outlined,
              size: 64,
              color: Colors.white38,
            ),
            const SizedBox(height: 16),
            const Text(
              'No projects yet',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                // Ensure we're not loading before creating
                if (!_loading) {
                  _showCreateProjectDialog();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Project'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildProjectSelector(),
        Expanded(child: _buildKanbanBoard()),
      ],
    );
  }

  Widget _buildProjectSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x22FFFFFF))),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              value: _selectedProject?['id'],
              dropdownColor: const Color(0xFF1E1E1E),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              underline: Container(),
              items: _projects.map((project) {
                return DropdownMenuItem(
                  value: project['id'] as String,
                  child: Text(project['name'] as String),
                );
              }).toList(),
              onChanged: (projectId) async {
                if (projectId == null) return;
                final project = _projects.firstWhere((p) => p['id'] == projectId);
                setState(() => _selectedProject = project);
                // Load project into global state to activate background module
                await context.read<ProjectState>().loadProject(projectId);
                // Load tasks
                _loadTasks(projectId);
                // Notify parent
                widget.onProjectOpen?.call(project);
              },
            ),
          ),
          IconButton(
            onPressed: _showCreateProjectDialog,
            icon: const Icon(Icons.add, color: Color(0xFF0066FF)),
            tooltip: 'Create Project',
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanBoard() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _statuses.map((status) {
          final tasks = _tasksByStatus[status] ?? [];
          return _buildColumn(status, tasks);
        }).toList(),
      ),
    );
  }

  Widget _buildColumn(String status, List<Map<String, dynamic>> tasks) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0x22FFFFFF)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _statusLabels[status]!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066FF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${tasks.length}',
                          style: const TextStyle(
                            color: Color(0xFF0066FF),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: tasks.length + 1,
                    itemBuilder: (context, index) {
                      if (index == tasks.length) {
                        return _buildAddTaskButton(status);
                      }
                      return _buildTaskCard(tasks[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final priority = task['priority'] as String? ?? 'medium';
    final priorityColor = priority == 'high'
        ? Colors.red
        : priority == 'low'
        ? Colors.green
        : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _showTaskDetails(task),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: priorityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (task['description'] != null &&
                    (task['description'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      task['description'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (task['due_date'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.white38,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(task['due_date'] as String),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddTaskButton(String status) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCreateTaskDialog(status),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 16, color: Colors.white38),
              SizedBox(width: 8),
              Text(
                'Add task',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    return '${date.month}/${date.day}';
  }

  void _showCreateProjectDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    pt.ProjectTemplate? selectedTemplate;

    // Load templates
    final templates = await pt.ProjectTemplatesService.getTemplates();
    selectedTemplate = templates.firstWhere(
      (t) => t.id == 'blank',
      orElse: () => templates.first,
    );

    if (!mounted) return;

    // Get example descriptions for each template
    final templateExamples = {
      'brainstorming-whiteboard':
          'Perfect for: Idea generation, concept development, visual thinking',
      'workflow-automation':
          'Perfect for: Building tools like a9n/n8n, automation platforms, node-based systems',
      'game-engine-ai':
          'Perfect for: VyreVault 6, Unreal Engine forks, AI-integrated game engines',
      'story-building-software':
          'Perfect for: CreativeOS, writing tools, narrative development software',
      'software-development':
          'Perfect for: General software projects, web apps, APIs, services',
      'product-launch':
          'Perfect for: Launching new products, features, or services',
      'research-project':
          'Perfect for: Technical research, experiments, proof-of-concepts',
      'blank':
          'Perfect for: Custom projects, undefined workflows, starting from scratch',
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0x22FFFFFF)),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Create New Project',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choose a Project Template',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Select a template to get started with pre-configured tasks and structure',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        // Template grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.4,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: templates.length,
                          itemBuilder: (context, index) {
                            final template = templates[index];
                            final isSelected =
                                selectedTemplate?.id == template.id;
                            final example = templateExamples[template.id] ?? '';
                            return InkWell(
                              onTap: () {
                                setDialogState(() {
                                  selectedTemplate = template;
                                  descController.text = template.description;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(
                                          0xFF0066FF,
                                        ).withValues(alpha: 0.15)
                                      : Colors.white.withValues(alpha: 0.05),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF0066FF)
                                        : Colors.white.withValues(alpha: 0.1),
                                    width: isSelected ? 2.5 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          template.icon,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            template.name,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF0066FF),
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      template.description,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (example.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.05,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          example,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                    if (template.defaultTasks.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.task_alt,
                                            size: 12,
                                            color: Colors.white.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${template.defaultTasks.length} default tasks',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.5,
                                              ),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Project details section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Project Details',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: nameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Project Name *',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white54,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF0066FF),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: descController,
                                style: const TextStyle(color: Colors.white),
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'Description',
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  hintText:
                                      selectedTemplate?.description ??
                                      'Project description',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white54,
                                    ),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF0066FF),
                                    ),
                                  ),
                                ),
                              ),
                              if (selectedTemplate != null &&
                                  (selectedTemplate?.defaultTasks.isNotEmpty ??
                                      false)) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF0066FF,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        color: Color(0xFF0066FF),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'This template will create ${selectedTemplate?.defaultTasks.length ?? 0} default tasks to get you started',
                                          style: const TextStyle(
                                            color: Color(0xFF0066FF),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a project name'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context);

                          final user = await AuthService.getCurrentUser();
                          if (user == null) return;

                          // Create project via backend API
                          try {
                            final createRes = await ApiClient.post(
                              '/projects/create',
                              body: {
                                'name': nameController.text.trim(),
                                'templateId': selectedTemplate?.id ?? 'blank',
                              },
                            );

                            final createdProjectId =
                                createRes['projectId'] as String;

                            // Load full project into global ProjectState
                            if (mounted) {
                              await context.read<ProjectState>().loadProject(
                                createdProjectId,
                              );
                            }

                            // Refresh local list UI
                            if (mounted) {
                              await _loadProjects();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to create project: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                        ),
                        child: const Text('Create Project'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateTaskDialog(String status) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String priority = 'medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Create Task',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Task Title',
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
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: priority,
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                ],
                onChanged: (value) => setDialogState(() => priority = value!),
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
                if (titleController.text.trim().isEmpty) return;
                Navigator.pop(context);

                final user = await AuthService.getCurrentUser();
                if (user == null) return;

                final taskId = DateTime.now().millisecondsSinceEpoch.toString();
                final now = DateTime.now().toIso8601String();

                await DatabaseService.insertTask({
                  'id': taskId,
                  'project_id': _selectedProject!['id'],
                  'workspace_id': _workspaceId!,
                  'title': titleController.text.trim(),
                  'description': descController.text.trim(),
                  'status': status,
                  'priority': priority,
                  'assigned_to': null,
                  'created_by': user['id'],
                  'due_date': null,
                  'created_at': now,
                  'updated_at': now,
                });

                _loadTasks(_selectedProject!['id'] as String);
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

  void _showTaskDetails(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          task['title'] as String,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task['description'] != null)
              Text(
                task['description'] as String,
                style: const TextStyle(color: Colors.white70),
              ),
            const SizedBox(height: 16),
            Text(
              'Priority: ${task['priority']}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
