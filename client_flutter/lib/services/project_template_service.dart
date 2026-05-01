/// Local-first project template definitions
/// These define how projects are structured and what tools they have
class TemplateDefinition {
  final String id;
  final String name;
  final String description;
  final String backgroundModule;
  final List<String> tools;
  final List<String> defaultBoards;

  const TemplateDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.backgroundModule,
    required this.tools,
    required this.defaultBoards,
  });
}

class ProjectTemplateService {
  static const Map<String, TemplateDefinition> _templates = {
    'brainstorm-lite': TemplateDefinition(
      id: 'brainstorm-lite',
      name: 'Brainstorming',
      description: 'Quick ideation and mind mapping',
      backgroundModule: 'infinite-canvas',
      tools: ['canvas', 'sticky-notes', 'shapes', 'connectors'],
      defaultBoards: ['Ideas', 'Organize'],
    ),
    'story': TemplateDefinition(
      id: 'story',
      name: 'Story Building',
      description: 'Narrative development and world building',
      backgroundModule: 'story-timeline',
      tools: ['characters', 'scenes', 'plot', 'worldbuilding', 'drafts'],
      defaultBoards: ['Characters', 'Scenes', 'Plot'],
    ),
    'whiteboard': TemplateDefinition(
      id: 'whiteboard',
      name: 'Whiteboard',
      description: 'Infinite canvas for visual thinking',
      backgroundModule: 'infinite-canvas',
      tools: ['canvas', 'sticky-notes', 'shapes', 'inks', 'connectors', 'images'],
      defaultBoards: ['Canvas', 'Exports'],
    ),
    'workflow': TemplateDefinition(
      id: 'workflow',
      name: 'Workflow Automation',
      description: 'Node-based automation pipelines',
      backgroundModule: 'graph-canvas',
      tools: ['node-editor', 'workflow-log', 'triggers', 'variables'],
      defaultBoards: ['Workflows', 'Nodes'],
    ),
    'game': TemplateDefinition(
      id: 'game',
      name: 'Game Project',
      description: 'Game development planning',
      backgroundModule: 'standard',
      tools: ['kanban', 'build-schedule', 'assets', 'git'],
      defaultBoards: ['Backlog', 'Sprint', 'Testing', 'Release'],
    ),
    'blank': TemplateDefinition(
      id: 'blank',
      name: 'Blank Project',
      description: 'General purpose workspace',
      backgroundModule: 'standard',
      tools: ['kanban', 'notes', 'files'],
      defaultBoards: ['Tasks'],
    ),
  };

  /// Get template definition by ID
  static TemplateDefinition getTemplate(String templateId) {
    return _templates[templateId] ?? _templates['blank']!;
  }

  /// Get all available templates
  static List<TemplateDefinition> getAllTemplates() {
    return _templates.values.toList();
  }

  /// Check if template exists
  static bool hasTemplate(String templateId) {
    return _templates.containsKey(templateId);
  }
}
