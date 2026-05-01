import 'package:audioplayers/audioplayers.dart';
import 'server_config_service.dart';

/// Service for playing sound effects
/// Supports both backend-served sounds (via URL) and local asset fallback
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  AudioPlayer? _player;
  bool _enabled = true;
  bool _initFailed = false;
  String? _cachedBaseUrl;

  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  AudioPlayer? _getPlayer() {
    if (_initFailed) return null;
    if (_player != null) return _player;
    
    try {
      _player = AudioPlayer();
      return _player;
    } catch (e) {
      print('SoundService: Failed to initialize AudioPlayer: $e');
      _initFailed = true;
      return null;
    }
  }

  Future<String?> _getBaseUrl() async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl;
    try {
      _cachedBaseUrl = await ServerConfigService.instance.getServerBaseUrl();
      return _cachedBaseUrl;
    } catch (e) {
      print('SoundService: Error getting server URL: $e');
      return null;
    }
  }

  /// Play sound from URL (provided by backend in WebSocket events)
  /// Falls back to local assets if URL playback fails
  Future<void> playFromUrl(String soundUrl) async {
    if (!_enabled) {
      print('SoundService: Sounds disabled');
      return;
    }
    
    final player = _getPlayer();
    if (player == null) {
      print('SoundService: Audio player not available');
      return;
    }

    try {
      final baseUrl = await _getBaseUrl();
      if (baseUrl != null) {
        final fullUrl = '$baseUrl$soundUrl';
        print('SoundService: Playing from URL: $fullUrl');
        await player.play(UrlSource(fullUrl));
        return;
      }
    } catch (e) {
      print('SoundService: Failed to play from URL: $e, falling back to local');
    }

    // Fallback to local assets
    await _playLocalFallback(soundUrl);
  }

  /// Play local asset sound as fallback
  Future<void> _playLocalFallback(String soundUrl) async {
    final player = _getPlayer();
    if (player == null) return;

    // Extract filename from URL path (e.g. /assets/sounds/notification.wav -> notification)
    final filename = soundUrl.split('/').last.split('.').first;
    
    // Map backend sound names to local asset names
    String localName;
    switch (filename) {
      case 'notification':
        localName = 'message';
        break;
      case 'clockbeep':
        localName = 'mention';
        break;
      case 'whoosh':
        localName = 'online';
        break;
      default:
        localName = filename;
    }

    await playSound(localName);
  }

  Future<void> playSound(String soundName) async {
    if (!_enabled) {
      print('SoundService: Sounds disabled, not playing $soundName');
      return;
    }
    
    final player = _getPlayer();
    if (player == null) {
      print('SoundService: Audio player not available');
      return;
    }

    try {
      print('SoundService: Attempting to play $soundName.mp3');
      await player.play(AssetSource('sounds/$soundName.mp3'));
      print('SoundService: Successfully played $soundName.mp3');
    } catch (e) {
      print('SoundService: mp3 failed ($e), trying wav');
      // Fallback to wav if mp3 fails or is empty
      try {
        await player.play(AssetSource('sounds/$soundName.wav'));
        print('SoundService: Successfully played $soundName.wav');
      } catch (e2) {
        print('SoundService: Error playing $soundName: $e2');
      }
    }
  }

  Future<void> playMessage() => playSound('message');
  Future<void> playMention() => playSound('mention');
  Future<void> playOnline() => playSound('online');
  Future<void> playOffline() => playSound('offline');
  Future<void> playTyping() => playSound('typing');

  void dispose() {
    _player?.dispose();
  }
}
