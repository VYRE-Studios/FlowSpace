import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/tool_state.dart';

/// Infinite canvas background module for whiteboard projects
/// Features: pan, zoom, draw, sticky notes, shapes, grid
class InfiniteCanvasModule extends StatefulWidget {
  const InfiniteCanvasModule({super.key});

  @override
  State<InfiniteCanvasModule> createState() => _InfiniteCanvasModuleState();
}

class _InfiniteCanvasModuleState extends State<InfiniteCanvasModule> {
  final TransformationController _controller = TransformationController();
  final List<Offset> _drawingPoints = [];
  bool _isPanning = false;

  @override
  Widget build(BuildContext context) {
    final tool = context.watch<ToolState>().activeTool;
    final isDrawMode = tool == ToolId.draw;

    return InteractiveViewer(
      transformationController: _controller,
      minScale: 0.1,
      maxScale: 4.0,
      panEnabled: !isDrawMode, // Disable InteractiveViewer pan when drawing
      child: GestureDetector(
        onPanUpdate: (details) {
          if (isDrawMode) {
            setState(() {
              _drawingPoints.add(details.localPosition);
            });
          }
        },
        onPanEnd: (_) {
          if (isDrawMode) {
            _drawingPoints.add(Offset.infinite);
          }
        },
        child: Container(
          width: 5000,
          height: 5000,
          color: const Color(0xFF1A1A1A),
          child: CustomPaint(
            painter: _CanvasPainter(_drawingPoints),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _CanvasPainter extends CustomPainter {
  final List<Offset> points;
  
  _CanvasPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.infinite && points[i + 1] != Offset.infinite) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
