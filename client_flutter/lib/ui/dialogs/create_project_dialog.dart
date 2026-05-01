import 'package:flutter/material.dart';
import '../../services/project_templates_service.dart';
import '../../services/vault_storage_service.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/workspace_service.dart';
import '../../services/project_template_structures.dart';

class CreateProjectDialog extends StatefulWidget {
  final String? workspaceId;

  const CreateProjectDialog({super.key, this.workspaceId});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  
  List<ProjectTemplate> _templates = [];
  ProjectTemplate? _selectedTemplate;
  bool _loading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await ProjectTemplatesService.getTemplates();
      if (mounted) {
        setState(() {
          _templates = templates;
          _selectedTemplate = templates.isNotEmpty ? templates[0] : null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Title Bar
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0x22FFFFFF))),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Create New Project',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Choose a template and start building',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Content Area
                  Expanded(
                    child: Row(
                      children: [
                        // Left: Template List
                        Container(
                          width: 300,
                          decoration: const BoxDecoration(
                            border: Border(right: BorderSide(color: Color(0x22FFFFFF))),
                          ),
                          child: ListView.builder(
                            itemCount: _templates.length,
                            itemBuilder: (context, index) {
                              final template = _templates[index];
                              final isSelected = _selectedTemplate?.id == template.id;
                              
                              return Material(
                                color: isSelected 
                                    ? const Color(0xFF0066FF).withOpacity(0.2)
                                    : Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() => _selectedTemplate = template);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          color: isSelected 
                                              ? const Color(0xFF0066FF)
                                              : Colors.transparent,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          template.icon,
                                          style: const TextStyle(fontSize: 32),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                template.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                template.category,
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.5),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
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

                        // Right: Template Details
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: _selectedTemplate == null
                                ? const Center(child: Text('Select a template'))
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Template Name
                                      Row(
                                        children: [
                                          Text(
                                            _selectedTemplate!.icon,
                                            style: const TextStyle(fontSize: 48),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _selectedTemplate!.name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  _selectedTemplate!.category,
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.6),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Description
                                      Text(
                                        _selectedTemplate!.description,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Project Name Input
                                      const Text(
                                        'Project Name',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _nameController,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: 'Enter project name',
                                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.05),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Description Input
                                      const Text(
                                        'Description (Optional)',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _descController,
                                        style: const TextStyle(color: Colors.white),
                                        maxLines: 3,
                                        decoration: InputDecoration(
                                          hintText: _selectedTemplate!.description,
                                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.05),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Folder Structure Preview
                                      _buildFolderPreview(),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Bar
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _creating ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _creating ? null : _createProject,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0066FF),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: _creating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Create Project'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFolderPreview() {
    if (_selectedTemplate == null) return const SizedBox();
    
    final structure = ProjectTemplateStructure.getStructure(
      _selectedTemplate!.id,
      'Preview',
      null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Folder Structure',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...structure.folders.take(5).map((folder) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.folder, color: Color(0xFF0066FF), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      folder + '/',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              )),
              if (structure.folders.length > 5) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    '... ${structure.folders.length - 5} more',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Divider(color: Color(0x22FFFFFF)),
              const SizedBox(height: 8),
              Text(
                '${structure.files.length} starter files included',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _createProject() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project name')),
      );
      return;
    }

    setState(() => _creating = true);

    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception('Not logged in');

      // Get or create workspace
      String? workspaceId = widget.workspaceId;
      if (workspaceId == null || workspaceId.isEmpty) {
        final workspaces = await DatabaseService.getUserWorkspaces(user['id'] as String);
        if (workspaces.isEmpty) {
          final workspace = await WorkspaceService.createWorkspace(
            name: 'General',
            description: 'General workspace',
            workspaceType: 'project',
          );
          workspaceId = workspace['id'] as String;
        } else {
          workspaceId = workspaces.first['id'] as String;
        }
      }

      // Create project in database
      final projectId = DateTime.now().millisecondsSinceEpoch.toString();
      await DatabaseService.insertProject({
        'id': projectId,
        'workspace_id': workspaceId,
        'name': _nameController.text.trim(),
        'description': _descController.text.trim().isEmpty
            ? _selectedTemplate!.description
            : _descController.text.trim(),
        'project_type': _selectedTemplate!.category,
        'template_id': _selectedTemplate!.id,
        'status': 'active',
        'created_by': user['id'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Create local vault folder with template structure
      final projectPath = await VaultStorageService.createProjectVaultFolder(
        projectId: projectId,
        templateId: _selectedTemplate!.id,
        projectName: _nameController.text.trim(),
      );
      
      print('FlowSpace: Project created at $projectPath');

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating project: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }
}
