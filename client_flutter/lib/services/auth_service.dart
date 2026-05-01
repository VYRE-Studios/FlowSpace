import 'dart:async';
import 'api_client.dart';
import 'database_service.dart';
import 'vault_storage_service.dart';
import 'encryption_service.dart';
import 'secure_storage_service.dart';
import 'user_service.dart';

class AuthService {

  /// Register a new user with email verification
  static Future<Map<String, dynamic>> registerWithVerification({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      print('FlowSpace: Starting registration with verification for $email...');
      
      final response = await ApiClient.post(
        '/auth/register-with-verification',
        body: {
          'name': name,
          'email': email,
          'password': password,
        },
      );
      
      print('FlowSpace: Registration response: $response');
      
      return {
        'success': true,
        'message': response['message'] ?? 'Verification email sent',
        'userId': response['userId'],
      };
    } catch (e, stack) {
      print('FlowSpace: ERROR in registration: $e');
      print('FlowSpace: Stack trace: $stack');
      rethrow;
    }
  }

  /// Verify email with token from email link
  static Future<Map<String, dynamic>> verifyEmail(String token) async {
    try {
      print('FlowSpace: Verifying email with token...');
      
      final response = await ApiClient.get('/auth/verify-email?token=$token');
      
      print('FlowSpace: Email verification response: $response');
      
      return {
        'success': true,
        'message': response['message'] ?? 'Email verified successfully',
      };
    } catch (e, stack) {
      print('FlowSpace: ERROR in email verification: $e');
      print('FlowSpace: Stack trace: $stack');
      rethrow;
    }
  }

  /// Register a new user with the production server (instant, no verification)
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String workspaceName,
  }) async {
    try {
      print('FlowSpace: Starting registration for $email via API...');
      
      // Call the real API endpoint
      final response = await ApiClient.post(
        '/auth/register',
        body: {
          'name': name,
          'email': email,
          'password': password,
          'workspaceName': workspaceName,
        },
      );
      
      print('FlowSpace: Registration API response: $response');
      
      // Extract data from API response
      // Response format: { token: string, user: { id, email, displayName } }
      final responseMap = Map<String, dynamic>.from(response as Map);
      
      // Get token from response
      final token = responseMap['token'] as String?;
      if (token != null) {
        ApiClient.setToken(token);
        await SecureStorageService.setJwtToken(token); // Persist JWT token
      }
      if (responseMap['sessionToken'] != null) {
        ApiClient.setSessionToken(responseMap['sessionToken'] as String);
      }
      
      // Get user object from response
      final userObj = responseMap['user'] as Map<String, dynamic>?;
      if (userObj == null) {
        throw Exception('Registration failed: No user object in response. Response: $response');
      }
      
      final userId = userObj['id'] as String?;
      if (userId == null) {
        throw Exception('Registration failed: No user ID in response. User object: $userObj');
      }
      
      // Store user ID in secure storage
      await SecureStorageService.setCurrentUserId(userId);
      
      // Cache user data locally for offline access
      await DatabaseService.insertUser({
        'id': userId,
        'name': userObj['displayName'] as String? ?? name,
        'email': userObj['email'] as String? ?? email,
        'password_hash': null,
        'avatar_url': userObj['avatarUrl'] as String?,
        'status': 'online',
        'created_at': userObj['createdAt'] as String? ?? DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      print('FlowSpace: Registration complete! User ID: $userId');
      
      return {
        'success': true,
        'user': userObj,
      };
    } catch (e, stack) {
      print('FlowSpace: ERROR in registration: $e');
      print('FlowSpace: Stack trace: $stack');
      rethrow;
    }
  }

  /// Login with email and password (with Remember Me support and refresh tokens)
  static Future<Map<String, dynamic>> loginWithRememberMe({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      print('FlowSpace: Starting login with remember me for $email...');
      
      final response = await ApiClient.post(
        '/auth/login-with-remember-me',
        body: {
          'email': email,
          'password': password,
          'rememberMe': rememberMe,
        },
      );
      
      print('FlowSpace: Login API response received: $response');
      
      final responseMap = Map<String, dynamic>.from(response as Map);
      
      // Store access token
      final token = responseMap['token'] as String?;
      if (token != null) {
        ApiClient.setToken(token);
        await SecureStorageService.setJwtToken(token);
      }
      
      // Store refresh token if provided
      final refreshToken = responseMap['refreshToken'] as String?;
      if (refreshToken != null) {
        await SecureStorageService.setRefreshToken(refreshToken);
      }
      
      // Get user object
      final userObj = responseMap['user'] as Map<String, dynamic>?;
      if (userObj == null) {
        throw Exception('Login failed: No user object in response');
      }
      
      final userId = userObj['id'] as String?;
      if (userId == null) {
        throw Exception('Login failed: No user ID in response');
      }
      
      await SecureStorageService.setCurrentUserId(userId);
      
      // Cache user data locally
      await DatabaseService.insertUser({
        'id': userId,
        'name': userObj['displayName'] as String? ?? userObj['name'] as String? ?? 'User',
        'email': userObj['email'] as String? ?? email,
        'password_hash': null,
        'avatar_url': userObj['avatarUrl'] as String?,
        'status': 'online',
        'created_at': userObj['createdAt'] as String? ?? DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      print('FlowSpace: Login complete! User ID: $userId');
      
      return {
        'success': true,
        'user': userObj,
      };
    } catch (e, stack) {
      print('FlowSpace: ERROR in login: $e');
      print('FlowSpace: Stack trace: $stack');
      rethrow;
    }
  }

  /// Refresh access token using refresh token
  static Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await SecureStorageService.getRefreshToken();
      if (refreshToken == null) {
        print('FlowSpace: No refresh token available');
        return null;
      }
      
      print('FlowSpace: Refreshing access token...');
      
      final response = await ApiClient.post(
        '/auth/refresh',
        body: {'refreshToken': refreshToken},
      );
      
      final newToken = response['token'] as String?;
      if (newToken != null) {
        ApiClient.setToken(newToken);
        await SecureStorageService.setJwtToken(newToken);
        print('FlowSpace: Access token refreshed successfully');
      }
      
      return newToken;
    } catch (e) {
      print('FlowSpace: Failed to refresh token: $e');
      return null;
    }
  }

  /// Login with email and password (simple, no refresh token)
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      print('FlowSpace: Starting login for $email via API...');
      
      // Call the real API endpoint
      final response = await ApiClient.post(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );
      
      print('FlowSpace: Login API response received: $response');
      
      // Extract data from API response
      // Response format: { token: string, user: { id, email, displayName } }
      final responseMap = Map<String, dynamic>.from(response as Map);
      
      // Get token from response
      final token = responseMap['token'] as String?;
      if (token != null) {
        ApiClient.setToken(token);
        await SecureStorageService.setJwtToken(token); // Persist JWT token
      }
      if (responseMap['sessionToken'] != null) {
        ApiClient.setSessionToken(responseMap['sessionToken'] as String);
      }
      
      // Get user object from response
      final userObj = responseMap['user'] as Map<String, dynamic>?;
      if (userObj == null) {
        throw Exception('Login failed: No user object in response. Response: $response');
      }
      
      final userId = userObj['id'] as String?;
      if (userId == null) {
        throw Exception('Login failed: No user ID in response. User object: $userObj');
      }
      
      // Store user ID in secure storage
      await SecureStorageService.setCurrentUserId(userId);
      
      // Cache user data locally for offline access
      await DatabaseService.insertUser({
        'id': userId,
        'name': userObj['displayName'] as String? ?? userObj['name'] as String? ?? 'User',
        'email': userObj['email'] as String? ?? email,
        'password_hash': null,
        'avatar_url': userObj['avatarUrl'] as String?,
        'status': 'online',
        'created_at': userObj['createdAt'] as String? ?? DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      print('FlowSpace: Login complete! User ID: $userId');
      
      // Save credentials if remember me is enabled
      if (rememberMe) {
        await SecureStorageService.saveCredentials(email, password);
      } else {
        await SecureStorageService.clearCredentials();
      }
      
      return {
        'success': true,
        'user': userObj,
      };
    } on TimeoutException catch (e) {
      print('FlowSpace: Login timeout: $e');
      throw Exception('Server is slow, please wait... The request took longer than 30 seconds. Please try again.');
    } catch (e, stack) {
      print('FlowSpace: ERROR in login: $e');
      print('FlowSpace: Stack trace: $stack');
      rethrow;
    }
  }

  /// Get current user (checks local cache first, then API)
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    // Restore JWT token from secure storage if not in memory
    if (ApiClient.token == null) {
      final storedToken = await SecureStorageService.getJwtToken();
      if (storedToken != null) {
        ApiClient.setToken(storedToken);
      }
    }

    // First check local database
    final localUser = await DatabaseService.getCurrentUser();
    if (localUser != null) {
      // Try to refresh from API if we have a token
      if (ApiClient.token != null) {
        try {
          final apiUser = await UserService.getProfile();
          // Update local cache with fresh data
          await DatabaseService.insertUser({
            'id': apiUser['id'] as String,
            'name': apiUser['name'] as String? ?? apiUser['displayName'] as String? ?? 'User',
            'email': apiUser['email'] as String,
            'password_hash': null,
            'avatar_url': apiUser['avatarUrl'] as String?,
            'status': 'online',
            'created_at': apiUser['createdAt'] as String? ?? DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          return apiUser;
        } catch (e) {
          print('FlowSpace: Could not refresh user from API, using local cache: $e');
          return localUser;
        }
      }
      return localUser;
    }
    return null;
  }

  /// Get the current JWT token
  static Future<String?> getToken() async {
    return await SecureStorageService.getJwtToken();
  }

  /// Legacy method for getting auth token (alias for getToken)
  static Future<String?> getAuthToken() async {
    try {
      // Prefer secure storage token
      final token = await SecureStorageService.getJwtToken();
      if (token != null && token.isNotEmpty) {
        return token;
      }

      // Fallback to in-memory token if available
      if (ApiClient.token != null && ApiClient.token!.isNotEmpty) {
        return ApiClient.token;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Logout - clear tokens and local data
  static Future<void> logout({bool clearRememberMe = false}) async {
    try {
      // Try to revoke refresh token on server
      final refreshToken = await SecureStorageService.getRefreshToken();
      if (refreshToken != null) {
        try {
          await ApiClient.post('/auth/logout', body: {'refreshToken': refreshToken});
        } catch (e) {
          print('FlowSpace: Failed to revoke refresh token on server: $e');
        }
      }
      
      // Clear API tokens
      ApiClient.clearAuth();
      
      // Clear JWT and refresh tokens from secure storage
      await SecureStorageService.setJwtToken('');
      await SecureStorageService.clearRefreshToken();
      
      // Clear secure storage
      final userId = await SecureStorageService.getCurrentUserId();
      if (userId != null) {
        await SecureStorageService.deleteEncryptedMasterKey(userId);
      }
      await SecureStorageService.setCurrentUserId('');
      
      // Clear credentials if explicitly requested
      if (clearRememberMe) {
        await SecureStorageService.clearCredentials();
      }
      
      print('FlowSpace: Logout complete');
    } catch (e) {
      print('FlowSpace: Error during logout: $e');
    }
  }
}
