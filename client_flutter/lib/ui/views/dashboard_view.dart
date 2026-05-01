import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/project_state.dart';
import '../../services/project_registry.dart';
import '../../services/workspace_loader.dart';
import '../../models/project_manifest.dart';
import '../widgets/project_card.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final project = context.watch<ProjectState>().currentProject;
    
    if (project == null) {
      return const Center(
        child: Text(
          'Load a project to begin',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }
    
    final boards = project.boards;
    final registry = ProjectRegistryService();

    return FutureBuilder(
      future: registry.getAllProjects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final projects = snapshot.data ?? [];

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          body: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Projects',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: projects.isEmpty
                      ? _buildEmptyState(context)
                      : _buildProjectGrid(context, projects),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, '/create-project'),
            icon: const Icon(Icons.add),
            label: const Text('New Project'),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
            'No projects yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create your first project to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white54,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectGrid(BuildContext context, List projects) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.6,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return ProjectCard(
          manifest: project,
          onOpen: () async {
            await WorkspaceLoader.openFromProjectMap(
              context,
              projectMap: project.toJson(),
            );
          },
        );
      },
    );
  }
}
