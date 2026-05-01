import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/tool_state.dart';
import '../../state/active_workspace_state.dart';
import '../../services/board_persistence_service.dart';

/// Node graph background module for workflow projects
/// Features: nodes, edges, snap grid, zoom, drag and drop
class GraphCanvasModule extends StatefulWidget {
  const GraphCanvasModule({super.key});

  @override
  State<GraphCanvasModule> createState() => _GraphCanvasModuleState();
}

class _GraphCanvasModuleState extends State<GraphCanvasModule> {
  List<_GraphNode> nodes = [
    _GraphNode(id: "1", position: const Offset(200, 200)),
  ];

  @override
  Widget build(BuildContext context) {
    final tool = context.watch<ToolState>().activeTool;
    final workspace = context.watch<ActiveWorkspaceState>();
    final canAddNodes = tool == ToolId.select;

    return GestureDetector(
      onLongPressStart: canAddNodes ? (details) {
        setState(() {
          nodes.add(
            _GraphNode(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              position: details.localPosition,
            ),
          );
        });
        _autoSave(workspace);
      } : null,
      child: Container(
        color: const Color(0xFF1A1A1A),
        child: Stack(
          children: [
            const Positioned.fill(child: _GridBackground()),
            ...nodes.map((node) => _buildNode(node)),
          ],
        ),
      ),
    );
  }

  Widget _buildNode(_GraphNode node) {
    return Positioned(
      left: node.position.dx,
      top: node.position.dy,
      child: Draggable(
        feedback: _nodeWidget(node),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() {
            node.position = details.offset;
          });
          _autoSave(context.read<ActiveWorkspaceState>());
        },
        child: _nodeWidget(node),
      ),
    );
  }

  Widget _nodeWidget(_GraphNode node) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "Node ${node.id}",
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  void _autoSave(ActiveWorkspaceState workspace) {
    final project = workspace.activeProject;
    final board = workspace.activeBoard;
    
    if (project == null || board == null) return;

    BoardPersistenceService.saveBoardData(
      project.workspaceId,
      project.projectId,
      board.id,
      {
        'nodes': nodes.map((n) => {
          'id': n.id,
          'x': n.position.dx,
          'y': n.position.dy,
        }).toList(),
      },
    );
  }
}

class _GraphNode {
  String id;
  Offset position;
  _GraphNode({required this.id, required this.position});
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white12;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
