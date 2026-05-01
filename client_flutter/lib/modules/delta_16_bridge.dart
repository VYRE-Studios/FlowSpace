// lib/modules/delta_16_bridge.dart

import 'package:flutter/material.dart';
import '../engine/canvas_engine.dart';
import '../engine/stroke_engine.dart';
import '../engine/node_graph_engine.dart';
import 'brainstorming/brainstorming_module.dart';
import 'graph/graph_module.dart';
import 'story/story_module.dart';

/// Bridge to integrate Δ-16 modules into FlowSpace's existing architecture
/// This allows testing new engine-based modules alongside existing modules
class Delta16Bridge {
  /// Create Δ-16 module instances with proper engine initialization
  static Widget createModule(String moduleId) {
    switch (moduleId) {
      case 'delta16_brainstorming':
        return BrainstormingModule(
          canvasEngine: CanvasEngine(strokeEngine: StrokeEngine()),
        );

      case 'delta16_graph':
        return GraphModule(
          graphEngine: NodeGraphEngine(),
        );

      case 'delta16_story':
        return StoryModule();

      default:
        return Container(
          color: const Color(0xFF1A1A1A),
          child: Center(
            child: Text(
              'Δ-16 Module: $moduleId\nNot yet implemented',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        );
    }
  }

  /// Check if a module ID is a Δ-16 module
  static bool isDelta16Module(String? moduleId) {
    if (moduleId == null) return false;
    return moduleId.startsWith('delta16_');
  }
}
