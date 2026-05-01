import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/project_state.dart';
import '../../services/project_registry.dart';
import '../../theme/flowspace_colors.dart';

class UnifiedSidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final projectState = Provider.of<ProjectState>(context);
    final registry = ProjectRegistryService();

    return FutureBuilder(
      future: registry.getAllProjects(),
      builder: (context, snapshot) {
        final projects = snapshot.data ?? [];

        return Container(
          width: 260,
          color: FlowspaceColors.sidebar,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context, projectState),
              const SizedBox(height: 8),
              _sectionTitle("Projects"),
              Expanded(child: _projectList(context, projects)),
              _sectionTitle("Actions"),
              _actionButton(context),
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, ProjectState projectState) {
    final projectName = projectState.currentProject?.name;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Text(
        projectName ?? "No Project Selected",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _projectList(BuildContext context, List projects) {
    if (projects.isEmpty) {
      return Center(
        child: Text(
          "No projects yet",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      itemCount: projects.length,
      itemBuilder: (_, index) {
        final p = projects[index];
        return ListTile(
          title: Text(
            p.name,
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            p.templateId,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/project');
          },
        );
      },
    );
  }

  Widget _actionButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/create-project'),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add),
            SizedBox(width: 12),
            Text("New Project"),
          ],
        ),
      ),
    );
  }
}
