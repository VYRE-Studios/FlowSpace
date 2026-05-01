import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api_client.dart';
import '../state/project_state.dart';
import 'vault_storage_service.dart';

/// WorkspaceLoader: the glue that binds a project to its template-driven environment.
///
/// Responsibilities
/// - Fetch the full project payload from the backend (includes template, boards, tools, backgroundModule)
/// - Set global ProjectState so the Shell renders the correct background module and tools
/// - Optionally navigate to the Projects tab via a provided callback
class WorkspaceLoader {
  /// Open a workspace by projectId.
  /// - Loads the project from backend: GET /projects/:id
  /// - Pushes it into ProjectState (which activates background module + tools)
  /// - Returns the parsed Project instance
  static Future<Project> openByProjectId(
    BuildContext context, {
    required String projectId,
  }) async {
    final projectJson = await ApiClient.get('/projects/$projectId') as Map<String, dynamic>;
    final project = Project.fromJson(projectJson);

    // Ensure local workspace folder + initialize template files
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

    // Update global state to activate background module + tools
    // setProject() assigns boards, tools, and backgroundModule for Shell overlay
    context.read<ProjectState>().setProject(project);
    return project;
  }

  /// Open a workspace from a project JSON map (e.g., dashboard selection list item).
  /// If the minimal JSON lacks template/boards/tools, this will fetch the full object first.
  static Future<Project> openFromProjectMap(
    BuildContext context, {
    required Map<String, dynamic> projectMap,
  }) async {
    final id = (projectMap['id'] ?? projectMap['projectId']) as String?;
    if (id == null || id.isEmpty) {
      throw ArgumentError('openFromProjectMap: project id missing');
    }

    // Try to detect if this is already a full payload (has boards/tools/backgroundModule)
    final hasFull = projectMap.containsKey('boards') &&
        projectMap.containsKey('tools') &&
        projectMap.containsKey('backgroundModule');

    if (!hasFull) {
      return openByProjectId(context, projectId: id);
    }

    final project = Project.fromJson(projectMap);
    context.read<ProjectState>().setProject(project);
    return project;
  }

  /// Convenience: open the first project in a workspace (if any) and return it.
  /// Useful when landing in a workspace and wanting to auto-load its primary project.
  static Future<Project?> openFirstInWorkspace(
    BuildContext context, {
    required String workspaceId,
  }) async {
    final list = await ApiClient.get('/projects/workspace/$workspaceId') as List<dynamic>;
    if (list.isEmpty) return null;
    final first = list.first as Map<String, dynamic>;
    return openFromProjectMap(context, projectMap: first);
  }
}
