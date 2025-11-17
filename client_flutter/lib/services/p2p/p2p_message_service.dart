import 'dart:typed_data';
import 'dart:convert';
import 'udp_socket_service.dart';
import 'p2p_crypto_service.dart';

class P2PMessageService {
  final UdpSocketService udp;
  final P2PCryptoService crypto;
  Uint8List? sessionKey;

  P2PMessageService(this.udp, this.crypto);

  Future<void> setSessionKey(Uint8List key) async {
    sessionKey = key;
  }

  Future<void> sendMessage(String text, String address) async {
    if (sessionKey == null) return;

    final encoded = Uint8List.fromList(utf8.encode(text));
    final encrypted = await crypto.encrypt(encoded, sessionKey!);

    final packet = Uint8List.fromList([
      0xA3, // FLO_MESSAGE
      ...encrypted,
    ]);

    await udp.sendPacket(packet, address);
  }

  void handleIncoming(Uint8List data) async {
    if (sessionKey == null) return;
    if (data.isEmpty) return;

    final type = data[0];
    if (type != 0xA3) return;

    final encrypted = data.sublist(1);
    final clear = await crypto.decrypt(encrypted, sessionKey!);
    final message = utf8.decode(clear);

    onMessageReceived?.call(message);
  }

  Function(String message)? onMessageReceived;
}
