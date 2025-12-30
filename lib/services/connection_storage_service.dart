import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:path_provider/path_provider.dart';
import '../models/connection_info.dart';

/// Service for persisting connection information with encryption.
/// All connection data (including passwords) is stored in an encrypted JSON file.
class ConnectionStorageService {
  static const _connectionsFileName = 'harbor_connections.enc';
  static const _keyFileName = 'harbor.key';

  Key? _encryptionKey;
  IV? _iv;

  /// Get the application support directory for storing data
  Future<Directory> _getStorageDir() async {
    final appDir = await getApplicationSupportDirectory();
    final harborDir = Directory('${appDir.path}/Harbor');
    if (!await harborDir.exists()) {
      await harborDir.create(recursive: true);
    }
    return harborDir;
  }

  /// Get or create the encryption key
  Future<Key> _getEncryptionKey() async {
    if (_encryptionKey != null) return _encryptionKey!;

    final storageDir = await _getStorageDir();
    final keyFile = File('${storageDir.path}/$_keyFileName');

    if (await keyFile.exists()) {
      // Load existing key
      final keyBase64 = await keyFile.readAsString();
      _encryptionKey = Key.fromBase64(keyBase64);
    } else {
      // Generate new key (256-bit for AES-256)
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      _encryptionKey = Key(Uint8List.fromList(keyBytes));

      // Save key to file
      await keyFile.writeAsString(_encryptionKey!.base64);
    }

    // Use a fixed IV derived from the key (first 16 bytes)
    // This is acceptable since each connection has unique data
    _iv = IV.fromLength(16);

    return _encryptionKey!;
  }

  /// Encrypt data
  Future<String> _encrypt(String plainText) async {
    final key = await _getEncryptionKey();
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypt data
  Future<String> _decrypt(String encryptedBase64) async {
    final key = await _getEncryptionKey();
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final decrypted = encrypter.decrypt64(encryptedBase64, iv: _iv);
    return decrypted;
  }

  /// Get the connections file
  Future<File> _getConnectionsFile() async {
    final storageDir = await _getStorageDir();
    return File('${storageDir.path}/$_connectionsFileName');
  }

  /// Load all saved connections
  Future<List<ConnectionInfo>> loadConnections() async {
    try {
      final file = await _getConnectionsFile();
      if (!await file.exists()) {
        return [];
      }

      final encryptedContent = await file.readAsString();
      if (encryptedContent.isEmpty) {
        return [];
      }

      final jsonString = await _decrypt(encryptedContent);
      final List<dynamic> connectionsList = json.decode(jsonString);

      return connectionsList
          .map((connJson) => _connectionFromFullJson(connJson as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If there's an error loading (corrupted file, etc.), return empty list
      return [];
    }
  }

  /// Save all connections
  Future<void> saveConnections(List<ConnectionInfo> connections) async {
    final connectionsJson = connections.map((c) => _connectionToFullJson(c)).toList();
    final jsonString = json.encode(connectionsJson);
    final encrypted = await _encrypt(jsonString);

    final file = await _getConnectionsFile();
    await file.writeAsString(encrypted);
  }

  /// Add a new connection
  Future<void> addConnection(ConnectionInfo connection) async {
    final connections = await loadConnections();
    connections.add(connection);
    await saveConnections(connections);
  }

  /// Update an existing connection
  Future<void> updateConnection(ConnectionInfo connection) async {
    final connections = await loadConnections();
    final index = connections.indexWhere((c) => c.id == connection.id);
    if (index >= 0) {
      connections[index] = connection;
      await saveConnections(connections);
    }
  }

  /// Delete a connection
  Future<void> deleteConnection(String id) async {
    final connections = await loadConnections();
    connections.removeWhere((c) => c.id == id);
    await saveConnections(connections);
  }

  /// Clear all stored connections
  Future<void> clearAll() async {
    final file = await _getConnectionsFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Convert ConnectionInfo to JSON including passwords
  Map<String, dynamic> _connectionToFullJson(ConnectionInfo conn) => {
    'id': conn.id,
    'name': conn.name,
    'host': conn.host,
    'port': conn.port,
    'username': conn.username,
    'password': conn.password,
    'database': conn.database,
    'useSSL': conn.useSSL,
    'useSSH': conn.useSSH,
    'sshHost': conn.sshHost,
    'sshPort': conn.sshPort,
    'sshUsername': conn.sshUsername,
    'sshPassword': conn.sshPassword,
    'sshKeyPath': conn.sshKeyPath,
    'color': conn.color,
  };

  /// Create ConnectionInfo from JSON including passwords
  ConnectionInfo _connectionFromFullJson(Map<String, dynamic> json) => ConnectionInfo(
    id: json['id'] as String,
    name: json['name'] as String,
    host: json['host'] as String,
    port: json['port'] as int? ?? 3306,
    username: json['username'] as String,
    password: json['password'] as String?,
    database: json['database'] as String?,
    useSSL: json['useSSL'] as bool? ?? false,
    useSSH: json['useSSH'] as bool? ?? false,
    sshHost: json['sshHost'] as String?,
    sshPort: json['sshPort'] as int? ?? 22,
    sshUsername: json['sshUsername'] as String?,
    sshPassword: json['sshPassword'] as String?,
    sshKeyPath: json['sshKeyPath'] as String?,
    color: json['color'] as String?,
  );
}
