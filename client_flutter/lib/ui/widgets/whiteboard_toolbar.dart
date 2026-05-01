import 'package:flutter/material.dart';

class WhiteboardToolbar extends StatelessWidget {
  final String activeTool;
  final bool showGrid;
  final ValueChanged<String> onToolSelected;
  final ValueChanged<bool> onToggleGrid;
  final VoidCallback onAddSticky;

  const WhiteboardToolbar({
    super.key,
    required this.activeTool,
    required this.showGrid,
    required this.onToolSelected,
    required this.onToggleGrid,
    required this.onAddSticky,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_ToolItem>[
      _ToolItem('select', Icons.near_me_outlined),
      _ToolItem('hand', Icons.pan_tool_alt_outlined),
      _ToolItem('pen', Icons.brush_outlined),
      _ToolItem('text', Icons.text_fields),
      _ToolItem('shape', Icons.crop_square),
      _ToolItem('eraser', Icons.auto_fix_off),
    ];

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF121212).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final it in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: IconButton(
                  onPressed: () => onToolSelected(it.id),
                  icon: Icon(it.icon,
                      color: activeTool == it.id ? const Color(0xFF0066FF) : Colors.white70),
                  tooltip: it.id,
                ),
              ),
            const Divider(height: 16, color: Colors.white24),
            IconButton(
              onPressed: onAddSticky,
              tooltip: 'Add sticky',
              icon: const Icon(Icons.note_outlined, color: Color(0xFFFFD54F)),
            ),
            IconButton(
              onPressed: () => onToggleGrid(!showGrid),
              tooltip: 'Toggle grid',
              icon: Icon(showGrid ? Icons.grid_on : Icons.grid_off, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolItem {
  final String id;
  final IconData icon;
  _ToolItem(this.id, this.icon);
}
