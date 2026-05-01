import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/project_state.dart';
import '../../state/active_workspace_state.dart';

/// Spaces view - shows project boards/workspaces
class SpacesView extends StatelessWidget {
  const SpacesView({super.key});

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

    final spaces = project.boards;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spaces - ${project.name}',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Template: ${project.template.name}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: spaces.isEmpty
                  ? const Center(
                      child: Text(
                        'No boards in this project',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: spaces.length,
                      itemBuilder: (context, index) {
                        final space = spaces[index];
                        return Card(
                          color: Colors.white.withOpacity(0.05),
                          child: InkWell(
                            onTap: () {
                              // Set active board for module routing
                              context.read<ActiveWorkspaceState>().setActiveBoard(space);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.dashboard,
                                    size: 32,
                                    color: Colors.blue.shade300,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    space.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    space.type,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
