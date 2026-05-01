import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/project_state.dart';
import '../../state/tool_state.dart';
import '../../state/active_workspace_state.dart';
import '../../models/whiteboard/whiteboard_state.dart';
import '../widgets/whiteboard_toolbar.dart';
import '../../services/board_persistence_service.dart';

/// FLŌ Whiteboard module
/// Dark canvas, optional grid, pen strokes, draggable sticky notes.
class WhiteboardModule extends StatefulWidget {
  final bool useBlack; // true => #0D0D0D, false => #1E1E1E
  const WhiteboardModule({super.key, this.useBlack = false});

  @override
  State<WhiteboardModule> createState() => _WhiteboardModuleState();
}

class _WhiteboardModuleState extends State<WhiteboardModule> {
  bool _showGrid = true;

  @override
  Widget build(BuildContext context) {
    final projectState = context.watch<ProjectState>();
    final toolState = context.watch<ToolState>();
    final activeWorkspace = context.watch<ActiveWorkspaceState>();
    final WhiteboardState? state = projectState.whiteboardState;
    
    // Map global tool to whiteboard tool
    final String localTool = _mapGlobalToolToLocal(toolState.activeTool);

    // If state not yet loaded, show empty surface
    if (state == null) {
      return Container(color: widget.useBlack ? const Color(0xFF0D0D0D) : const Color(0xFF1E1E1E));
    }

    return Stack(children: [
      // Canvas surface with optional grid
      GestureDetector(
        onPanStart: (details) {
          if (localTool == 'pen') {
            state.startStroke(details.localPosition);
            setState(() {});
          }
        },
        onPanUpdate: (details) {
          if (localTool == 'pen') {
            state.extendStroke(details.localPosition);
            setState(() {});
          }
        },
        onPanEnd: (_) async {
          if (localTool == 'pen') {
            state.finishStroke();
            // Auto-save after stroke
            _autoSave(activeWorkspace, state);
          }
        },
        child: CustomPaint(
          painter: _WhiteboardPainter(state, bgBlack: widget.useBlack, showGrid: _showGrid),
          child: const SizedBox.expand(),
        ),
      ),

      // Sticky notes
      ...state.stickies.map((sticky) => Positioned(
            left: sticky.position.dx,
            top: sticky.position.dy,
            child: GestureDetector(
              onPanUpdate: (d) {
                sticky.position += d.delta;
                setState(() {});
              },
              onPanEnd: (_) {
                // Auto-save after moving sticky
                _autoSave(activeWorkspace, state);
              },
              child: Container(
                width: sticky.size.width,
                height: sticky.size.height,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: sticky.color, borderRadius: BorderRadius.circular(8)),
                child: Text(sticky.text, style: const TextStyle(color: Colors.black, fontSize: 14)),
              ),
            ),
          )),

      // Floating toolbar
      Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: WhiteboardToolbar(
            activeTool: localTool,
            showGrid: _showGrid,
            onToggleGrid: (v) => setState(() => _showGrid = v),
            onToolSelected: (t) {
              // Sync local tool selection back to global state
              final globalTool = _mapLocalToolToGlobal(t);
              toolState.setActiveTool(globalTool);
            },
            onAddSticky: () {
              state.addDefaultSticky(center: const Offset(400, 300));
              setState(() {});
              // Auto-save after adding sticky
              _autoSave(activeWorkspace, state);
            },
          ),
        ),
      ),
    ]);
  }

  String _mapGlobalToolToLocal(ToolId tool) {
    switch (tool) {
      case ToolId.pan:
        return 'hand';
      case ToolId.draw:
        return 'pen';
      case ToolId.text:
        return 'text';
      case ToolId.select:
        return 'select';
      case ToolId.erase:
        return 'eraser';
    }
  }

  ToolId _mapLocalToolToGlobal(String tool) {
    switch (tool) {
      case 'hand':
        return ToolId.pan;
      case 'pen':
        return ToolId.draw;
      case 'text':
        return ToolId.text;
      case 'select':
        return ToolId.select;
      case 'eraser':
        return ToolId.erase;
      default:
        return ToolId.select;
    }
  }

  void _autoSave(ActiveWorkspaceState workspace, WhiteboardState state) {
    final project = workspace.activeProject;
    final board = workspace.activeBoard;
    
    if (project == null || board == null) return;

    // Save whiteboard state to disk
    BoardPersistenceService.saveBoardData(
      project.workspaceId,
      project.projectId,
      board.id,
      {
        'stickies': state.stickies.map((s) => s.toJson()).toList(),
        'strokes': state.strokes.map((s) => s.toJson()).toList(),
      },
    );
  }
}

class _WhiteboardPainter extends CustomPainter {
  final WhiteboardState state;
  final bool bgBlack;
  final bool showGrid;
  _WhiteboardPainter(this.state, {required this.bgBlack, required this.showGrid});

  @override
  void paint(Canvas canvas, Size size) {
    // Background fill
    final bg = Paint()..color = bgBlack ? const Color(0xFF0D0D0D) : const Color(0xFF1E1E1E);
    canvas.drawRect(Offset.zero & size, bg);

    // Optional grid
    if (showGrid) {
      final gridPaint = Paint()
        ..color = const Color(0xFF2A2A2A)
        ..strokeWidth = 1;
      const spacing = 24.0;
      for (double x = 0; x <= size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    // Strokes
    for (final stroke in state.strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteboardPainter old) {
    return old.state != state || old.bgBlack != bgBlack || old.showGrid != showGrid;
  }
}
