import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommandItem {
  final String id;
  final String label;
  final String? description;
  final IconData icon;
  final VoidCallback onExecute;

  CommandItem({
    required this.id,
    required this.label,
    this.description,
    required this.icon,
    required this.onExecute,
  });
}

class CommandPalette extends StatefulWidget {
  final List<CommandItem> commands;

  const CommandPalette({
    super.key,
    required this.commands,
  });

  static void show(BuildContext context, List<CommandItem> commands) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => CommandPalette(commands: commands),
    );
  }

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  List<CommandItem> _filteredCommands = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _filteredCommands = widget.commands;
    _searchController.addListener(_filterCommands);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCommands() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCommands = widget.commands.where((cmd) {
        return cmd.label.toLowerCase().contains(query) ||
            (cmd.description?.toLowerCase().contains(query) ?? false);
      }).toList();
      _selectedIndex = 0;
    });
  }

  void _executeSelected() {
    if (_filteredCommands.isEmpty) return;
    final cmd = _filteredCommands[_selectedIndex];
    Navigator.of(context).pop();
    cmd.onExecute();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % _filteredCommands.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1 + _filteredCommands.length) %
            _filteredCommands.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      _executeSelected();
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKeyEvent,
      child: Center(
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSearchField(),
              if (_filteredCommands.isNotEmpty)
                Flexible(child: _buildCommandList()),
              if (_filteredCommands.isEmpty) _buildEmptyState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF808080), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Type a command...',
                hintStyle: TextStyle(color: Color(0xFF606060)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Text(
            'ESC',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _filteredCommands.length,
      itemBuilder: (context, index) {
        final cmd = _filteredCommands[index];
        final isSelected = index == _selectedIndex;

        return InkWell(
          onTap: () {
            setState(() => _selectedIndex = index);
            _executeSelected();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isSelected ? const Color(0xFF2A2A2A) : null,
            child: Row(
              children: [
                Icon(cmd.icon, size: 18, color: const Color(0xFF00A3FF)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cmd.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (cmd.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          cmd.description!,
                          style: const TextStyle(
                            color: Color(0xFF808080),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.keyboard_return,
                    size: 16,
                    color: Color(0xFF606060),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        'No commands found',
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 13,
        ),
      ),
    );
  }
}
