// lib/models/board_content.dart

import '../engine/stroke_model.dart';
import '../engine/node_model.dart';

class BoardContent {
  final List<Stroke> strokes;
  final List<GraphNode> nodes;

  BoardContent({
    required this.strokes,
    required this.nodes,
  });

  Map<String, dynamic> toJson() {
    return {
      'strokes': strokes.map((s) => s.toJson()).toList(),
      'nodes': nodes.map((n) => n.toJson()).toList(),
    };
  }

  static BoardContent empty() {
    return BoardContent(strokes: [], nodes: []);
  }

  static BoardContent fromJson(Map<String, dynamic> json) {
    return BoardContent(
      strokes: (json['strokes'] as List<dynamic>)
          .map((s) => Stroke.fromJson(s))
          .toList(),
      nodes: (json['nodes'] as List<dynamic>)
          .map((n) => GraphNode.fromJson(n))
          .toList(),
    );
  }
}
