import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/project_state.dart';
import '../../services/project_registry.dart';

class WorkspaceSidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final projectState = Provider.of<ProjectState>(context);
    final registry = ProjectRegistryService();

    return FutureBuilder(
      future: registry.getAllProjects(),
      builder: (context, snapshot) {
        final allProjects = snapshot.data ?? [];

        return Container(
          width: 240,
          color: Colors.grey[950],
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'Projects',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              for (var project in allProjects)
                ListTile(
                  title: Text(
                    project.name,
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    project.templateId,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, '/project');
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
