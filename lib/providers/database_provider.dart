import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection_info.dart';
import '../services/mysql_service.dart';
import '../services/connection_storage_service.dart';

/// Global MySQL service instance
final mysqlServiceProvider = Provider<MySqlService>((ref) {
  return MySqlService();
});

/// Connection state
enum ConnectionStatus { disconnected, connecting, connected, error }

class ConnectionState {
  final ConnectionStatus status;
  final ConnectionInfo? connection;
  final String? error;
  final int? connectionId;

  const ConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.connection,
    this.error,
    this.connectionId,
  });

  ConnectionState copyWith({
    ConnectionStatus? status,
    ConnectionInfo? connection,
    String? error,
    int? connectionId,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      connection: connection ?? this.connection,
      error: error,
      connectionId: connectionId ?? this.connectionId,
    );
  }
}

/// Connection state notifier
class ConnectionNotifier extends StateNotifier<ConnectionState> {
  final MySqlService _service;

  ConnectionNotifier(this._service) : super(const ConnectionState());

  Future<bool> connect(ConnectionInfo info) async {
    state = state.copyWith(status: ConnectionStatus.connecting, error: null);

    final result = await _service.connect(info);

    if (result.isSuccess) {
      state = ConnectionState(
        status: ConnectionStatus.connected,
        connection: info,
        connectionId: _service.connectionId,
      );
      return true;
    } else {
      state = ConnectionState(
        status: ConnectionStatus.error,
        error: result.error,
      );
      return false;
    }
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    state = const ConnectionState(status: ConnectionStatus.disconnected);
  }
}

final connectionProvider = StateNotifierProvider<ConnectionNotifier, ConnectionState>((ref) {
  final service = ref.watch(mysqlServiceProvider);
  return ConnectionNotifier(service);
});

/// Current database
final currentDatabaseProvider = StateProvider<String?>((ref) => null);

/// Selected table
final selectedTableProvider = StateProvider<String?>((ref) => null);

/// Database list
final databaseListProvider = FutureProvider<List<String>>((ref) async {
  final connectionState = ref.watch(connectionProvider);
  if (connectionState.status != ConnectionStatus.connected) return [];

  final service = ref.read(mysqlServiceProvider);
  return service.getDatabases();
});

/// Table list for current database
final tableListProvider = FutureProvider<List<String>>((ref) async {
  final connectionState = ref.watch(connectionProvider);
  final currentDb = ref.watch(currentDatabaseProvider);

  if (connectionState.status != ConnectionStatus.connected) return [];
  if (currentDb == null) return [];

  final service = ref.read(mysqlServiceProvider);
  await service.useDatabase(currentDb);
  return service.getTables();
});

/// Columns for selected table
final columnListProvider = FutureProvider<List<ColumnInfo>>((ref) async {
  final connectionState = ref.watch(connectionProvider);
  final selectedTable = ref.watch(selectedTableProvider);

  if (connectionState.status != ConnectionStatus.connected) return [];
  if (selectedTable == null) return [];

  final service = ref.read(mysqlServiceProvider);
  return service.getColumns(selectedTable);
});

/// Indexes for selected table
final indexListProvider = FutureProvider<List<IndexInfo>>((ref) async {
  final connectionState = ref.watch(connectionProvider);
  final selectedTable = ref.watch(selectedTableProvider);

  if (connectionState.status != ConnectionStatus.connected) return [];
  if (selectedTable == null) return [];

  final service = ref.read(mysqlServiceProvider);
  return service.getIndexes(selectedTable);
});

/// Table info for selected table
final tableInfoProvider = FutureProvider<TableInfo?>((ref) async {
  final connectionState = ref.watch(connectionProvider);
  final selectedTable = ref.watch(selectedTableProvider);

  if (connectionState.status != ConnectionStatus.connected) return null;
  if (selectedTable == null) return null;

  final service = ref.read(mysqlServiceProvider);
  return service.getTableInfo(selectedTable);
});

/// Table content for selected table
final tableContentProvider = FutureProvider<QueryResult>((ref) async {
  final connectionState = ref.watch(connectionProvider);
  final selectedTable = ref.watch(selectedTableProvider);

  if (connectionState.status != ConnectionStatus.connected) {
    return const QueryResult(error: 'Not connected');
  }
  if (selectedTable == null) {
    return const QueryResult(error: 'No table selected');
  }

  final service = ref.read(mysqlServiceProvider);
  return service.getTableContent(selectedTable);
});

/// CREATE TABLE statement
final createTableProvider = FutureProvider<String?>((ref) async {
  final connectionState = ref.watch(connectionProvider);
  final selectedTable = ref.watch(selectedTableProvider);

  if (connectionState.status != ConnectionStatus.connected) return null;
  if (selectedTable == null) return null;

  final service = ref.read(mysqlServiceProvider);
  return service.getCreateTable(selectedTable);
});

/// Query execution state
class QueryState {
  final String query;
  final bool isExecuting;
  final QueryResult? result;
  final DateTime? executedAt;

  const QueryState({
    this.query = '',
    this.isExecuting = false,
    this.result,
    this.executedAt,
  });

  QueryState copyWith({
    String? query,
    bool? isExecuting,
    QueryResult? result,
    DateTime? executedAt,
  }) {
    return QueryState(
      query: query ?? this.query,
      isExecuting: isExecuting ?? this.isExecuting,
      result: result ?? this.result,
      executedAt: executedAt ?? this.executedAt,
    );
  }
}

class QueryNotifier extends StateNotifier<QueryState> {
  final MySqlService _service;

  QueryNotifier(this._service) : super(const QueryState());

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  Future<void> execute() async {
    if (state.query.trim().isEmpty) return;

    state = state.copyWith(isExecuting: true);

    final result = await _service.execute(state.query);

    state = QueryState(
      query: state.query,
      isExecuting: false,
      result: result,
      executedAt: DateTime.now(),
    );
  }
}

final queryProvider = StateNotifierProvider<QueryNotifier, QueryState>((ref) {
  final service = ref.watch(mysqlServiceProvider);
  return QueryNotifier(service);
});

/// Connection storage service provider
final connectionStorageProvider = Provider<ConnectionStorageService>((ref) {
  return ConnectionStorageService();
});

/// Saved connections with persistence
class SavedConnectionsNotifier extends StateNotifier<List<ConnectionInfo>> {
  final ConnectionStorageService _storage;
  bool _initialized = false;

  SavedConnectionsNotifier(this._storage) : super([]);

  bool get isInitialized => _initialized;

  /// Load connections from secure storage
  Future<void> loadConnections() async {
    if (_initialized) return;

    final connections = await _storage.loadConnections();
    state = connections;
    _initialized = true;
  }

  /// Add a new connection
  Future<void> add(ConnectionInfo connection) async {
    state = [...state, connection];
    await _storage.saveConnections(state);
  }

  /// Update an existing connection
  Future<void> update(ConnectionInfo connection) async {
    state = state.map((c) => c.id == connection.id ? connection : c).toList();
    await _storage.saveConnections(state);
  }

  /// Remove a connection
  Future<void> remove(String id) async {
    state = state.where((c) => c.id != id).toList();
    await _storage.deleteConnection(id);
  }
}

final savedConnectionsProvider = StateNotifierProvider<SavedConnectionsNotifier, List<ConnectionInfo>>((ref) {
  final storage = ref.watch(connectionStorageProvider);
  return SavedConnectionsNotifier(storage);
});
