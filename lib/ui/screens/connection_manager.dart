import 'package:flutter/material.dart';
import '../../models/connection_info.dart';
import '../theme/app_theme.dart';

class ConnectionManager extends StatefulWidget {
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
  State<ConnectionManager> createState() => _ConnectionManagerState();
}

class _ConnectionManagerState extends State<ConnectionManager> {
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
  bool _useSSH = false;

  @override
  void initState() {
    super.initState();
    _selectedConnection = widget.selectedConnection ?? widget.connections.firstOrNull;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                            itemCount: widget.connections.length,
                            itemBuilder: (context, index) {
                              final conn = widget.connections[index];
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
                  if (_testResult != null)
                    Row(
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
                  const Spacer(),
                  TextButton(
                    onPressed: _isTesting ? null : _testConnection,
                    child: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Test Connection'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selectedConnection != null
                        ? () => widget.onConnect?.call(_selectedConnection!)
                        : null,
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
