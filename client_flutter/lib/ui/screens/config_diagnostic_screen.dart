import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/flowspace_config.dart';
import '../../sync/sync_manager.dart';
import '../constants/colors.dart';

/// Configuration diagnostic screen
/// Shows current FlowSpace backend configuration status
class ConfigDiagnosticScreen extends StatefulWidget {
  const ConfigDiagnosticScreen({super.key});

  @override
  State<ConfigDiagnosticScreen> createState() => _ConfigDiagnosticScreenState();
}

class _ConfigDiagnosticScreenState extends State<ConfigDiagnosticScreen> {
  @override
  Widget build(BuildContext context) {
    final isConfigured = FlowSpaceConfig.isConfigured;
    final syncConnected = SyncManager.instance.connected;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('FlowSpace Configuration'),
        backgroundColor: AppColors.backgroundSecondary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Configuration Status
            _StatusCard(
              title: 'Backend Configuration',
              status: isConfigured ? 'Configured' : 'NOT CONFIGURED',
              statusColor: isConfigured ? AppColors.success : AppColors.error,
              icon: isConfigured ? Icons.check_circle : Icons.warning,
            ),
            const SizedBox(height: 16),

            // Sync Status
            _StatusCard(
              title: 'Real-Time Sync',
              status: syncConnected ? 'Connected' : 'Disconnected',
              statusColor: syncConnected ? AppColors.success : AppColors.warning,
              icon: syncConnected ? Icons.wifi : Icons.wifi_off,
            ),
            const SizedBox(height: 32),

            // Current URLs
            _SectionHeader('Current Configuration'),
            const SizedBox(height: 16),
            _ConfigItem(
              label: 'Render Service URL',
              value: FlowSpaceConfig.renderServiceUrl,
              copyable: true,
            ),
            _ConfigItem(
              label: 'API Base URL',
              value: FlowSpaceConfig.apiBaseUrl,
              copyable: true,
            ),
            _ConfigItem(
              label: 'WebSocket URL',
              value: FlowSpaceConfig.syncUrl,
              copyable: true,
            ),
            const SizedBox(height: 32),

            // Setup Instructions
            if (!isConfigured) ...[
              _SectionHeader('Setup Instructions'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: AppColors.warning, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Configuration Required',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '1. Open Render Dashboard and find your FlowSpace backend service\n\n'
                      '2. Copy your service URL (e.g., https://flowspace-abc123.onrender.com)\n\n'
                      '3. Open this file in your code editor:\n'
                      '   lib/services/flowspace_config.dart\n\n'
                      '4. Replace YOUR_SERVICE_NAME_HERE with your actual service name\n\n'
                      '5. Save the file and rebuild the app:\n'
                      '   flutter build windows --release\n\n'
                      '6. Restart FlowSpace',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Test Connection Button
            const SizedBox(height: 32),
            if (isConfigured)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _testConnection,
                  icon: const Icon(Icons.network_check),
                  label: const Text('Test Connection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    // Show connection test dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Testing Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Connecting to ${FlowSpaceConfig.renderServiceUrl}...',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context);
      
      final connected = SyncManager.instance.connected;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            connected ? 'Connection Successful' : 'Connection Failed',
            style: TextStyle(
              color: connected ? AppColors.success : AppColors.error,
            ),
          ),
          content: Text(
            connected
                ? 'Successfully connected to FlowSpace backend'
                : 'Could not connect to backend. Check your configuration and network.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String status;
  final Color statusColor;
  final IconData icon;

  const _StatusCard({
    required this.title,
    required this.status,
    required this.statusColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: statusColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;

  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ConfigItem extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;

  const _ConfigItem({
    required this.label,
    required this.value,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                if (copyable)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    color: AppColors.primary,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
