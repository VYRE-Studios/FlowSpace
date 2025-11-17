import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/whiteboard_service.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class WhiteboardView extends StatefulWidget {
  const WhiteboardView({super.key});

  @override
  State<WhiteboardView> createState() => _WhiteboardViewState();
}

class _WhiteboardViewState extends State<WhiteboardView> {
  String? _workspaceId;
  List<Map<String, dynamic>> _elements = [];
  bool _loading = true;
  String _currentTool = 'pen';
  Color _currentColor = Colors.blue;
  List<Offset> _currentStroke = [];

  @override
  void initState() {
    super.initState();
    _loadWorkspaceAndElements();
  }

  Future<void> _loadWorkspaceAndElements() async {
    setState(() => _loading = true);
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) return;

      final workspaces = await DatabaseService.getUserWorkspaces(user['id'] as String);
      if (workspaces.isEmpty) return;

      final workspace = workspaces.first;
      final elements = await WhiteboardService.getWorkspaceElements(workspace['id'] as String);

      if (!mounted) return;
      setState(() {
        _workspaceId = workspace['id'] as String;
        _elements = elements;
        _loading = false;
      });
    } catch (e) {
      print('Whiteboard: Error loading: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: GestureDetector(
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            onTapUp: _handleTapUp,
            child: CustomPaint(
              painter: WhiteboardPainter(_elements),
              child: Container(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 60,
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _toolButton(Icons.edit, 'pen', 'Pen'),
          const SizedBox(width: 8),
          _toolButton(Icons.sticky_note_2, 'note', 'Sticky Note'),
          const SizedBox(width: 8),
          _toolButton(Icons.text_fields, 'text', 'Text'),
          const SizedBox(width: 8),
          _toolButton(Icons.crop_square, 'rectangle', 'Rectangle'),
          const SizedBox(width: 16),
          _colorPicker(Colors.blue),
          _colorPicker(Colors.red),
          _colorPicker(Colors.green),
          _colorPicker(Colors.yellow),
          _colorPicker(Colors.purple),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white70),
            onPressed: _clearWhiteboard,
            tooltip: 'Clear All',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadWorkspaceAndElements,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _toolButton(IconData icon, String tool, String tooltip) {
    final isSelected = _currentTool == tool;
    return IconButton(
      icon: Icon(icon, color: isSelected ? const Color(0xFF0066FF) : Colors.white70),
      onPressed: () => setState(() => _currentTool = tool),
      tooltip: tooltip,
    );
  }

  Widget _colorPicker(Color color) {
    final isSelected = _currentColor == color;
    return GestureDetector(
      onTap: () => setState(() => _currentColor = color),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }

  void _handlePanStart(DragStartDetails details) {
    if (_currentTool == 'pen') {
      setState(() {
        _currentStroke = [details.localPosition];
      });
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_currentTool == 'pen') {
      setState(() {
        _currentStroke.add(details.localPosition);
      });
    }
  }

  Future<void> _handlePanEnd(DragEndDetails details) async {
    if (_currentTool == 'pen' && _currentStroke.isNotEmpty && _workspaceId != null) {
      final points = _currentStroke.map((offset) => {
        'x': offset.dx,
        'y': offset.dy,
      }).toList();

      await WhiteboardService.addStroke(
        workspaceId: _workspaceId!,
        points: points,
        color: '#${_currentColor.value.toRadixString(16).substring(2)}',
        strokeWidth: 2.0,
      );

      setState(() => _currentStroke = []);
      await _loadWorkspaceAndElements();
    }
  }

  Future<void> _handleTapUp(TapUpDetails details) async {
    if (_workspaceId == null) return;

    if (_currentTool == 'note') {
      await WhiteboardService.addStickyNote(
        workspaceId: _workspaceId!,
        x: details.localPosition.dx,
        y: details.localPosition.dy,
        content: 'New Note',
        color: '#${_currentColor.value.toRadixString(16).substring(2)}',
      );
      await _loadWorkspaceAndElements();
    } else if (_currentTool == 'text') {
      await WhiteboardService.addTextBox(
        workspaceId: _workspaceId!,
        x: details.localPosition.dx,
        y: details.localPosition.dy,
        content: 'Text',
      );
      await _loadWorkspaceAndElements();
    } else if (_currentTool == 'rectangle') {
      await WhiteboardService.addShape(
        workspaceId: _workspaceId!,
        shapeType: 'rectangle',
        x: details.localPosition.dx,
        y: details.localPosition.dy,
        width: 100,
        height: 100,
        color: '#${_currentColor.value.toRadixString(16).substring(2)}',
      );
      await _loadWorkspaceAndElements();
    }
  }

  Future<void> _clearWhiteboard() async {
    if (_workspaceId == null) return;
    await WhiteboardService.clearWorkspace(_workspaceId!);
    await _loadWorkspaceAndElements();
  }
}

class WhiteboardPainter extends CustomPainter {
  final List<Map<String, dynamic>> elements;

  WhiteboardPainter(this.elements);

  @override
  void paint(Canvas canvas, Size size) {
    for (final element in elements) {
      final type = element['element_type'] as String;
      final colorStr = element['color'] as String?;
      final color = colorStr != null ? Color(int.parse('0xFF${colorStr.substring(1)}')) : Colors.black;

      if (type == 'stroke') {
        _paintStroke(canvas, element, color);
      } else if (type == 'sticky_note') {
        _paintStickyNote(canvas, element, color);
      } else if (type == 'text') {
        _paintText(canvas, element);
      } else if (type == 'shape') {
        _paintShape(canvas, element, color);
      }
    }
  }

  void _paintStroke(Canvas canvas, Map<String, dynamic> element, Color color) {
    final data = jsonDecode(element['data'] as String) as Map<String, dynamic>;
    final points = (data['points'] as List).cast<Map<String, dynamic>>();
    final strokeWidth = data['strokeWidth'] as double? ?? 2.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = Offset(points[i]['x'] as double, points[i]['y'] as double);
      final p2 = Offset(points[i + 1]['x'] as double, points[i + 1]['y'] as double);
      canvas.drawLine(p1, p2, paint);
    }
  }

  void _paintStickyNote(Canvas canvas, Map<String, dynamic> element, Color color) {
    final x = element['x'] as double;
    final y = element['y'] as double;
    final data = jsonDecode(element['data'] as String) as Map<String, dynamic>;
    final content = data['content'] as String;
    final width = data['width'] as double? ?? 200;
    final height = data['height'] as double? ?? 200;

    final rect = Rect.fromLTWH(x, y, width, height);
    final paint = Paint()..color = color.withValues(alpha: 0.7);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);

    final textPainter = TextPainter(
      text: TextSpan(text: content, style: const TextStyle(color: Colors.black, fontSize: 14)),
      textDirection: TextDirection.ltr,
      maxLines: 10,
    );
    textPainter.layout(maxWidth: width - 16);
    textPainter.paint(canvas, Offset(x + 8, y + 8));
  }

  void _paintText(Canvas canvas, Map<String, dynamic> element) {
    final x = element['x'] as double;
    final y = element['y'] as double;
    final data = jsonDecode(element['data'] as String) as Map<String, dynamic>;
    final content = data['content'] as String;
    final fontSize = data['fontSize'] as double? ?? 16;

    final textPainter = TextPainter(
      text: TextSpan(text: content, style: TextStyle(color: Colors.black, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y));
  }

  void _paintShape(Canvas canvas, Map<String, dynamic> element, Color color) {
    final x = element['x'] as double;
    final y = element['y'] as double;
    final data = jsonDecode(element['data'] as String) as Map<String, dynamic>;
    final width = data['width'] as double;
    final height = data['height'] as double;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromLTWH(x, y, width, height);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(WhiteboardPainter oldDelegate) => true;
}
