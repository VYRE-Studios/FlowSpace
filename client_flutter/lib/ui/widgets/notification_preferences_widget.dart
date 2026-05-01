import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

/// Widget for managing notification preferences
class NotificationPreferencesWidget extends StatefulWidget {
  const NotificationPreferencesWidget({super.key});

  @override
  State<NotificationPreferencesWidget> createState() =>
      _NotificationPreferencesWidgetState();
}

class _NotificationPreferencesWidgetState
    extends State<NotificationPreferencesWidget> {
  late NotificationPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = NotificationService.instance.preferences;
  }

  void _updatePreferences(NotificationPreferences prefs) {
    setState(() {
      _prefs = prefs;
    });
    NotificationService.instance.updatePreferences(prefs);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Preferences',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive desktop notifications'),
              value: _prefs.enabled,
              onChanged: (value) {
                _updatePreferences(_prefs.copyWith(enabled: value));
              },
            ),
            SwitchListTile(
              title: const Text('Sound Alerts'),
              subtitle: const Text('Play sound for notifications'),
              value: _prefs.soundEnabled,
              onChanged: _prefs.enabled
                  ? (value) {
                      _updatePreferences(_prefs.copyWith(soundEnabled: value));
                    }
                  : null,
            ),
            SwitchListTile(
              title: const Text('Show Message Preview'),
              subtitle: const Text('Display message content in notifications'),
              value: _prefs.showPreview,
              onChanged: _prefs.enabled
                  ? (value) {
                      _updatePreferences(_prefs.copyWith(showPreview: value));
                    }
                  : null,
            ),
            SwitchListTile(
              title: const Text('Only When Window Unfocused'),
              subtitle: const Text('Only show notifications when app is in background'),
              value: _prefs.notifyOnlyWhenUnfocused,
              onChanged: _prefs.enabled
                  ? (value) {
                      _updatePreferences(
                          _prefs.copyWith(notifyOnlyWhenUnfocused: value));
                    }
                  : null,
            ),
            const Divider(height: 32),
            Text(
              'Sound Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildSoundSelector(
              'Default Messages',
              _prefs.defaultSound,
              (sound) => _updatePreferences(_prefs.copyWith(defaultSound: sound)),
            ),
            _buildSoundSelector(
              'Mentions',
              _prefs.mentionSound,
              (sound) => _updatePreferences(_prefs.copyWith(mentionSound: sound)),
            ),
            _buildSoundSelector(
              'Direct Messages',
              _prefs.dmSound,
              (sound) => _updatePreferences(_prefs.copyWith(dmSound: sound)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundSelector(
    String label,
    SoundType currentSound,
    void Function(SoundType) onChanged,
  ) {
    return ListTile(
      title: Text(label),
      trailing: DropdownButton<SoundType>(
        value: currentSound,
        onChanged: (_prefs.enabled && _prefs.soundEnabled)
            ? (SoundType? value) {
                if (value != null) onChanged(value);
              }
            : null,
        items: SoundType.values.map((sound) {
          return DropdownMenuItem(
            value: sound,
            child: Text(_soundTypeToString(sound)),
          );
        }).toList(),
      ),
    );
  }

  String _soundTypeToString(SoundType sound) {
    switch (sound) {
      case SoundType.none:
        return 'None';
      case SoundType.default_:
        return 'Default';
      case SoundType.mention:
        return 'Mention Alert';
      case SoundType.dm:
        return 'DM Alert';
    }
  }
}
