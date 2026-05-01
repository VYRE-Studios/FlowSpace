import 'dart:io';
import '../models/project_manifest.dart';
import 'workspace_location_service.dart';
import 'project_registry_service.dart';
import 'project_channel_service.dart';

/// Service for loading projects from local disk (local-first architecture)
class LocalProjectLoader {
  /// Load all projects from disk into registry
  /// This scans the VyreVault/projects folder and loads manifest.json files
  static Future<List<ProjectManifest>> loadLocalProjects() async {
    print('[LocalProjectLoader] ========== LOADING LOCAL PROJECTS ==========');
    
    final workspacePath = await WorkspaceLocationService.getWorkspacePath();
    if (workspacePath == null) {
      print('[LocalProjectLoader] No workspace configured - skipping local load');
      return [];
    }

    print('[LocalProjectLoader] Workspace path: $workspacePath');

    final projectsDir = Directory('$workspacePath/VyreVault/projects');
    if (!projectsDir.existsSync()) {
      print('[LocalProjectLoader] Projects directory does not exist yet');
      return [];
    }

    final loadedProjects = <ProjectManifest>[];

    // Scan for project folders
    final items = projectsDir.listSync();
    print('[LocalProjectLoader] Found ${items.length} items in projects folder');

    for (final item in items) {
      if (item is Directory) {
        final manifestFile = File('${item.path}/manifest.json');
        
        if (manifestFile.existsSync()) {
          try {
            final jsonString = manifestFile.readAsStringSync();
            final manifest = ProjectManifest.fromJsonString(jsonString);
            
            // Register in registry
            await ProjectRegistryService.instance.register(manifest);
            loadedProjects.add(manifest);
            
            print('[LocalProjectLoader]   ✓ Loaded: ${manifest.name} (${manifest.projectId})');
          } catch (e) {
            print('[LocalProjectLoader]   ✗ Failed to parse ${item.path}: $e');
          }
        } else {
          print('[LocalProjectLoader]   ⚠ Skipped ${item.path} (no manifest.json)');
        }
      }
    }

    print('[LocalProjectLoader] ========== LOADED ${loadedProjects.length} PROJECTS ==========');
    return loadedProjects;
  }

  /// Create a new project locally and add to registry
  static Future<ProjectManifest> createLocalProject({
    required String name,
    required String templateId,
    required String workspaceId,
    required String backgroundModule,
    required List<String> tools,
    required List<String> defaultBoards,
  }) async {
    print('[LocalProjectLoader] Creating local project: $name');
    
    final workspacePath = await WorkspaceLocationService.getWorkspacePath();
    if (workspacePath == null) {
      throw Exception('Workspace location not configured');
    }

    // Generate project ID (simple timestamp-based ID)
    final projectId = 'project_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();

    // Create project folder
    final projectFolder = Directory('$workspacePath/VyreVault/projects/$name');
    if (!projectFolder.existsSync()) {
      projectFolder.createSync(recursive: true);
    }

    // Create boards as folder structure
    final boards = <BoardManifest>[];
    for (var i = 0; i < defaultBoards.length; i++) {
      final boardName = defaultBoards[i];
      final boardId = 'board_${DateTime.now().millisecondsSinceEpoch}_$i';
      
      // Create board folder
      final boardFolder = Directory('${projectFolder.path}/$boardName');
      if (!boardFolder.existsSync()) {
        boardFolder.createSync(recursive: true);
      }

      // Assign module based on template and board index
      String? boardModule;
      if (templateId == 'brainstorm-lite' || templateId == 'whiteboard') {
        boardModule = 'infinite_canvas';
      } else if (templateId == 'story') {
        boardModule = i == 0 ? 'standard' : 'story_timeline';
      } else if (templateId == 'workflow') {
        boardModule = 'graph_canvas';
      } else {
        boardModule = 'standard';
      }

      boards.add(BoardManifest(
        id: boardId,
        name: boardName,
        type: 'kanban',
        order: i,
        module: boardModule,
      ));
    }

    // Create manifest
    final manifest = ProjectManifest(
      projectId: projectId,
      workspaceId: workspaceId,
      templateId: templateId,
      name: name,
      lastOpened: now,
      createdAt: now,
      boards: boards,
      localPath: projectFolder.path,
      backgroundModule: backgroundModule,
      tools: tools,
    );

    // Write manifest.json
    final manifestFile = File('${projectFolder.path}/manifest.json');
    manifestFile.writeAsStringSync(manifest.toJsonString());

    // Register in registry
    await ProjectRegistryService.instance.register(manifest);

    // Initialize channels for project
    await ProjectChannelService.initializeProjectChannels(
      projectId: projectId,
      boardNames: defaultBoards,
    );

    print('[LocalProjectLoader] ✓ Created project: $name at ${projectFolder.path}');
    return manifest;
  }

  /// Load a specific project manifest from disk
  static Future<ProjectManifest?> loadProjectManifest(String projectId) async {
    final workspacePath = await WorkspaceLocationService.getWorkspacePath();
    if (workspacePath == null) return null;

    // Check registry first
    final registryEntry = ProjectRegistryService.instance.getProject(projectId);
    if (registryEntry == null) return null;

    // Load from disk
    final manifestFile = File('${registryEntry.localPath}/manifest.json');
    if (!manifestFile.existsSync()) return null;

    try {
      final jsonString = manifestFile.readAsStringSync();
      return ProjectManifest.fromJsonString(jsonString);
    } catch (e) {
      print('[LocalProjectLoader] ERROR loading manifest for $projectId: $e');
      return null;
    }
  }

  /// Update project manifest on disk
  static Future<void> updateProjectManifest(ProjectManifest manifest) async {
    final manifestFile = File('${manifest.localPath}/manifest.json');
    if (!manifestFile.existsSync()) {
      throw Exception('Manifest file does not exist: ${manifestFile.path}');
    }

    manifestFile.writeAsStringSync(manifest.toJsonString());
    
    // Update registry
    await ProjectRegistryService.instance.register(manifest);
    
    print('[LocalProjectLoader] Updated manifest for ${manifest.name}');
  }

  /// Delete project from disk and registry
  static Future<void> deleteLocalProject(String projectId) async {
    final registryEntry = ProjectRegistryService.instance.getProject(projectId);
    if (registryEntry == null) {
      print('[LocalProjectLoader] Project $projectId not found in registry');
      return;
    }

    // Delete folder
    final projectDir = Directory(registryEntry.localPath);
    if (projectDir.existsSync()) {
      projectDir.deleteSync(recursive: true);
      print('[LocalProjectLoader] Deleted project folder: ${registryEntry.localPath}');
    }

    // Remove from registry
    await ProjectRegistryService.instance.unregister(projectId);
    print('[LocalProjectLoader] Unregistered project: $projectId');
  }
}
