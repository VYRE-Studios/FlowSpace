import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = String.fromEnvironment(
    'FLOWSPACE_API_BASE',
    defaultValue: 'http://localhost:4000/api/v1',
  );

  static String? _token;
  static String? _sessionToken;

  static void setToken(String? token) {
    _token = token;
  }

  static String? get token => _token;

  static void setSessionToken(String? token) {
    _sessionToken = token;
  }

  static String? get sessionToken => _sessionToken;

  static Uri _uri(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path);
    }
    if (path.startsWith('/')) {
      return Uri.parse('$baseUrl$path');
    }
    return Uri.parse('$baseUrl/$path');
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

  static Future<dynamic> get(String path) async {
    final uri = _uri(path);
    try {
      final response = await http.get(uri, headers: _headers());
      return _decodeResponse(response, 'GET', path);
    } on SocketException {
      rethrow;
    }
  }

  static Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = _uri(path);
    try {
      final response = await http.post(
        uri,
        headers: _headers(),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      );
      return _decodeResponse(response, 'POST', path);
    } on SocketException {
      rethrow;
    }
  }

  static Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final uri = _uri(path);
    try {
      final response = await http.patch(
        uri,
        headers: _headers(),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      );
      return _decodeResponse(response, 'PATCH', path);
    } on SocketException {
      rethrow;
    }
  }

  static Future<void> delete(String path) async {
    final uri = _uri(path);
    try {
      final response = await http.delete(uri, headers: _headers());
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw HttpException(
          'DELETE $path failed: ${response.statusCode}',
          uri: uri,
        );
      }
    } on SocketException {
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