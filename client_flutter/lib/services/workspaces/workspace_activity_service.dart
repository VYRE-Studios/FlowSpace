import 'package:flutter/foundation.dart';

import '../realtime/socket_service.dart';
import '../../ui/widgets/sidebar/right_sidebar.dart';

/// Collects recent workspace activity events for display in the sidebar.
class WorkspaceActivityService {
  WorkspaceActivityService._();

  static final WorkspaceActivityService instance =
      WorkspaceActivityService._();

  /// Most recent events first.
  final ValueNotifier<List<ActivityEvent>> events =
      ValueNotifier<List<ActivityEvent>>(<ActivityEvent>[]);

  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;

    SocketService.instance.events.listen((Map<String, dynamic> event) {
      final String? type = event['type'] as String?;
      if (type == null) return;

      String description;
      switch (type) {
        case 'workspace_event':
          description = event['description'] as String? ??
              'Workspace event';
          break;
        case 'new_message':
          description = 'New message in ${event['channel'] ?? 'channel'}';
          break;
        case 'user_joined':
          description =
              '${event['user_name'] ?? 'Someone'} joined the workspace';
          break;
        case 'user_left':
          description =
              '${event['user_name'] ?? 'Someone'} left the workspace';
          break;
        case 'call_started':
          description = 'Call started';
          break;
        case 'call_ended':
          description = 'Call ended';
          break;
        default:
          return;
      }

      final List<ActivityEvent> current =
          List<ActivityEvent>.from(events.value);
      current.insert(
        0,
        ActivityEvent(
          description: description,
          timestamp: DateTime.now(),
        ),
      );
      // Keep list reasonably small.
      if (current.length > 50) {
        current.removeRange(50, current.length);
      }
      events.value = current;
    });
  }

  /// Manually add an event to the activity feed.
  void addEvent(ActivityEvent event) {
    final List<ActivityEvent> current =
        List<ActivityEvent>.from(events.value);
    current.insert(0, event);
    // Keep list reasonably small.
    if (current.length > 50) {
      current.removeRange(50, current.length);
    }
    events.value = current;
  }
}


