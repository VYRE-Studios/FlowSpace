import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/workspace_service.dart';

class ProjectsView extends StatefulWidget {
  final String? workspaceId;
  
  const ProjectsView({super.key, this.workspaceId});

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
    if (widget.workspaceId != oldWidget.workspaceId && widget.workspaceId != null) {
      _lastWorkspaceId = widget.workspaceId;
      _loadProjects();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only reload if workspace actually changed AND we don't have data for it
    if (widget.workspaceId != _lastWorkspaceId) {
      print('Projects: Workspace changed from $_lastWorkspaceId to ${widget.workspaceId}');
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
        
        var workspaces = await DatabaseService.getUserWorkspaces(user['id'] as String);
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
            workspaces = await DatabaseService.getUserWorkspaces(user['id'] as String);
            print('Projects: After creation, found ${workspaces.length} workspaces');
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
            final aUpdated = DateTime.tryParse(a['updated_at'] as String? ?? '') ?? DateTime(1970);
            final bUpdated = DateTime.tryParse(b['updated_at'] as String? ?? '') ?? DateTime(1970);
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
      final projects = await DatabaseService.getWorkspaceProjects(workspaceId).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('Projects: Timeout loading projects');
          return <Map<String, dynamic>>[];
        },
      );
      
      print('Projects: Loaded ${projects.length} projects for workspace $workspaceId');
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
      
      print('Projects: State updated, loading tasks...');
      
      // Load tasks for selected project (don't await - let it load in background)
      if (_selectedProject != null && _selectedProject!['id'] != null) {
        _loadTasks(_selectedProject!['id'] as String).catchError((e) {
          print('Projects: Error loading tasks: $e');
        });
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
            const Icon(Icons.dashboard_outlined, size: 64, color: Colors.white38),
            const SizedBox(height: 16),
            const Text('No projects yet', style: TextStyle(color: Colors.white70)),
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
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              underline: Container(),
              items: _projects.map((project) {
                return DropdownMenuItem(
                  value: project['id'] as String,
                  child: Text(project['name'] as String),
                );
              }).toList(),
              onChanged: (projectId) {
                final project = _projects.firstWhere((p) => p['id'] == projectId);
                setState(() => _selectedProject = project);
                _loadTasks(projectId!);
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
                    border: Border(bottom: BorderSide(color: Color(0x22FFFFFF))),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066FF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${tasks.length}',
                          style: const TextStyle(color: Color(0xFF0066FF), fontSize: 12),
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
                if (task['description'] != null && (task['description'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      task['description'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                if (task['due_date'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(task['due_date'] as String),
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 16, color: Colors.white38),
              SizedBox(width: 8),
              Text('Add task', style: TextStyle(color: Colors.white38, fontSize: 12)),
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

  void _showCreateProjectDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Create Project', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Project Name',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
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
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
              ),
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
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(context);
              
              final user = await AuthService.getCurrentUser();
              if (user == null) return;
              
              final projectId = DateTime.now().millisecondsSinceEpoch.toString();
              final now = DateTime.now().toIso8601String();
              
              // Ensure we have a workspace ID - auto-create if needed
              String? workspaceId = _workspaceId ?? widget.workspaceId;
              if (workspaceId == null || workspaceId.isEmpty) {
                // Try to get workspace ID again
                var workspaces = await DatabaseService.getUserWorkspaces(user['id'] as String);
                if (workspaces.isNotEmpty) {
                  final workspace = workspaces.reduce((a, b) {
                    final aUpdated = DateTime.tryParse(a['updated_at'] as String? ?? '') ?? DateTime(1970);
                    final bUpdated = DateTime.tryParse(b['updated_at'] as String? ?? '') ?? DateTime(1970);
                    return bUpdated.isAfter(aUpdated) ? b : a;
                  });
                  workspaceId = workspace['id'] as String?;
                } else {
                  // Auto-create a workspace if none exists
                  try {
                    final defaultWorkspace = await WorkspaceService.createWorkspace(
                      name: 'General',
                      description: 'General workspace for team collaboration',
                      workspaceType: 'project',
                    );
                    workspaceId = defaultWorkspace['id'] as String?;
                    print('Projects: Created workspace for project: $workspaceId');
                    // Update local state
                    if (mounted) {
                      setState(() {
                        _workspaceId = workspaceId;
                      });
                    }
                  } catch (e) {
                    print('Projects: Error creating workspace: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error creating workspace: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }
                }
              }
              
              if (workspaceId == null || workspaceId.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to create workspace. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }
              
              await DatabaseService.insertProject({
                'id': projectId,
                'workspace_id': workspaceId,
                'name': nameController.text.trim(),
                'description': descController.text.trim(),
                'status': 'active',
                'created_by': user['id'],
                'created_at': now,
                'updated_at': now,
              });
              
              // Reload projects immediately after creation
              if (mounted) {
                await _loadProjects();
              }
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0066FF)),
            child: const Text('Create'),
          ),
        ],
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
          title: const Text('Create Task', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
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
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
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
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
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
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0066FF)),
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
        title: Text(task['title'] as String, style: const TextStyle(color: Colors.white)),
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
