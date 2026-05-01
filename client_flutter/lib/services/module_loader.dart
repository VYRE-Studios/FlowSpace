import 'package:flutter/material.dart';
import '../ui/modules/infinite_canvas_module.dart';
import '../ui/modules/story_timeline_module.dart';
import '../ui/modules/graph_canvas_module.dart';
import '../ui/modules/standard_module.dart';
import '../ui/modules/whiteboard_module.dart';

/// Module loader - selects background module based on template type
class ModuleLoader {
  /// Load background module widget based on module ID
  static Widget loadBackgroundModule(String? moduleType) {
    if (moduleType == null) {
      return const StandardModule();
    }

    switch (moduleType) {
      case 'whiteboard':
      case 'infinite-canvas':
        // Use the FLŌ whiteboard (dark canvas) for whiteboard/infinite canvas
        return const WhiteboardModule();
      case 'story-timeline':
        return const StoryTimelineModule();
      case 'node-graph':
      case 'graph-canvas':
        return const GraphCanvasModule();
      case 'clean-surface':
      case 'light-canvas':
      case 'clean':
        return const StandardModule();
      default:
        // Unknown module type, fallback to standard
        return const StandardModule();
    }
  }

  /// Get module display name for UI
  static String getModuleName(String moduleType) {
    const names = {
      'infinite-canvas': 'Infinite Canvas',
      'story-timeline': 'Story Timeline',
      'node-graph': 'Node Graph',
      'graph-canvas': 'Graph Canvas',
      'clean-surface': 'Clean Surface',
      'light-canvas': 'Light Canvas',
      'clean': 'Standard',
    };
    return names[moduleType] ?? moduleType;
  }

  /// Get module icon for UI
  static IconData getModuleIcon(String moduleType) {
    const icons = {
      'infinite-canvas': Icons.brush,
      'story-timeline': Icons.timeline,
      'node-graph': Icons.account_tree,
      'graph-canvas': Icons.device_hub,
      'clean-surface': Icons.dashboard,
      'light-canvas': Icons.lightbulb_outline,
      'clean': Icons.dashboard_outlined,
    };
    return icons[moduleType] ?? Icons.dashboard;
  }
}
