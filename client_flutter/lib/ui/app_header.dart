import 'dart:ui';

import 'package:flutter/material.dart';

import 'widgets/header/header_search_bar.dart';
import 'widgets/header/presence_selector.dart';
import 'widgets/header/workspace_switcher.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String currentWorkspace;
  final List<String> workspaces;
  final void Function(String)? onWorkspaceSelect;
  final VoidCallback? onCreateWorkspace;
  final UserPresence presence;
  final ValueChanged<UserPresence>? onPresenceChange;

  const AppHeader({
    super.key,
    required this.title,
    required this.currentWorkspace,
    required this.workspaces,
    this.onWorkspaceSelect,
    this.onCreateWorkspace,
    this.presence = UserPresence.online,
    this.onPresenceChange,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            border: const Border(
              bottom: BorderSide(
                color: Color.fromRGBO(255, 255, 255, 0.08),
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Left side: FLŌ logo
              WorkspaceSwitcher(
                currentWorkspace: currentWorkspace,
                workspaces: workspaces,
                onSelect: onWorkspaceSelect ?? (_) {},
                onCreateNew: onCreateWorkspace ?? () {},
              ),
              // Center: search bar
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 380,
                    child: const HeaderSearchBar(),
                  ),
                ),
              ),
              // Right side: Avatar menu with presence + settings
              PopupMenuButton<void>(
                color: const Color(0xFF0F0F0F),
                icon: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF0066FF),
                  child: Icon(Icons.person, size: 18, color: Colors.white),
                ),
                itemBuilder: (context) => [
                  // Status header
                  PopupMenuItem(
                    enabled: false,
                    child: Text(
                      'Status',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                  // Presence options
                  PopupMenuItem(
                    onTap: () => onPresenceChange?.call(UserPresence.online),
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                        SizedBox(width: 8),
                        Text('Online', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () => onPresenceChange?.call(UserPresence.away),
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: Colors.yellowAccent, size: 10),
                        SizedBox(width: 8),
                        Text('Away', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () => onPresenceChange?.call(UserPresence.busy),
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: Colors.orangeAccent, size: 10),
                        SizedBox(width: 8),
                        Text('Busy', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  PopupMenuDivider(),
                  // Settings
                  PopupMenuItem(
                    onTap: () {
                      Navigator.of(context).pushNamed('/settings');
                    },
                    child: Row(
                      children: [
                        Icon(Icons.settings, size: 18, color: Colors.white70),
                        SizedBox(width: 8),
                        Text('Settings', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

