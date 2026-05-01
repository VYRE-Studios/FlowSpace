import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../models/whiteboard/whiteboard_state.dart';
import '../services/vault_storage_service.dart';
import '../models/project_manifest.dart';
import '../ui/modules/module_registry.dart';

/// Project data loaded from backend
class Project {
  final String projectId;
  final String name;
  final String templateId;
  final String workspaceId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProjectTemplate template;
  final List<ProjectBoard> boards;
  final List<String> tools;
  final String backgroundModule;

  Project({
    required this.projectId,
    required this.name,
    required this.templateId,
    required this.workspaceId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.template,
    required this.boards,
    required this.tools,
    required this.backgroundModule,
  });

  /// Get background module ID enum for routing
  ModuleId? get backgroundModuleId => ModuleRegistry.fromString(backgroundModule);

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      projectId: json['id'] as String,
      name: json['name'] as String,
      templateId: json['templateId'] as String,
      workspaceId: json['workspaceId'] as String,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      template: ProjectTemplate.fromJson(
        json['template'] as Map<String, dynamic>,
      ),
      boards: (json['boards'] as List<dynamic>)
          .map((b) => ProjectBoard.fromJson(b as Map<String, dynamic>))
          .toList(),
      tools: (json['tools'] as List<dynamic>).cast<String>(),
      backgroundModule: json['backgroundModule'] as String,
    );
  }
}

/// Template definition from backend
class ProjectTemplate {
  final String id;
  final String name;
  final String description;
  final String backgroundModule;
  final List<String> tools;
  final List<String> defaultBoards;
  final Map<String, dynamic> defaultSettings;

  ProjectTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.backgroundModule,
    required this.tools,
    required this.defaultBoards,
    required this.defaultSettings,
  });

  factory ProjectTemplate.fromJson(Map<String, dynamic> json) {
    return ProjectTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      backgroundModule: json['backgroundModule'] as String,
      tools: (json['tools'] as List<dynamic>).cast<String>(),
      defaultBoards: (json['defaultBoards'] as List<dynamic>).cast<String>(),
      defaultSettings: json['defaultSettings'] as Map<String, dynamic>,
    );
  }
}

/// Board within a project
class ProjectBoard {
  final String id;
  final String projectId;
  final String name;
  final String type;
  final int order;
  final String? module;

  ProjectBoard({
    required this.id,
    required this.projectId,
    required this.name,
    required this.type,
    required this.order,
    this.module,
  });

  /// Get module ID enum for routing
  ModuleId? get moduleId => ModuleRegistry.fromString(module);

  factory ProjectBoard.fromJson(Map<String, dynamic> json) {
    return ProjectBoard(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      order: json['order'] as int,
      module: json['module'] as String?,
    );
  }
}

/// Global project state manager
class ProjectState extends ChangeNotifier {
  Project? _currentProject;
  Map<String, dynamic>? _currentWorkspace;
  List<ProjectBoard> _currentBoards = [];
  List<String> _activeTools = [];
  String? _activeBackground;
  bool _loading = false;
  String? _error;
  WhiteboardState? _whiteboardState;
  
  // Callback to sync active project into routing state
  void Function(Project?)? _onProjectChanged;

  // Getters
  Project? get currentProject => _currentProject;
  Map<String, dynamic>? get currentWorkspace => _currentWorkspace;
  List<ProjectBoard> get currentBoards => _currentBoards;
  List<String> get activeTools => _activeTools;
  String? get activeBackground => _activeBackground;
  bool get loading => _loading;
  String? get error => _error;
  WhiteboardState? get whiteboardState => _whiteboardState;
  
  /// Set callback for syncing project changes to ActiveWorkspaceState
  void setProjectChangeCallback(void Function(Project?) callback) {
    _onProjectChanged = callback;
  }

  /// Load project from local manifest (local-first)
  Future<void> loadLocalProject(ProjectManifest manifest) async {
    print('[ProjectState] ========== LOADING LOCAL PROJECT ==========');
    print('[ProjectState] Loading project: ${manifest.name}');
    
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Convert manifest to Project format
      final project = Project(
        projectId: manifest.projectId,
        name: manifest.name,
        templateId: manifest.templateId,
        workspaceId: manifest.workspaceId,
        createdBy: 'local', // No user tracking in local-first
        createdAt: DateTime.parse(manifest.createdAt),
        updatedAt: DateTime.parse(manifest.lastOpened),
        template: ProjectTemplate(
          id: manifest.templateId,
          name: manifest.templateId,
          description: '',
          backgroundModule: manifest.backgroundModule,
          tools: manifest.tools,
          defaultBoards: manifest.boards.map((b) => b.name).toList(),
          defaultSettings: {},
        ),
        boards: manifest.boards.map((b) => ProjectBoard(
          id: b.id,
          projectId: manifest.projectId,
          name: b.name,
          type: b.type,
          order: b.order,
          module: b.module,
        )).toList(),
        tools: manifest.tools,
        backgroundModule: manifest.backgroundModule,
      );

      _currentProject = project;
      _currentBoards = project.boards;
      _activeTools = project.tools;
      _activeBackground = project.backgroundModule;

      print('[ProjectState] Project state updated:');
      print('[ProjectState]   - Name: ${project.name}');
      print('[ProjectState]   - Template: ${project.template.name}');
      print('[ProjectState]   - Background: ${project.backgroundModule}');
      print('[ProjectState]   - Tools: ${project.tools}');
      print('[ProjectState]   - Boards: ${project.boards.length}');

      // Initialize module-local state
      print('[ProjectState] Initializing module state...');
      await _initModuleState(project);
      print('[ProjectState] Module state initialized');
      
      // Workspace data from manifest
      _currentWorkspace = {'id': project.workspaceId, 'name': project.name};
      
      _loading = false;
      _onProjectChanged?.call(project);
      notifyListeners();
      print('[ProjectState] notifyListeners() called - UI should rebuild');
      print('[ProjectState] ========== LOCAL PROJECT LOADED ==========');
    } catch (e, stackTrace) {
      print('[ProjectState] ERROR loading local project: $e');
      print('[ProjectState] Stack trace: $stackTrace');
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Load project from backend by ID (legacy - now fallback only)
  Future<void> loadProject(String projectId) async {
    print('[ProjectState] ========== LOADING PROJECT ==========');
    print('[ProjectState] Loading project: $projectId');
    
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Backend returns the project object directly (no { success, data } wrapper)
      print('[ProjectState] Fetching from backend: /projects/$projectId');
      final data = await ApiClient.get('/projects/$projectId');
      print('[ProjectState] Raw response type: ${data.runtimeType}');
      print('[ProjectState] Raw response: $data');
      
      final project = Project.fromJson(data as Map<String, dynamic>);
      print('[ProjectState] Parsed project: ${project.name}');

      _currentProject = project;
      _currentBoards = project.boards;
      _activeTools = project.tools;
      _activeBackground = project.backgroundModule;

      print('[ProjectState] Project state updated:');
      print('[ProjectState]   - Name: ${project.name}');
      print('[ProjectState]   - Template: ${project.template.name}');
      print('[ProjectState]   - Background: ${project.backgroundModule}');
      print('[ProjectState]   - Tools: ${project.tools}');
      print('[ProjectState]   - Boards: ${project.boards.length}');

      // Initialize module-local state and ensure local vault
      print('[ProjectState] Initializing module state...');
      await _initModuleState(project);
      print('[ProjectState] Module state initialized');
      
      // Workspace data should come from project
      _currentWorkspace = {'id': project.workspaceId, 'name': project.name};
      
      _loading = false;
      _onProjectChanged?.call(project);
      notifyListeners();
      print('[ProjectState] notifyListeners() called - UI should rebuild');
      print('[ProjectState] ========== PROJECT LOADED ==========');
    } catch (e, stackTrace) {
      print('[ProjectState] ERROR loading project: $e');
      print('[ProjectState] Stack trace: $stackTrace');
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Clear current project
  void clearProject() {
    _currentProject = null;
    _currentWorkspace = null;
    _currentBoards = [];
    _activeTools = [];
    _activeBackground = null;
    _error = null;
    _onProjectChanged?.call(null);
    notifyListeners();
  }

  /// Set project directly (for newly created projects)
  void setProject(Project project) {
    _currentProject = project;
    _currentBoards = project.boards;
    _activeTools = project.tools;
    _activeBackground = project.backgroundModule;
    _currentWorkspace = {'id': project.workspaceId, 'name': project.name};
    _onProjectChanged?.call(project);
    // Fire-and-forget init
    _initModuleState(project).then((_) => notifyListeners());
    notifyListeners();
  }

  Future<void> _initModuleState(Project project) async {
    try {
      await VaultStorageService.ensureLocalWorkspaceFolder(project.workspaceId, project.projectId);
      await VaultStorageService.initializeProjectFiles(
        workspaceId: project.workspaceId,
        projectId: project.projectId,
        template: {
          'id': project.template.id,
          'defaultBoards': project.template.defaultBoards,
          'backgroundModule': project.backgroundModule,
        },
      );
    } catch (_) {}

    if (project.backgroundModule == 'whiteboard' || project.backgroundModule == 'infinite-canvas') {
      _whiteboardState = WhiteboardState(project.projectId);
      await _whiteboardState!.load();
    } else {
      _whiteboardState = null;
    }
  }
}
