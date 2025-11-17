import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class P2PCryptoService {
  final algorithm = X25519();
  final cipher = Chacha20.poly1305Aead();

  late SimpleKeyPair identityKeypair;

  Future<void> initialize() async {
    identityKeypair = await algorithm.newKeyPair();
  }

  Future<Uint8List> getPublicKeyBytes() async {
    final key = await identityKeypair.extractPublicKey();
    return Uint8List.fromList(key.bytes);
  }

  Future<Uint8List> deriveSharedSecret(
    Uint8List privateKeyBytes,
    Uint8List publicKeyBytes,
  ) async {
    final privateKey = SimpleKeyPairData(
      privateKeyBytes,
      publicKey: SimplePublicKey(privateKeyBytes.sublist(0, 32), type: KeyPairType.x25519),
      type: KeyPairType.x25519,
    );
    final publicKey = SimplePublicKey(publicKeyBytes, type: KeyPairType.x25519);

    final shared = await algorithm.sharedSecretKey(
      keyPair: privateKey,
      remotePublicKey: publicKey,
    );

    final secretBytes = await shared.extractBytes();
    return Uint8List.fromList(secretBytes);
  }

  Future<Uint8List> encrypt(Uint8List message, Uint8List key) async {
    final secretKey = SecretKey(key);
    final nonce = cipher.newNonce();
    final secretBox = await cipher.encrypt(
      message,
      secretKey: secretKey,
      nonce: nonce,
    );

    return Uint8List.fromList([
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
  }

  Future<Uint8List> decrypt(Uint8List data, Uint8List key) async {
    final nonce = data.sublist(0, 12);
    final mac = Mac(data.sublist(data.length - 16));
    final ciphertext = data.sublist(12, data.length - 16);

    final secretKey = SecretKey(key);

    final box = SecretBox(ciphertext, nonce: nonce, mac: mac);

    final clear = await cipher.decrypt(
      box,
      secretKey: secretKey,
    );

    return Uint8List.fromList(clear);
  }
}
