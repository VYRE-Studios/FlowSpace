import 'package:flutter/foundation.dart';
import 'project_state.dart';

/// Workspace routing state - tracks active project and active board
/// Separate from ProjectState to enable clean module routing in WorkspaceShell
class ActiveWorkspaceState extends ChangeNotifier {
  Map<String, dynamic>? _activeWorkspace;
  Project? _activeProject;
  ProjectBoard? _activeBoard;

  Map<String, dynamic>? get activeWorkspace => _activeWorkspace;
  String? get activeWorkspaceId => _activeWorkspace?['id'] as String?;
  String? get activeWorkspaceName => _activeWorkspace?['name'] as String?;
  Project? get activeProject => _activeProject;
  ProjectBoard? get activeBoard => _activeBoard;

  void setActiveWorkspace(Map<String, dynamic>? workspace) {
    _activeWorkspace = workspace;
    notifyListeners();
  }

  void setActiveProject(Project? project) {
    _activeProject = project;

    // Auto-select first board when project loads
    if (project != null && project.boards.isNotEmpty) {
      _activeBoard = project.boards.first;
    } else {
      _activeBoard = null;
    }

    notifyListeners();
  }

  void setActiveBoard(ProjectBoard? board) {
    _activeBoard = board;
    notifyListeners();
  }

  void clear() {
    _activeWorkspace = null;
    _activeProject = null;
    _activeBoard = null;
    notifyListeners();
  }
}
