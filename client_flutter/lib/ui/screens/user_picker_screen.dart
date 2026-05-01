import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../../core/theme/flo_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shell/app_shell.dart';
import '../../services/chat_integration_helper.dart';
import '../../services/analytics_service.dart';
import '../../services/error_logging_service.dart';

/// Simple user picker for testing chat without authentication
class UserPickerScreen extends StatelessWidget {
  const UserPickerScreen({super.key});

  static const List<String> testUsers = [
    'Joseph',
    'Christa',
    'Karen',
    'Pop',
    'User',
  ];

  Future<void> _selectUser(BuildContext context, String username) async {
    // Save selected user to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('test_user_name', username);
    await prefs.setString('test_user_id', username.toLowerCase());
    
    // Initialize chat services with selected user
    try {
      await ChatIntegrationHelper.initialize(
        userId: username.toLowerCase(),
        username: username,
      );
      
      AnalyticsService.instance.init(userId: username.toLowerCase());
      AnalyticsService.instance.track('app_started', properties: {
        'version': '2.0.0',
        'test_mode': true,
      });
      
      ErrorLoggingService.instance.info('Chat services initialized for test user: $username');
    } catch (e) {
      ErrorLoggingService.instance.error('Error initializing chat services', error: e);
    }
    
    // Navigate to main app shell
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AppShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.bgTop,
              AppColors.bgBottom,
            ],
          ),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Icon(
                  Icons.person_outline,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Who are you?',
                  textAlign: TextAlign.center,
                  style: FloTheme.displayMedium,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Select your name to test messaging',
                  textAlign: TextAlign.center,
                  style: FloTheme.bodySecondary,
                ),
                
                const SizedBox(height: 48),
                
                // User buttons
                ...testUsers.map((username) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _UserButton(
                    username: username,
                    onTap: () => _selectUser(context, username),
                  ),
                )),
                
                const SizedBox(height: 24),
                
                Text(
                  'Testing Mode - No authentication required',
                  textAlign: TextAlign.center,
                  style: FloTheme.caption.copyWith(
                    color: AppColors.textMeta,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserButton extends StatefulWidget {
  final String username;
  final VoidCallback onTap;

  const _UserButton({
    required this.username,
    required this.onTap,
  });

  @override
  State<_UserButton> createState() => _UserButtonState();
}

class _UserButtonState extends State<_UserButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.buttonSecondaryHover
                : AppColors.buttonSecondaryBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? AppColors.primary
                  : AppColors.buttonSecondaryBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    widget.username[0],
                    style: FloTheme.titleMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.username,
                  style: FloTheme.titleMedium.copyWith(
                    color: _isHovered
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: _isHovered
                    ? AppColors.primary
                    : AppColors.textMeta,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
