import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/update_service.dart';
import '../../services/user_service.dart';
import '../../services/workspace_service.dart';
import '../../services/vault_storage_service.dart';
import '../../services/secure_storage_service.dart';
import '../../services/database_credential_service.dart';
import '../../services/server_config_service.dart';
import 'database_settings_view.dart';
import '../onboarding/welcome_screen.dart';

class SettingsView extends StatefulWidget {
  final String? workspaceName;

  const SettingsView({super.key, this.workspaceName});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _loading = true;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _workspace;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _channels = [];
  String _tier = 'free';

  // Settings state
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _desktopNotifications = true;
  bool _soundEnabled = true;
  String _theme = 'dark';
  bool _autoStart = false;
  bool _minimizeToTray = true;
  String _language = 'en';
  bool _showOnlineStatus = true;
  bool _allowDirectMessages = true;
  bool _enableScreenSharing = true;
  bool _enableFileSharing = true;
  int _videoQuality = 2; // 0=low, 1=medium, 2=high
  int _audioQuality = 2;
  bool _noiseSuppression = true;
  bool _echoCancellation = true;
  bool _autoGainControl = true;
  String _inputDevice = 'default';
  String _outputDevice = 'default';
  bool _pushToTalk = false;
  String _pushToTalkKey = 'Space';
  bool _enableKeyboardShortcuts = true;
  bool _enableSpellCheck = true;
  bool _enableAutoSave = true;
  int _autoSaveInterval = 5; // minutes
  bool _enableCloudSync = false;
  bool _enableAnalytics = true;
  bool _enableCrashReporting = true;
  int _cacheSize = 500; // MB
  bool _enableHardwareAcceleration = true;
  String? _customStoragePath;
  FlowSpaceConnectionMode _connectionMode = FlowSpaceConnectionMode.local;
  String _serverUrl = '';
  String? _serverStatus;
  bool _testingServer = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      // Load custom storage path
      final customPath = await VaultStorageService.getCustomStoragePath();
      final connectionMode = await ServerConfigService.instance
          .getConnectionMode();
      final serverUrl = await ServerConfigService.instance.getServerBaseUrl();

      // Load workspace data if workspace name is provided
      Map<String, dynamic>? workspace;
      if (widget.workspaceName != null &&
          widget.workspaceName!.isNotEmpty &&
          widget.workspaceName != 'FlowSpace') {
        try {
          workspace = await WorkspaceService.selectWorkspaceByName(
            widget.workspaceName!,
          );
        } catch (e) {
          print('Settings: Error finding workspace: $e');
        }
      }

      if (workspace == null) {
        final workspaces = await DatabaseService.getUserWorkspaces(
          user['id'] as String,
        );
        if (workspaces.isNotEmpty) {
          workspace = workspaces.reduce((a, b) {
            final aUpdated =
                DateTime.tryParse(a['updated_at'] as String? ?? '') ??
                DateTime(1970);
            final bUpdated =
                DateTime.tryParse(b['updated_at'] as String? ?? '') ??
                DateTime(1970);
            return bUpdated.isAfter(aUpdated) ? b : a;
          });
        }
      }

      if (workspace != null) {
        final workspaceId = workspace['id'] as String?;
        if (workspaceId != null) {
          final members = await DatabaseService.getWorkspaceMembers(
            workspaceId,
          );
          final channels = await DatabaseService.getWorkspaceChannels(
            workspaceId,
          );

          if (!mounted) return;
          setState(() {
            _workspace = workspace;
            _members = members;
            _channels = channels;
            _tier = workspace?['subscription_tier'] as String? ?? 'free';
          });
        }
      }

      // TODO: Load settings from database/preferences
      if (!mounted) return;
      setState(() {
        _user = user;
        _customStoragePath = customPath;
        _connectionMode = connectionMode;
        _serverUrl = serverUrl;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 32),
          _buildSection(
            title: 'Connection',
            icon: Icons.hub,
            children: [
              _buildDropdownTile(
                title: 'Mode',
                subtitle: _connectionMode == FlowSpaceConnectionMode.local
                    ? 'Use this device only with the local offline workspace'
                    : 'Connect this app to a self-hosted FlowSpace server',
                value: _connectionMode,
                items: const [
                  FlowSpaceConnectionMode.local,
                  FlowSpaceConnectionMode.server,
                ],
                labels: const ['Local', 'Self-hosted Server'],
                onChanged: _setConnectionMode,
              ),
              _buildSettingTile(
                title: 'Server URL',
                subtitle: _serverUrl.isEmpty
                    ? 'No server URL configured'
                    : _serverUrl,
                icon: Icons.dns,
                onTap: _showServerUrlDialog,
              ),
              ListTile(
                leading: Icon(
                  _connectionMode == FlowSpaceConnectionMode.server
                      ? Icons.cloud_queue
                      : Icons.computer,
                  color: const Color(0xFF0066FF),
                ),
                title: const Text(
                  'Connection Status',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  _serverStatus ??
                      (_connectionMode == FlowSpaceConnectionMode.server
                          ? 'Server mode is selected. Test the configured URL before signing in.'
                          : 'Local mode is active. Server calls are skipped for login/register.'),
                  style: const TextStyle(color: Colors.white54),
                ),
                trailing: FilledButton.icon(
                  onPressed: _testingServer ? null : _testServerConnection,
                  icon: _testingServer
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.network_check),
                  label: const Text('Test'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (_workspace != null) ...[
            _buildTierBanner(),
            const SizedBox(height: 32),
            _buildWorkspaceInfo(),
            const SizedBox(height: 32),
            _buildMembersList(),
            const SizedBox(height: 32),
            _buildChannelsList(),
            const SizedBox(height: 32),
          ],
          _buildSection(
            title: 'Account',
            icon: Icons.person,
            children: [
              _buildAccountInfo(),
              const SizedBox(height: 16),
              _buildSettingTile(
                title: 'Edit Nickname',
                subtitle: _user?['nickname'] != null
                    ? 'Current: @${_user!['nickname']}'
                    : 'Set a nickname for @mentions',
                icon: Icons.alternate_email,
                onTap: () {
                  _showEditNicknameDialog();
                },
              ),
              _buildSettingTile(
                title: 'Profile',
                subtitle: 'Edit your profile information',
                icon: Icons.edit,
                onTap: () {
                  // Navigate to profile
                },
              ),
              _buildSettingTile(
                title: 'Change Password',
                subtitle: 'Update your account password',
                icon: Icons.lock,
                onTap: () {
                  _showChangePasswordDialog();
                },
              ),
              _buildSettingTile(
                title: 'Sign Out',
                subtitle: 'Sign out of your account',
                icon: Icons.logout,
                iconColor: Colors.redAccent,
                onTap: () {
                  _showSignOutDialog();
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSection(
            title: 'Notifications',
            icon: Icons.notifications,
            children: [
              _buildSwitchTile(
                title: 'Enable Notifications',
                subtitle: 'Receive notifications for messages and mentions',
                value: _notificationsEnabled,
                onChanged: (value) =>
                    setState(() => _notificationsEnabled = value),
              ),
              if (_notificationsEnabled) ...[
                _buildSwitchTile(
                  title: 'Email Notifications',
                  subtitle: 'Receive notifications via email',
                  value: _emailNotifications,
                  onChanged: (value) =>
                      setState(() => _emailNotifications = value),
                ),
                _buildSwitchTile(
                  title: 'Desktop Notifications',
                  subtitle: 'Show desktop notifications',
                  value: _desktopNotifications,
                  onChanged: (value) =>
                      setState(() => _desktopNotifications = value),
                ),
                _buildSwitchTile(
                  title: 'Sound',
                  subtitle: 'Play sound for notifications',
                  value: _soundEnabled,
                  onChanged: (value) => setState(() => _soundEnabled = value),
                ),
              ],
            ],
          ),
          const SizedBox(height: 32),
          _buildSection(
            title: 'Appearance',
            icon: Icons.palette,
            children: [
              _buildDropdownTile(
                title: 'Theme',
                subtitle: 'Choose your preferred theme',
                value: _theme,
                items: const ['dark', 'light', 'system'],
                onChanged: (value) => setState(() => _theme = value!),
              ),
              _buildDropdownTile(
                title: 'Language',
                subtitle: 'Select your language',
                value: _language,
                items: const ['en', 'es', 'fr', 'de', 'ja', 'zh'],
                onChanged: (value) => setState(() => _language = value!),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSection(
            title: 'Privacy & Security',
            icon: Icons.security,
            children: [
              _buildSwitchTile(
                title: 'Show Online Status',
                subtitle: 'Let others see when you\'re online',
                value: _showOnlineStatus,
                onChanged: (value) => setState(() => _showOnlineStatus = value),
              ),
              _buildSwitchTile(
                title: 'Allow Direct Messages',
                subtitle: 'Allow others to send you direct messages',
                value: _allowDirectMessages,
                onChanged: (value) =>
                    setState(() => _allowDirectMessages = value),
              ),
              _buildSettingTile(
                title: 'Blocked Users',
                subtitle: 'Manage blocked users',
                icon: Icons.block,
                onTap: () {
                  // Show blocked users
                },
              ),
              _buildSettingTile(
                title: 'Data & Privacy',
                subtitle: 'Manage your data and privacy settings',
                icon: Icons.privacy_tip,
                onTap: () {
                  // Show privacy settings
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSection(
            title: 'Audio & Video',
            icon: Icons.videocam,
            children: [
              _buildDropdownTile(
                title: 'Video Quality',
                subtitle: 'Select video quality for calls',
                value: _videoQuality,
                items: const [0, 1, 2],
                labels: const ['Low', 'Medium', 'High'],
                onChanged: (value) => setState(() => _videoQuality = value!),
              ),
              _buildDropdownTile(
                title: 'Audio Quality',
                subtitle: 'Select audio quality for calls',
                value: _audioQuality,
                items: const [0, 1, 2],
                labels: const ['Low', 'Medium', 'High'],
                onChanged: (value) => setState(() => _audioQuality = value!),
              ),
              _buildDropdownTile(
                title: 'Input Device',
                subtitle: 'Select microphone',
                value: _inputDevice,
                items: const ['default', 'device1', 'device2'],
                onChanged: (value) => setState(() => _inputDevice = value!),
              ),
              _buildDropdownTile(
                title: 'Output Device',
                subtitle: 'Select speaker/headphones',
                value: _outputDevice,
                items: const ['default', 'device1', 'device2'],
                onChanged: (value) => setState(() => _outputDevice = value!),
              ),
              _buildSwitchTile(
                title: 'Noise Suppression',
                subtitle: 'Reduce background noise',
                value: _noiseSuppression,
                onChanged: (value) => setState(() => _noiseSuppression = value),
              ),
              _buildSwitchTile(
                title: 'Echo Cancellation',
                subtitle: 'Reduce echo in calls',
                value: _echoCancellation,
                onChanged: (value) => setState(() => _echoCancellation = value),
              ),
              _buildSwitchTile(
                title: 'Auto Gain Control',
                subtitle: 'Automatically adjust microphone volume',
                value: _autoGainControl,
                onChanged: (value) => setState(() => _autoGainControl = value),
              ),
              _buildSwitchTile(
                title: 'Push to Talk',
                subtitle: 'Hold a key to speak',
                value: _pushToTalk,
                onChanged: (value) => setState(() => _pushToTalk = value),
              ),
              if (_pushToTalk)
                _buildSettingTile(
                  title: 'Push to Talk Key',
                  subtitle: 'Current: $_pushToTalkKey',
                  icon: Icons.keyboard,
                  onTap: () {
                    _showKeyBindingDialog();
                  },
                ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSection(
            title: 'General',
            icon: Icons.settings,
            children: [
              _buildSwitchTile(
                title: 'Start on System Startup',
                subtitle: 'Automatically start FLO when you log in',
                value: _autoStart,
                onChanged: (value) => setState(() => _autoStart = value),
              ),
              _buildSwitchTile(
                title: 'Minimize to System Tray',
                subtitle: 'Minimize to tray instead of taskbar',
                value: _minimizeToTray,
                onChanged: (value) => setState(() => _minimizeToTray = value),
              ),
              _buildSwitchTile(
                title: 'Enable Screen Sharing',
                subtitle: 'Allow screen sharing in calls',
                value: _enableScreenSharing,
                onChanged: (value) =>
                    setState(() => _enableScreenSharing = value),
              ),
              _buildSwitchTile(
                title: 'Enable File Sharing',
                subtitle: 'Allow file sharing in workspaces',
                value: _enableFileSharing,
                onChanged: (value) =>
                    setState(() => _enableFileSharing = value),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSection(
            title: 'Editor',
            icon: Icons.edit,
            children: [
              _buildSwitchTile(
                title: 'Enable Spell Check',
                subtitle: 'Check spelling as you type',
                value: _enableSpellCheck,
                onChanged: (value) => setState(() => _enableSpellCheck = value),
              ),
              _buildSwitchTile(
                title: 'Auto Save',
                subtitle: 'Automatically save your work',
                value: _enableAutoSave,
                onChanged: (value) => setState(() => _enableAutoSave = value),
              ),
              if (_enableAutoSave)
                _buildSliderTile(
                  title: 'Auto Save Interval',
                  subtitle: '$_autoSaveInterval minutes',
                  value: _autoSaveInterval.toDouble(),
                  min: 1,
                  max: 30,
                  divisions: 29,
                  onChanged: (value) =>
                      setState(() => _autoSaveInterval = value.toInt()),
                ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSection(
            title: 'Keyboard Shortcuts',
            icon: Icons.keyboard,
            children: [
              _buildSwitchTile(
                title: 'Enable Keyboard Shortcuts',
                subtitle: 'Use keyboard shortcuts for faster navigation',
                value: _enableKeyboardShortcuts,
                onChanged: (value) =>
                    setState(() => _enableKeyboardShortcuts = value),
              ),
              if (_enableKeyboardShortcuts)
                _buildSettingTile(
                  title: 'View All Shortcuts',
                  subtitle: 'See all available keyboard shortcuts',
                  icon: Icons.list,
                  onTap: () {
                    _showKeyboardShortcutsDialog();
                  },
                ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSection(
            title: 'Advanced',
            icon: Icons.build,
            children: [
              _buildSwitchTile(
                title: 'Enable Cloud Sync',
                subtitle: 'Sync your data to the cloud (optional)',
                value: _enableCloudSync,
                onChanged: (value) => setState(() => _enableCloudSync = value),
              ),
              _buildSwitchTile(
                title: 'Enable Analytics',
                subtitle: 'Help improve FLO by sharing usage data',
                value: _enableAnalytics,
                onChanged: (value) => setState(() => _enableAnalytics = value),
              ),
              _buildSwitchTile(
                title: 'Enable Crash Reporting',
                subtitle: 'Automatically report crashes',
                value: _enableCrashReporting,
                onChanged: (value) =>
                    setState(() => _enableCrashReporting = value),
              ),
              _buildSwitchTile(
                title: 'Hardware Acceleration',
                subtitle: 'Use GPU acceleration for better performance',
                value: _enableHardwareAcceleration,
                onChanged: (value) =>
                    setState(() => _enableHardwareAcceleration = value),
              ),
              _buildSliderTile(
                title: 'Cache Size',
                subtitle: '$_cacheSize MB',
                value: _cacheSize.toDouble(),
                min: 100,
                max: 2000,
                divisions: 19,
                onChanged: (value) =>
                    setState(() => _cacheSize = value.toInt()),
              ),
              _buildSettingTile(
                title: 'Clear Cache',
                subtitle: 'Clear all cached data',
                icon: Icons.delete_outline,
                iconColor: Colors.orange,
                onTap: () {
                  _showClearCacheDialog();
                },
              ),
              _buildStoragePathTile(),
              _buildSettingTile(
                title: 'Database Connection',
                subtitle: 'Configure secure database credentials',
                icon: Icons.storage,
                iconColor: const Color(0xFF0066FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DatabaseSettingsView(),
                    ),
                  );
                },
              ),
              _buildSettingTile(
                title: 'Export Data',
                subtitle: 'Export your workspace data',
                icon: Icons.download,
                onTap: () {
                  // Export data
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSection(
            title: 'About',
            icon: Icons.info,
            children: [
              FutureBuilder<String>(
                future: UpdateService.getCurrentVersion(),
                builder: (context, snapshot) {
                  final version = snapshot.data ?? '1.0.0';
                  return _buildInfoTile('Version', version);
                },
              ),
              FutureBuilder<String>(
                future: UpdateService.getCurrentBuild(),
                builder: (context, snapshot) {
                  final build = snapshot.data ?? '1';
                  return _buildInfoTile('Build', build);
                },
              ),
              _buildSettingTile(
                title: 'Check for Updates',
                subtitle: 'Check if a new version is available',
                icon: Icons.system_update,
                onTap: () {
                  _checkForUpdates();
                },
              ),
              _buildSettingTile(
                title: 'Release Notes',
                subtitle: 'View what\'s new in this version',
                icon: Icons.description,
                onTap: () async {
                  final url = Uri.parse('https://flo.app/releases');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
              _buildSettingTile(
                title: 'Help & Support',
                subtitle: 'Get help and contact support',
                icon: Icons.help_outline,
                onTap: () async {
                  final url = Uri.parse('https://flo.app/support');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
              _buildSettingTile(
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                icon: Icons.privacy_tip,
                onTap: () async {
                  final url = Uri.parse('https://flo.app/privacy');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
              _buildSettingTile(
                title: 'Terms of Service',
                subtitle: 'Read our terms of service',
                icon: Icons.description,
                onTap: () async {
                  final url = Uri.parse('https://flo.app/terms');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF0066FF), size: 24),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setConnectionMode(FlowSpaceConnectionMode? mode) async {
    if (mode == null) return;

    final saved = await ServerConfigService.instance.setConnectionMode(mode);
    if (!mounted) return;

    setState(() {
      _connectionMode = mode;
      _serverStatus = saved
          ? mode == FlowSpaceConnectionMode.local
                ? 'Local mode saved. Login and registration will use this device.'
                : 'Server mode saved. Test the server URL before signing in.'
          : 'Could not save connection mode.';
    });
  }

  Future<void> _showServerUrlDialog() async {
    final controller = TextEditingController(text: _serverUrl);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Self-hosted Server URL',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'https://flowspace.yourcompany.com',
            hintStyle: TextStyle(color: Colors.white38),
            helperText: 'Use the base URL, without /api/v1',
            helperStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0066FF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (result == null || result.isEmpty) return;

    final saved = await ServerConfigService.instance.setServerBaseUrl(result);
    if (saved) {
      final url = await ServerConfigService.instance.getServerBaseUrl();
      if (!mounted) return;
      setState(() {
        _serverUrl = url;
        _serverStatus = 'Server URL saved. Run Test to verify it.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _serverStatus = 'Server URL must start with http:// or https://.';
    });
  }

  Future<void> _testServerConnection() async {
    setState(() {
      _testingServer = true;
      _serverStatus = 'Testing $_serverUrl...';
    });

    final result = await ServerConfigService.instance.testConnection();
    if (!mounted) return;

    setState(() {
      _testingServer = false;
      _serverStatus = result.ok
          ? '${result.message} ${result.url}'
          : '${result.message} ${result.url}';
    });
  }

  Widget _buildAccountInfo() {
    final email = _user?['email'] as String? ?? 'user@example.com';
    final name = _user?['name'] as String? ?? email.split('@').first;
    final nickname = _user?['nickname'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFF0066FF),
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                if (nickname != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.alternate_email,
                        size: 12,
                        color: Color(0xFF0066FF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        nickname,
                        style: const TextStyle(
                          color: Color(0xFF0066FF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? const Color(0xFF0066FF)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF0066FF),
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    required String subtitle,
    required T value,
    required List<T> items,
    List<String>? labels,
    required ValueChanged<T?> onChanged,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
      trailing: DropdownButton<T>(
        value: value,
        dropdownColor: const Color(0xFF1E1E1E),
        style: const TextStyle(color: Colors.white),
        underline: Container(),
        items: items.map((item) {
          final label = labels != null
              ? labels[items.indexOf(item)]
              : item.toString();
          return DropdownMenuItem(value: item, child: Text(label));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: const TextStyle(color: Colors.white54)),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: const Color(0xFF0066FF),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white54)),
      trailing: Text(value, style: const TextStyle(color: Colors.white)),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Change Password',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Implement password change
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password change feature coming soon!'),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
            ),
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _signOut();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      // Get user ID before clearing
      final user = await AuthService.getCurrentUser();
      final userId = user?['id'] as String?;

      // Clear local database user data first
      if (userId != null) {
        final db = await DatabaseService.database;
        await db.delete('users', where: 'id = ?', whereArgs: [userId]);
      }

      // Call AuthService logout to clear tokens and secure storage
      await AuthService.logout();

      // Navigate to welcome screen
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false, // Remove all previous routes
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signed out successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showKeyBindingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Set Push to Talk Key',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Press the key you want to use for push to talk',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Implement key binding
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
            ),
            child: const Text('Set Key'),
          ),
        ],
      ),
    );
  }

  void _showKeyboardShortcutsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Keyboard Shortcuts',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShortcutRow('New Workspace', 'Ctrl+N'),
                _buildShortcutRow('New Channel', 'Ctrl+K'),
                _buildShortcutRow('Search', 'Ctrl+F'),
                _buildShortcutRow('Toggle Sidebar', 'Ctrl+B'),
                _buildShortcutRow('Start Call', 'Ctrl+Shift+C'),
                _buildShortcutRow('Mute/Unmute', 'Ctrl+M'),
                _buildShortcutRow('Push to Talk', _pushToTalkKey),
                _buildShortcutRow('Mark as Read', 'Esc'),
                _buildShortcutRow('Settings', 'Ctrl+,'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(String action, String shortcut) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(action, style: const TextStyle(color: Colors.white70)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Clear Cache', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will clear all cached data. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Implement cache clearing
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Cache cleared!')));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Checking for updates...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final updateInfo = await UpdateService.checkForUpdates(force: true);
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (updateInfo != null) {
        _showUpdateAvailableDialog(updateInfo);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are running the latest version!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking for updates: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUpdateAvailableDialog(UpdateInfo updateInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          children: [
            const Icon(Icons.system_update, color: Color(0xFF0066FF)),
            const SizedBox(width: 12),
            Text(
              'Update Available',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version of FLO is available!',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Current Version', updateInfo.currentVersion),
            _buildInfoRow('Latest Version', updateInfo.latestVersion),
            if (updateInfo.updateSize != null)
              _buildInfoRow('Download Size', updateInfo.sizeDisplay),
            if (updateInfo.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'What\'s New:',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                updateInfo.releaseNotes,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
            if (updateInfo.isRequired) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This update is required for security and stability.',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!updateInfo.isRequired)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final url = Uri.parse(updateInfo.downloadUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not open download link'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
            ),
            child: const Text('Download Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Workspace settings widgets
  Widget _buildTierBanner() {
    final isFree = _tier == 'free';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                isFree ? Icons.rocket_outlined : Icons.workspace_premium,
                color: const Color(0xFF0066FF),
                size: 48,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFree ? 'FlowSpace Free' : 'FlowSpace Pro',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isFree
                          ? '1 workspace • 2 channels • 5GB storage • Up to 5 members'
                          : 'Unlimited workspaces • Unlimited channels • 100GB storage • Unlimited members',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (isFree)
                FilledButton.icon(
                  onPressed: _showUpgradeDialog,
                  icon: const Icon(Icons.arrow_upward),
                  label: const Text('Upgrade to Pro'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspaceInfo() {
    if (_workspace == null) return const SizedBox.shrink();

    return _buildSection(
      title: 'Workspace Settings',
      icon: Icons.workspace_premium,
      children: [
        _buildInfoRow('Name', _workspace!['name'] ?? 'Unnamed'),
        _buildInfoRow('Slug', _workspace!['slug'] ?? ''),
        _buildInfoRow(
          'Created',
          _formatWorkspaceDate(_workspace!['created_at'] as String?),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _showRenameDialog,
          icon: const Icon(Icons.edit),
          label: const Text('Rename Workspace'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0066FF),
            side: const BorderSide(color: Color(0xFF0066FF)),
          ),
        ),
      ],
    );
  }

  Widget _buildMembersList() {
    if (_workspace == null) return const SizedBox.shrink();

    return _buildSection(
      title: 'Team Members (${_members.length}/5)',
      icon: Icons.people,
      children: [
        ..._members.map((member) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF0066FF).withValues(alpha: 0.2),
              child: Text(
                (member['name'] as String? ?? 'U')[0].toUpperCase(),
                style: const TextStyle(color: Color(0xFF0066FF)),
              ),
            ),
            title: Text(
              member['name'] as String? ?? 'Unknown',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              member['email'] as String? ?? '',
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: Chip(
              label: Text(
                (member['role'] as String? ?? 'member').toUpperCase(),
                style: const TextStyle(fontSize: 10),
              ),
              backgroundColor: const Color(0xFF0066FF).withValues(alpha: 0.2),
              labelStyle: const TextStyle(color: Color(0xFF0066FF)),
            ),
          );
        }),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            print('SettingsView: Invite Member button clicked!');
            if (_workspace == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No workspace selected')),
              );
              return;
            }
            if (_tier == 'free' && _members.length >= 5) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Free tier limit: Maximum 5 members reached'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            _showInviteDialog();
          },
          icon: const Icon(Icons.person_add),
          label: const Text('Invite Member'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0066FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildChannelsList() {
    if (_workspace == null) return const SizedBox.shrink();

    return _buildSection(
      title: 'Channels (${_channels.length}/2)',
      icon: Icons.tag,
      children: [
        ..._channels.map((channel) {
          return ListTile(
            leading: const Icon(Icons.tag, color: Color(0xFF0066FF)),
            title: Text(
              '# ${channel['name']}',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              channel['description'] as String? ?? '',
              style: const TextStyle(color: Colors.white54),
            ),
          );
        }),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _tier == 'free' && _channels.length >= 2
              ? null
              : null, // TODO: implement add channel
          icon: const Icon(Icons.add),
          label: const Text('Add Channel'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0066FF),
            side: const BorderSide(color: Color(0xFF0066FF)),
          ),
        ),
      ],
    );
  }

  String _formatWorkspaceDate(String? iso) {
    if (iso == null) return '';
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Upgrade to Pro',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FlowSpace Pro - \$9/user/month',
              style: TextStyle(
                color: Color(0xFF0066FF),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              'Unlimited workspaces',
              'Unlimited channels',
              '100GB storage per workspace',
              'Project management & Kanban boards',
              'Calendar & scheduling',
              'Screen recording',
              'API access',
              'Cloud sync backup (optional)',
            ].map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF0066FF),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: implement upgrade flow
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Upgrade flow coming soon!')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog() {
    if (_workspace == null) return;
    final controller = TextEditingController(
      text: _workspace!['name'] as String?,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Rename Workspace',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Workspace Name',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white54),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: implement rename
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rename feature coming soon!')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
            ),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  Widget _buildStoragePathTile() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vault Storage Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _customStoragePath ?? 'Default (App Data)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _selectStorageFolder,
                icon: const Icon(Icons.folder_open, size: 16),
                label: const Text('Browse'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0066FF),
                ),
              ),
              if (_customStoragePath != null)
                IconButton(
                  onPressed: _clearStoragePath,
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.white54,
                  tooltip: 'Reset to default',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectStorageFolder() async {
    try {
      // For Windows, we'll use a text input dialog since file_picker doesn't support folder selection on all platforms
      // In a production app, you'd use a native folder picker
      final controller = TextEditingController(text: _customStoragePath ?? '');

      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Set Vault Storage Location',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the full path to your custom storage folder:',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'C:\\Users\\YourName\\Documents\\FlowSpace',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0066FF)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Leave empty to use default App Data location',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final path = controller.text.trim();
                Navigator.pop(context, path.isEmpty ? null : path);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
              ),
              child: const Text('Set Path'),
            ),
          ],
        ),
      );

      if (result != null) {
        String? pathToSet = result.isEmpty ? null : result;

        // Validate path if provided
        if (pathToSet != null) {
          final dir = Directory(pathToSet);
          if (!await dir.exists()) {
            // Ask if user wants to create it
            final create = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                title: const Text(
                  'Create Folder?',
                  style: TextStyle(color: Colors.white),
                ),
                content: Text(
                  'The folder "$pathToSet" does not exist. Create it?',
                  style: const TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                    ),
                    child: const Text('Create'),
                  ),
                ],
              ),
            );

            if (create == true) {
              try {
                await dir.create(recursive: true);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create folder: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }
            } else {
              return; // User cancelled
            }
          }
        }

        // Save the path
        await VaultStorageService.setCustomStoragePath(pathToSet);

        if (mounted) {
          setState(() {
            _customStoragePath = pathToSet;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                pathToSet == null
                    ? 'Reset to default storage location'
                    : 'Storage location updated. Restart app for changes to take effect.',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting storage path: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearStoragePath() async {
    await VaultStorageService.setCustomStoragePath(null);
    if (mounted) {
      setState(() {
        _customStoragePath = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reset to default storage location. Restart app for changes to take effect.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showInviteDialog() {
    if (_workspace == null) return;

    final emailController = TextEditingController();
    final workspaceId = _workspace!['id'] as String;

    showDialog(
      context: context,
      builder: (context) => _InviteDialog(
        emailController: emailController,
        workspaceId: workspaceId,
        members: _members,
        tier: _tier,
        onMemberAdded: () {
          _loadSettings();
        },
      ),
    );
  }

  void _showEditNicknameDialog() {
    final currentNickname = _user?['nickname'] as String? ?? '';
    final controller = TextEditingController(text: currentNickname);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Edit Nickname',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your nickname is used for @mentions in chat',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nickname',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'e.g., john, jdoe',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                prefixText: '@',
                prefixStyle: const TextStyle(color: Color(0xFF0066FF)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newNickname = controller.text.trim();

              // Validate nickname (alphanumeric and underscores only)
              if (newNickname.isNotEmpty &&
                  !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(newNickname)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Nickname can only contain letters, numbers, and underscores',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                // Update nickname on backend
                await UserService.updateProfile(
                  nickname: newNickname.isEmpty ? null : newNickname,
                );

                // Update local state
                if (_user != null) {
                  _user!['nickname'] = newNickname.isEmpty ? null : newNickname;
                  setState(() {});
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      newNickname.isEmpty
                          ? 'Nickname removed'
                          : 'Nickname updated to @$newNickname',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating nickname: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _InviteDialog extends StatefulWidget {
  final TextEditingController emailController;
  final String workspaceId;
  final List<Map<String, dynamic>> members;
  final String tier;
  final VoidCallback onMemberAdded;

  const _InviteDialog({
    required this.emailController,
    required this.workspaceId,
    required this.members,
    required this.tier,
    required this.onMemberAdded,
  });

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  bool _isInviting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text(
        'Invite Team Member',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.emailController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Email Address',
              labelStyle: TextStyle(color: Colors.white70),
              hintText: 'user@example.com',
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF0066FF)),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            enabled: !_isInviting,
          ),
          const SizedBox(height: 16),
          if (widget.tier == 'free')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Free tier: Max 5 members (${widget.members.length}/5)',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isInviting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isInviting
              ? null
              : () async {
                  final email = widget.emailController.text.trim();
                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter an email address'),
                      ),
                    );
                    return;
                  }

                  if (!email.contains('@') || !email.contains('.')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid email address'),
                      ),
                    );
                    return;
                  }

                  setState(() => _isInviting = true);

                  try {
                    final user = await DatabaseService.getUserByEmail(email);

                    if (user == null) {
                      final userId =
                          '${DateTime.now().millisecondsSinceEpoch}_user';
                      final now = DateTime.now().toIso8601String();

                      await DatabaseService.insertUser({
                        'id': userId,
                        'name': email.split('@')[0],
                        'email': email,
                        'password_hash': null,
                        'avatar_url': null,
                        'status': 'offline',
                        'created_at': now,
                        'updated_at': now,
                      });

                      await DatabaseService.addWorkspaceMember({
                        'workspace_id': widget.workspaceId,
                        'user_id': userId,
                        'role': 'member',
                        'joined_at': now,
                      });

                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$email has been added to the workspace',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );

                      widget.onMemberAdded();
                    } else {
                      final existingMembers =
                          await DatabaseService.getWorkspaceMembers(
                            widget.workspaceId,
                          );
                      final isAlreadyMember = existingMembers.any(
                        (m) => m['email'] == email,
                      );

                      if (isAlreadyMember) {
                        if (!mounted) return;
                        setState(() => _isInviting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'User is already a member of this workspace',
                            ),
                          ),
                        );
                        return;
                      }

                      final now = DateTime.now().toIso8601String();
                      await DatabaseService.addWorkspaceMember({
                        'workspace_id': widget.workspaceId,
                        'user_id': user['id'] as String,
                        'role': 'member',
                        'joined_at': now,
                      });

                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${user['name']} has been added to the workspace',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );

                      widget.onMemberAdded();
                    }
                  } catch (e) {
                    if (!mounted) return;
                    setState(() => _isInviting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error adding member: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0066FF),
          ),
          child: _isInviting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Invite'),
        ),
      ],
    );
  }
}
