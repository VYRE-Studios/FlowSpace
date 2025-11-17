// update_to_flo_branding.dart
// Run this script to update all FlowSpace references to FLŌ

import 'package:flutter/material.dart';
import '../../core/theme/flo_theme.dart';
import '../../core/theme/flo_brand.dart';
import '../../ui/widgets/flo_components.dart';
import 'setup_user_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FloTheme.bgPure,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // FLŌ Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: FloTheme.floPrimary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'FLŌ',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Welcome text
              FloTheme.gradientText(
                'Welcome to FLŌ',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Tagline
              Text(
                'The Unified Operations Core',
                style: TextStyle(
                  fontSize: 16,
                  color: FloTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Feature tiles
              _FeatureTile(
                icon: FloIcons.chat,
                title: 'Real-time Chat',
                subtitle: 'Stay connected with your team',
              ),
              const SizedBox(height: 16),
              _FeatureTile(
                icon: FloIcons.video,
                title: 'Video Meetings',
                subtitle: 'Face-to-face collaboration',
              ),
              const SizedBox(height: 16),
              _FeatureTile(
                icon: FloIcons.vault,
                title: 'Secure Vault',
                subtitle: 'Share files safely',
              ),
              const SizedBox(height: 48),
              
              // Get Started button
              FloButton(
                text: 'Get Started',
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const SetupUserScreen(),
                    ),
                  );
                },
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
            gradient: FloTheme.floGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: FloTheme.textPrimary,
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