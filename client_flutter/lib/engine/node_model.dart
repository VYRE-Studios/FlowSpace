// lib/engine/node_model.dart

import 'package:flutter/material.dart';

class GraphNode {
  final String id;
  final Offset position;
  final String label;

  GraphNode({
    required this.id,
    required this.position,
    required this.label,
  });

  GraphNode moveTo(Offset newPos) {
    return GraphNode(
      id: id,
      position: newPos,
      label: label,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': position.dx,
      'y': position.dy,
      'label': label,
    };
  }

  static GraphNode fromJson(Map<String, dynamic> json) {
    return GraphNode(
      id: json['id'],
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      label: json['label'],
    );
  }
}
