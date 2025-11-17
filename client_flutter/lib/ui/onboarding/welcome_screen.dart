import 'package:flutter/material.dart';
import '../../core/theme/flo_theme.dart';
import 'setup_user_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
              Container(
                decoration: BoxDecoration(
                  gradient: FloTheme.floGradient,
                  borderRadius: BorderRadius.circular(FloTheme.radiusMd),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const SetupUserScreen(),
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
                    'Get Started',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
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
