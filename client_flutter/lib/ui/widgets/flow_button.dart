import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../../core/theme/flo_theme.dart';

/// Unified FlowSpace button engine - Δ-PM2.C
/// Primary, secondary, icon, and ghost button styles with micro-motion
class FlowButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final FlowButtonStyle style;
  final double height;
  final double radius;
  final EdgeInsets padding;

  const FlowButton({
    super.key,
    this.label,
    this.icon,
    required this.onTap,
    required this.style,
    this.height = 38,
    this.radius = 22,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
  });

  const FlowButton.primary({
    super.key,
    required String label,
    required VoidCallback onTap,
  })  : label = label,
        icon = null,
        onTap = onTap,
        style = FlowButtonStyle.primary,
        height = 38,
        radius = 22,
        padding = const EdgeInsets.symmetric(horizontal: 20);

  const FlowButton.secondary({
    super.key,
    required String label,
    required VoidCallback onTap,
  })  : label = label,
        icon = null,
        onTap = onTap,
        style = FlowButtonStyle.secondary,
        height = 38,
        radius = 22,
        padding = const EdgeInsets.symmetric(horizontal: 20);

  const FlowButton.icon({
    super.key,
    required IconData icon,
    required VoidCallback onTap,
  })  : label = null,
        icon = icon,
        onTap = onTap,
        style = FlowButtonStyle.icon,
        height = 36,
        radius = 18,
        padding = const EdgeInsets.symmetric(horizontal: 14);

  const FlowButton.ghost({
    super.key,
    required String label,
    required VoidCallback onTap,
  })  : label = label,
        icon = null,
        onTap = onTap,
        style = FlowButtonStyle.ghost,
        height = 36,
        radius = 18,
        padding = const EdgeInsets.symmetric(horizontal: 16);

  @override
  State<FlowButton> createState() => _FlowButtonState();
}

class _FlowButtonState extends State<FlowButton>
    with SingleTickerProviderStateMixin {
  double hover = 0;
  double press = 0;

  @override
  Widget build(BuildContext context) {
    final style = widget.style;

    return MouseRegion(
      onEnter: (_) => setState(() => hover = 1),
      onExit: (_) => setState(() => hover = 0),
      child: GestureDetector(
        onTapDown: (_) => setState(() => press = 1),
        onTapUp: (_) => setState(() => press = 0),
        onTapCancel: () => setState(() => press = 0),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _bgColor(style, hover, press),
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(
              color: _borderColor(style, hover),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null)
                Padding(
                  padding: EdgeInsets.only(right: widget.label != null ? 8 : 0),
                  child: Icon(
                    widget.icon,
                    size: 18,
                    color: _textColor(style),
                  ),
                ),
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: _textStyle(style),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _bgColor(FlowButtonStyle style, double hover, double press) {
    if (style == FlowButtonStyle.primary) {
      if (press == 1) return AppColors.buttonPrimaryActive;
      if (hover == 1) return AppColors.buttonPrimaryHover;
      return AppColors.buttonPrimaryBg;
    }
    if (style == FlowButtonStyle.secondary) {
      if (press == 1) return AppColors.buttonSecondaryActive;
      if (hover == 1) return AppColors.buttonSecondaryHover;
      return AppColors.buttonSecondaryBg;
    }
    if (style == FlowButtonStyle.icon) {
      if (press == 1) return AppColors.buttonIconActive;
      if (hover == 1) return AppColors.buttonIconHover;
      return AppColors.buttonIconBg;
    }
    if (style == FlowButtonStyle.ghost) {
      if (press == 1) return AppColors.buttonGhostActive;
      if (hover == 1) return AppColors.buttonGhostHover;
      return AppColors.buttonGhostBg;
    }
    return Colors.transparent;
  }

  Color _borderColor(FlowButtonStyle style, double hover) {
    switch (style) {
      case FlowButtonStyle.primary:
        return AppColors.buttonPrimaryBorder;
      case FlowButtonStyle.secondary:
        return AppColors.buttonSecondaryBorder;
      case FlowButtonStyle.icon:
        return AppColors.buttonIconBorder;
      case FlowButtonStyle.ghost:
        return AppColors.buttonGhostBorder;
    }
  }

  Color _textColor(FlowButtonStyle style) {
    switch (style) {
      case FlowButtonStyle.primary:
        return AppColors.textPrimary;
      case FlowButtonStyle.secondary:
        return AppColors.textSecondary;
      case FlowButtonStyle.icon:
        return AppColors.textPrimary;
      case FlowButtonStyle.ghost:
        return AppColors.textSecondary;
    }
  }

  TextStyle _textStyle(FlowButtonStyle style) {
    return style == FlowButtonStyle.primary
        ? FloTheme.buttonPrimary
        : style == FlowButtonStyle.secondary
            ? FloTheme.buttonSecondary
            : FloTheme.buttonSecondary;
  }
}

enum FlowButtonStyle {
  primary,
  secondary,
  icon,
  ghost,
}
