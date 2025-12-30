import 'package:flutter/material.dart';
import '../../models/connection_info.dart';
import '../theme/app_theme.dart';
import 'query_editor.dart';
import 'results_grid.dart';

enum ContentTab { structure, content, query, info }

class ContentTabs extends StatefulWidget {
  final String? selectedTable;
  final ContentTab initialTab;

  const ContentTabs({
    super.key,
    this.selectedTable,
    this.initialTab = ContentTab.content,
  });

  @override
  State<ContentTabs> createState() => _ContentTabsState();
}

class _ContentTabsState extends State<ContentTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _currentQuery = 'SELECT * FROM users\nWHERE created_at > "2024-01-01"\nLIMIT 100;';
  bool _isExecuting = false;
  List<Map<String, dynamic>> _resultRows = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
    // Load mock data
    _resultRows = MockData.generateRows(50);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _executeQuery() {
    setState(() => _isExecuting = true);
    // Simulate query execution
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isExecuting = false;
          _resultRows = MockData.generateRows(100);
        });
      }
    });
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
              _buildStructureTab(theme),
              _buildContentTab(theme),
              _buildQueryTab(theme),
              _buildInfoTab(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStructureTab(ThemeData theme) {
    if (widget.selectedTable == null) {
      return _buildEmptyState(theme, 'Select a table to view its structure');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Columns section
        _SectionHeader(title: 'Columns', count: MockData.columns.length),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: MockData.columns.asMap().entries.map((entry) {
              final index = entry.key;
              final col = entry.value;
              final isLast = index == MockData.columns.length - 1;
              return _ColumnRow(
                name: col['name'] as String,
                type: col['type'] as String,
                nullable: col['nullable'] as bool,
                keyType: col['key'] as String?,
                defaultValue: col['default'] as String?,
                extra: col['extra'] as String?,
                showBorder: !isLast,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        // Indexes section
        _SectionHeader(title: 'Indexes', count: 2),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              _IndexRow(name: 'PRIMARY', columns: ['id'], type: 'PRIMARY', showBorder: true),
              _IndexRow(name: 'users_email_unique', columns: ['email'], type: 'UNIQUE', showBorder: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentTab(ThemeData theme) {
    if (widget.selectedTable == null) {
      return _buildEmptyState(theme, 'Select a table to view its content');
    }

    return ResultsGrid(
      columns: MockData.columns,
      rows: _resultRows,
    );
  }

  Widget _buildQueryTab(ThemeData theme) {
    return Column(
      children: [
        // Query editor
        SizedBox(
          height: 200,
          child: QueryEditor(
            initialQuery: _currentQuery,
            isExecuting: _isExecuting,
            onQueryChanged: (query) => _currentQuery = query,
            onExecute: _executeQuery,
          ),
        ),
        // Divider
        Container(
          height: 4,
          color: theme.dividerColor,
        ),
        // Results
        Expanded(
          child: _isExecuting
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
              : ResultsGrid(
                  columns: MockData.columns,
                  rows: _resultRows,
                ),
        ),
      ],
    );
  }

  Widget _buildInfoTab(ThemeData theme) {
    if (widget.selectedTable == null) {
      return _buildEmptyState(theme, 'Select a table to view its info');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow(label: 'Table', value: widget.selectedTable!),
        _InfoRow(label: 'Engine', value: 'InnoDB'),
        _InfoRow(label: 'Row Format', value: 'Dynamic'),
        _InfoRow(label: 'Rows', value: '~1,234'),
        _InfoRow(label: 'Data Size', value: '96.0 KB'),
        _InfoRow(label: 'Index Size', value: '16.0 KB'),
        _InfoRow(label: 'Collation', value: 'utf8mb4_unicode_ci'),
        _InfoRow(label: 'Auto Increment', value: '1235'),
        _InfoRow(label: 'Created', value: '2024-01-15 10:30:00'),
        _InfoRow(label: 'Updated', value: '2024-12-28 15:45:00'),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Create Statement', count: null),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.editorBackground,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: theme.dividerColor),
          ),
          child: SelectableText(
            '''CREATE TABLE `users` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_email_unique` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;''',
            style: const TextStyle(
              fontFamily: 'Consolas',
              fontSize: 12,
              color: Color(0xFFD4D4D4),
            ),
          ),
        ),
      ],
    );
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
            width: 60,
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
