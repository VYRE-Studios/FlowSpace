import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';
import '../constants/text_styles.dart';

/// Empty state shown when workspace has no projects
class WorkspaceEmptyState extends StatelessWidget {
  final VoidCallback onCreateProject;

  const WorkspaceEmptyState({
    super.key,
    required this.onCreateProject,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: AppSpacing.paddingXXL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: AppColors.textDisabled,
            ),
            AppSpacing.spaceVerticalXL,
            Text(
              'No projects yet',
              style: AppTextStyles.displaySmall,
              textAlign: TextAlign.center,
            ),
            AppSpacing.spaceVerticalMD,
            Text(
              'Create your first project to begin working in this workspace',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            AppSpacing.spaceVerticalXXL,
            ElevatedButton.icon(
              onPressed: onCreateProject,
              icon: const Icon(Icons.add),
              label: const Text('Create Project'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: AppSpacing.paddingLG,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
