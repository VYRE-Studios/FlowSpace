import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'encryption_service.dart';

/// Database connection credentials
class DatabaseCredentials {
    final String server;
    final int port;
    final String database;
    final String username;
    final String password;
    final bool useSSL;
    final String? sslCertPath;

    DatabaseCredentials({
      required this.server,
      required this.port,
      required this.database,
      required this.username,
      required this.password,
      this.useSSL = false,
      this.sslCertPath,
    });

    /// Build PostgreSQL connection URL
    String toConnectionString() {
      final encodedUser = Uri.encodeComponent(username);
      final encodedPass = Uri.encodeComponent(password);
      final sslParam = useSSL ? '?sslmode=require' : '';
      return 'postgresql://$encodedUser:$encodedPass@$server:$port/$database$sslParam';
    }

    Map<String, dynamic> toJson() {
      return {
        'server': server,
        'port': port,
        'database': database,
        'username': username,
        'password': password,
        'useSSL': useSSL,
        'sslCertPath': sslCertPath,
      };
    }

    factory DatabaseCredentials.fromJson(Map<String, dynamic> json) {
      return DatabaseCredentials(
        server: json['server'] as String,
        port: json['port'] as int,
        database: json['database'] as String,
        username: json['username'] as String,
        password: json['password'] as String,
        useSSL: json['useSSL'] as bool? ?? false,
        sslCertPath: json['sslCertPath'] as String?,
      );
    }
}

/// Service for securely storing and retrieving database credentials
/// Uses platform secure storage (Windows Credential Manager) + encryption
class DatabaseCredentialService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
    wOptions: WindowsOptions(
      useBackwardCompatibility: false,
    ),
  );

  static const String _keyDbCredentials = 'db_credentials_encrypted';
  static const String _keyDbServer = 'db_server';
  static const String _keyDbPort = 'db_port';
  static const String _keyDbName = 'db_name';
  static const String _keyDbUser = 'db_user_encrypted';
  static const String _keyDbPassword = 'db_password_encrypted';

  /// Save database credentials securely
  /// Encrypts password before storing
  static Future<void> saveCredentials(DatabaseCredentials credentials) async {
    try {
      // Generate encryption key from master key or create one
      final masterKey = await _getOrCreateMasterKey();
      
      // Extract master key bytes for encryption
      final masterKeyBytes = await masterKey.extractBytes();
      final masterKeyForEncryption = SecretKey(masterKeyBytes);
      
      // Encrypt sensitive data
      final encryptedUser = await EncryptionService.encryptString(
        credentials.username,
        masterKeyForEncryption,
      );
      final encryptedPass = await EncryptionService.encryptString(
        credentials.password,
        masterKeyForEncryption,
      );

      // Store non-sensitive data in plain text (for quick access)
      await _storage.write(key: _keyDbServer, value: credentials.server);
      await _storage.write(key: _keyDbPort, value: credentials.port.toString());
      await _storage.write(key: _keyDbName, value: credentials.database);

      // Store encrypted sensitive data
      await _storage.write(
        key: _keyDbUser,
        value: jsonEncode(encryptedUser),
      );
      await _storage.write(
        key: _keyDbPassword,
        value: jsonEncode(encryptedPass),
      );

      // Store full credentials object (encrypted) for easy retrieval
      final credentialsJson = credentials.toJson();
      final encryptedCredentials = await EncryptionService.encryptString(
        jsonEncode(credentialsJson),
        masterKeyForEncryption,
      );
      await _storage.write(
        key: _keyDbCredentials,
        value: jsonEncode(encryptedCredentials),
      );

      print('FlowSpace: Database credentials saved securely');
    } catch (e) {
      print('FlowSpace: Error saving database credentials: $e');
      rethrow;
    }
  }

  /// Retrieve database credentials
  static Future<DatabaseCredentials?> getCredentials() async {
    try {
      final masterKey = await _getOrCreateMasterKey();
      
      // Try to get full encrypted credentials first
      final encryptedCredentialsJson = await _storage.read(key: _keyDbCredentials);
      if (encryptedCredentialsJson != null) {
        final encryptedCredentials = jsonDecode(encryptedCredentialsJson) as Map<String, dynamic>;
        
        // Extract master key bytes for decryption
        final masterKeyBytes = await masterKey.extractBytes();
        final masterKeyForDecryption = SecretKey(masterKeyBytes);
        
        // Convert Map<String, dynamic> to Map<String, String>
        final encryptedCredentialsString = {
          'ciphertext': encryptedCredentials['ciphertext'] as String,
          'nonce': encryptedCredentials['nonce'] as String,
          'mac': encryptedCredentials['mac'] as String,
        };
        
        final decryptedJson = await EncryptionService.decryptString(
          encryptedCredentialsString,
          masterKeyForDecryption,
        );
        final credentialsMap = jsonDecode(decryptedJson) as Map<String, dynamic>;
        return DatabaseCredentials.fromJson(credentialsMap);
      }

      // Fallback: reconstruct from individual fields
      final server = await _storage.read(key: _keyDbServer);
      final portStr = await _storage.read(key: _keyDbPort);
      final database = await _storage.read(key: _keyDbName);
      final encryptedUserJson = await _storage.read(key: _keyDbUser);
      final encryptedPassJson = await _storage.read(key: _keyDbPassword);

      if (server == null || portStr == null || database == null ||
          encryptedUserJson == null || encryptedPassJson == null) {
        return null;
      }

      final encryptedUserData = jsonDecode(encryptedUserJson) as Map<String, dynamic>;
      final encryptedPassData = jsonDecode(encryptedPassJson) as Map<String, dynamic>;

      // Convert Map<String, dynamic> to Map<String, String>
      final encryptedUser = {
        'ciphertext': encryptedUserData['ciphertext'] as String,
        'nonce': encryptedUserData['nonce'] as String,
        'mac': encryptedUserData['mac'] as String,
      };
      final encryptedPass = {
        'ciphertext': encryptedPassData['ciphertext'] as String,
        'nonce': encryptedPassData['nonce'] as String,
        'mac': encryptedPassData['mac'] as String,
      };

      // Extract master key bytes for decryption
      final masterKeyBytes = await masterKey.extractBytes();
      final masterKeyForDecryption = SecretKey(masterKeyBytes);

      final username = await EncryptionService.decryptString(encryptedUser, masterKeyForDecryption);
      final password = await EncryptionService.decryptString(encryptedPass, masterKeyForDecryption);

      return DatabaseCredentials(
        server: server,
        port: int.parse(portStr),
        database: database,
        username: username,
        password: password,
      );
    } catch (e) {
      print('FlowSpace: Error retrieving database credentials: $e');
      return null;
    }
  }

  /// Check if credentials are saved
  static Future<bool> hasCredentials() async {
    final server = await _storage.read(key: _keyDbServer);
    return server != null;
  }

  /// Delete saved credentials
  static Future<void> deleteCredentials() async {
    await _storage.delete(key: _keyDbServer);
    await _storage.delete(key: _keyDbPort);
    await _storage.delete(key: _keyDbName);
    await _storage.delete(key: _keyDbUser);
    await _storage.delete(key: _keyDbPassword);
    await _storage.delete(key: _keyDbCredentials);
    print('FlowSpace: Database credentials deleted');
  }

  /// Get or create master encryption key for credential storage
  static Future<SecretKey> _getOrCreateMasterKey() async {
    const masterKeyKey = 'db_credential_master_key';
    
    // Try to get existing key
    final existingKeyJson = await _storage.read(key: masterKeyKey);
    if (existingKeyJson != null) {
      final keyData = jsonDecode(existingKeyJson) as Map<String, dynamic>;
      final encryptedKey = {
        'ciphertext': keyData['ciphertext'] as String,
        'nonce': keyData['nonce'] as String,
        'mac': keyData['mac'] as String,
      };
      
      // Derive key from device ID or user ID (for decryption)
      final deviceKey = await _getDeviceKey();
      final masterKeyBytes = await EncryptionService.decrypt(encryptedKey, deviceKey);
      final algorithm = AesGcm.with256bits();
      return SecretKey(masterKeyBytes);
    }

    // Create new master key
    final masterKey = await EncryptionService.generateMasterKey();
    final deviceKey = await _getDeviceKey();
    final masterKeyBytesList = await masterKey.extractBytes();
    final masterKeyBytes = Uint8List.fromList(masterKeyBytesList);
    final encryptedKey = await EncryptionService.encrypt(masterKeyBytes, deviceKey);
    
    await _storage.write(
      key: masterKeyKey,
      value: jsonEncode({
        'ciphertext': encryptedKey['ciphertext'],
        'nonce': encryptedKey['nonce'],
        'mac': encryptedKey['mac'],
      }),
    );

    return masterKey;
  }

  /// Get device-specific key for encrypting master key
  /// Uses a combination of machine-specific identifiers
  static Future<SecretKey> _getDeviceKey() async {
    // In production, use actual device ID
    // For now, use a fixed key derived from machine name
    final machineName = Platform.environment['COMPUTERNAME'] ?? 'default';
    final keyMaterial = 'FlowSpace_DB_Credentials_$machineName';
    final saltBytes = utf8.encode('FlowSpace_Salt');
    final salt = Uint8List.fromList(saltBytes);
    
    // Derive 32-byte key using PBKDF2
    return await EncryptionService.deriveKeyFromPassword(keyMaterial, salt);
  }

  /// Test database connection with credentials
  static Future<bool> testConnection(DatabaseCredentials credentials) async {
    try {
      // This would require a PostgreSQL client library
      // For now, just validate the connection string format
      final connectionString = credentials.toConnectionString();
      if (connectionString.contains('postgresql://')) {
        // TODO: Actually test connection using pg package or similar
        return true;
      }
      return false;
    } catch (e) {
      print('FlowSpace: Connection test failed: $e');
      return false;
    }
  }
}

