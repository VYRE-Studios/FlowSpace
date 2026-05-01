import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/registry_entry.dart';

class ProjectRegistryService {
  ProjectRegistry? _registry;
  String? _registryPath;

  /// Load the project registry from disk
  Future<ProjectRegistry> loadRegistry() async {
    if (_registry != null) {
      return _registry!;
    }

    final registryFile = await _getRegistryFile();
    
    if (!await registryFile.exists()) {
      // Create new empty registry
      _registry = ProjectRegistry(
        lastUpdated: DateTime.now().toIso8601String(),
        projects: [],
      );
      await saveRegistry();
      return _registry!;
    }

    try {
      final contents = await registryFile.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;
      _registry = ProjectRegistry.fromJson(json);
      return _registry!;
    } catch (e) {
      print('Error loading registry: $e');
      // Return empty registry if corrupted
      _registry = ProjectRegistry(
        lastUpdated: DateTime.now().toIso8601String(),
        projects: [],
      );
      return _registry!;
    }
  }

  /// Save the current registry to disk
  Future<void> saveRegistry() async {
    if (_registry == null) {
      throw Exception('Cannot save null registry');
    }

    final registryFile = await _getRegistryFile();
    final updated = _registry!.copyWith(
      lastUpdated: DateTime.now().toIso8601String(),
    );
    _registry = updated;

    await registryFile.writeAsString(
      jsonEncode(updated.toJson()),
    );
  }

  /// Add a project to the registry
  Future<void> addProject(RegistryEntry entry) async {
    await loadRegistry();
    
    // Remove existing entry if it exists
    final filtered = _registry!.projects
        .where((p) => p.projectId != entry.projectId)
        .toList();
    
    // Add new entry
    filtered.add(entry);
    
    _registry = _registry!.copyWith(projects: filtered);
    await saveRegistry();
  }

  /// Remove a project from the registry
  Future<void> removeProject(String projectId) async {
    await loadRegistry();
    
    final filtered = _registry!.projects
        .where((p) => p.projectId != projectId)
        .toList();
    
    _registry = _registry!.copyWith(projects: filtered);
    await saveRegistry();
  }

  /// Update lastOpened timestamp for a project
  Future<void> updateLastOpened(String projectId) async {
    await loadRegistry();
    
    final updated = _registry!.projects.map((p) {
      if (p.projectId == projectId) {
        return p.copyWith(lastOpened: DateTime.now().toIso8601String());
      }
      return p;
    }).toList();
    
    _registry = _registry!.copyWith(projects: updated);
    await saveRegistry();
  }

  /// Get all projects for a specific workspace
  Future<List<RegistryEntry>> getProjectsByWorkspace(String workspaceId) async {
    await loadRegistry();
    
    return _registry!.projects
        .where((p) => p.workspaceId == workspaceId)
        .toList();
  }

  /// Get all projects sorted by lastOpened (most recent first)
  Future<List<RegistryEntry>> getAllProjects() async {
    await loadRegistry();
    
    final projects = List<RegistryEntry>.from(_registry!.projects);
    projects.sort((a, b) {
      final dateA = DateTime.parse(a.lastOpened);
      final dateB = DateTime.parse(b.lastOpened);
      return dateB.compareTo(dateA); // Descending order
    });
    
    return projects;
  }

  /// Get a specific project by ID
  Future<RegistryEntry?> getProject(String projectId) async {
    await loadRegistry();
    
    try {
      return _registry!.projects.firstWhere((p) => p.projectId == projectId);
    } catch (e) {
      return null;
    }
  }

  /// Clear the registry (for testing or reset)
  Future<void> clearRegistry() async {
    _registry = ProjectRegistry(
      lastUpdated: DateTime.now().toIso8601String(),
      projects: [],
    );
    await saveRegistry();
  }

  /// Get the registry file handle
  Future<File> _getRegistryFile() async {
    if (_registryPath != null) {
      return File(_registryPath!);
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final registryDir = Directory(p.join(docsDir.path, 'VyreVault', 'ProjectRegistry'));
    
    if (!await registryDir.exists()) {
      await registryDir.create(recursive: true);
    }

    _registryPath = p.join(registryDir.path, 'registry.json');
    return File(_registryPath!);
  }

  /// Get the vault base directory
  Future<Directory> getVaultDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    return Directory(p.join(docsDir.path, 'VyreVault'));
  }

  /// Get the projects directory
  Future<Directory> getProjectsDirectory() async {
    final vaultDir = await getVaultDirectory();
    final projectsDir = Directory(p.join(vaultDir.path, 'Projects'));
    
    if (!await projectsDir.exists()) {
      await projectsDir.create(recursive: true);
    }
    
    return projectsDir;
  }
}
