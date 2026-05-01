import 'api_client.dart';

class UserService {
  static Future<Map<String, dynamic>> getProfile() async {
    final data = await ApiClient.get('/users/me');
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? nickname,
  }) async {
    final data = await ApiClient.patch(
      '/users/me',
      body: {
        if (displayName != null) 'displayName': displayName,
        if (nickname != null) 'nickname': nickname,
      },
    );
    return Map<String, dynamic>.from(data as Map);
  }
}
