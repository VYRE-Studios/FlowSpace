import 'package:flutter/material.dart';

class HeaderActionsMenu extends StatelessWidget {
  final VoidCallback onCreateWorkspace;
  final VoidCallback onOpenSettings;

  const HeaderActionsMenu({
    super.key,
    required this.onCreateWorkspace,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      color: const Color(0xFF0F0F0F),
      icon: const Icon(Icons.more_vert, color: Colors.white70),
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: onCreateWorkspace,
          child: const Text(
            'New Workspace',
            style: TextStyle(color: Colors.white),
          ),
        ),
        PopupMenuItem(
          onTap: () {
            // Navigate to settings (index 6 in shell)
            // We'll use a callback or Navigator to switch tabs
            onOpenSettings();
          },
          child: const Text(
            'Settings',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}


