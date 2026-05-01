import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for FlowSpace
/// Wraps flutter_secure_storage to store encryption keys and sensitive data
/// Uses platform-specific secure storage (Windows Credential Manager, macOS Keychain, etc.)
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
    wOptions: WindowsOptions(
      useBackwardCompatibility: false,
    ),
  );

  // Storage keys
  static const String _keyMasterKey = 'master_key_encrypted';
  static const String _keyUserId = 'current_user_id';
  static const String _keyJwtToken = 'jwt_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyRememberMe = 'remember_me';
  static const String _keySavedEmail = 'saved_email';
  static const String _keySavedPassword = 'saved_password';

  /// Store the encrypted master key
  static Future<void> storeEncryptedMasterKey(
    String userId,
    Map<String, dynamic> encryptedKey,
  ) async {
    final keyJson = jsonEncode(encryptedKey);
    await _storage.write(
      key: '${_keyMasterKey}_$userId',
      value: keyJson,
    );
    print('FlowSpace: Encrypted master key stored for user $userId');
  }

  /// Retrieve the encrypted master key
  static Future<Map<String, dynamic>?> getEncryptedMasterKey(String userId) async {
    final keyJson = await _storage.read(key: '${_keyMasterKey}_$userId');
    if (keyJson == null) return null;
    return jsonDecode(keyJson) as Map<String, dynamic>;
  }

  /// Check if encrypted master key exists for user
  static Future<bool> hasEncryptedMasterKey(String userId) async {
    final key = await _storage.read(key: '${_keyMasterKey}_$userId');
    return key != null;
  }

  /// Store the current user ID
  static Future<void> setCurrentUserId(String userId) async {
    await _storage.write(key: _keyUserId, value: userId);
  }

  /// Get the current user ID
  static Future<String?> getCurrentUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  /// Store the JWT token
  static Future<void> setJwtToken(String token) async {
    await _storage.write(key: _keyJwtToken, value: token);
  }

  /// Get the JWT token
  static Future<String?> getJwtToken() async {
    return await _storage.read(key: _keyJwtToken);
  }

  /// Store the refresh token
  static Future<void> setRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  /// Get the refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Clear the refresh token
  static Future<void> clearRefreshToken() async {
    await _storage.delete(key: _keyRefreshToken);
  }

  /// Delete encrypted master key (e.g., on logout)
  static Future<void> deleteEncryptedMasterKey(String userId) async {
    await _storage.delete(key: '${_keyMasterKey}_$userId');
    print('FlowSpace: Encrypted master key deleted for user $userId');
  }

  /// Delete all stored data (e.g., on app reset)
  static Future<void> deleteAll() async {
    await _storage.deleteAll();
    print('FlowSpace: All secure storage cleared');
  }

  /// Check if storage is available
  static Future<bool> isAvailable() async {
    try {
      await _storage.containsKey(key: 'test');
      return true;
    } catch (e) {
      print('FlowSpace: Secure storage not available: $e');
      return false;
    }
  }

  // Remember Me functionality
  
  /// Set remember me preference
  static Future<void> setRememberMe(bool remember) async {
    await _storage.write(key: _keyRememberMe, value: remember.toString());
  }

  /// Get remember me preference
  static Future<bool> getRememberMe() async {
    final value = await _storage.read(key: _keyRememberMe);
    return value == 'true';
  }

  /// Save login credentials (only if remember me is enabled)
  static Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _keySavedEmail, value: email);
    await _storage.write(key: _keySavedPassword, value: password);
    await setRememberMe(true);
    print('FlowSpace: Credentials saved');
  }

  /// Get saved credentials
  static Future<Map<String, String>?> getSavedCredentials() async {
    final rememberMe = await getRememberMe();
    if (!rememberMe) return null;

    final email = await _storage.read(key: _keySavedEmail);
    final password = await _storage.read(key: _keySavedPassword);

    if (email == null || password == null) return null;

    return {'email': email, 'password': password};
  }

  /// Clear saved credentials
  static Future<void> clearCredentials() async {
    await _storage.delete(key: _keySavedEmail);
    await _storage.delete(key: _keySavedPassword);
    await setRememberMe(false);
    print('FlowSpace: Credentials cleared');
  }
}
