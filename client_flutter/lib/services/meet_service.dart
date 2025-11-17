import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'database_service.dart';
import 'auth_service.dart';

class MeetService {
  static final JitsiMeet _jitsiMeet = JitsiMeet();

  /// Get all active meetings for a workspace
  static Future<List<Map<String, dynamic>>> getWorkspaceMeetings(String workspaceId) async {
    return await DatabaseService.getWorkspaceMeetings(workspaceId);
  }

  /// Start a new meeting
  static Future<String> startMeeting({
    required String workspaceId,
    required String title,
  }) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) throw Exception('No user found');

    final meetingId = DateTime.now().millisecondsSinceEpoch.toString();
    final roomName = 'flowspace_${workspaceId}_$meetingId';
    final now = DateTime.now().toIso8601String();

    // Save meeting to database
    await DatabaseService.insertMeeting({
      'id': meetingId,
      'workspace_id': workspaceId,
      'room_name': roomName,
      'title': title,
      'started_by': user['id'],
      'started_at': now,
      'status': 'active',
    });

    // Join the Jitsi room
    await joinMeeting(
      roomName: roomName,
      displayName: user['name'] as String,
      title: title,
    );

    return meetingId;
  }

  /// Join an existing meeting
  static Future<void> joinMeeting({
    required String roomName,
    required String displayName,
    String? title,
  }) async {
    var options = JitsiMeetConferenceOptions(
      serverURL: 'https://meet.jit.si',
      room: roomName,
      configOverrides: {
        'startWithAudioMuted': false,
        'startWithVideoMuted': false,
        'subject': title ?? 'FlowSpace Meeting',
      },
      featureFlags: {
        'unsaferoomwarning.enabled': false,
        'prejoinpage.enabled': false,
      },
      userInfo: JitsiMeetUserInfo(
        displayName: displayName,
        email: '',
      ),
    );

    await _jitsiMeet.join(options);
  }

  /// End a meeting
  static Future<void> endMeeting(String meetingId) async {
    await DatabaseService.endMeeting(meetingId);
    // Note: Jitsi doesn't have a server-side "end" - users just leave
  }
}
