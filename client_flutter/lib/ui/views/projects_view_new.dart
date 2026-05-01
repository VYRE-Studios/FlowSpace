import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/project_state.dart';
import '../../services/module_loader.dart';
import '../widgets/unified_sidebar.dart';
import '../widgets/workspace_sidebar.dart';
import '../modules/background_skin.dart';

class ProjectsView extends StatelessWidget {
  const ProjectsView({super.key});

  @override
  Widget build(BuildContext context) {
    final projectState = Provider.of<ProjectState>(context);
    final currentProject = projectState.currentProject;

    if (currentProject == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open,
                size: 80,
                color: Colors.white24,
              ),
              const SizedBox(height: 24),
              Text(
                'No project selected',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Select a project from the dashboard',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white54,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    final templateId = currentProject.templateId;
    final backgroundModule = currentProject.backgroundModule;

    return Scaffold(
      body: Row(
        children: [
          UnifiedSidebar(),
          Expanded(
            child: Stack(
              children: [
                BackgroundSkin(
                  child: Row(
                    children: [
                      WorkspaceSidebar(),
                      Expanded(
                        child: _buildModuleContent(
                          context,
                          backgroundModule ?? templateId ?? 'blank',
                          currentProject,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleContent(
    BuildContext context,
    String? moduleId,
    dynamic project,
  ) {
    return ModuleLoader.loadBackgroundModule(moduleId);
  }
}
