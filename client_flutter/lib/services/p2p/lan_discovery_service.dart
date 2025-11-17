import 'dart:convert';
import 'dart:typed_data';
import 'udp_socket_service.dart';
import 'p2p_crypto_service.dart';

class LanDiscoveryService {
  final UdpSocketService udp;
  final P2PCryptoService crypto;

  LanDiscoveryService(this.udp, this.crypto);

  final int discoveryIntervalMs = 2000;

  Map<String, PeerInfo> discoveredPeers = {};

  Future<void> start() async {
    udp.onPacketReceived = _handlePacket;

    _broadcastLoop();
  }

  void _broadcastLoop() async {
    while (true) {
      await Future.delayed(Duration(milliseconds: discoveryIntervalMs));

      final publicKey = await crypto.getPublicKeyBytes();
      final packet = Uint8List.fromList([
        0xA1, // FLO_DISCOVER
        ...publicKey,
      ]);

      await udp.broadcastPacket(packet);
    }
  }

  void _handlePacket(Uint8List data, String address) {
    if (data.isEmpty) return;

    final type = data[0];

    if (type == 0xA1) {
      final pubKey = data.sublist(1);
      final keyHex = pubKey.map((e) => e.toRadixString(16).padLeft(2, "0")).join();

      discoveredPeers[keyHex] = PeerInfo(
        publicKey: pubKey,
        address: address,
        lastSeen: DateTime.now(),
      );

      onPeerDiscovered?.call(keyHex, address);
    }
  }

  Function(String peerId, String address)? onPeerDiscovered;

  void dispose() {
    discoveredPeers.clear();
  }
}

class PeerInfo {
  final Uint8List publicKey;
  final String address;
  final DateTime lastSeen;

  PeerInfo({
    required this.publicKey,
    required this.address,
    required this.lastSeen,
  });
}
