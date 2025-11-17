import 'dart:ui';

import 'package:flutter/material.dart';

import 'widgets/header/header_actions_menu.dart';
import 'widgets/header/header_search_bar.dart';
import 'widgets/header/presence_selector.dart';
import 'widgets/header/workspace_switcher.dart';
import '../../widgets/status/connection_status_indicator.dart';
import '../../widgets/status/presence_indicator.dart';
import '../../widgets/status/sync_status_badge.dart';

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
              // Left side: workspace switcher + title.
              WorkspaceSwitcher(
                currentWorkspace: currentWorkspace,
                workspaces: workspaces,
                onSelect: onWorkspaceSelect ?? (_) {},
                onCreateNew: onCreateWorkspace ?? () {},
              ),
              const SizedBox(width: 24),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              // Center-right: search bar.
              const HeaderSearchBar(),
              const SizedBox(width: 16),
              // Presence selector for the current user.
              PresenceSelector(
                current: presence,
                onChange: onPresenceChange ?? (_) {},
              ),
              const SizedBox(width: 16),
              // Floating status indicators: presence, connection quality, sync.
              PresenceIndicator(state: PresenceState.online),
              const SizedBox(width: 12),
              ConnectionStatusIndicator(
                ping: const Duration(milliseconds: 42),
                connected: true,
              ),
              const SizedBox(width: 12),
              SyncStatusBadge(status: SyncStatus.idle),
              const SizedBox(width: 16),
              HeaderActionsMenu(
                onCreateWorkspace: onCreateWorkspace ?? () {},
                onOpenSettings: () {
                  // Simple placeholder; can be replaced with a proper
                  // navigation callback from the shell.
                  Navigator.of(context).maybePop();
                },
              ),
              const SizedBox(width: 16),
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF0066FF),
                child: Icon(Icons.person, size: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

