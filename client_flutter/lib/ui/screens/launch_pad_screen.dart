import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';
import '../constants/text_styles.dart';
import '../../services/api_client.dart';

/// LaunchPad screen shown when no workspaces exist
/// 
/// Guides new users to create their first workspace
class LaunchPadScreen extends StatefulWidget {
  final VoidCallback onWorkspaceCreated;

  const LaunchPadScreen({
    super.key,
    required this.onWorkspaceCreated,
  });

  @override
  State<LaunchPadScreen> createState() => _LaunchPadScreenState();
}

class _LaunchPadScreenState extends State<LaunchPadScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createWorkspace() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a workspace name')),
      );
      return;
    }

    setState(() => _creating = true);

    try {
      await ApiClient.post('/workspaces', body: {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'slug': _nameController.text.trim().toLowerCase().replaceAll(' ', '-'),
      });

      if (mounted) {
        widget.onWorkspaceCreated();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create workspace: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: AppSpacing.paddingXXL,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // FLŌ Logo
              Text(
                'FLŌ',
                style: AppTextStyles.displayLarge.copyWith(fontSize: 48),
                textAlign: TextAlign.center,
              ),
              AppSpacing.spaceVerticalXXL,
              
              // Welcome message
              Text(
                'Welcome to FlowSpace',
                style: AppTextStyles.displayMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacing.spaceVerticalMD,
              Text(
                'Create your first workspace to begin',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              AppSpacing.spaceVerticalXXL,

              // Workspace name input
              TextField(
                controller: _nameController,
                style: AppTextStyles.inputText,
                decoration: InputDecoration(
                  labelText: 'Workspace Name',
                  hintText: 'e.g., My Team, Personal Projects',
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
                ),
                onSubmitted: (_) => _createWorkspace(),
              ),
              AppSpacing.spaceVerticalLG,

              // Description input (optional)
              TextField(
                controller: _descriptionController,
                style: AppTextStyles.inputText,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'What is this workspace for?',
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
                ),
              ),
              AppSpacing.spaceVerticalXXL,

              // Create button
              ElevatedButton(
                onPressed: _creating ? null : _createWorkspace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: AppSpacing.paddingLG,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _creating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Create Workspace',
                        style: AppTextStyles.labelLarge.copyWith(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
