import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Base card component - Δ-PM2.B Card Refinement
/// Engineered carbon panel with micro-motion and refined shadows
class BaseCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool hoverLift;

  const BaseCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.hoverLift = true,
  });

  @override
  State<BaseCard> createState() => _BaseCardState();
}

class _BaseCardState extends State<BaseCard>
    with SingleTickerProviderStateMixin {
  double hover = 0.0;

  @override
  Widget build(BuildContext context) {
    final canHover = widget.onTap != null && widget.hoverLift;

    return MouseRegion(
      onEnter: (_) {
        if (canHover) setState(() => hover = 1.0);
      },
      onExit: (_) {
        if (canHover) setState(() => hover = 0.0);
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: hover > 0 ? 1.02 : 1.0,
        curve: Curves.easeOut,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: AppColors.bgCardPrimary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderCard,
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowLow,
                  blurRadius: 6,
                  spreadRadius: 0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
