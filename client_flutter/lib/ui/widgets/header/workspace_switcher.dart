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
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        'FLŌ',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
    );
  }
}


