import 'package:shared_preferences/shared_preferences.dart';
import 'flowspace_config.dart';

/// Service for managing server configuration (URL, port, etc.)
/// Stores configuration in SharedPreferences for persistence across app restarts.
class ServerConfigService {
  static const String _keyServerBaseUrl = 'server_base_url';
  // Default to Render production server from config
  static String get _defaultServerUrl => FlowSpaceConfig.renderServiceUrl;

  static ServerConfigService? _instance;
  static ServerConfigService get instance {
    _instance ??= ServerConfigService._internal();
    return _instance!;
  }

  ServerConfigService._internal();

  /// Get the base server URL (e.g., 'http://localhost:4000' or 'http://10.5.0.2:4000')
  /// Returns the stored value or the default localhost URL.
  Future<String> getServerBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyServerBaseUrl) ?? _defaultServerUrl;
    } catch (e) {
      print('ServerConfigService: Error reading server URL: $e');
      return _defaultServerUrl;
    }
  }

  /// Set the base server URL
  /// [url] should be in format 'http://host:port' or 'https://host:port'
  /// Example: 'http://10.5.0.2:4000'
  Future<bool> setServerBaseUrl(String url) async {
    try {
      // Basic validation - ensure URL starts with http:// or https://
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        throw ArgumentError('Server URL must start with http:// or https://');
      }

      // Remove trailing slash if present
      url = url.trim();
      if (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }

      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_keyServerBaseUrl, url);
      
      if (success) {
        print('ServerConfigService: Server URL updated to: $url');
      }
      
      return success;
    } catch (e) {
      print('ServerConfigService: Error saving server URL: $e');
      return false;
    }
  }

  /// Get the API base URL (server URL + /api/v1)
  Future<String> getApiBaseUrl() async {
    final baseUrl = await getServerBaseUrl();
    return '$baseUrl/api/v1';
  }

  /// Reset to default localhost URL
  Future<bool> resetToDefault() async {
    return await setServerBaseUrl(_defaultServerUrl);
  }

  /// Check if server URL has been customized (not using default)
  Future<bool> isCustomized() async {
    final currentUrl = await getServerBaseUrl();
    return currentUrl != _defaultServerUrl;
  }

  /// Clear stored server URL (forces use of default Railway URL)
  Future<bool> clearStoredUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_keyServerBaseUrl);
    } catch (e) {
      print('ServerConfigService: Error clearing server URL: $e');
      return false;
    }
  }
}

