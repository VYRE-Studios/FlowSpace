import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/tool_state.dart';

/// Tool palette for selecting canvas interaction tools
class ToolPalette extends StatelessWidget {
  const ToolPalette({super.key});

  @override
  Widget build(BuildContext context) {
    final tool = context.watch<ToolState>().activeTool;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ToolId.values.map((t) {
          final selected = t == tool;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: IconButton(
              onPressed: () {
                context.read<ToolState>().setActiveTool(t);
              },
              icon: Icon(
                _icon(t),
                color: selected ? Colors.blue.shade300 : Colors.white70,
                size: 20,
              ),
              tooltip: _label(t),
              splashRadius: 20,
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _icon(ToolId t) {
    switch (t) {
      case ToolId.pan:
        return Icons.open_with;
      case ToolId.draw:
        return Icons.brush;
      case ToolId.text:
        return Icons.text_fields;
      case ToolId.select:
        return Icons.radio_button_unchecked;
      case ToolId.erase:
        return Icons.layers_clear;
    }
  }

  String _label(ToolId t) {
    switch (t) {
      case ToolId.pan:
        return 'Pan (V)';
      case ToolId.draw:
        return 'Draw (D)';
      case ToolId.text:
        return 'Text (T)';
      case ToolId.select:
        return 'Select (S)';
      case ToolId.erase:
        return 'Erase (E)';
    }
  }
}
