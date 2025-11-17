import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:convert/convert.dart';

/// Encryption service for FlowSpace zero-knowledge architecture
/// Uses AES-256-GCM for encryption and PBKDF2 for password-based key derivation
class EncryptionService {
  static const int _keyLength = 32; // 256 bits
  static const int _pbkdf2Iterations = 100000;
  static const int _saltLength = 32;

  /// Generate a new random master encryption key
  static Future<SecretKey> generateMasterKey() async {
    final algorithm = AesGcm.with256bits();
    return await algorithm.newSecretKey();
  }

  /// Derive an encryption key from a password using PBKDF2
  static Future<SecretKey> deriveKeyFromPassword(
    String password,
    Uint8List salt,
  ) async {
    final algorithm = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: _keyLength * 8, // 256 bits
    );

    return await algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  /// Generate a random salt for PBKDF2
  static Uint8List generateSalt() {
    final bytes = List<int>.generate(_saltLength, (i) => 
      DateTime.now().microsecondsSinceEpoch % 256);
    return Uint8List.fromList(bytes);
  }

  /// Encrypt data using AES-256-GCM
  /// Returns a map with 'ciphertext', 'nonce', and 'mac' (authentication tag)
  static Future<Map<String, String>> encrypt(
    Uint8List plaintext,
    SecretKey key,
  ) async {
    final algorithm = AesGcm.with256bits();
    
    final secretBox = await algorithm.encrypt(
      plaintext,
      secretKey: key,
    );

    return {
      'ciphertext': hex.encode(secretBox.cipherText),
      'nonce': hex.encode(secretBox.nonce),
      'mac': hex.encode(secretBox.mac.bytes),
    };
  }

  /// Decrypt data using AES-256-GCM
  static Future<Uint8List> decrypt(
    Map<String, String> encryptedData,
    SecretKey key,
  ) async {
    final algorithm = AesGcm.with256bits();

    final secretBox = SecretBox(
      hex.decode(encryptedData['ciphertext']!),
      nonce: hex.decode(encryptedData['nonce']!),
      mac: Mac(hex.decode(encryptedData['mac']!)),
    );

    return Uint8List.fromList(await algorithm.decrypt(
      secretBox,
      secretKey: key,
    ));
  }

  /// Encrypt a string (convenience method)
  static Future<Map<String, String>> encryptString(
    String plaintext,
    SecretKey key,
  ) async {
    return await encrypt(Uint8List.fromList(utf8.encode(plaintext)), key);
  }

  /// Decrypt to string (convenience method)
  static Future<String> decryptString(
    Map<String, String> encryptedData,
    SecretKey key,
  ) async {
    final bytes = await decrypt(encryptedData, key);
    return utf8.decode(bytes);
  }

  /// Encrypt a master key with a password-derived key
  /// This is used to store the user's master key securely
  static Future<Map<String, dynamic>> encryptMasterKey(
    SecretKey masterKey,
    String password,
  ) async {
    // Generate salt for PBKDF2
    final salt = generateSalt();
    
    // Derive key from password
    final derivedKey = await deriveKeyFromPassword(password, salt);
    
    // Extract master key bytes
    final masterKeyBytes = await masterKey.extractBytes();
    
    // Encrypt master key
    final encrypted = await encrypt(Uint8List.fromList(masterKeyBytes), derivedKey);
    
    return {
      'salt': hex.encode(salt),
      'ciphertext': encrypted['ciphertext'],
      'nonce': encrypted['nonce'],
      'mac': encrypted['mac'],
      'version': 1, // Encryption version for future migrations
    };
  }

  /// Decrypt a master key using a password
  static Future<SecretKey> decryptMasterKey(
    Map<String, dynamic> encryptedMasterKey,
    String password,
  ) async {
    // Extract salt
    final salt = Uint8List.fromList(hex.decode(encryptedMasterKey['salt'] as String));
    
    // Derive key from password
    final derivedKey = await deriveKeyFromPassword(password, salt);
    
    // Decrypt master key
    final masterKeyBytes = await decrypt({
      'ciphertext': encryptedMasterKey['ciphertext'] as String,
      'nonce': encryptedMasterKey['nonce'] as String,
      'mac': encryptedMasterKey['mac'] as String,
    }, derivedKey);
    
    return SecretKey(masterKeyBytes);
  }

  /// Convert SecretKey to storable format
  static Future<String> secretKeyToHex(SecretKey key) async {
    final bytes = await key.extractBytes();
    return hex.encode(bytes);
  }

  /// Convert hex string back to SecretKey
  static SecretKey secretKeyFromHex(String hexString) {
    return SecretKey(hex.decode(hexString));
  }
}
