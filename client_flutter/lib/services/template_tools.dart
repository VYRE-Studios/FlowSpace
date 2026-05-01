class TemplateTools {
  // Define folder structures for each template
  static Map<String, List<String>> getFolderStructure(String templateId) {
    switch (templateId) {
      case 'whiteboard':
      case 'brainstorm-lite':
        return {
          'root': ['Boards', 'Exports', 'Images']
        };
      
      case 'story':
        return {
          'root': ['Characters', 'Scenes', 'Drafts', 'Worldbuilding', 'Research']
        };
      
      case 'game':
        return {
          'root': ['Assets', 'Builds', 'Documentation', 'Source']
        };
      
      case 'workflow':
        return {
          'root': ['Workflows', 'Logs', 'Config']
        };
      
      case 'blank':
      default:
        return {
          'root': ['Files', 'Notes']
        };
    }
  }

  // Get tools available for each template
  static List<String> getTools(String templateId) {
    switch (templateId) {
      case 'whiteboard':
      case 'brainstorm-lite':
        return ['canvas', 'sticky-notes', 'shapes', 'inks', 'connectors', 'images'];
      
      case 'story':
        return ['characters', 'plot', 'timeline', 'worldbuilding', 'scenes', 'drafts'];
      
      case 'game':
        return ['kanban', 'build-schedule', 'assets', 'api-panel', 'git'];
      
      case 'workflow':
        return ['node-editor', 'workflow-log', 'triggers', 'variables'];
      
      case 'blank':
      default:
        return ['kanban', 'notes', 'files'];
    }
  }

  // Get background module for template
  static String getBackgroundModule(String templateId) {
    switch (templateId) {
      case 'whiteboard':
      case 'brainstorm-lite':
        return 'infinite-canvas';
      
      case 'story':
        return 'story-timeline';
      
      case 'workflow':
        return 'graph-canvas';
      
      case 'game':
      case 'blank':
      default:
        return 'standard';
    }
  }

  // Get template display name
  static String getTemplateName(String templateId) {
    switch (templateId) {
      case 'whiteboard':
        return 'Whiteboard';
      case 'brainstorm-lite':
        return 'Brainstorm';
      case 'story':
        return 'Story Building';
      case 'game':
        return 'Game Project';
      case 'workflow':
        return 'Workflow Automation';
      case 'blank':
        return 'Blank Project';
      default:
        return 'Project';
    }
  }
  
  // Get template icon
  static String getTemplateIcon(String templateId) {
    switch (templateId) {
      case 'whiteboard':
      case 'brainstorm-lite':
        return '📋';
      case 'story':
        return '📖';
      case 'game':
        return '🎮';
      case 'workflow':
        return '⚙️';
      case 'blank':
        return '📁';
      default:
        return '📦';
    }
  }
}
