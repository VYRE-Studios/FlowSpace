import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/tool_state.dart';
import '../../state/active_workspace_state.dart';
import '../../services/board_persistence_service.dart';

/// Story timeline background module for story projects
/// Features: timeline bars, zoom, scene markers, chronological view
class StoryTimelineModule extends StatefulWidget {
  const StoryTimelineModule({super.key});

  @override
  State<StoryTimelineModule> createState() => _StoryTimelineModuleState();
}

class _StoryTimelineModuleState extends State<StoryTimelineModule> {
  double zoom = 1.0;
  List<_SceneEvent> events = [
    _SceneEvent("Opening", 100),
    _SceneEvent("Inciting Incident", 300),
    _SceneEvent("Midpoint", 600)
  ];

  @override
  Widget build(BuildContext context) {
    final tool = context.watch<ToolState>().activeTool;
    final workspace = context.watch<ActiveWorkspaceState>();
    final canZoom = tool == ToolId.pan;

    return GestureDetector(
      onScaleUpdate: canZoom ? (details) {
        setState(() {
          zoom = details.scale.clamp(0.5, 2.5);
        });
      } : null,
      child: Container(
        color: const Color(0xFF1A1A1A),
        child: Stack(
          children: [
            Positioned.fill(child: _timelineBackground()),
            ...events.map((e) => _eventMarker(e)),
          ],
        ),
      ),
    );
  }

  Widget _timelineBackground() {
    return Container(
      color: Colors.black.withValues(alpha: 0.2),
      child: CustomPaint(
        painter: _TimelinePainter(zoom),
      ),
    );
  }

  Widget _eventMarker(_SceneEvent e) {
    return Positioned(
      left: e.position * zoom,
      top: 40,
      child: Draggable(
        feedback: _eventWidget(e),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() {
            e.position = details.offset.dx / zoom;
          });
          _autoSave(context.read<ActiveWorkspaceState>());
        },
        child: _eventWidget(e),
      ),
    );
  }

  Widget _eventWidget(_SceneEvent e) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        e.title,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

class _SceneEvent {
  String title;
  double position;
  _SceneEvent(this.title, this.position);
}

class _TimelinePainter extends CustomPainter {
  final double zoom;
  _TimelinePainter(this.zoom);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white24;

    for (double x = 0; x < size.width; x += 100 * zoom) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

extension on _StoryTimelineModuleState {
  void _autoSave(ActiveWorkspaceState workspace) {
    final project = workspace.activeProject;
    final board = workspace.activeBoard;
    
    if (project == null || board == null) return;

    BoardPersistenceService.saveBoardData(
      project.workspaceId,
      project.projectId,
      board.id,
      {
        'zoom': zoom,
        'events': events.map((e) => {
          'title': e.title,
          'position': e.position,
        }).toList(),
      },
    );
  }
}
