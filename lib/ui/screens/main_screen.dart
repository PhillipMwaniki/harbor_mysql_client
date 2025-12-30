import 'package:flutter/material.dart';
import '../../models/connection_info.dart';
import '../widgets/app_toolbar.dart';
import '../widgets/schema_browser.dart';
import '../widgets/content_tabs.dart';
import 'connection_manager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  double _sidebarWidth = 220;
  final double _minSidebarWidth = 150;
  final double _maxSidebarWidth = 400;

  ConnectionInfo? _currentConnection;
  String? _selectedDatabase;
  String? _selectedTable;
  bool _isConnected = false;

  void _showConnectionManager() {
    showDialog(
      context: context,
      builder: (context) => ConnectionManager(
        connections: MockData.connections,
        selectedConnection: _currentConnection,
        onConnectionSelected: (conn) {
          setState(() => _currentConnection = conn);
        },
        onConnect: (conn) {
          setState(() {
            _currentConnection = conn;
            _isConnected = true;
            _selectedDatabase = conn.database ?? MockData.databases.first;
          });
          Navigator.of(context).pop();
        },
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _disconnect() {
    setState(() {
      _isConnected = false;
      _selectedDatabase = null;
      _selectedTable = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Toolbar
          AppToolbar(
            connectionName: _currentConnection?.name,
            isConnected: _isConnected,
            onConnectionTap: _showConnectionManager,
            onDisconnect: _disconnect,
            onRefresh: () {
              setState(() {});
            },
          ),
          // Main content
          Expanded(
            child: _isConnected ? _buildMainContent(theme) : _buildWelcomeScreen(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme) {
    return Row(
      children: [
        // Schema browser with resizable width
        SizedBox(
          width: _sidebarWidth,
          child: Container(
            color: theme.colorScheme.surface,
            child: SchemaBrowser(
              selectedDatabase: _selectedDatabase,
              selectedTable: _selectedTable,
              onDatabaseSelected: (db) {
                setState(() => _selectedDatabase = db);
              },
              onTableSelected: (table) {
                setState(() => _selectedTable = table);
              },
            ),
          ),
        ),
        // Resizable divider
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _sidebarWidth = (_sidebarWidth + details.delta.dx)
                    .clamp(_minSidebarWidth, _maxSidebarWidth);
              });
            },
            child: Container(
              width: 4,
              color: theme.dividerColor,
              child: Center(
                child: Container(
                  width: 2,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.iconTheme.color?.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Content area
        Expanded(
          child: ContentTabs(
            selectedTable: _selectedTable,
            initialTab: ContentTab.content,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeScreen(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.anchor,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Harbor',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A MySQL client for developers',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Connection'),
            onPressed: _showConnectionManager,
          ),
          const SizedBox(height: 48),
          // Recent connections
          if (MockData.connections.isNotEmpty) ...[
            Text(
              'Recent Connections',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ...MockData.connections.take(3).map((conn) {
              final color = conn.color != null
                  ? Color(int.parse(conn.color!.replaceFirst('#', '0xFF')))
                  : theme.colorScheme.primary;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _currentConnection = conn;
                      _isConnected = true;
                      _selectedDatabase = conn.database ?? MockData.databases.first;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 280,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                conn.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${conn.host}:${conn.port}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: theme.iconTheme.color,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
