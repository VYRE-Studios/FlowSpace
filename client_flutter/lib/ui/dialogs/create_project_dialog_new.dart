import 'package:flutter/material.dart';
import '../../services/local_project_loader.dart';
import '../../services/project_template_service.dart';
import '../../models/project_manifest.dart';

class CreateProjectDialog extends StatefulWidget {
  const CreateProjectDialog({super.key});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedTemplate = 'brainstorm-lite';
  bool _creating = false;

  final Map<String, Map<String, dynamic>> _templates = {
    'brainstorm-lite': {
      'name': 'Brainstorming',
      'icon': Icons.lightbulb_outline,
      'description': 'Quick ideation and mind mapping',
    },
    'story': {
      'name': 'Story Building',
      'icon': Icons.auto_stories,
      'description': 'Narrative development and world building',
    },
    'whiteboard': {
      'name': 'Whiteboard',
      'icon': Icons.brush,
      'description': 'Infinite canvas for visual thinking',
    },
    'workflow': {
      'name': 'Workflow',
      'icon': Icons.account_tree,
      'description': 'Node-based automation pipelines',
    },
    'game': {
      'name': 'Game Project',
      'icon': Icons.videogame_asset,
      'description': 'Game development planning',
    },
    'blank': {
      'name': 'Blank Project',
      'icon': Icons.note,
      'description': 'General purpose workspace',
    },
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Project'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                hintText: 'My Awesome Project',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Template',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _templates.entries.map((entry) {
                final isSelected = _selectedTemplate == entry.key;
                final template = entry.value;

                return InkWell(
                  onTap: () => setState(() => _selectedTemplate = entry.key),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blueAccent.withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blueAccent
                            : Colors.white.withOpacity(0.1),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          template['icon'] as IconData,
                          size: 32,
                          color: isSelected ? Colors.blueAccent : Colors.white70,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          template['name'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_templates[_selectedTemplate] != null) ...[
              const SizedBox(height: 16),
              Text(
                _templates[_selectedTemplate]!['description'] as String,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white54,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _creating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _creating ? null : _create,
          child: _creating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project name')),
      );
      return;
    }

    setState(() => _creating = true);

    try {
      // Get template definition
      final template = ProjectTemplateService.getTemplate(_selectedTemplate);
      
      // Create project locally with LocalProjectLoader
      final manifest = await LocalProjectLoader.createLocalProject(
        name: name,
        templateId: _selectedTemplate,
        workspaceId: 'vyrevault-local', // Local workspace ID
        backgroundModule: template.backgroundModule,
        tools: template.tools,
        defaultBoards: template.defaultBoards,
      );

      if (!mounted) return;

      // Return manifest to caller
      Navigator.pop(context, manifest);
    } catch (e) {
      if (!mounted) return;

      setState(() => _creating = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating project: $e')),
      );
    }
  }
}
