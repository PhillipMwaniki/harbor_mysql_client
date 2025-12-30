import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/connection_info.dart';
import '../../providers/database_provider.dart';
import '../widgets/app_toolbar.dart';
import '../widgets/schema_browser.dart';
import '../widgets/content_tabs.dart';
import 'connection_manager.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  double _sidebarWidth = 220;
  final double _minSidebarWidth = 150;
  final double _maxSidebarWidth = 400;

  void _showConnectionManager() {
    final savedConnections = ref.read(savedConnectionsProvider);

    showDialog(
      context: context,
      builder: (context) => ConnectionManager(
        connections: savedConnections,
        selectedConnection: ref.read(connectionProvider).connection,
        onConnectionSelected: (conn) {
          // Just selecting, not connecting yet
        },
        onConnect: (conn) async {
          Navigator.of(context).pop();
          await _connect(conn);
        },
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<void> _connect(ConnectionInfo conn) async {
    final success = await ref.read(connectionProvider.notifier).connect(conn);

    if (success && mounted) {
      // Set the initial database
      final databases = await ref.read(mysqlServiceProvider).getDatabases();
      if (databases.isNotEmpty) {
        final defaultDb = conn.database ?? databases.first;
        ref.read(currentDatabaseProvider.notifier).state = defaultDb;
        await ref.read(mysqlServiceProvider).useDatabase(defaultDb);
      }
    } else if (mounted) {
      // Show error dialog with copyable text
      final error = ref.read(connectionProvider).error ?? 'Unknown error';
      _showErrorDialog('Connection Failed', error);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 24),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Error details (tap to copy):',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                message,
                style: const TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnect() async {
    await ref.read(connectionProvider.notifier).disconnect();
    ref.read(currentDatabaseProvider.notifier).state = null;
    ref.read(selectedTableProvider.notifier).state = null;
  }

  void _refresh() {
    // Invalidate all data providers to refresh
    ref.invalidate(databaseListProvider);
    ref.invalidate(tableListProvider);
    ref.invalidate(columnListProvider);
    ref.invalidate(tableContentProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connectionState = ref.watch(connectionProvider);
    final isConnected = connectionState.status == ConnectionStatus.connected;
    final isConnecting = connectionState.status == ConnectionStatus.connecting;

    return Scaffold(
      body: Column(
        children: [
          // Toolbar
          AppToolbar(
            connectionName: connectionState.connection?.name,
            isConnected: isConnected,
            onConnectionTap: _showConnectionManager,
            onDisconnect: _disconnect,
            onRefresh: _refresh,
          ),
          // Loading indicator when connecting
          if (isConnecting)
            LinearProgressIndicator(
              backgroundColor: theme.colorScheme.surface,
              color: theme.colorScheme.primary,
            ),
          // Main content
          Expanded(
            child: isConnected ? _buildMainContent(theme) : _buildWelcomeScreen(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme) {
    final currentDb = ref.watch(currentDatabaseProvider);
    final selectedTable = ref.watch(selectedTableProvider);

    return Row(
      children: [
        // Schema browser with resizable width
        SizedBox(
          width: _sidebarWidth,
          child: Container(
            color: theme.colorScheme.surface,
            child: SchemaBrowser(
              selectedDatabase: currentDb,
              selectedTable: selectedTable,
              onDatabaseSelected: (db) async {
                ref.read(currentDatabaseProvider.notifier).state = db;
                ref.read(selectedTableProvider.notifier).state = null;
                await ref.read(mysqlServiceProvider).useDatabase(db);
                ref.invalidate(tableListProvider);
              },
              onTableSelected: (table) {
                ref.read(selectedTableProvider.notifier).state = table;
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
            selectedTable: selectedTable,
            initialTab: ContentTab.content,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeScreen(ThemeData theme) {
    final savedConnections = ref.watch(savedConnectionsProvider);

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
          if (savedConnections.isNotEmpty) ...[
            Text(
              'Saved Connections',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ...savedConnections.take(3).map((conn) {
              final color = conn.color != null
                  ? Color(int.parse(conn.color!.replaceFirst('#', '0xFF')))
                  : theme.colorScheme.primary;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: () => _connect(conn),
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
