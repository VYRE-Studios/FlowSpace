import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../../core/theme/flo_theme.dart';

/// Premium sidebar navigation item - Δ-PM2.A
/// Micro-motion animations, refined hover/active states
class SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem>
    with SingleTickerProviderStateMixin {
  double hover = 0.0;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.active;

    return MouseRegion(
      onEnter: (_) => setState(() => hover = 1.0),
      onExit: (_) => setState(() => hover = 0.0),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? AppColors.sidebarItemActive
                : hover > 0
                    ? AppColors.sidebarItemHover
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(
                widget.icon,
                size: 22,
                color: active
                    ? AppColors.accentBlue
                    : AppColors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: active
                    ? FloTheme.textSidebarActive
                    : FloTheme.textSidebar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
