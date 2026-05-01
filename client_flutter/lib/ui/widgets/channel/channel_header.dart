import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../constants/colors.dart';

/// Header bar for channel view with title and actions
class ChannelHeader extends StatelessWidget {
  final String? channelName;
  final List<Widget>? actions;

  const ChannelHeader({
    super.key,
    this.channelName,
    this.actions,
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
          const Icon(Icons.tag, color: Colors.white70, size: 20),
          AppSpacing.spaceHorizontalSM,
          Text(
            channelName ?? 'general',
            style: AppTextStyles.headingLarge,
          ),
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
