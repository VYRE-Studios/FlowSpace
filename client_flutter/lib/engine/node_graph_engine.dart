// lib/engine/node_graph_engine.dart

import 'package:flutter/material.dart';
import 'node_model.dart';

class NodeGraphEngine {
  final List<GraphNode> nodes = [];

  GraphNode createNode(Offset position, String label) {
    final node = GraphNode(
      id: UniqueKey().toString(),
      position: position,
      label: label,
    );
    nodes.add(node);
    return node;
  }

  void moveNode(String id, Offset newPosition) {
    final index = nodes.indexWhere((n) => n.id == id);
    if (index == -1) return;

    nodes[index] = nodes[index].moveTo(newPosition);
  }
}
