import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/database_provider.dart';
import '../theme/app_theme.dart';
import 'query_editor.dart';
import 'results_grid.dart';

enum ContentTab { structure, content, query, info }

class ContentTabs extends ConsumerStatefulWidget {
  final String? selectedTable;
  final ContentTab initialTab;

  const ContentTabs({
    super.key,
    this.selectedTable,
    this.initialTab = ContentTab.content,
  });

  @override
  ConsumerState<ContentTabs> createState() => _ContentTabsState();
}

class _ContentTabsState extends ConsumerState<ContentTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Tab bar
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Structure'),
              Tab(text: 'Content'),
              Tab(text: 'Query'),
              Tab(text: 'Info'),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _StructureTab(selectedTable: widget.selectedTable),
              _ContentTab(selectedTable: widget.selectedTable),
              const _QueryTab(),
              _InfoTab(selectedTable: widget.selectedTable),
            ],
          ),
        ),
      ],
    );
  }
}

// Structure Tab - shows columns and indexes
class _StructureTab extends ConsumerWidget {
  final String? selectedTable;

  const _StructureTab({this.selectedTable});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (selectedTable == null) {
      return _buildEmptyState(theme, 'Select a table to view its structure');
    }

    final columnsAsync = ref.watch(columnListProvider);
    final indexesAsync = ref.watch(indexListProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Columns section
        columnsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (e, _) => Text('Error loading columns: $e'),
          data: (columns) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: 'Columns', count: columns.length),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: columns.asMap().entries.map((entry) {
                      final index = entry.key;
                      final col = entry.value;
                      final isLast = index == columns.length - 1;
                      return _ColumnRow(
                        name: col.name,
                        type: col.type,
                        nullable: col.nullable,
                        keyType: col.key,
                        defaultValue: col.defaultValue,
                        extra: col.extra,
                        showBorder: !isLast,
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        // Indexes section
        indexesAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Text('Error loading indexes: $e'),
          data: (indexes) {
            if (indexes.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: 'Indexes', count: indexes.length),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: indexes.asMap().entries.map((entry) {
                      final index = entry.key;
                      final idx = entry.value;
                      final isLast = index == indexes.length - 1;
                      return _IndexRow(
                        name: idx.name,
                        columns: idx.columns,
                        type: idx.primary ? 'PRIMARY' : (idx.unique ? 'UNIQUE' : 'INDEX'),
                        showBorder: !isLast,
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// Content Tab - shows table data
class _ContentTab extends ConsumerWidget {
  final String? selectedTable;

  const _ContentTab({this.selectedTable});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (selectedTable == null) {
      return _buildEmptyState(theme, 'Select a table to view its content');
    }

    final columnsAsync = ref.watch(columnListProvider);
    final contentAsync = ref.watch(tableContentProvider);

    return columnsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (columns) {
        return contentAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (result) {
            if (!result.isSuccess) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppTheme.statusError),
                    const SizedBox(height: 16),
                    Text('Query Error', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        result.error ?? 'Unknown error',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            final columnMaps = columns.map((c) => c.toMap()).toList();
            return ResultsGrid(
              columns: columnMaps,
              rows: result.rows,
            );
          },
        );
      },
    );
  }
}

// Query Tab - custom SQL execution
class _QueryTab extends ConsumerStatefulWidget {
  const _QueryTab();

  @override
  ConsumerState<_QueryTab> createState() => _QueryTabState();
}

class _QueryTabState extends ConsumerState<_QueryTab> {
  String _currentQuery = 'SELECT * FROM users LIMIT 100;';

  void _executeQuery() async {
    ref.read(queryProvider.notifier).setQuery(_currentQuery);
    await ref.read(queryProvider.notifier).execute();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final queryState = ref.watch(queryProvider);
    final columnsFromResult = queryState.result?.columns ?? [];

    // Convert column names to column maps for the grid
    final columnMaps = columnsFromResult.map((name) => {
      'name': name,
      'type': 'unknown',
      'nullable': true,
      'key': '',
      'default': null,
      'extra': '',
    }).toList();

    return Column(
      children: [
        // Query editor
        SizedBox(
          height: 200,
          child: QueryEditor(
            initialQuery: _currentQuery,
            isExecuting: queryState.isExecuting,
            onQueryChanged: (query) => _currentQuery = query,
            onExecute: _executeQuery,
          ),
        ),
        // Divider with execution time
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.dividerColor),
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Row(
            children: [
              if (queryState.result != null) ...[
                if (queryState.result!.isSuccess)
                  Icon(Icons.check_circle, size: 14, color: AppTheme.statusConnected)
                else
                  Icon(Icons.error, size: 14, color: AppTheme.statusError),
                const SizedBox(width: 6),
                Text(
                  queryState.result!.isSuccess
                      ? '${queryState.result!.rows.length} rows returned'
                      : 'Query failed',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Text(
                  '${queryState.result!.executionTime.inMilliseconds}ms',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Results
        Expanded(
          child: queryState.isExecuting
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(strokeWidth: 2),
                      const SizedBox(height: 16),
                      Text('Executing query...', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                )
              : queryState.result == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_circle_outline, size: 48, color: theme.iconTheme.color),
                          const SizedBox(height: 16),
                          Text('Run a query to see results', style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          Text('Press Ctrl+Enter or click Run', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    )
                  : queryState.result!.isSuccess
                      ? ResultsGrid(
                          columns: columnMaps,
                          rows: queryState.result!.rows,
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: AppTheme.statusError),
                                const SizedBox(height: 16),
                                Text('Query Error', style: theme.textTheme.titleMedium),
                                const SizedBox(height: 8),
                                SelectableText(
                                  queryState.result!.error ?? 'Unknown error',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontFamily: 'Consolas',
                                    color: AppTheme.statusError,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
        ),
      ],
    );
  }
}

// Info Tab - table metadata
class _InfoTab extends ConsumerWidget {
  final String? selectedTable;

  const _InfoTab({this.selectedTable});

  String _formatBytes(int? bytes) {
    if (bytes == null) return '-';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (selectedTable == null) {
      return _buildEmptyState(theme, 'Select a table to view its info');
    }

    final tableInfoAsync = ref.watch(tableInfoProvider);
    final createTableAsync = ref.watch(createTableProvider);

    return tableInfoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (info) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InfoRow(label: 'Table', value: selectedTable!),
            _InfoRow(label: 'Engine', value: info?.engine ?? '-'),
            _InfoRow(label: 'Rows', value: info?.rows?.toString() ?? '-'),
            _InfoRow(label: 'Data Size', value: _formatBytes(info?.dataLength)),
            _InfoRow(label: 'Index Size', value: _formatBytes(info?.indexLength)),
            _InfoRow(label: 'Collation', value: info?.collation ?? '-'),
            _InfoRow(label: 'Auto Increment', value: info?.autoIncrement?.toString() ?? '-'),
            _InfoRow(label: 'Created', value: info?.createTime ?? '-'),
            _InfoRow(label: 'Updated', value: info?.updateTime ?? '-'),
            const SizedBox(height: 24),
            const _SectionHeader(title: 'Create Statement', count: null),
            const SizedBox(height: 8),
            createTableAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Text('Error loading CREATE statement: $e'),
              data: (createSql) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.editorBackground,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: SelectableText(
                    createSql ?? 'Unable to retrieve CREATE statement',
                    style: const TextStyle(
                      fontFamily: 'Consolas',
                      fontSize: 12,
                      color: Color(0xFFD4D4D4),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

Widget _buildEmptyState(ThemeData theme, String message) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.table_chart_outlined, size: 48, color: theme.iconTheme.color),
        const SizedBox(height: 16),
        Text(message, style: theme.textTheme.bodyMedium),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;

  const _SectionHeader({required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ColumnRow extends StatelessWidget {
  final String name;
  final String type;
  final bool nullable;
  final String? keyType;
  final String? defaultValue;
  final String? extra;
  final bool showBorder;

  const _ColumnRow({
    required this.name,
    required this.type,
    required this.nullable,
    this.keyType,
    this.defaultValue,
    this.extra,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: showBorder ? Border(bottom: BorderSide(color: theme.dividerColor)) : null,
      ),
      child: Row(
        children: [
          // Key indicator
          SizedBox(
            width: 24,
            child: keyType == 'PRI'
                ? Icon(Icons.key, size: 14, color: AppTheme.syntaxKeyword)
                : keyType == 'UNI'
                    ? Icon(Icons.fingerprint, size: 14, color: AppTheme.syntaxFunction)
                    : keyType == 'MUL'
                        ? Icon(Icons.link, size: 14, color: AppTheme.syntaxComment)
                        : null,
          ),
          // Name
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          // Type
          Expanded(
            flex: 2,
            child: Text(
              type,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'Consolas',
                color: AppTheme.syntaxType,
              ),
            ),
          ),
          // Nullable
          SizedBox(
            width: 70,
            child: Text(
              nullable ? 'NULL' : 'NOT NULL',
              style: theme.textTheme.bodySmall?.copyWith(
                color: nullable ? AppTheme.gridNull : theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
          // Default
          Expanded(
            flex: 2,
            child: Text(
              defaultValue ?? '-',
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Extra
          Expanded(
            child: Text(
              extra ?? '',
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.syntaxComment),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _IndexRow extends StatelessWidget {
  final String name;
  final List<String> columns;
  final String type;
  final bool showBorder;

  const _IndexRow({
    required this.name,
    required this.columns,
    required this.type,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: showBorder ? Border(bottom: BorderSide(color: theme.dividerColor)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              columns.join(', '),
              style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'Consolas'),
            ),
          ),
          SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: type == 'PRIMARY'
                    ? AppTheme.syntaxKeyword.withValues(alpha: 0.2)
                    : AppTheme.syntaxFunction.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                type,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: type == 'PRIMARY' ? AppTheme.syntaxKeyword : AppTheme.syntaxFunction,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
