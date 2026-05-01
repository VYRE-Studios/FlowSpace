import 'api_client.dart';

class MeetService {
  /// Get all active meetings for a workspace from the FlowSpace backend.
  static Future<List<Map<String, dynamic>>> getWorkspaceMeetings(String workspaceId) async {
    final response = await ApiClient.get(
      'meet/sessions?workspaceId=${Uri.encodeComponent(workspaceId)}',
    );
    final data = response as Map<String, dynamic>;
    return (data['meetings'] as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Create and immediately start a new backend-backed LiveKit meeting.
  static Future<Map<String, dynamic>> startMeeting({
    required String workspaceId,
    required String title,
  }) async {
    final created = await ApiClient.post(
      'meet',
      body: {
        'workspaceId': workspaceId,
        'title': title,
      },
    ) as Map<String, dynamic>;

    final meetingId = created['id'] as String;
    final started = await ApiClient.post('meet/$meetingId/start');
    return Map<String, dynamic>.from(started as Map);
  }

  /// Mark the current user as joined and fetch the LiveKit connection payload.
  ///
  /// The UI layer still needs a LiveKit room widget to consume this token.
  static Future<Map<String, dynamic>> joinMeeting({
    required String meetingId,
  }) async {
    await ApiClient.post('meet/$meetingId/join');
    final tokenPayload = await ApiClient.get('meet/$meetingId/token');
    return Map<String, dynamic>.from(tokenPayload as Map);
  }

  static Future<void> leaveMeeting(String meetingId) async {
    await ApiClient.post('meet/$meetingId/leave');
  }

  static Future<void> endMeeting(String meetingId) async {
    await ApiClient.post('meet/$meetingId/end');
  }
}
