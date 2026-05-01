import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationPriority { low, normal, high, urgent }

enum SoundType { none, default_, mention, dm }

class NotificationPreferences {
  final bool enabled;
  final bool soundEnabled;
  final bool showPreview;
  final bool notifyOnlyWhenUnfocused;
  final SoundType defaultSound;
  final SoundType mentionSound;
  final SoundType dmSound;

  const NotificationPreferences({
    this.enabled = true,
    this.soundEnabled = true,
    this.showPreview = true,
    this.notifyOnlyWhenUnfocused = true,
    this.defaultSound = SoundType.default_,
    this.mentionSound = SoundType.mention,
    this.dmSound = SoundType.dm,
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'soundEnabled': soundEnabled,
        'showPreview': showPreview,
        'notifyOnlyWhenUnfocused': notifyOnlyWhenUnfocused,
        'defaultSound': defaultSound.toString(),
        'mentionSound': mentionSound.toString(),
        'dmSound': dmSound.toString(),
      };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      enabled: json['enabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      showPreview: json['showPreview'] ?? true,
      notifyOnlyWhenUnfocused: json['notifyOnlyWhenUnfocused'] ?? true,
      defaultSound: _soundTypeFromString(json['defaultSound']),
      mentionSound: _soundTypeFromString(json['mentionSound']),
      dmSound: _soundTypeFromString(json['dmSound']),
    );
  }

  static SoundType _soundTypeFromString(String? str) {
    if (str == null) return SoundType.default_;
    return SoundType.values.firstWhere(
      (e) => e.toString() == str,
      orElse: () => SoundType.default_,
    );
  }

  NotificationPreferences copyWith({
    bool? enabled,
    bool? soundEnabled,
    bool? showPreview,
    bool? notifyOnlyWhenUnfocused,
    SoundType? defaultSound,
    SoundType? mentionSound,
    SoundType? dmSound,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      showPreview: showPreview ?? this.showPreview,
      notifyOnlyWhenUnfocused:
          notifyOnlyWhenUnfocused ?? this.notifyOnlyWhenUnfocused,
      defaultSound: defaultSound ?? this.defaultSound,
      mentionSound: mentionSound ?? this.mentionSound,
      dmSound: dmSound ?? this.dmSound,
    );
  }
}

/// Service for handling desktop notifications (Windows, Linux, macOS)
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _initialized = false;
  bool _windowFocused = true;
  int _badgeCount = 0;
  NotificationPreferences _preferences = const NotificationPreferences();
  SharedPreferences? _prefs;

  Future<void> init() async {
    if (_initialized) return;

    // Load preferences
    _prefs = await SharedPreferences.getInstance();
    await _loadPreferences();

    const initializationSettings = InitializationSettings(
      linux: LinuxInitializationSettings(
        defaultActionName: 'Open',
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        // Handle notification click - focus window
        _windowFocused = true;
      },
    );

    _initialized = true;
  }

  Future<void> _loadPreferences() async {
    final json = _prefs?.getString('notification_preferences');
    if (json != null) {
      try {
        _preferences = NotificationPreferences.fromJson(
          Map<String, dynamic>.from(
            // ignore: avoid_dynamic_calls
            const {}..addAll({}),
          ),
        );
      } catch (e) {
        // Use defaults on error
      }
    }
  }

  Future<void> updatePreferences(NotificationPreferences prefs) async {
    _preferences = prefs;
    await _prefs?.setString('notification_preferences', prefs.toJson().toString());
  }

  NotificationPreferences get preferences => _preferences;

  void setWindowFocused(bool focused) {
    _windowFocused = focused;
    if (focused) {
      // Clear badge when window gains focus
      resetBadgeCount();
    }
  }

  int get badgeCount => _badgeCount;

  void incrementBadgeCount() {
    _badgeCount++;
    _updateBadge();
  }

  void resetBadgeCount() {
    _badgeCount = 0;
    _updateBadge();
  }

  void _updateBadge() {
    // Platform-specific badge updates would go here
    // For now, just track the count internally
  }

  Future<void> _playSound(SoundType soundType) async {
    if (!_preferences.soundEnabled || soundType == SoundType.none) return;

    String soundPath;
    switch (soundType) {
      case SoundType.mention:
        soundPath = 'assets/sounds/mention.mp3';
        break;
      case SoundType.dm:
        soundPath = 'assets/sounds/dm.mp3';
        break;
      case SoundType.default_:
        soundPath = 'assets/sounds/notification.mp3';
        break;
      case SoundType.none:
        return;
    }

    try {
      await _audioPlayer.play(AssetSource(soundPath.replaceFirst('assets/', '')));
    } catch (e) {
      // Silently fail if sound file not found
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
    NotificationPriority priority = NotificationPriority.normal,
    SoundType? soundType,
  }) async {
    // Check if notifications are enabled
    if (!_preferences.enabled) return;

    // Only show if window is not focused (if preference set)
    if (_preferences.notifyOnlyWhenUnfocused && _windowFocused) return;

    // Increment badge count
    incrementBadgeCount();

    // Play sound if specified
    if (soundType != null) {
      await _playSound(soundType);
    }

    // Show preview or generic message
    final notificationBody = _preferences.showPreview ? body : 'New message';

    await _notifications.show(
      id,
      title,
      notificationBody,
      const NotificationDetails(
        linux: LinuxNotificationDetails(),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false, // We handle sound manually
        ),
      ),
    );
  }

  Future<void> showMessageNotification({
    required String senderName,
    required String messageText,
    bool isDM = false,
  }) async {
    await showNotification(
      title: senderName,
      body: messageText,
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      priority: isDM ? NotificationPriority.high : NotificationPriority.normal,
      soundType: isDM ? _preferences.dmSound : _preferences.defaultSound,
    );
  }

  Future<void> showMentionNotification({
    required String senderName,
    required String messageText,
  }) async {
    await showNotification(
      title: '@ $senderName mentioned you',
      body: messageText,
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      priority: NotificationPriority.high,
      soundType: _preferences.mentionSound,
    );
  }

  Future<void> showDirectMessageNotification({
    required String senderName,
    required String messageText,
  }) async {
    await showNotification(
      title: '💬 $senderName (Direct Message)',
      body: messageText,
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      priority: NotificationPriority.urgent,
      soundType: _preferences.dmSound,
    );
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
