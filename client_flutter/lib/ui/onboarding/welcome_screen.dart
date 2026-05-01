import 'package:flutter/material.dart';
import '../../core/theme/flo_theme.dart';
import '../../services/server_config_service.dart';
import '../../services/api_client.dart';
import '../../core/chat_core.dart';
import '../../services/app_reset_service.dart';
import '../../services/realtime/socket_service.dart';
import 'setup_user_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Server Settings Button (top right)
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.settings, color: FloTheme.textSecondary),
                  tooltip: 'Server Settings',
                  onPressed: () => _showServerSettingsDialog(context),
                ),
              ),
              const SizedBox(height: 8),
              // FLŌ Logo Text with Gradient
              ShaderMask(
                shaderCallback: (bounds) => FloTheme.floGradient.createShader(bounds),
                child: const Text(
                  'FLŌ',
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Teams. Unified.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: FloTheme.textSecondary,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              const Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'The local-first team collaboration platform',
                style: TextStyle(
                  fontSize: 16,
                  color: FloTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              const _FeatureTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Real-time Chat',
                subtitle: 'Stay connected with your team',
              ),
              const SizedBox(height: 16),
              const _FeatureTile(
                icon: Icons.videocam_rounded,
                title: 'Video Meetings',
                subtitle: 'Face-to-face collaboration',
              ),
              const SizedBox(height: 16),
              const _FeatureTile(
                icon: Icons.folder_rounded,
                title: 'Secure Vault',
                subtitle: 'Zero-knowledge encryption',
              ),
              const SizedBox(height: 48),
              // Log In Button
              Container(
                decoration: BoxDecoration(
                  gradient: FloTheme.floGradient,
                  borderRadius: BorderRadius.circular(FloTheme.radiusMd),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FloTheme.radiusMd),
                    ),
                  ),
                  child: const Text(
                    'Log In',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Create Account Button
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const SetupUserScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: FloTheme.floPrimary,
                  side: BorderSide(color: FloTheme.floPrimary, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FloTheme.radiusMd),
                  ),
                ),
                child: const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showServerSettingsDialog(BuildContext context) async {
    final configService = ServerConfigService.instance;
    final currentUrl = await configService.getServerBaseUrl();
    final controller = TextEditingController(text: currentUrl);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the server address:',
              style: TextStyle(fontSize: 14, color: FloTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Server URL',
                hintText: 'http://localhost:4000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FloTheme.radiusMd),
                ),
                prefixIcon: const Icon(Icons.dns),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Example: http://10.5.0.2:4000 or http://192.168.1.100:4000',
              style: TextStyle(
                fontSize: 12,
                color: FloTheme.textSecondary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            // Reset App Button - Prominent placement
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 1.5),
                borderRadius: BorderRadius.circular(FloTheme.radiusMd),
              ),
              child: TextButton.icon(
                onPressed: () async {
                  // Reset app to clear all cached data
                  await AppResetService.resetConnection();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('App reset! Now using Railway production server.'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.refresh, color: Colors.orange),
                label: const Text(
                  'Reset App (Clear Cache & Use Railway)',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                final success = await configService.setServerBaseUrl(url);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Server URL updated to: $url'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Clear caches in API client and socket service
                    ApiClient.clearCache();
                    SocketService.instance.clearCache();
                    // Note: ChatCore instances manage their own cache per instance
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to save server URL'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FloTheme.floPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(FloTheme.radiusMd),
          ),
          child: Icon(icon, color: FloTheme.floPrimary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: FloTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
