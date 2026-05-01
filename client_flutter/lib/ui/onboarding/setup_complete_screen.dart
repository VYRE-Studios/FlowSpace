import 'package:flutter/material.dart';
import '../../core/theme/flo_theme.dart';
import '../shell/workspace_shell.dart';

class SetupCompleteScreen extends StatelessWidget {
  final String teamName;
  final String userName;

  const SetupCompleteScreen({
    super.key,
    required this.teamName,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              const Icon(
                Icons.check_circle,
                size: 80,
                color: Color(0xFF10B981),
              ),
              const SizedBox(height: 24),
              const Text(
                '🎉 You\'re All Set!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome to FLŌ, $userName!',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              _SetupItem(
                icon: Icons.groups,
                title: 'Team Created',
                subtitle: teamName,
              ),
              const SizedBox(height: 16),
              const _SetupItem(
                icon: Icons.tag,
                title: 'Default Channels',
                subtitle: '#general, #random',
              ),
              const SizedBox(height: 16),
              const _SetupItem(
                icon: Icons.folder,
                title: 'Vault Space',
                subtitle: 'Ready for file sharing',
              ),
              
              const SizedBox(height: 48),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: FloTheme.floPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(FloTheme.radiusLg),
                  border: Border.all(color: FloTheme.floPrimary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: FloTheme.floPrimary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Quick Tips',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: FloTheme.floPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _TipItem('Chat with your team in real-time'),
                    _TipItem('Share files securely in the Vault'),
                    _TipItem('Start video meetings anytime'),
                    _TipItem('Invite team members to collaborate'),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const WorkspaceShell(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: FloTheme.floPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FloTheme.radiusMd),
                  ),
                ),
                child: const Text(
                  'Enter FLŌ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

class _SetupItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SetupItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FloTheme.floPrimary.withOpacity(0.2),
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check, color: Color(0xFF10B981), size: 20),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;

  const _TipItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.arrow_forward, size: 16, color: FloTheme.floPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
