import 'lan_discovery_service.dart';
import 'p2p_message_service.dart';
import 'p2p_crypto_service.dart';
import 'udp_socket_service.dart';
import 'p2p_chat_adapter.dart';
import 'p2p_connection_service.dart';
import 'nat/stun_service.dart';
import 'nat/hole_punch_service.dart';
import 'dht/dht_service.dart';

/// Unified P2P Manager
/// 
/// Single entry point for all P2P functionality in FLO.
/// Coordinates all services and provides simple API for the app.
/// 
/// Usage:
/// ```dart
/// final p2p = P2PManager();
/// await p2p.initialize();
/// 
/// // Messages arrive via
/// p2p.chatAdapter.messages.listen((msg) => print(msg.text));
/// 
/// // Send messages via
/// await p2p.chatAdapter.broadcastMessage('Hello P2P!');
/// ```
class P2PManager {
  // Phase 1: LAN P2P Services
  late UdpSocketService udp;
  late P2PCryptoService crypto;
  late LanDiscoveryService discovery;
  late P2PMessageService messaging;
  late P2PConnectionService connection;
  late P2PChatAdapter chatAdapter;

  // Phase 2: NAT Traversal Services (scaffolds)
  late STUNService stun;
  late HolePunchService holePunch;
  late DHTService dht;

  bool _initialized = false;

  /// Initialize all P2P services
  /// 
  /// This sets up:
  /// - UDP socket for networking
  /// - Cryptography for encryption
  /// - LAN discovery for finding peers
  /// - Message service for sending/receiving
  /// - Chat adapter for app integration
  /// - Phase 2 scaffolds (STUN, DHT, hole-punching)
  Future<void> initialize() async {
    if (_initialized) {
      print('P2PManager: Already initialized');
      return;
    }

    print('P2PManager: Initializing Phase 1 services...');

    // Phase 1: Core P2P services
    udp = UdpSocketService();
    crypto = P2PCryptoService();
    
    await udp.initialize();
    await crypto.initialize();

    discovery = LanDiscoveryService(udp, crypto);
    messaging = P2PMessageService(udp, crypto);
    connection = P2PConnectionService(udp, crypto, messaging);
    
    await connection.initialize();

    chatAdapter = P2PChatAdapter(discovery, messaging);

    // Phase 2: NAT traversal scaffolds
    stun = STUNService();
    holePunch = HolePunchService();
    dht = DHTService();

    // Start discovery
    await chatAdapter.start();

    _initialized = true;
    print('P2PManager: Initialization complete!');
    print('P2PManager: Listening for peers on LAN...');
  }

  /// Check if P2P system is initialized and active
  bool get isInitialized => _initialized;

  /// Check if any peers are connected
  bool get hasActivePeers => chatAdapter.isActive;

  /// Get list of connected peer IDs
  List<String> get activePeers => chatAdapter.connectedPeers;

  /// Get count of connected peers
  int get peerCount => chatAdapter.peerAddresses.length;

  /// Send message to specific peer
  Future<void> sendToPeer(String peerId, String message) async {
    if (!_initialized) {
      print('P2PManager: Not initialized - call initialize() first');
      return;
    }
    await chatAdapter.sendMessageToPeer(peerId, message);
  }

  /// Broadcast message to all connected peers
  Future<void> broadcast(String message) async {
    if (!_initialized) {
      print('P2PManager: Not initialized - call initialize() first');
      return;
    }
    await chatAdapter.broadcastMessage(message);
  }

  /// Dispose all P2P resources
  void dispose() {
    if (!_initialized) return;

    chatAdapter.dispose();
    connection.dispose();
    discovery.dispose();
    udp.dispose();

    _initialized = false;
    print('P2PManager: Disposed');
  }

  /// Get system status for debugging
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _initialized,
      'active_peers': peerCount,
      'peer_ids': activePeers,
      'udp_port': udp.port,
    };
  }
}
