import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/active_workspace_state.dart';
import '../../state/project_state.dart';
import '../modules/module_registry.dart';

/// Board tab strip for fast board switching within a project
class BoardTabs extends StatelessWidget {
  const BoardTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final activeWS = context.watch<ActiveWorkspaceState>();
    final project = activeWS.activeProject;
    final activeBoard = activeWS.activeBoard;

    if (project == null || project.boards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: project.boards.map((board) {
          final bool selected = board.id == activeBoard?.id;
          final moduleId = board.moduleId;

          return GestureDetector(
            onTap: () {
              context.read<ActiveWorkspaceState>().setActiveBoard(board);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected
                      ? Colors.blue.withOpacity(0.4)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconForModule(moduleId),
                    size: 16,
                    color: selected ? Colors.blue.shade300 : Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    board.name,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _iconForModule(ModuleId? id) {
    switch (id) {
      case ModuleId.infiniteCanvas:
        return Icons.edit;
      case ModuleId.whiteboard:
        return Icons.brush;
      case ModuleId.storyTimeline:
        return Icons.timeline;
      case ModuleId.graphCanvas:
        return Icons.hub;
      case ModuleId.standard:
      case null:
        return Icons.insert_drive_file;
    }
  }
}
