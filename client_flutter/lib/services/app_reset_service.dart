import 'api_client.dart';
import 'server_config_service.dart';
import 'secure_storage_service.dart';
import 'database_service.dart';
import 'realtime/socket_service.dart';
import '../core/chat_core.dart';

/// Service to reset the app state and clear all cached data
/// Useful for testing new server connections or troubleshooting
class AppResetService {
  /// Clear all cached data and reset app to default state
  /// This will:
  /// - Clear authentication tokens
  /// - Clear server URL configuration (forces Railway default)
  /// - Clear secure storage (user IDs, keys)
  /// - Clear API client cache
  /// - Clear chat core cache
  static Future<void> resetAll() async {
    print('AppResetService: Starting full app reset...');

    // Clear authentication tokens
    ApiClient.clearAuth();
    print('AppResetService: Cleared authentication tokens');

    // Clear server URL (will use Railway default)
    await ServerConfigService.instance.clearStoredUrl();
    print('AppResetService: Cleared server URL (will use Railway default)');

    // Clear secure storage
    await SecureStorageService.deleteAll();
    print('AppResetService: Cleared secure storage');

    // Clear API client cache
    ApiClient.clearCache();
    print('AppResetService: Cleared API client cache');

    // Clear socket service cache
    SocketService.instance.clearCache();
    print('AppResetService: Cleared socket service cache');

    // Note: ChatCore cache is cleared when server URL changes
    // Database is kept (local data)

    print('AppResetService: Full reset complete! App will use Railway production server.');
  }

  /// Clear only authentication and server config (keeps local database)
  static Future<void> resetConnection() async {
    print('AppResetService: Resetting connection settings...');

    // Clear authentication tokens
    ApiClient.clearAuth();
    print('AppResetService: Cleared authentication tokens');

    // Clear server URL (will use Railway default)
    await ServerConfigService.instance.clearStoredUrl();
    print('AppResetService: Cleared server URL (will use Railway default)');

    // Clear API client cache
    ApiClient.clearCache();
    print('AppResetService: Cleared API client cache');

    // Clear socket service cache
    SocketService.instance.clearCache();
    print('AppResetService: Cleared socket service cache');

    print('AppResetService: Connection reset complete!');
  }
}

