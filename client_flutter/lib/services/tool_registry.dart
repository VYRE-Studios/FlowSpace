import 'package:flutter/material.dart';

/// Tool module interface
abstract class ToolModule {
  String get id;
  String get name;
  IconData get icon;
  
  /// Enable the tool in the active workspace
  void enable();
  
  /// Disable the tool
  void disable();
  
  /// Get the tool's UI widget (toolbar, panel, etc.)
  Widget? getWidget();
}

/// Tool registry - maps tool IDs to implementations
class ToolRegistry {
  static final Map<String, ToolModule> _tools = {
    'canvas': CanvasTool(),
    'sticky-notes': StickyNotesTool(),
    'shapes': ShapesTool(),
    'characters': CharactersTool(),
    'plot': PlotTool(),
    'codex': CodexTool(),
    'timeline': TimelineTool(),
    'node-editor': NodeEditorTool(),
    'workflow-log': WorkflowLogTool(),
    'asset-tracker': AssetTrackerTool(),
    'milestones': MilestonesTool(),
    'idea-cards': IdeaCardsTool(),
    'kanban': KanbanTool(),
    'notes': NotesTool(),
    'chat': ChatTool(),
  };

  /// Get tool by ID
  static ToolModule? getTool(String toolId) {
    return _tools[toolId];
  }

  /// Get tools for a list of tool IDs
  static List<ToolModule> getToolsForIds(List<String> toolIds) {
    return toolIds
        .map((id) => _tools[id])
        .where((tool) => tool != null)
        .cast<ToolModule>()
        .toList();
  }

  /// Get all available tools
  static List<ToolModule> getAllTools() {
    return _tools.values.toList();
  }
}

// Tool implementations (stubs for now)

class CanvasTool implements ToolModule {
  @override
  String get id => 'canvas';
  @override
  String get name => 'Canvas';
  @override
  IconData get icon => Icons.brush;
  @override
  void enable() {}
  @override
  void disable() {}
  @override
  Widget? getWidget() => null;
}

class StickyNotesTool implements ToolModule {
  @override
  String get id => 'sticky-notes';
  @override
  String get name => 'Sticky Notes';
  @override
  IconData get icon => Icons.note;
  @override
  void enable() {}
  @override
  void disable() {}
  @override
  Widget? getWidget() => null;
}

class ShapesTool implements ToolModule {
  @override
  String get id => 'shapes';
  @override
  String get name => 'Shapes';
  @override
  IconData get icon => Icons.category;
  @override
  void enable() {}
  @override
  void disable() {}
  @override
  Widget? getWidget() => null;
}

class CharactersTool implements ToolModule {
  @override
  String get id => 'characters';
  @override
  String get name => 'Characters';
  @override
  IconData get icon => Icons.people;
  @override
  void enable() {}
  @override
  void disable() {}
  @override
  Widget? getWidget() => null;
}

class PlotTool implements ToolModule {
  @override
  String get id => 'plot';
  @override
  String get name => 'Plot';
  @override
  IconData get icon => Icons.auto_stories;
  @override
  void enable() {}
  @override
  void disable() {}
  @override
  Widget? getWidget() => null;
}

class CodexTool implements ToolModule {
  @override
  String get id => 'codex';
  @override
  String get name => 'Codex';
  @override
  IconData get icon => Icons.book;
  @override
  void enable() {}
  @override
  void disable() {}
  @override
  Widget? getWidget() => null;
}

class TimelineTool implements ToolModule {
  @override
  String get id => 'timeline';
  @override
  String get name => 'Timeline';
  @override
  IconData get icon => Icons.timeline;
  @override
  void enable() {}
  @override
  void disable() {}
  @override
  Widget? getWidget() => null;
}

class NodeEditorTool implements ToolModule {
  @override
  String get id => 'node-editor';
  @override
  String get name => 'Node Editor';
  @override
  IconData get icon => Icons.account_tree;
  @override
  void enable() {}
  @override
  void disable() {}
  @override
  Widget? getWidget() => null;
}

class WorkflowLogTool implements ToolModule {
  @override
  String get id => 'workflow-log';
  @override
  String get name => 'Workflow Log';
  @override
  IconData get icon => Icons.list;
  @override
  void enable() {}
  @override
  void disable() {}
  @override
  Widget? getWidget() => null;
}

class AssetTrackerTool implements ToolModule {
  @override
  String get id => 'asset-tracker';
  @override
  String get name => 'Asset Tracker';
  @override
  IconData get icon => Icons.inventory;
  @override
  void enable() {}
  @override
  void disable() {}
  @override
  Widget? getWidget() => null;
}

class MilestonesTool implements ToolModule {
  @override
  String get id => 'milestones';
  @override
  String get name => 'Milestones';
  @override
  IconData get icon => Icons.flag;
  @override
  void enable() {}
  @override
  void disable() {}
  @override
  Widget? getWidget() => null;
}

class IdeaCardsTool implements ToolModule {
  @override
  String get id => 'idea-cards';
  @override
  String get name => 'Idea Cards';
  @override
  IconData get icon => Icons.lightbulb;
  @override
  void enable() {}
  @override
  void disable() {}
  @override
  Widget? getWidget() => null;
}

class KanbanTool implements ToolModule {
  @override
  String get id => 'kanban';
  @override
  String get name => 'Kanban';
  @override
  IconData get icon => Icons.view_column;
  @override
  void enable() {}
  @override
  void disable() {}
  @override
  Widget? getWidget() => null;
}

class NotesTool implements ToolModule {
  @override
  String get id => 'notes';
  @override
  String get name => 'Notes';
  @override
  IconData get icon => Icons.note_alt;
  @override
  void enable() {}
  @override
  void disable() {}
  @override
  Widget? getWidget() => null;
}

class ChatTool implements ToolModule {
  @override
  String get id => 'chat';
  @override
  String get name => 'Chat';
  @override
  IconData get icon => Icons.chat;
  @override
  void enable() {}
  @override
  void disable() {}
  @override
  Widget? getWidget() => null;
}
