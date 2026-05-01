import 'api_client.dart';

class ProjectTemplate {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final List<Map<String, dynamic>> defaultTasks;
  final List<String>? defaultChannels;

  ProjectTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.defaultTasks,
    this.defaultChannels,
  });

  factory ProjectTemplate.fromJson(Map<String, dynamic> json) {
    return ProjectTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      category: json['category'] as String,
      defaultTasks: (json['defaultTasks'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      defaultChannels: (json['defaultChannels'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}

class ProjectTemplatesService {
  static Future<List<ProjectTemplate>> getTemplates() async {
    try {
      final data = await ApiClient.get('/projects/templates');
      if (data is List) {
        return data.map((json) => ProjectTemplate.fromJson(json as Map<String, dynamic>)).toList();
      }
      return _getDefaultTemplates();
    } catch (e) {
      print('Error loading templates: $e');
      return _getDefaultTemplates();
    }
  }

  static Future<ProjectTemplate?> getTemplate(String templateId) async {
    try {
      final data = await ApiClient.get('/projects/templates/$templateId');
      if (data != null) {
        return ProjectTemplate.fromJson(data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error loading template: $e');
      return null;
    }
  }

  static List<ProjectTemplate> _getDefaultTemplates() {
    // Fallback templates if API fails
    return [
      ProjectTemplate(
        id: 'brainstorming-whiteboard',
        name: 'Brainstorming Whiteboard',
        description: 'Creative brainstorming and ideation project',
        icon: '🧠',
        category: 'Creative',
        defaultTasks: [
          {'title': 'Define Problem Space', 'status': 'todo', 'priority': 'high'},
          {'title': 'Initial Brainstorming', 'status': 'todo', 'priority': 'high'},
          {'title': 'Organize Ideas', 'status': 'backlog', 'priority': 'medium'},
        ],
      ),
      ProjectTemplate(
        id: 'workflow-automation',
        name: 'Workflow Automation',
        description: 'Build workflow automation tools (like a9n/n8n)',
        icon: '⚙️',
        category: 'Development',
        defaultTasks: [
          {'title': 'Node System Architecture', 'status': 'todo', 'priority': 'high'},
          {'title': 'Visual Editor', 'status': 'backlog', 'priority': 'high'},
          {'title': 'Execution Engine', 'status': 'backlog', 'priority': 'high'},
        ],
      ),
      ProjectTemplate(
        id: 'game-engine-ai',
        name: 'Game Engine with AI',
        description: 'Unreal Engine fork with AI integration',
        icon: '🎮',
        category: 'Development',
        defaultTasks: [
          {'title': 'Engine Fork Setup', 'status': 'todo', 'priority': 'high'},
          {'title': 'AI Integration', 'status': 'backlog', 'priority': 'high'},
          {'title': 'Blueprint AI Nodes', 'status': 'backlog', 'priority': 'high'},
        ],
      ),
      ProjectTemplate(
        id: 'story-building-software',
        name: 'Story Building Software',
        description: 'Creative writing and story development tool',
        icon: '📖',
        category: 'Creative',
        defaultTasks: [
          {'title': 'Story Structure System', 'status': 'todo', 'priority': 'high'},
          {'title': 'Character Management', 'status': 'todo', 'priority': 'high'},
          {'title': 'Writing Interface', 'status': 'backlog', 'priority': 'high'},
        ],
      ),
      ProjectTemplate(
        id: 'blank',
        name: 'Blank Project',
        description: 'Start with an empty project',
        icon: '📋',
        category: 'General',
        defaultTasks: [],
      ),
    ];
  }
}

