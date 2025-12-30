import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/connection_info.dart';
import '../../providers/database_provider.dart';
import '../theme/app_theme.dart';

class ConnectionManager extends ConsumerStatefulWidget {
  final List<ConnectionInfo> connections;
  final ConnectionInfo? selectedConnection;
  final ValueChanged<ConnectionInfo>? onConnectionSelected;
  final ValueChanged<ConnectionInfo>? onConnect;
  final VoidCallback? onClose;

  const ConnectionManager({
    super.key,
    required this.connections,
    this.selectedConnection,
    this.onConnectionSelected,
    this.onConnect,
    this.onClose,
  });

  @override
  ConsumerState<ConnectionManager> createState() => _ConnectionManagerState();
}

class _ConnectionManagerState extends ConsumerState<ConnectionManager> {
  ConnectionInfo? _selectedConnection;
  bool _isTesting = false;
  String? _testResult;

  // Form controllers
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '3306');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _databaseController = TextEditingController();
  final _sshHostController = TextEditingController();
  final _sshPortController = TextEditingController(text: '22');
  final _sshUsernameController = TextEditingController();
  final _sshPasswordController = TextEditingController();
  bool _useSSL = false;
  bool _useSSH = false;

  @override
  void initState() {
    super.initState();
    final connections = ref.read(savedConnectionsProvider);
    _selectedConnection = widget.selectedConnection ?? connections.firstOrNull;
    if (_selectedConnection != null) {
      _populateForm(_selectedConnection!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _databaseController.dispose();
    _sshHostController.dispose();
    _sshPortController.dispose();
    _sshUsernameController.dispose();
    _sshPasswordController.dispose();
    super.dispose();
  }

  void _populateForm(ConnectionInfo conn) {
    _nameController.text = conn.name;
    _hostController.text = conn.host;
    _portController.text = conn.port.toString();
    _usernameController.text = conn.username;
    _passwordController.text = conn.password ?? '';
    _databaseController.text = conn.database ?? '';
    _useSSL = conn.useSSL;
    _useSSH = conn.useSSH;
    _sshHostController.text = conn.sshHost ?? '';
    _sshPortController.text = (conn.sshPort ?? 22).toString();
    _sshUsernameController.text = conn.sshUsername ?? '';
    _sshPasswordController.text = conn.sshPassword ?? '';
  }

  void _testConnection() {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    // Simulate connection test
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testResult = 'Connection successful!';
        });
      }
    });
  }

  ConnectionInfo _buildConnectionFromForm({String? existingId}) {
    return ConnectionInfo(
      id: existingId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.isEmpty ? 'New Connection' : _nameController.text,
      host: _hostController.text.isEmpty ? 'localhost' : _hostController.text,
      port: int.tryParse(_portController.text) ?? 3306,
      username: _usernameController.text,
      password: _passwordController.text.isEmpty ? null : _passwordController.text,
      database: _databaseController.text.isEmpty ? null : _databaseController.text,
      useSSL: _useSSL,
      useSSH: _useSSH,
      sshHost: _sshHostController.text.isEmpty ? null : _sshHostController.text,
      sshPort: int.tryParse(_sshPortController.text) ?? 22,
      sshUsername: _sshUsernameController.text.isEmpty ? null : _sshUsernameController.text,
      sshPassword: _sshPasswordController.text.isEmpty ? null : _sshPasswordController.text,
      color: _selectedConnection?.color ?? '#4EC9B0',
    );
  }

  Future<void> _saveConnection() async {
    final notifier = ref.read(savedConnectionsProvider.notifier);

    if (_selectedConnection != null) {
      // Update existing connection
      final updated = _buildConnectionFromForm(existingId: _selectedConnection!.id);
      await notifier.update(updated);
      setState(() {
        _selectedConnection = updated;
      });
    } else {
      // Add new connection
      final newConn = _buildConnectionFromForm();
      await notifier.add(newConn);
      setState(() {
        _selectedConnection = newConn;
      });
    }
  }

  Future<void> _deleteConnection() async {
    if (_selectedConnection == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Connection'),
        content: Text('Are you sure you want to delete "${_selectedConnection!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(savedConnectionsProvider.notifier).remove(_selectedConnection!.id);
      setState(() {
        _selectedConnection = null;
        _clearForm();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Watch the provider directly to get updates when connections change
    final connections = ref.watch(savedConnectionsProvider);

    return Dialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 800,
        height: 500,
        child: Column(
          children: [
            // Header
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storage, size: 20),
                  const SizedBox(width: 8),
                  Text('Connection Manager', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: widget.onClose,
                    splashRadius: 16,
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: Row(
                children: [
                  // Connection list
                  Container(
                    width: 240,
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: theme.dividerColor)),
                    ),
                    child: Column(
                      children: [
                        // List header
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: theme.dividerColor)),
                          ),
                          child: Row(
                            children: [
                              Text('Connections', style: theme.textTheme.bodySmall),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16),
                                onPressed: () {
                                  setState(() {
                                    _selectedConnection = null;
                                    _clearForm();
                                  });
                                },
                                splashRadius: 14,
                                tooltip: 'New Connection',
                              ),
                            ],
                          ),
                        ),
                        // Connection items
                        Expanded(
                          child: ListView.builder(
                            itemCount: connections.length,
                            itemBuilder: (context, index) {
                              final conn = connections[index];
                              final isSelected = _selectedConnection?.id == conn.id;
                              return _ConnectionListItem(
                                connection: conn,
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _selectedConnection = conn;
                                    _populateForm(conn);
                                  });
                                  widget.onConnectionSelected?.call(conn);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Connection form
                  Expanded(
                    child: _buildConnectionForm(theme),
                  ),
                ],
              ),
            ),
            // Footer
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  // Delete button (only for existing connections)
                  if (_selectedConnection != null)
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
                      onPressed: _deleteConnection,
                    ),
                  if (_testResult != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppTheme.statusConnected,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _testResult!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.statusConnected,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _isTesting ? null : _testConnection,
                    child: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Test'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _saveConnection,
                    child: const Text('Save'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      // Save before connecting
                      await _saveConnection();
                      if (_selectedConnection != null) {
                        widget.onConnect?.call(_selectedConnection!);
                      }
                    },
                    child: const Text('Connect'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _hostController.text = '';
    _portController.text = '3306';
    _usernameController.clear();
    _passwordController.clear();
    _databaseController.clear();
    _useSSL = false;
    _useSSH = false;
    _sshHostController.clear();
    _sshPortController.text = '22';
    _sshUsernameController.clear();
    _sshPasswordController.clear();
  }

  Widget _buildConnectionForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection name
          _FormField(
            label: 'Connection Name',
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'My Database'),
            ),
          ),
          const SizedBox(height: 20),
          // MySQL section
          Text('MySQL Connection', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _FormField(
                  label: 'Host',
                  child: TextField(
                    controller: _hostController,
                    decoration: const InputDecoration(hintText: 'localhost'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FormField(
                  label: 'Port',
                  child: TextField(
                    controller: _portController,
                    decoration: const InputDecoration(hintText: '3306'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FormField(
                  label: 'Username',
                  child: TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(hintText: 'root'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FormField(
                  label: 'Password',
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: '••••••••'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FormField(
            label: 'Database (optional)',
            child: TextField(
              controller: _databaseController,
              decoration: const InputDecoration(hintText: 'my_database'),
            ),
          ),
          const SizedBox(height: 16),
          // SSL/TLS option
          Row(
            children: [
              Checkbox(
                value: _useSSL,
                onChanged: (value) => setState(() => _useSSL = value ?? false),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Use SSL/TLS', style: theme.textTheme.bodyMedium),
                    Text(
                      'Required for caching_sha2_password authentication',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // SSH section
          Row(
            children: [
              Checkbox(
                value: _useSSH,
                onChanged: (value) => setState(() => _useSSH = value ?? false),
              ),
              Text('Connect via SSH Tunnel', style: theme.textTheme.titleMedium),
            ],
          ),
          if (_useSSH) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _FormField(
                    label: 'SSH Host',
                    child: TextField(
                      controller: _sshHostController,
                      decoration: const InputDecoration(hintText: 'bastion.example.com'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FormField(
                    label: 'SSH Port',
                    child: TextField(
                      controller: _sshPortController,
                      decoration: const InputDecoration(hintText: '22'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FormField(
                    label: 'SSH Username',
                    child: TextField(
                      controller: _sshUsernameController,
                      decoration: const InputDecoration(hintText: 'deploy'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FormField(
                    label: 'SSH Password',
                    child: TextField(
                      controller: _sshPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(hintText: '••••••••'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.key, size: 16),
                  label: const Text('Use SSH Key'),
                  onPressed: () {
                    // TODO: File picker for SSH key
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final Widget child;

  const _FormField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _ConnectionListItem extends StatelessWidget {
  final ConnectionInfo connection;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ConnectionListItem({
    required this.connection,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = connection.color != null
        ? Color(int.parse(connection.color!.replaceFirst('#', '0xFF')))
        : theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.15) : null,
          border: Border(
            left: BorderSide(
              width: 3,
              color: isSelected ? color : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connection.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${connection.host}:${connection.port}',
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (connection.useSSH)
              Tooltip(
                message: 'SSH Tunnel',
                child: Icon(Icons.vpn_key, size: 14, color: theme.iconTheme.color),
              ),
          ],
        ),
      ),
    );
  }
}
