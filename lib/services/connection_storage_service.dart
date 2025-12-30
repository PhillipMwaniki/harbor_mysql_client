import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/connection_info.dart';

/// Service for persisting connection information securely.
/// Non-sensitive data is stored as JSON, while passwords are stored
/// separately in secure storage.
class ConnectionStorageService {
  static const _connectionsKey = 'harbor_connections';
  static const _passwordKeyPrefix = 'harbor_pwd_';
  static const _sshPasswordKeyPrefix = 'harbor_ssh_pwd_';

  final FlutterSecureStorage _secureStorage;

  ConnectionStorageService()
      : _secureStorage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
          wOptions: WindowsOptions(),
        );

  /// Load all saved connections
  Future<List<ConnectionInfo>> loadConnections() async {
    try {
      final connectionsJson = await _secureStorage.read(key: _connectionsKey);
      if (connectionsJson == null || connectionsJson.isEmpty) {
        return [];
      }

      final List<dynamic> connectionsList = json.decode(connectionsJson);
      final connections = <ConnectionInfo>[];

      for (final connJson in connectionsList) {
        final conn = ConnectionInfo.fromJson(connJson as Map<String, dynamic>);

        // Load passwords from secure storage
        final password = await _secureStorage.read(
          key: '$_passwordKeyPrefix${conn.id}',
        );
        final sshPassword = await _secureStorage.read(
          key: '$_sshPasswordKeyPrefix${conn.id}',
        );

        connections.add(conn.copyWith(
          password: password,
          sshPassword: sshPassword,
        ));
      }

      return connections;
    } catch (e) {
      // If there's an error loading, return empty list
      return [];
    }
  }

  /// Save all connections
  Future<void> saveConnections(List<ConnectionInfo> connections) async {
    // Save non-sensitive data as JSON
    final connectionsJson = connections.map((c) => c.toJson()).toList();
    await _secureStorage.write(
      key: _connectionsKey,
      value: json.encode(connectionsJson),
    );

    // Save passwords separately in secure storage
    for (final conn in connections) {
      if (conn.password != null) {
        await _secureStorage.write(
          key: '$_passwordKeyPrefix${conn.id}',
          value: conn.password,
        );
      } else {
        await _secureStorage.delete(key: '$_passwordKeyPrefix${conn.id}');
      }

      if (conn.sshPassword != null) {
        await _secureStorage.write(
          key: '$_sshPasswordKeyPrefix${conn.id}',
          value: conn.sshPassword,
        );
      } else {
        await _secureStorage.delete(key: '$_sshPasswordKeyPrefix${conn.id}');
      }
    }
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

    // Also delete the password entries
    await _secureStorage.delete(key: '$_passwordKeyPrefix$id');
    await _secureStorage.delete(key: '$_sshPasswordKeyPrefix$id');
  }

  /// Clear all stored connections
  Future<void> clearAll() async {
    final connections = await loadConnections();

    // Delete all password entries
    for (final conn in connections) {
      await _secureStorage.delete(key: '$_passwordKeyPrefix${conn.id}');
      await _secureStorage.delete(key: '$_sshPasswordKeyPrefix${conn.id}');
    }

    // Delete the connections list
    await _secureStorage.delete(key: _connectionsKey);
  }
}
