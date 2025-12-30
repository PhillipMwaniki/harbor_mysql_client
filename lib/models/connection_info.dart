class ConnectionInfo {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String? password;
  final String? database;
  final bool useSSH;
  final String? sshHost;
  final int? sshPort;
  final String? sshUsername;
  final String? sshPassword;
  final String? sshKeyPath;
  final String? color;

  const ConnectionInfo({
    required this.id,
    required this.name,
    required this.host,
    this.port = 3306,
    required this.username,
    this.password,
    this.database,
    this.useSSH = false,
    this.sshHost,
    this.sshPort = 22,
    this.sshUsername,
    this.sshPassword,
    this.sshKeyPath,
    this.color,
  });

  ConnectionInfo copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    String? database,
    bool? useSSH,
    String? sshHost,
    int? sshPort,
    String? sshUsername,
    String? sshPassword,
    String? sshKeyPath,
    String? color,
  }) {
    return ConnectionInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      database: database ?? this.database,
      useSSH: useSSH ?? this.useSSH,
      sshHost: sshHost ?? this.sshHost,
      sshPort: sshPort ?? this.sshPort,
      sshUsername: sshUsername ?? this.sshUsername,
      sshPassword: sshPassword ?? this.sshPassword,
      sshKeyPath: sshKeyPath ?? this.sshKeyPath,
      color: color ?? this.color,
    );
  }
}

// Mock data for UI development
class MockData {
  static const connections = [
    ConnectionInfo(
      id: '1',
      name: 'Local Development',
      host: 'localhost',
      port: 3306,
      username: 'root',
      database: 'app_dev',
      color: '#4EC9B0',
    ),
    ConnectionInfo(
      id: '2',
      name: 'Production (SSH)',
      host: '10.0.0.5',
      port: 3306,
      username: 'admin',
      database: 'app_prod',
      useSSH: true,
      sshHost: 'bastion.example.com',
      sshPort: 22,
      sshUsername: 'deploy',
      color: '#F14C4C',
    ),
    ConnectionInfo(
      id: '3',
      name: 'Staging',
      host: 'staging-db.example.com',
      port: 3306,
      username: 'staging_user',
      database: 'app_staging',
      color: '#CCA700',
    ),
  ];

  static const databases = ['app_dev', 'mysql', 'information_schema', 'performance_schema'];

  static const tables = [
    'users',
    'posts',
    'comments',
    'categories',
    'tags',
    'post_tags',
    'sessions',
    'migrations',
    'password_resets',
    'settings',
  ];

  static const columns = [
    {'name': 'id', 'type': 'bigint(20)', 'nullable': false, 'key': 'PRI', 'default': null, 'extra': 'auto_increment'},
    {'name': 'email', 'type': 'varchar(255)', 'nullable': false, 'key': 'UNI', 'default': null, 'extra': ''},
    {'name': 'password', 'type': 'varchar(255)', 'nullable': false, 'key': '', 'default': null, 'extra': ''},
    {'name': 'name', 'type': 'varchar(100)', 'nullable': true, 'key': '', 'default': null, 'extra': ''},
    {'name': 'created_at', 'type': 'timestamp', 'nullable': true, 'key': '', 'default': 'CURRENT_TIMESTAMP', 'extra': ''},
    {'name': 'updated_at', 'type': 'timestamp', 'nullable': true, 'key': '', 'default': null, 'extra': 'on update CURRENT_TIMESTAMP'},
  ];

  static List<Map<String, dynamic>> generateRows(int count) {
    return List.generate(count, (i) => {
      'id': i + 1,
      'email': 'user${i + 1}@example.com',
      'password': '••••••••',
      'name': i % 5 == 0 ? null : 'User ${i + 1}',
      'created_at': '2024-01-${(i % 28 + 1).toString().padLeft(2, '0')} 10:30:00',
      'updated_at': i % 3 == 0 ? null : '2024-12-${(i % 28 + 1).toString().padLeft(2, '0')} 15:45:00',
    });
  }
}
