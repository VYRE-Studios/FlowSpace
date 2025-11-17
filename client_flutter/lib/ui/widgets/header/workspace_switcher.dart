import 'package:flutter/material.dart';

/// Simple workspace switcher control for the header.
///
/// Currently uses a list of workspace names; it can be wired to richer
/// workspace models later without changing the header layout.
class WorkspaceSwitcher extends StatelessWidget {
  final String currentWorkspace;
  final List<String> workspaces;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreateNew;

  const WorkspaceSwitcher({
    super.key,
    required this.currentWorkspace,
    required this.workspaces,
    required this.onSelect,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentWorkspace,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            color: const Color(0xFF0F0F0F),
            onSelected: (value) {
              if (value == '__create_new') {
                onCreateNew();
              } else {
                onSelect(value);
              }
            },
            itemBuilder: (context) {
              return [
                for (final w in workspaces)
                  PopupMenuItem(
                    value: w,
                    child: Text(
                      w,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: '__create_new',
                  child: Text(
                    'Create New Workspace',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ];
            },
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}


