import 'dart:io';
import 'dart:convert';
import '../models/project_manifest.dart';
import 'workspace_location_service.dart';
import 'safe_writer.dart';

/// Service for managing the project registry file (registry.json)
/// This provides fast access to all projects without scanning directories
class ProjectRegistryService {
  static ProjectRegistryService? _instance;
  static ProjectRegistryService get instance {
    _instance ??= ProjectRegistryService._internal();
    return _instance!;
  }

  ProjectRegistryService._internal();

  /// Registry file schema
  static const String _version = '1.0.0';
  
  /// In-memory cache of the registry
  List<RegistryEntry> _projects = [];

  /// Get registry file path
  Future<File?> _getRegistryFile() async {
    final workspacePath = await WorkspaceLocationService.getWorkspacePath();
    if (workspacePath == null) return null;

    final registryDir = Directory('$workspacePath/VyreVault/ProjectRegistry');
    if (!registryDir.existsSync()) {
      registryDir.createSync(recursive: true);
    }

    return File('${registryDir.path}/registry.json');
  }

  /// Load registry from disk with validation and recovery
  Future<void> loadRegistry() async {
    print('[ProjectRegistry] Loading registry from disk...');
    
    final file = await _getRegistryFile();
    if (file == null) {
      print('[ProjectRegistry] No workspace configured yet');
      _projects = [];
      return;
    }

    if (!file.existsSync()) {
      print('[ProjectRegistry] Registry file does not exist yet - starting fresh');
      _projects = [];
      await saveRegistry(); // Create empty registry
      return;
    }

    try {
      final jsonString = file.readAsStringSync();
      final data = jsonDecode(jsonString);
      
      // Validate registry format
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid registry format - expected Map');
      }

      if (!data.containsKey('projects') || data['projects'] is! List) {
        throw Exception('Invalid registry format - missing or invalid projects array');
      }
      
      final projectsList = data['projects'] as List<dynamic>;
      _projects = [];
      
      // Load entries with individual error handling
      for (final projectData in projectsList) {
        try {
          if (projectData is Map<String, dynamic>) {
            final entry = RegistryEntry.fromJson(projectData);
            _projects.add(entry);
          }
        } catch (e) {
          // Skip corrupted entry
          print('[ProjectRegistry] Skipping corrupted entry: $e');
        }
      }

      print('[ProjectRegistry] Loaded ${_projects.length} projects from registry');
    } catch (e) {
      print('[ProjectRegistry] ERROR loading registry: $e - starting fresh');
      _projects = [];
      // Save empty registry to fix corruption
      await saveRegistry();
    }
  }

  /// Save registry to disk atomically
  Future<void> saveRegistry() async {
    final file = await _getRegistryFile();
    if (file == null) {
      print('[ProjectRegistry] Cannot save - no workspace configured');
      return;
    }

    final data = {
      'version': _version,
      'lastUpdated': DateTime.now().toIso8601String(),
      'projects': _projects.map((p) => p.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    
    // Use atomic write to prevent corruption
    await SafeWriter.writeAtomic(file, jsonString);
    
    print('[ProjectRegistry] Saved registry with ${_projects.length} projects');
  }

  /// Add or update project in registry
  Future<void> register(ProjectManifest manifest) async {
    final entry = RegistryEntry(
      projectId: manifest.projectId,
      workspaceId: manifest.workspaceId,
      name: manifest.name,
      templateId: manifest.templateId,
      lastOpened: manifest.lastOpened,
      localPath: manifest.localPath,
      backgroundModule: manifest.backgroundModule,
      tools: manifest.tools,
    );

    // Remove existing entry if present
    _projects.removeWhere((p) => p.projectId == manifest.projectId);
    
    // Add new entry
    _projects.add(entry);

    await saveRegistry();
    print('[ProjectRegistry] Registered project: ${manifest.name}');
  }

  /// Remove project from registry
  Future<void> unregister(String projectId) async {
    _projects.removeWhere((p) => p.projectId == projectId);
    await saveRegistry();
    print('[ProjectRegistry] Unregistered project: $projectId');
  }

  /// Update lastOpened timestamp for a project
  Future<void> updateLastOpened(String projectId) async {
    final index = _projects.indexWhere((p) => p.projectId == projectId);
    if (index == -1) return;

    final newEntry = _projects[index].copyWith(
      lastOpened: DateTime.now().toIso8601String(),
    );
    _projects[index] = newEntry;

    await saveRegistry();
  }

  /// Get all projects sorted by lastOpened (most recent first)
  List<RegistryEntry> getAllProjects() {
    final sorted = List<RegistryEntry>.from(_projects);
    sorted.sort((a, b) {
      final aTime = DateTime.parse(a.lastOpened);
      final bTime = DateTime.parse(b.lastOpened);
      return bTime.compareTo(aTime); // Most recent first
    });
    return sorted;
  }

  /// Get projects for a specific workspace
  List<RegistryEntry> getProjectsByWorkspace(String workspaceId) {
    return _projects.where((p) => p.workspaceId == workspaceId).toList();
  }

  /// Check if project exists in registry
  bool hasProject(String projectId) {
    return _projects.any((p) => p.projectId == projectId);
  }

  /// Get project entry by ID
  RegistryEntry? getProject(String projectId) {
    try {
      return _projects.firstWhere((p) => p.projectId == projectId);
    } catch (e) {
      return null;
    }
  }

  /// Clear all projects from registry
  Future<void> clearRegistry() async {
    _projects = [];
    await saveRegistry();
  }
}

/// Minimal project info stored in registry for fast access
class RegistryEntry {
  final String projectId;
  final String workspaceId;
  final String name;
  final String templateId;
  final String lastOpened;
  final String localPath;
  final String backgroundModule;
  final List<String> tools;

  RegistryEntry({
    required this.projectId,
    required this.workspaceId,
    required this.name,
    required this.templateId,
    required this.lastOpened,
    required this.localPath,
    this.backgroundModule = 'standard',
    this.tools = const [],
  });

  factory RegistryEntry.fromJson(Map<String, dynamic> json) {
    return RegistryEntry(
      projectId: json['projectId'] as String,
      workspaceId: json['workspaceId'] as String,
      name: json['name'] as String,
      templateId: json['templateId'] as String,
      lastOpened: json['lastOpened'] as String,
      localPath: json['localPath'] as String,
      backgroundModule: json['backgroundModule'] as String? ?? 'standard',
      tools: (json['tools'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'workspaceId': workspaceId,
      'name': name,
      'templateId': templateId,
      'lastOpened': lastOpened,
      'localPath': localPath,
      'backgroundModule': backgroundModule,
      'tools': tools,
    };
  }

  RegistryEntry copyWith({
    String? projectId,
    String? workspaceId,
    String? name,
    String? templateId,
    String? lastOpened,
    String? localPath,
    String? backgroundModule,
    List<String>? tools,
  }) {
    return RegistryEntry(
      projectId: projectId ?? this.projectId,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      templateId: templateId ?? this.templateId,
      lastOpened: lastOpened ?? this.lastOpened,
      localPath: localPath ?? this.localPath,
      backgroundModule: backgroundModule ?? this.backgroundModule,
      tools: tools ?? this.tools,
    );
  }
}
