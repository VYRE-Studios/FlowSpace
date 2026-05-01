import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'flowspace_config.dart';

enum FlowSpaceConnectionMode { local, server }

class ServerConnectionCheck {
  final bool ok;
  final String message;
  final String url;
  final int? statusCode;

  const ServerConnectionCheck({
    required this.ok,
    required this.message,
    required this.url,
    this.statusCode,
  });
}

/// Service for managing server configuration (URL, port, etc.)
/// Stores configuration in SharedPreferences for persistence across app restarts.
class ServerConfigService {
  static const String _keyServerBaseUrl = 'server_base_url';
  static const String _keyConnectionMode = 'connection_mode';
  static const Duration _testTimeout = Duration(seconds: 5);

  // Default to Render production server from config
  static String get _defaultServerUrl => FlowSpaceConfig.renderServiceUrl;

  static ServerConfigService? _instance;
  static ServerConfigService get instance {
    _instance ??= ServerConfigService._internal();
    return _instance!;
  }

  ServerConfigService._internal();

  Future<FlowSpaceConnectionMode> getConnectionMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_keyConnectionMode);
      return value == FlowSpaceConnectionMode.server.name
          ? FlowSpaceConnectionMode.server
          : FlowSpaceConnectionMode.local;
    } catch (e) {
      print('ServerConfigService: Error reading connection mode: $e');
      return FlowSpaceConnectionMode.local;
    }
  }

  Future<bool> setConnectionMode(FlowSpaceConnectionMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_keyConnectionMode, mode.name);
    } catch (e) {
      print('ServerConfigService: Error saving connection mode: $e');
      return false;
    }
  }

  Future<bool> isServerMode() async {
    return await getConnectionMode() == FlowSpaceConnectionMode.server;
  }

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

  Future<ServerConnectionCheck> testConnection({String? url}) async {
    final baseUrl = _normalizeServerUrl(url ?? await getServerBaseUrl());
    final healthUrl = '$baseUrl/api/v1/health';

    try {
      final response = await http
          .get(Uri.parse(healthUrl))
          .timeout(_testTimeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ServerConnectionCheck(
          ok: true,
          message: 'Connected to FlowSpace server.',
          url: baseUrl,
          statusCode: response.statusCode,
        );
      }

      return ServerConnectionCheck(
        ok: false,
        message: 'Server responded with HTTP ${response.statusCode}.',
        url: baseUrl,
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      return ServerConnectionCheck(
        ok: false,
        message:
            'Connection timed out after ${_testTimeout.inSeconds} seconds.',
        url: baseUrl,
      );
    } catch (e) {
      return ServerConnectionCheck(
        ok: false,
        message: 'Could not reach server: $e',
        url: baseUrl,
      );
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

  String _normalizeServerUrl(String url) {
    url = url.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }
}
