import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/project_manifest.dart';
import '../models/registry_entry.dart';
import 'project_registry.dart';
import 'package:http/http.dart' as http;

class ProjectLoaderService {
  final ProjectRegistryService registryService;
  final String apiBaseUrl;
  final String? authToken;

  ProjectLoaderService({
    required this.registryService,
    required this.apiBaseUrl,
    this.authToken,
  });

  /// Main startup sequence - scan and load all projects
  Future<void> scanAndLoadProjects() async {
    print('[ProjectLoader] Starting project scan...');
    
    try {
      // 1. Load registry
      final registry = await registryService.loadRegistry();
      print('[ProjectLoader] Registry loaded with ${registry.projects.length} projects');

      // 2. Verify each project in registry
      final verifiedProjects = <RegistryEntry>[];
      for (final entry in registry.projects) {
        try {
          final verified = await verifyProject(entry.projectId);
          if (verified) {
            verifiedProjects.add(entry);
          } else {
            print('[ProjectLoader] Project ${entry.projectId} failed verification');
          }
        } catch (e) {
          print('[ProjectLoader] Error verifying ${entry.projectId}: $e');
        }
      }

      // 3. Discover orphaned projects (exist locally but not in registry)
      await discoverOrphanedProjects();

      print('[ProjectLoader] Project scan complete');
    } catch (e) {
      print('[ProjectLoader] Error during scan: $e');
    }
  }

  /// Verify a single project (check local + backend consistency)
  Future<bool> verifyProject(String projectId) async {
    try {
      // 1. Check if local folder exists
      final projectsDir = await registryService.getProjectsDirectory();
      final projectDir = Directory(p.join(projectsDir.path, projectId));
      
      if (!await projectDir.exists()) {
        print('[ProjectLoader] Local folder missing for $projectId - attempting repair');
        return await repairProject(projectId, 'missing_folder');
      }

      // 2. Check if manifest file exists
      final manifestFile = File(p.join(projectDir.path, 'project.json'));
      if (!await manifestFile.exists()) {
        print('[ProjectLoader] Manifest missing for $projectId - attempting repair');
        return await repairProject(projectId, 'missing_manifest');
      }

      // 3. Load local manifest
      final localManifestJson = jsonDecode(await manifestFile.readAsString());
      final localManifest = ProjectManifest.fromJson(localManifestJson);

      // 4. Verify with backend (async, non-blocking)
      _verifyWithBackend(projectId, localManifest);

      return true;
    } catch (e) {
      print('[ProjectLoader] Verification failed for $projectId: $e');
      return false;
    }
  }

  /// Repair a project based on the failure type
  Future<bool> repairProject(String projectId, String failureType) async {
    try {
      if (failureType == 'missing_folder' || failureType == 'missing_manifest') {
        // Download manifest from backend and rebuild
        final manifest = await _downloadManifestFromBackend(projectId);
        if (manifest != null) {
          await _rebuildProjectLocally(manifest);
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('[ProjectLoader] Repair failed for $projectId: $e');
      return false;
    }
  }

  /// Discover projects that exist locally but not in registry
  Future<void> discoverOrphanedProjects() async {
    try {
      final projectsDir = await registryService.getProjectsDirectory();
      
      if (!await projectsDir.exists()) {
        return;
      }

      final entities = await projectsDir.list().toList();
      final registry = await registryService.loadRegistry();
      final knownProjectIds = registry.projects.map((p) => p.projectId).toSet();

      for (final entity in entities) {
        if (entity is Directory) {
          final projectId = p.basename(entity.path);
          
          if (!knownProjectIds.contains(projectId)) {
            print('[ProjectLoader] Discovered orphaned project: $projectId');
            
            // Check if manifest exists
            final manifestFile = File(p.join(entity.path, 'project.json'));
            if (await manifestFile.exists()) {
              try {
                final manifestJson = jsonDecode(await manifestFile.readAsString());
                final manifest = ProjectManifest.fromJson(manifestJson);
                
                // Add to registry
                await registryService.addProject(RegistryEntry(
                  projectId: manifest.projectId,
                  workspaceId: manifest.workspaceId,
                  name: manifest.name,
                  templateId: manifest.templateId,
                  lastOpened: manifest.lastOpened,
                  localPath: manifest.localPath,
                ));
                
                print('[ProjectLoader] Added orphaned project to registry: $projectId');
              } catch (e) {
                print('[ProjectLoader] Failed to add orphaned project: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      print('[ProjectLoader] Error discovering orphaned projects: $e');
    }
  }

  /// Verify project with backend (async background task)
  Future<void> _verifyWithBackend(String projectId, ProjectManifest localManifest) async {
    if (authToken == null) {
      return; // Skip if not authenticated
    }

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/projects/$projectId/manifest'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final serverManifestJson = jsonDecode(response.body);
        final serverManifest = ProjectManifest.fromJson(serverManifestJson);
        
        // Check for drift
        if (localManifest.name != serverManifest.name) {
          print('[ProjectLoader] Detected drift in project $projectId - server has newer name');
          // Could auto-sync here or flag for user review
        }
      }
    } catch (e) {
      // Silent fail - offline mode or network issue
      print('[ProjectLoader] Backend verification skipped for $projectId: $e');
    }
  }

  /// Download manifest from backend
  Future<ProjectManifest?> _downloadManifestFromBackend(String projectId) async {
    if (authToken == null) {
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/projects/$projectId/manifest'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final manifestJson = jsonDecode(response.body);
        return ProjectManifest.fromJson(manifestJson);
      }
    } catch (e) {
      print('[ProjectLoader] Failed to download manifest: $e');
    }
    
    return null;
  }

  /// Rebuild project locally from manifest
  Future<void> _rebuildProjectLocally(ProjectManifest manifest) async {
    final projectsDir = await registryService.getProjectsDirectory();
    final projectDir = Directory(p.join(projectsDir.path, manifest.projectId));
    
    // Create project directory
    if (!await projectDir.exists()) {
      await projectDir.create(recursive: true);
    }

    // Write manifest file
    final manifestFile = File(p.join(projectDir.path, 'project.json'));
    await manifestFile.writeAsString(jsonEncode(manifest.toJson()));

    // Create template-specific folders
    await _createTemplateFolders(projectDir.path, manifest.templateId);

    // Add to registry
    await registryService.addProject(RegistryEntry(
      projectId: manifest.projectId,
      workspaceId: manifest.workspaceId,
      name: manifest.name,
      templateId: manifest.templateId,
      lastOpened: manifest.lastOpened,
      localPath: manifest.localPath,
    ));

    print('[ProjectLoader] Rebuilt project ${manifest.projectId} locally');
  }

  /// Create template-specific folder structure
  Future<void> _createTemplateFolders(String projectPath, String templateId) async {
    final foldersMap = {
      'whiteboard': ['Boards', 'Exports', 'Images'],
      'story': ['Characters', 'Scenes', 'Drafts', 'Worldbuilding', 'Research'],
      'workflow': ['Workflows', 'Logs', 'Config', 'Scripts'],
      'game': ['Assets', 'Builds', 'Documentation', 'Source', 'Milestones'],
      'brainstorm-lite': ['Sessions', 'Exports'],
      'blank': ['Files', 'Notes', 'Tasks'],
    };

    final folders = foldersMap[templateId] ?? ['Files'];

    for (final folderName in folders) {
      final folder = Directory(p.join(projectPath, folderName));
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
    }
  }
}
