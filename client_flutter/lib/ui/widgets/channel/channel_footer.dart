import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../constants/colors.dart';

/// Footer bar with message composer for channels
class ChannelFooter extends StatelessWidget {
  const ChannelFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingHorizontalLG.copyWith(
        top: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          top: BorderSide(
            color: AppColors.borderSubtle,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: AppTextStyles.inputText,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: AppTextStyles.inputHint,
                filled: true,
                fillColor: AppColors.surfaceOverlay5,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                contentPadding: AppSpacing.paddingMD,
              ),
            ),
          ),
          AppSpacing.spaceHorizontalMD,
          IconButton(
            icon: Icon(Icons.send, color: AppColors.primary),
            onPressed: () {
              // Phase 4 message send integration in Step 4
            },
            tooltip: 'Send message',
          ),
        ],
      ),
    );
  }
}
