import 'package:flutter/foundation.dart';

import '../realtime/socket_service.dart';

/// Tracks online/offline state for users based on realtime events.
class PresenceService {
  PresenceService._();

  static final PresenceService instance = PresenceService._();

  /// Map of userId -> online.
  final ValueNotifier<Map<String, bool>> memberStatus =
      ValueNotifier<Map<String, bool>>(<String, bool>{});

  /// Map of peerId -> presence status (for P2P peers).
  final ValueNotifier<Map<String, PresenceStatus>> peerStatus =
      ValueNotifier<Map<String, PresenceStatus>>(<String, PresenceStatus>{});

  /// Current user's presence status string, e.g. "online", "away".
  final ValueNotifier<String> selfPresence =
      ValueNotifier<String>('online');

  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;

    SocketService.instance.events.listen((Map<String, dynamic> event) {
      switch (event['type']) {
        case 'presence_update':
          final String? userId = event['user_id'] as String?;
          final bool? online = event['online'] as bool?;
          if (userId == null || online == null) return;
          final Map<String, bool> updated =
              Map<String, bool>.from(memberStatus.value);
          updated[userId] = online;
          memberStatus.value = updated;
          break;
        case 'self_presence':
          final String? status = event['status'] as String?;
          if (status != null) {
            selfPresence.value = status;
          }
          break;
        default:
      }
    });
  }

  void setPresence(String status) {
    selfPresence.value = status;
    SocketService.instance.send(<String, dynamic>{
      'type': 'set_presence',
      'status': status,
    });
  }

  /// Update the presence status for a P2P peer.
  void updatePeerStatus(String peerId, PresenceStatus status) {
    final updated = Map<String, PresenceStatus>.from(peerStatus.value);
    updated[peerId] = status;
    peerStatus.value = updated;
  }
}

/// Presence status enum for P2P peers.
enum PresenceStatus {
  online,
  offline,
}


