import 'dart:typed_data';
import 'udp_socket_service.dart';
import 'p2p_crypto_service.dart';
import 'lan_discovery_service.dart';
import 'p2p_message_service.dart';
import 'p2p_connection_service.dart';

class P2PRouterService {
  late UdpSocketService udpService;
  late P2PCryptoService cryptoService;
  late LanDiscoveryService discoveryService;
  late P2PMessageService messageService;
  late P2PConnectionService connectionService;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Create services
    udpService = UdpSocketService();
    cryptoService = P2PCryptoService();
    
    // Initialize in order
    await udpService.initialize();
    await cryptoService.initialize();

    // Create dependent services
    messageService = P2PMessageService(udpService, cryptoService);
    discoveryService = LanDiscoveryService(udpService, cryptoService);
    connectionService = P2PConnectionService(udpService, cryptoService, messageService);

    // Initialize connection service
    await connectionService.initialize();

    // Set up callbacks
    discoveryService.onPeerDiscovered = (peerId, address) {
      print('P2P: Discovered peer $peerId at $address');
      onPeerDiscovered?.call(peerId, address);
    };

    connectionService.onConnectionEstablished = (peerId, address) {
      print('P2P: Connection established with $peerId at $address');
      onConnectionEstablished?.call(peerId, address);
    };

    messageService.onMessageReceived = (message) {
      print('P2P: Message received: $message');
      onMessageReceived?.call(message);
    };

    // Start discovery
    await discoveryService.start();

    _initialized = true;
    print('P2P Router initialized successfully');
  }

  Future<void> connectToPeer(String peerId, String address) async {
    final peer = discoveryService.discoveredPeers[peerId];
    if (peer == null) {
      print('P2P: Peer $peerId not found in discovered peers');
      return;
    }

    await connectionService.connectToPeer(peerId, address, peer.publicKey);
  }

  Future<void> sendMessage(String text, String peerId) async {
    final connection = connectionService.activeConnections[peerId];
    if (connection == null) {
      print('P2P: No active connection to peer $peerId');
      return;
    }

    await messageService.sendMessage(text, connection.address);
  }

  List<String> getDiscoveredPeers() {
    return discoveryService.discoveredPeers.keys.toList();
  }

  List<String> getActivePeers() {
    return connectionService.activeConnections.keys.toList();
  }

  Function(String peerId, String address)? onPeerDiscovered;
  Function(String peerId, String address)? onConnectionEstablished;
  Function(String message)? onMessageReceived;

  void dispose() {
    discoveryService.dispose();
    connectionService.dispose();
    udpService.dispose();
    _initialized = false;
  }
}
