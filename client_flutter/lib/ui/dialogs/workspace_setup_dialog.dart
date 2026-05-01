import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/workspace_location_service.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../constants/spacing.dart';

/// Dialog to select workspace location on disk (shown once on first launch)
class WorkspaceSetupDialog extends StatefulWidget {
  const WorkspaceSetupDialog({super.key});

  /// Show dialog and return true if workspace was configured
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Must choose a location
      builder: (context) => const WorkspaceSetupDialog(),
    );
    return result ?? false;
  }

  @override
  State<WorkspaceSetupDialog> createState() => _WorkspaceSetupDialogState();
}

class _WorkspaceSetupDialogState extends State<WorkspaceSetupDialog> {
  String? _selectedPath;
  bool _isSelecting = false;

  Future<void> _selectFolder() async {
    setState(() => _isSelecting = true);

    try {
      final path = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose FlowSpace Workspace Location',
      );

      if (path != null) {
        setState(() {
          _selectedPath = path;
        });
      }
    } finally {
      setState(() => _isSelecting = false);
    }
  }

  Future<void> _confirm() async {
    if (_selectedPath == null) return;

    // Save workspace location and create folder structure
    await WorkspaceLocationService.setWorkspacePath(_selectedPath!);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Welcome to FlowSpace',
              style: AppTextStyles.displaySmall,
            ),
            AppSpacing.spaceVerticalMD,
            Text(
              'Choose where to store your FlowSpace workspace on this device. This will contain all your projects and files.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.spaceVerticalXL,

            // Selected path display
            if (_selectedPath != null) ...[
              Text(
                'Selected Location:',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.spaceVerticalXS,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundPrimary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.borderSubtle,
                  ),
                ),
                child: Text(
                  _selectedPath!,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              AppSpacing.spaceVerticalLG,
            ],

            // Choose folder button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSelecting ? null : _selectFolder,
                icon: _isSelecting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : const Icon(Icons.folder_open),
                label: Text(_selectedPath == null
                    ? 'Choose Folder'
                    : 'Choose Different Folder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedPath == null
                      ? AppColors.primary
                      : AppColors.backgroundTertiary,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            // Info text
            if (_selectedPath == null) ...[
              AppSpacing.spaceVerticalMD,
              Text(
                'Recommended: Choose a folder in your Documents or a dedicated workspace folder.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],

            // Confirm button
            if (_selectedPath != null) ...[
              AppSpacing.spaceVerticalLG,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedPath = null);
                    },
                    child: const Text('Cancel'),
                  ),
                  AppSpacing.spaceHorizontalMD,
                  ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
