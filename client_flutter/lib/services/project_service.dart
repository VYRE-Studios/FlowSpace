import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/project_manifest.dart';
import '../models/registry_entry.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'project_registry.dart';
import 'vault_storage_service.dart';
import 'project_loader.dart';

class ProjectService {
  final ProjectRegistryService _registryService;
  final String apiBaseUrl;
  
  ProjectService({
    required ProjectRegistryService registryService,
    required this.apiBaseUrl,
  }) : _registryService = registryService;

  /// Create a new project with full manifest and registry integration
  Future<Map<String, dynamic>> createProject({
    required String name,
    required String templateId,
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // 1. Create project on backend
      final response = await ApiClient.post(
        'projects/create',
        body: {
          'name': name,
          'templateId': templateId,
        },
      );

      final data = response as Map<String, dynamic>;
      final projectId = data['projectId'] as String;
      final workspaceId = data['workspaceId'] as String;
      final manifest = data['manifest'] as Map<String, dynamic>;
      
      // 2. Create local project manifest from backend response
      final projectManifest = ProjectManifest.fromJson(manifest);
      await VaultStorageService.createProjectManifest(projectManifest);

      // 3. Create local folder structure
      await VaultStorageService.createProjectVaultFolder(
        projectId: projectId,
        templateId: templateId,
        projectName: name,
      );

      // 4. Add to registry
      await _registryService.addProject(RegistryEntry(
        projectId: projectId,
        workspaceId: workspaceId,
        name: name,
        templateId: templateId,
        lastOpened: DateTime.now().toIso8601String(),
        localPath: 'VyreVault/Projects/$projectId/',
      ));

      print('[ProjectService] Project created: $name ($projectId)');
      return data;
    } catch (e) {
      print('[ProjectService] Error creating project: $e');
      rethrow;
    }
  }

  /// Open a project (updates lastOpened)
  Future<void> openProject(String projectId) async {
    try {
      // Update local manifest lastOpened
      await VaultStorageService.updateManifestLastOpened(projectId);
      
      // Update registry lastOpened
      await _registryService.updateLastOpened(projectId);
      
      print('[ProjectService] Opened project: $projectId');
    } catch (e) {
      print('[ProjectService] Error opening project: $e');
    }
  }

  /// Delete a project (removes from registry, local storage, and backend)
  Future<void> deleteProject(String projectId) async {
    try {
      // 1. Remove from registry
      await _registryService.removeProject(projectId);

      // 2. Delete local folder
      await VaultStorageService.deleteProjectFolder(projectId);

      // 3. Delete from backend
      try {
        await ApiClient.delete('projects/$projectId');
      } catch (e) {
        print('[ProjectService] Could not delete from backend: $e');
      }

      print('[ProjectService] Deleted project: $projectId');
    } catch (e) {
      print('[ProjectService] Error deleting project: $e');
      rethrow;
    }
  }

  /// Get all projects (from registry)
  Future<List<RegistryEntry>> getAllProjects() async {
    return await _registryService.getAllProjects();
  }

  /// Get projects for a specific workspace
  Future<List<RegistryEntry>> getProjectsByWorkspace(String workspaceId) async {
    return await _registryService.getProjectsByWorkspace(workspaceId);
  }

  /// Get a single project by ID
  Future<RegistryEntry?> getProject(String projectId) async {
    return await _registryService.getProject(projectId);
  }

  /// Sync project manifest with backend
  Future<void> syncProjectManifest(String projectId) async {
    try {
      final token = await AuthService.getAuthToken();
      if (token == null) return;

      // Load local manifest
      final localManifest = await VaultStorageService.loadProjectManifest(projectId);
      if (localManifest == null) {
        print('[ProjectService] No local manifest found for $projectId');
        return;
      }

      // Upload to backend
      await http.post(
        Uri.parse('$apiBaseUrl/projects/$projectId/manifest'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(localManifest.toJson()),
      );

      print('[ProjectService] Synced manifest for $projectId');
    } catch (e) {
      print('[ProjectService] Error syncing manifest: $e');
    }
  }

  /// Download manifest from backend and update local
  Future<void> downloadProjectManifest(String projectId) async {
    try {
      final token = await AuthService.getAuthToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$apiBaseUrl/projects/$projectId/manifest'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final manifestJson = jsonDecode(response.body) as Map<String, dynamic>;
        final manifest = ProjectManifest.fromJson(manifestJson);
        
        // Update local manifest
        await VaultStorageService.updateProjectManifest(projectId, manifest);
        
        print('[ProjectService] Downloaded manifest for $projectId');
      }
    } catch (e) {
      print('[ProjectService] Error downloading manifest: $e');
    }
  }

  /// Reconcile project with backend (merge conflicts)
  Future<void> reconcileProject(String projectId) async {
    try {
      final token = await AuthService.getAuthToken();
      if (token == null) return;

      final localManifest = await VaultStorageService.loadProjectManifest(projectId);
      if (localManifest == null) return;

      final response = await http.post(
        Uri.parse('$apiBaseUrl/projects/$projectId/reconcile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'localManifest': localManifest.toJson()}),
      );

      if (response.statusCode == 200) {
        final mergedJson = jsonDecode(response.body) as Map<String, dynamic>;
        final merged = ProjectManifest.fromJson(mergedJson);
        
        // Update local with merged version
        await VaultStorageService.updateProjectManifest(projectId, merged);
        
        print('[ProjectService] Reconciled project $projectId');
      }
    } catch (e) {
      print('[ProjectService] Error reconciling project: $e');
    }
  }
}
