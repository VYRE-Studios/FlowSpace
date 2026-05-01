import 'package:flutter/material.dart';
import '../constants/spacing.dart';
import '../constants/text_styles.dart';
import '../constants/colors.dart';

/// Unified header widget for consistent top bars across FlowSpace
/// 
/// Provides standard back button, title, and optional action buttons
class AppHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBack;

  const AppHeader({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingHorizontalLG.copyWith(
        top: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderSubtle,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBack ?? () => Navigator.pop(context),
              tooltip: 'Back',
            ),
          if (showBackButton) AppSpacing.spaceHorizontalSM,
          Text(title, style: AppTextStyles.displaySmall),
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
