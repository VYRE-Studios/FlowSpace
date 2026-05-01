import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'server_config_service.dart';

class ApiClient {
  // Runtime configuration - can be overridden by environment variable at compile time
  // but will use ServerConfigService for runtime configuration
  static String? _cachedBaseUrl;
  static String? _cachedApiBaseUrl;

  static String? _token;
  static String? _sessionToken;

  /// Get the base API URL (e.g., 'http://localhost:4000/api/v1')
  /// Uses runtime configuration from ServerConfigService, with fallback to environment variable or default
  static Future<String> get baseUrl async {
    // Check environment variable first (compile-time override)
    const envBaseUrl = String.fromEnvironment(
      'FLOWSPACE_API_BASE',
      defaultValue: '',
    );

    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }

    // Use cached value if available
    if (_cachedApiBaseUrl != null) {
      return _cachedApiBaseUrl!;
    }

    // Get from runtime configuration
    try {
      final apiBaseUrl = await ServerConfigService.instance.getApiBaseUrl();
      _cachedApiBaseUrl = apiBaseUrl;
      return apiBaseUrl;
    } catch (e) {
      print('ApiClient: Error getting server config, using default: $e');
      // Fallback to Render production server
      return 'https://flowspace-backend.onrender.com/api/v1';
    }
  }

  /// Clear cached URLs (call this when server URL changes)
  static void clearCache() {
    _cachedBaseUrl = null;
    _cachedApiBaseUrl = null;
  }

  /// Clear all authentication tokens and cached data
  static void clearAuth() {
    _token = null;
    _sessionToken = null;
    clearCache();
  }

  static void setToken(String? token) {
    _token = token;
  }

  static String? get token => _token;

  static void setSessionToken(String? token) {
    _sessionToken = token;
  }

  static String? get sessionToken => _sessionToken;

  static Future<Uri> _uri(String path) async {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path);
    }
    final apiBase = await baseUrl;
    if (path.startsWith('/')) {
      return Uri.parse('$apiBase$path');
    }
    return Uri.parse('$apiBase/$path');
  }

  static Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final token = _token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (_sessionToken != null && _sessionToken!.isNotEmpty) {
      headers['X-Session-Token'] = _sessionToken!;
    }

    return headers;
  }

  // Timeout settings (30 seconds)
  static const Duration _connectTimeout = Duration(seconds: 30);
  static const Duration _receiveTimeout = Duration(seconds: 30);

  static Future<dynamic> get(String path) async {
    final uri = await _uri(path);
    try {
      final response = await http.get(uri, headers: _headers())
          .timeout(_connectTimeout + _receiveTimeout);
      return _decodeResponse(response, 'GET', path);
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    }
  }

  static Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = await _uri(path);
    try {
      final response = await http.post(
        uri,
        headers: _headers(),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ).timeout(_connectTimeout + _receiveTimeout);
      return _decodeResponse(response, 'POST', path);
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    }
  }

  static Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final uri = await _uri(path);
    try {
      final response = await http.patch(
        uri,
        headers: _headers(),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ).timeout(_connectTimeout + _receiveTimeout);
      return _decodeResponse(response, 'PATCH', path);
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    }
  }

  static Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = await _uri(path);
    try {
      final response = await http.put(
        uri,
        headers: _headers(),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ).timeout(_connectTimeout + _receiveTimeout);
      return _decodeResponse(response, 'PUT', path);
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    }
  }

  static Future<void> delete(String path) async {
    final uri = await _uri(path);
    try {
      final response = await http.delete(uri, headers: _headers())
          .timeout(_connectTimeout + _receiveTimeout);
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw HttpException(
          'DELETE $path failed: ${response.statusCode}',
          uri: uri,
        );
      }
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    }
  }

  static Future<dynamic> deleteWithBody(String path, {Map<String, dynamic>? body}) async {
    final uri = await _uri(path);
    try {
      final request = http.Request('DELETE', uri);
      request.headers.addAll(_headers());
      if (body != null) {
        request.body = jsonEncode(body);
      }
      final streamedResponse = await request.send()
          .timeout(_connectTimeout + _receiveTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _decodeResponse(response, 'DELETE', path);
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    }
  }

  static dynamic _decodeResponse(http.Response response, String method, String path) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      return jsonDecode(response.body);
    }

    throw HttpException(
      '$method $path failed: ${response.statusCode}',
      uri: response.request?.url,
    );
  }

}
