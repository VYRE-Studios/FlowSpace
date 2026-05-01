import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../constants/colors.dart';
import '../../../state/channel_context.dart';
import '../../../state/active_workspace_state.dart';

/// Main sidebar for workspace navigation
class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.backgroundSecondary,
      child: Column(
        children: [
          AppSpacing.spaceVerticalXL,
          Text(
            'FLŌ',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.spaceVerticalXL,
          Expanded(
            child: Consumer2<ChannelContext, ActiveWorkspaceState>(
              builder: (context, channelContext, workspaceState, _) {
                final project = workspaceState.activeProject;
                final channels = channelContext.channels;
                final activeChannelId = channelContext.activeChannelId;

                if (project == null) {
                  return Center(
                    child: Text(
                      'No project active',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled),
                    ),
                  );
                }

                return ListView(
                  padding: AppSpacing.paddingHorizontalSM,
                  children: [
                    // Project name
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        project.name.toUpperCase(),
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.textDisabled,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AppSpacing.spaceVerticalMD,
                    // Channels section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'CHANNELS',
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.textDisabled,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...channels.map((channel) => _SidebarItem(
                      icon: Icons.tag,
                      label: channel.name,
                      isActive: channel.channelId == activeChannelId,
                      onTap: () => channelContext.setActiveChannel(channel.channelId),
                    )),
                    AppSpacing.spaceVerticalMD,
                    // Boards section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'BOARDS',
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.textDisabled,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...project.boards.map((board) => _SidebarItem(
                      icon: Icons.space_dashboard_outlined,
                      label: board.name,
                      isActive: workspaceState.activeBoard?.id == board.id,
                      onTap: () => workspaceState.setActiveBoard(board),
                    )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: widget.isActive 
              ? AppColors.primary.withValues(alpha: 0.2)
              : (_isHovered ? AppColors.hoverOverlay : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: Icon(
            widget.icon,
            color: widget.isActive ? AppColors.primary : Colors.white70,
            size: 20,
          ),
          title: Text(
            widget.label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: widget.isActive ? AppColors.primary : Colors.white70,
              fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          onTap: widget.onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
