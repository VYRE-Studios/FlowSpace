import 'dart:async';
import 'dart:typed_data';
import 'p2p_message_service.dart';
import 'lan_discovery_service.dart';

/// Adapter layer that bridges P2P messaging with FLO's chat system
/// 
/// This provides a clean integration point that:
/// - Routes messages through P2P when peers are available
/// - Provides stream-based message reception for UI updates
/// - Maintains peer address mappings for message routing
/// - Handles discovery and connection lifecycle
class P2PChatAdapter {
  final LanDiscoveryService discovery;
  final P2PMessageService messaging;

  final StreamController<P2PMessage> _incoming = StreamController<P2PMessage>.broadcast();

  /// Stream of incoming P2P messages
  Stream<P2PMessage> get messages => _incoming.stream;

  /// Map of peer IDs to their network addresses
  Map<String, String> peerAddresses = {};

  /// Map of peer IDs to their public keys
  Map<String, Uint8List> peerKeys = {};

  P2PChatAdapter(this.discovery, this.messaging) {
    discovery.onPeerDiscovered = (peerId, address) {
      peerAddresses[peerId] = address;
      
      final peer = discovery.discoveredPeers[peerId];
      if (peer != null) {
        peerKeys[peerId] = peer.publicKey;
      }
    };

    messaging.onMessageReceived = (msg) {
      _incoming.add(P2PMessage(
        text: msg,
        timestamp: DateTime.now(),
        senderId: 'unknown', // Will be enhanced in Phase 2
        isLocal: false,
      ));
    };
  }

  /// Send a message to a specific peer
  Future<void> sendMessageToPeer(String peerId, String message) async {
    if (peerAddresses.containsKey(peerId)) {
      final address = peerAddresses[peerId]!;
      await messaging.sendMessage(message, address);
      
      _incoming.add(P2PMessage(
        text: message,
        timestamp: DateTime.now(),
        senderId: 'local',
        isLocal: true,
      ));
    }
  }

  /// Broadcast a message to all connected peers
  Future<void> broadcastMessage(String message) async {
    for (final entry in peerAddresses.entries) {
      await messaging.sendMessage(message, entry.value);
    }
    
    if (peerAddresses.isNotEmpty) {
      _incoming.add(P2PMessage(
        text: message,
        timestamp: DateTime.now(),
        senderId: 'local',
        isLocal: true,
      ));
    }
  }

  /// Start the discovery and messaging services
  Future<void> start() async {
    await discovery.start();
  }

  /// Check if P2P is active and has connected peers
  bool get isActive => peerAddresses.isNotEmpty;

  /// Get list of connected peer IDs
  List<String> get connectedPeers => peerAddresses.keys.toList();

  /// Dispose resources
  void dispose() {
    _incoming.close();
    discovery.dispose();
  }
}

/// Represents a P2P message with metadata
class P2PMessage {
  final String text;
  final DateTime timestamp;
  final String senderId;
  final bool isLocal;

  P2PMessage({
    required this.text,
    required this.timestamp,
    required this.senderId,
    required this.isLocal,
  });
}
