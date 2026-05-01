/// FlowSpace Backend Configuration
/// 
/// IMPORTANT: Update these URLs with your actual Render service URLs
class FlowSpaceConfig {
  /// Your Render service URL for FlowSpace backend
  /// Format: https://your-service-name.onrender.com
  /// 
  /// CONFIGURED: Using actual Render service URL
  static const String renderServiceUrl = 'https://flowspace-backend.onrender.com';
  
  /// API Base URL
  static String get apiBaseUrl => '$renderServiceUrl/api/v1';
  
  /// WebSocket URL for real-time sync
  static String get websocketUrl => renderServiceUrl.replaceFirst('https://', 'wss://');
  
  /// Full WebSocket sync URL
  static String get syncUrl => '$websocketUrl/sync';
  
  /// Check if configuration has been updated
  static bool get isConfigured => !renderServiceUrl.contains('YOUR_SERVICE_NAME_HERE');
}
