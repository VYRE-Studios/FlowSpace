import 'package:flutter/widgets.dart';
import 'infinite_canvas_module.dart';
import 'whiteboard_module.dart';
import 'story_timeline_module.dart';
import 'graph_canvas_module.dart';
import 'standard_module.dart';
import '../../modules/delta_16_bridge.dart';

/// Module identifiers for background and board modules
enum ModuleId {
  infiniteCanvas,
  whiteboard,
  storyTimeline,
  graphCanvas,
  standard,
}

/// Registry for mapping module strings to ModuleId and building widgets
class ModuleRegistry {
  /// Parse module ID string from manifest
  static ModuleId? fromString(String? id) {
    if (id == null) return null;
    
    switch (id) {
      case 'infinite_canvas':
      case 'infinite-canvas':
        return ModuleId.infiniteCanvas;
      case 'whiteboard':
        return ModuleId.whiteboard;
      case 'story_timeline':
      case 'story-timeline':
        return ModuleId.storyTimeline;
      case 'graph_canvas':
      case 'graph-canvas':
        return ModuleId.graphCanvas;
      case 'standard':
        return ModuleId.standard;
      default:
        return null;
    }
  }

  /// Build background module widget
  /// Background stays constant when switching boards within a project
  static Widget buildBackground(ModuleId? moduleId) {
    switch (moduleId) {
      case ModuleId.infiniteCanvas:
        return const InfiniteCanvasModule();
      case ModuleId.whiteboard:
        return const WhiteboardModule();
      case ModuleId.storyTimeline:
        return const StoryTimelineModule();
      case ModuleId.graphCanvas:
        return const GraphCanvasModule();
      case ModuleId.standard:
      case null:
        return const StandardModule();
    }
  }

  /// Build Δ-16 module by string ID (for testing new engine-based modules)
  static Widget? buildDelta16Module(String? moduleId) {
    if (moduleId == null || !Delta16Bridge.isDelta16Module(moduleId)) {
      return null;
    }
    return Delta16Bridge.createModule(moduleId);
  }

  /// Build main content module widget
  /// Main module changes when user switches boards
  static Widget buildMain(ModuleId? moduleId) {
    // For now, main and background use same widgets
    // Future: boards may have different module implementations
    return buildBackground(moduleId);
  }
}
