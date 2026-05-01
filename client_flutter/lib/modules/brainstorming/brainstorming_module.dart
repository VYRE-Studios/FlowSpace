// lib/modules/brainstorming/brainstorming_module.dart

import 'package:flutter/material.dart';
import '../../engine/canvas_engine.dart';
import '../../engine/canvas_events.dart';
import '../../engine/stroke_model.dart';
import '../../models/board_content.dart';
import '../module_content_interface.dart';
import '../module_tool_interface.dart';

class BrainstormingModule extends StatefulWidget {
  final CanvasEngine canvasEngine;

  const BrainstormingModule({
    super.key,
    required this.canvasEngine,
  });

  @override
  State<BrainstormingModule> createState() => _BrainstormingModuleState();
}

class _BrainstormingModuleState extends State<BrainstormingModule>
    implements ModuleContentInterface, ModuleToolInterface {
  final GlobalKey _paintKey = GlobalKey();

  @override
  void handleCanvasEvent(CanvasEvent event) {
    widget.canvasEngine.handle(event);
    setState(() {});
  }

  @override
  void setTool(String toolId) {
    // Tool selection handled by canvas engine
  }

  @override
  BoardContent exportContent() {
    return BoardContent(
      strokes: [...widget.canvasEngine.strokeEngine.strokes],
      nodes: [],
    );
  }

  @override
  void importContent(BoardContent content) {
    widget.canvasEngine.strokeEngine.strokes
      ..clear()
      ..addAll(content.strokes);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        // Default pressure for gesture detector (stylus support requires Listener)
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
      child: RepaintBoundary(
        key: _paintKey,
        child: CustomPaint(
          painter: _BrainstormingPainter(
            strokes: widget.canvasEngine.strokeEngine.strokes,
            activeStroke: widget.canvasEngine.strokeEngine.activeStroke,
          ),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }
}

class _BrainstormingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? activeStroke;

  _BrainstormingPainter({
    required this.strokes,
    required this.activeStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }
    if (activeStroke != null) {
      _paintStroke(canvas, activeStroke!);
    }
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p1 = stroke.points[i].position;
      final p2 = stroke.points[i + 1].position;
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(_BrainstormingPainter oldDelegate) {
    return true;
  }
}
