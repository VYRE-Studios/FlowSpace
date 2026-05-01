import 'dart:async';
import 'package:flutter/foundation.dart';

import '../realtime/socket_service.dart';
import '../notification_service.dart';
import '../sound_service.dart';

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

  /// Map of userId -> displayName for showing notifications
  final Map<String, String> _userNames = {};

  /// Enable/disable presence notifications
  bool notificationsEnabled = true;

  bool _initialized = false;
  Timer? _heartbeatTimer;

  void init() {
    if (_initialized) return;
    _initialized = true;

    // Start heartbeat timer - send presence ping every 10 seconds
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      SocketService.instance.send(<String, dynamic>{
        'type': 'presence_ping',
        'status': selfPresence.value,
      });
    });

    SocketService.instance.events.listen((Map<String, dynamic> event) {
      switch (event['type']) {
        case 'presence_update':
          final String? userId = event['user_id'] as String?;
          final bool? online = event['online'] as bool?;
          if (userId == null || online == null) return;
          
          // Store previous state to detect changes
          final bool? previousState = memberStatus.value[userId];
          
          final Map<String, bool> updated =
              Map<String, bool>.from(memberStatus.value);
          updated[userId] = online;
          memberStatus.value = updated;
          
          // Show notification if state changed
          if (notificationsEnabled && previousState != null && previousState != online) {
            _showPresenceNotification(userId, online);
          }
          break;
        case 'presence.update':
          // Handle backend format: {userId, status, lastActiveAt}
          final String? userId = event['userId'] as String?;
          final String? status = event['status'] as String?;
          final String? displayName = event['displayName'] as String?;
          
          if (userId != null && status != null) {
            // Store user name for notifications
            if (displayName != null) {
              _userNames[userId] = displayName;
            }
            
            // Store previous state to detect changes
            final bool? previousState = memberStatus.value[userId];
            final bool online = (status == 'online');
            
            final Map<String, bool> updated =
                Map<String, bool>.from(memberStatus.value);
            updated[userId] = online;
            memberStatus.value = updated;
            
            // Show notification if state changed
            if (notificationsEnabled && previousState != null && previousState != online) {
              _showPresenceNotification(userId, online);
            }
          }
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

  void dispose() {
    _heartbeatTimer?.cancel();
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

  /// Set user display name for notifications
  void setUserName(String userId, String displayName) {
    _userNames[userId] = displayName;
  }

  /// Show presence notification and play sound
  void _showPresenceNotification(String userId, bool online) {
    final userName = _userNames[userId] ?? 'User';
    final status = online ? 'is now online' : 'went offline';
    
    // Show desktop notification
    NotificationService.instance.showNotification(
      title: 'Presence Update',
      body: '$userName $status',
      id: userId.hashCode,
    );
    
    // Play sound
    if (online) {
      SoundService.instance.playOnline();
    } else {
      SoundService.instance.playOffline();
    }
  }
}

/// Presence status enum for P2P peers.
enum PresenceStatus {
  online,
  offline,
}


