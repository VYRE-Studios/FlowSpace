import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:client_flutter/services/encryption_service.dart';

void main() {
  group('EncryptionService Tests', () {
    test('Generate master key', () async {
      final masterKey = await EncryptionService.generateMasterKey();
      expect(masterKey, isNotNull);
      
      // Verify key is 256 bits (32 bytes)
      final keyBytes = await masterKey.extractBytes();
      expect(keyBytes.length, equals(32));
    });

    test('Derive key from password with PBKDF2', () async {
      final password = 'test_password_123';
      final salt = EncryptionService.generateSalt();
      
      final derivedKey = await EncryptionService.deriveKeyFromPassword(
        password,
        salt,
      );
      
      expect(derivedKey, isNotNull);
      final keyBytes = await derivedKey.extractBytes();
      expect(keyBytes.length, equals(32));
      
      // Same password + salt should produce same key
      final derivedKey2 = await EncryptionService.deriveKeyFromPassword(
        password,
        salt,
      );
      final keyBytes2 = await derivedKey2.extractBytes();
      expect(keyBytes, equals(keyBytes2));
    });

    test('Encrypt and decrypt string', () async {
      final masterKey = await EncryptionService.generateMasterKey();
      final plaintext = 'Hello, FlowSpace! This is a secret message.';
      
      // Encrypt
      final encrypted = await EncryptionService.encryptString(plaintext, masterKey);
      expect(encrypted['ciphertext'], isNotNull);
      expect(encrypted['nonce'], isNotNull);
      expect(encrypted['mac'], isNotNull);
      
      // Verify ciphertext is different from plaintext
      expect(encrypted['ciphertext'], isNot(equals(plaintext)));
      
      // Decrypt
      final decrypted = await EncryptionService.decryptString(encrypted, masterKey);
      expect(decrypted, equals(plaintext));
    });

    test('Encrypt and decrypt binary data', () async {
      final masterKey = await EncryptionService.generateMasterKey();
      final plaintext = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      
      // Encrypt
      final encrypted = await EncryptionService.encrypt(plaintext, masterKey);
      expect(encrypted['ciphertext'], isNotNull);
      
      // Decrypt
      final decrypted = await EncryptionService.decrypt(encrypted, masterKey);
      expect(decrypted, equals(plaintext));
    });

    test('Encrypt and decrypt master key with password', () async {
      final password = 'my_secure_password_456';
      final masterKey = await EncryptionService.generateMasterKey();
      final originalKeyBytes = await masterKey.extractBytes();
      
      // Encrypt master key
      final encryptedMasterKey = await EncryptionService.encryptMasterKey(
        masterKey,
        password,
      );
      
      expect(encryptedMasterKey['salt'], isNotNull);
      expect(encryptedMasterKey['ciphertext'], isNotNull);
      expect(encryptedMasterKey['nonce'], isNotNull);
      expect(encryptedMasterKey['mac'], isNotNull);
      expect(encryptedMasterKey['version'], equals(1));
      
      // Decrypt master key
      final decryptedMasterKey = await EncryptionService.decryptMasterKey(
        encryptedMasterKey,
        password,
      );
      
      final decryptedKeyBytes = await decryptedMasterKey.extractBytes();
      expect(decryptedKeyBytes, equals(originalKeyBytes));
    });

    test('Wrong password fails to decrypt master key', () async {
      final correctPassword = 'correct_password';
      final wrongPassword = 'wrong_password';
      final masterKey = await EncryptionService.generateMasterKey();
      
      // Encrypt with correct password
      final encryptedMasterKey = await EncryptionService.encryptMasterKey(
        masterKey,
        correctPassword,
      );
      
      // Try to decrypt with wrong password - should throw
      expect(
        () async => await EncryptionService.decryptMasterKey(
          encryptedMasterKey,
          wrongPassword,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('SecretKey hex conversion', () async {
      final masterKey = await EncryptionService.generateMasterKey();
      final originalBytes = await masterKey.extractBytes();
      
      // Convert to hex
      final hex = await EncryptionService.secretKeyToHex(masterKey);
      expect(hex, isNotNull);
      expect(hex.length, equals(64)); // 32 bytes = 64 hex characters
      
      // Convert back from hex
      final restoredKey = EncryptionService.secretKeyFromHex(hex);
      final restoredBytes = await restoredKey.extractBytes();
      
      expect(restoredBytes, equals(originalBytes));
    });

    test('Multiple encryption produces different ciphertexts (nonce uniqueness)', () async {
      final masterKey = await EncryptionService.generateMasterKey();
      final plaintext = 'Same message';
      
      final encrypted1 = await EncryptionService.encryptString(plaintext, masterKey);
      final encrypted2 = await EncryptionService.encryptString(plaintext, masterKey);
      
      // Ciphertexts should be different due to different nonces
      expect(encrypted1['ciphertext'], isNot(equals(encrypted2['ciphertext'])));
      expect(encrypted1['nonce'], isNot(equals(encrypted2['nonce'])));
      
      // But both should decrypt to same plaintext
      final decrypted1 = await EncryptionService.decryptString(encrypted1, masterKey);
      final decrypted2 = await EncryptionService.decryptString(encrypted2, masterKey);
      
      expect(decrypted1, equals(plaintext));
      expect(decrypted2, equals(plaintext));
    });

    test('Encryption roundtrip for large data', () async {
      final masterKey = await EncryptionService.generateMasterKey();
      
      // Create 1MB of data
      final plaintext = Uint8List(1024 * 1024);
      for (int i = 0; i < plaintext.length; i++) {
        plaintext[i] = i % 256;
      }
      
      // Encrypt
      final encrypted = await EncryptionService.encrypt(plaintext, masterKey);
      
      // Decrypt
      final decrypted = await EncryptionService.decrypt(encrypted, masterKey);
      
      expect(decrypted, equals(plaintext));
    });

    test('Complete workflow: password -> master key -> data encryption', () async {
      final userPassword = 'user_password_789';
      
      // 1. Generate master key
      final masterKey = await EncryptionService.generateMasterKey();
      
      // 2. Encrypt master key with password
      final encryptedMasterKey = await EncryptionService.encryptMasterKey(
        masterKey,
        userPassword,
      );
      
      // 3. Encrypt some data with master key
      final secretData = 'This is secret FlowSpace data!';
      final encryptedData = await EncryptionService.encryptString(
        secretData,
        masterKey,
      );
      
      // Simulate storage/retrieval: only encrypted master key and encrypted data are stored
      // User enters password again to decrypt...
      
      // 4. Decrypt master key with password
      final recoveredMasterKey = await EncryptionService.decryptMasterKey(
        encryptedMasterKey,
        userPassword,
      );
      
      // 5. Decrypt data with recovered master key
      final recoveredData = await EncryptionService.decryptString(
        encryptedData,
        recoveredMasterKey,
      );
      
      expect(recoveredData, equals(secretData));
    });
  });
}
