import 'dart:async';

import '../presence/presence_service.dart';
import 'p2p_manager.dart';

/// Bridge that connects P2P discovery events to the PresenceService.
///
/// This listens to peer discovery/disconnection events from the P2P layer
/// and automatically updates the presence service so the UI reflects real-time
/// peer availability.
class P2PPresenceBridge {
  final P2PManager p2pManager;
  final PresenceService presenceService;
  StreamSubscription? _discoverySubscription;
  Timer? _heartbeatTimer;

  P2PPresenceBridge({
    required this.p2pManager,
    required this.presenceService,
  });

  /// Initialize the bridge and start listening to P2P events.
  void initialize() {
    if (!p2pManager.isInitialized) {
      print('P2PPresenceBridge: P2PManager not initialized yet');
      return;
    }

    // Listen to peer discovery events
    p2pManager.discovery.onPeerDiscovered = (String peerId, String address) {
      print('P2PPresenceBridge: Peer discovered: $peerId');
      presenceService.updatePeerStatus(peerId, PresenceStatus.online);
    };

    // Periodic heartbeat check: mark peers as offline if they haven't been seen recently
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final now = DateTime.now();
      final peers = p2pManager.discovery.discoveredPeers;

      for (final entry in peers.entries) {
        final peerId = entry.key;
        final peerInfo = entry.value;
        final timeSinceLastSeen = now.difference(peerInfo.lastSeen);

        // If peer hasn't been seen in 10 seconds, mark as offline
        if (timeSinceLastSeen.inSeconds > 10) {
          print('P2PPresenceBridge: Peer $peerId timed out');
          presenceService.updatePeerStatus(peerId, PresenceStatus.offline);
        } else {
          // Still active, ensure online status
          presenceService.updatePeerStatus(peerId, PresenceStatus.online);
        }
      }
    });

    print('P2PPresenceBridge: Initialized and listening to P2P events');
  }

  /// Dispose the bridge and clean up subscriptions.
  void dispose() {
    _discoverySubscription?.cancel();
    _heartbeatTimer?.cancel();
    p2pManager.discovery.onPeerDiscovered = null;
  }
}

