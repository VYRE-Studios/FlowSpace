// lib/modules/graph/graph_module.dart

import 'package:flutter/material.dart';
import '../../engine/node_graph_engine.dart';
import '../../engine/node_model.dart';
import '../../engine/canvas_events.dart';
import '../../models/board_content.dart';
import '../module_content_interface.dart';
import '../module_tool_interface.dart';

class GraphModule extends StatefulWidget {
  final NodeGraphEngine graphEngine;

  const GraphModule({
    super.key,
    required this.graphEngine,
  });

  @override
  State<GraphModule> createState() => _GraphModuleState();
}

class _GraphModuleState extends State<GraphModule>
    implements ModuleContentInterface, ModuleToolInterface {
  String? _draggingNodeId;

  @override
  BoardContent exportContent() {
    return BoardContent(
      strokes: [],
      nodes: [...widget.graphEngine.nodes],
    );
  }

  @override
  void importContent(BoardContent content) {
    widget.graphEngine.nodes
      ..clear()
      ..addAll(content.nodes);
    setState(() {});
  }

  @override
  void handleCanvasEvent(event) {
    // Graph module does not use stroke events, only pointer events
    if (event is CanvasPointerDown) {
      final hit = _hitTest(event.position);
      if (hit != null) {
        _draggingNodeId = hit.id;
      } else {
        widget.graphEngine.createNode(event.position, 'Node');
      }
    }

    if (event is CanvasPointerMove && _draggingNodeId != null) {
      widget.graphEngine.moveNode(_draggingNodeId!, event.position);
    }

    if (event is CanvasPointerUp) {
      _draggingNodeId = null;
    }

    setState(() {});
  }

  @override
  void setTool(String toolId) {
    // Tool selection for graph module
  }

  GraphNode? _hitTest(Offset point) {
    for (final node in widget.graphEngine.nodes) {
      final rect = Rect.fromCenter(
        center: node.position,
        width: 120,
        height: 40,
      );
      if (rect.contains(point)) return node;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        handleCanvasEvent(
          CanvasPointerDown(details.localPosition, 1.0),
        );
      },
      onPanUpdate: (details) {
        handleCanvasEvent(
          CanvasPointerMove(details.localPosition, 1.0),
        );
      },
      onPanEnd: (_) {
        handleCanvasEvent(
          CanvasPointerUp(Offset.zero),
        );
      },
      child: CustomPaint(
        painter: _GraphPainter(nodes: widget.graphEngine.nodes),
        child: Container(),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<GraphNode> nodes;

  _GraphPainter({required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2;

    for (final node in nodes) {
      final rect = Rect.fromCenter(
        center: node.position,
        width: 120,
        height: 40,
      );

      canvas.drawRect(rect, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: node.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          node.position.dx - textPainter.width / 2,
          node.position.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_GraphPainter oldDelegate) {
    return true;
  }
}
