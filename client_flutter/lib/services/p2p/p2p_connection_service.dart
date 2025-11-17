import 'dart:typed_data';
import 'udp_socket_service.dart';
import 'p2p_crypto_service.dart';
import 'p2p_message_service.dart';

class P2PConnectionService {
  final UdpSocketService udp;
  final P2PCryptoService crypto;
  final P2PMessageService messageService;

  P2PConnectionService(this.udp, this.crypto, this.messageService);

  Map<String, P2PConnection> activeConnections = {};

  Future<void> initialize() async {
    udp.onPacketReceived = _handlePacket;
  }

  Future<void> connectToPeer(String peerId, String address, Uint8List peerPublicKey) async {
    // Send handshake packet
    final myPublicKey = await crypto.getPublicKeyBytes();
    final packet = Uint8List.fromList([
      0xA2, // FLO_HANDSHAKE
      ...myPublicKey,
    ]);

    await udp.sendPacket(packet, address);

    // Generate session key
    final privateKeyBytes = await crypto.identityKeypair.extractPrivateKeyBytes();
    final sharedSecret = await crypto.deriveSharedSecret(
      Uint8List.fromList(privateKeyBytes),
      peerPublicKey,
    );

    // Store connection
    final connection = P2PConnection(
      peerId: peerId,
      address: address,
      sessionKey: sharedSecret,
      lastActive: DateTime.now(),
    );

    activeConnections[peerId] = connection;
    await messageService.setSessionKey(sharedSecret);

    onConnectionEstablished?.call(peerId, address);
  }

  void _handlePacket(Uint8List data, String address) {
    if (data.isEmpty) return;

    final type = data[0];

    if (type == 0xA2) {
      // Handshake packet
      _handleHandshake(data, address);
    } else if (type == 0xA3) {
      // Message packet
      messageService.handleIncoming(data);
    }
  }

  Future<void> _handleHandshake(Uint8List data, String address) async {
    final peerPublicKey = data.sublist(1);
    final keyHex = peerPublicKey.map((e) => e.toRadixString(16).padLeft(2, "0")).join();

    // Derive shared secret
    final privateKeyBytes = await crypto.identityKeypair.extractPrivateKeyBytes();
    final sharedSecret = await crypto.deriveSharedSecret(
      Uint8List.fromList(privateKeyBytes),
      peerPublicKey,
    );

    // Store connection
    final connection = P2PConnection(
      peerId: keyHex,
      address: address,
      sessionKey: sharedSecret,
      lastActive: DateTime.now(),
    );

    activeConnections[keyHex] = connection;
    await messageService.setSessionKey(sharedSecret);

    onConnectionEstablished?.call(keyHex, address);

    // Send handshake response
    final myPublicKey = await crypto.getPublicKeyBytes();
    final response = Uint8List.fromList([
      0xA2, // FLO_HANDSHAKE
      ...myPublicKey,
    ]);

    await udp.sendPacket(response, address);
  }

  Function(String peerId, String address)? onConnectionEstablished;

  void dispose() {
    activeConnections.clear();
  }
}

class P2PConnection {
  final String peerId;
  final String address;
  final Uint8List sessionKey;
  final DateTime lastActive;

  P2PConnection({
    required this.peerId,
    required this.address,
    required this.sessionKey,
    required this.lastActive,
  });
}
