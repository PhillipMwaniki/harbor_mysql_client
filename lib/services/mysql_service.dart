import 'package:mysql_client/mysql_client.dart';
import '../models/connection_info.dart';

/// Result of a query execution
class QueryResult {
  final List<String> columns;
  final List<Map<String, dynamic>> rows;
  final int affectedRows;
  final Duration executionTime;
  final String? error;

  const QueryResult({
    this.columns = const [],
    this.rows = const [],
    this.affectedRows = 0,
    this.executionTime = Duration.zero,
    this.error,
  });

  bool get isSuccess => error == null;
  bool get hasRows => rows.isNotEmpty;
}

/// Column metadata from database
class ColumnInfo {
  final String name;
  final String type;
  final bool nullable;
  final String? key;
  final String? defaultValue;
  final String? extra;

  const ColumnInfo({
    required this.name,
    required this.type,
    this.nullable = true,
    this.key,
    this.defaultValue,
    this.extra,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
    'nullable': nullable,
    'key': key ?? '',
    'default': defaultValue,
    'extra': extra ?? '',
  };
}

/// Index metadata from database
class IndexInfo {
  final String name;
  final List<String> columns;
  final bool unique;
  final bool primary;

  const IndexInfo({
    required this.name,
    required this.columns,
    this.unique = false,
    this.primary = false,
  });
}

/// Table metadata from database
class TableInfo {
  final String name;
  final String? engine;
  final int? rows;
  final int? dataLength;
  final int? indexLength;
  final String? collation;
  final String? createTime;
  final String? updateTime;
  final int? autoIncrement;

  const TableInfo({
    required this.name,
    this.engine,
    this.rows,
    this.dataLength,
    this.indexLength,
    this.collation,
    this.createTime,
    this.updateTime,
    this.autoIncrement,
  });
}

/// MySQL connection and query service
class MySqlService {
  MySQLConnection? _connection;
  ConnectionInfo? _connectionInfo;
  int? _connectionId;

  bool get isConnected => _connection != null;
  ConnectionInfo? get currentConnection => _connectionInfo;
  int? get connectionId => _connectionId;

  /// Connect to a MySQL database
  Future<QueryResult> connect(ConnectionInfo info) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Close existing connection if any
      await disconnect();

      _connection = await MySQLConnection.createConnection(
        host: info.host,
        port: info.port,
        userName: info.username,
        password: info.password ?? '',
        databaseName: info.database,
        secure: info.useSSL,
      );
      await _connection!.connect();

      _connectionInfo = info;

      // Get connection ID for query cancellation
      final idResult = await _connection!.execute('SELECT CONNECTION_ID() as id');
      for (final row in idResult.rows) {
        _connectionId = int.tryParse(row.colAt(0) ?? '');
      }

      stopwatch.stop();
      return QueryResult(
        executionTime: stopwatch.elapsed,
        affectedRows: 0,
      );
    } catch (e) {
      stopwatch.stop();
      _connection = null;
      _connectionInfo = null;
      return QueryResult(
        error: e.toString(),
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Disconnect from the database
  Future<void> disconnect() async {
    if (_connection != null) {
      try {
        await _connection!.close();
      } catch (_) {
        // Ignore close errors
      }
      _connection = null;
      _connectionInfo = null;
      _connectionId = null;
    }
  }

  /// Execute a SQL query
  Future<QueryResult> execute(String sql) async {
    if (_connection == null) {
      return const QueryResult(error: 'Not connected to database');
    }

    final stopwatch = Stopwatch()..start();

    try {
      final result = await _connection!.execute(sql);
      stopwatch.stop();

      final columns = <String>[];
      final rows = <Map<String, dynamic>>[];

      // Extract column names
      if (result.cols.isNotEmpty) {
        for (final col in result.cols) {
          columns.add(col.name);
        }
      }

      // Extract rows
      for (final row in result.rows) {
        final rowMap = <String, dynamic>{};
        for (var i = 0; i < columns.length; i++) {
          rowMap[columns[i]] = row.colAt(i);
        }
        rows.add(rowMap);
      }

      return QueryResult(
        columns: columns,
        rows: rows,
        affectedRows: result.affectedRows.toInt(),
        executionTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return QueryResult(
        error: e.toString(),
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Get list of databases
  Future<List<String>> getDatabases() async {
    final result = await execute('SHOW DATABASES');
    if (!result.isSuccess) return [];

    return result.rows
        .map((row) => row.values.first?.toString() ?? '')
        .where((db) => db.isNotEmpty)
        .toList();
  }

  /// Switch to a different database
  Future<QueryResult> useDatabase(String database) async {
    return execute('USE `$database`');
  }

  /// Get list of tables in current database
  Future<List<String>> getTables() async {
    final result = await execute('SHOW TABLES');
    if (!result.isSuccess) return [];

    return result.rows
        .map((row) => row.values.first?.toString() ?? '')
        .where((table) => table.isNotEmpty)
        .toList();
  }

  /// Get table information
  Future<TableInfo?> getTableInfo(String table) async {
    final result = await execute('''
      SELECT
        TABLE_NAME, ENGINE, TABLE_ROWS, DATA_LENGTH, INDEX_LENGTH,
        TABLE_COLLATION, CREATE_TIME, UPDATE_TIME, AUTO_INCREMENT
      FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '$table'
    ''');

    if (!result.isSuccess || result.rows.isEmpty) return null;

    final row = result.rows.first;
    return TableInfo(
      name: row['TABLE_NAME']?.toString() ?? table,
      engine: row['ENGINE']?.toString(),
      rows: int.tryParse(row['TABLE_ROWS']?.toString() ?? ''),
      dataLength: int.tryParse(row['DATA_LENGTH']?.toString() ?? ''),
      indexLength: int.tryParse(row['INDEX_LENGTH']?.toString() ?? ''),
      collation: row['TABLE_COLLATION']?.toString(),
      createTime: row['CREATE_TIME']?.toString(),
      updateTime: row['UPDATE_TIME']?.toString(),
      autoIncrement: int.tryParse(row['AUTO_INCREMENT']?.toString() ?? ''),
    );
  }

  /// Get columns for a table
  Future<List<ColumnInfo>> getColumns(String table) async {
    final result = await execute('DESCRIBE `$table`');
    if (!result.isSuccess) return [];

    return result.rows.map((row) {
      return ColumnInfo(
        name: row['Field']?.toString() ?? '',
        type: row['Type']?.toString() ?? '',
        nullable: row['Null']?.toString() == 'YES',
        key: row['Key']?.toString(),
        defaultValue: row['Default']?.toString(),
        extra: row['Extra']?.toString(),
      );
    }).toList();
  }

  /// Get indexes for a table
  Future<List<IndexInfo>> getIndexes(String table) async {
    final result = await execute('SHOW INDEX FROM `$table`');
    if (!result.isSuccess) return [];

    // Group columns by index name
    final indexMap = <String, List<String>>{};
    final indexUnique = <String, bool>{};

    for (final row in result.rows) {
      final keyName = row['Key_name']?.toString() ?? '';
      final colName = row['Column_name']?.toString() ?? '';
      final nonUnique = row['Non_unique']?.toString() == '1';

      indexMap.putIfAbsent(keyName, () => []).add(colName);
      indexUnique[keyName] = !nonUnique;
    }

    return indexMap.entries.map((entry) {
      return IndexInfo(
        name: entry.key,
        columns: entry.value,
        primary: entry.key == 'PRIMARY',
        unique: indexUnique[entry.key] ?? false,
      );
    }).toList();
  }

  /// Get CREATE TABLE statement
  Future<String?> getCreateTable(String table) async {
    final result = await execute('SHOW CREATE TABLE `$table`');
    if (!result.isSuccess || result.rows.isEmpty) return null;

    return result.rows.first['Create Table']?.toString();
  }

  /// Get table content with pagination
  Future<QueryResult> getTableContent(String table, {int limit = 1000, int offset = 0}) async {
    return execute('SELECT * FROM `$table` LIMIT $limit OFFSET $offset');
  }

  /// Get row count for a table
  Future<int> getRowCount(String table) async {
    final result = await execute('SELECT COUNT(*) as cnt FROM `$table`');
    if (!result.isSuccess || result.rows.isEmpty) return 0;

    return int.tryParse(result.rows.first['cnt']?.toString() ?? '') ?? 0;
  }
}
