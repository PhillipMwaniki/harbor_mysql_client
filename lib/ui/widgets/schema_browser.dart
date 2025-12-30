import 'package:flutter/material.dart';
import '../../models/connection_info.dart';

class SchemaBrowser extends StatefulWidget {
  final String? selectedDatabase;
  final String? selectedTable;
  final ValueChanged<String>? onDatabaseSelected;
  final ValueChanged<String>? onTableSelected;

  const SchemaBrowser({
    super.key,
    this.selectedDatabase,
    this.selectedTable,
    this.onDatabaseSelected,
    this.onTableSelected,
  });

  @override
  State<SchemaBrowser> createState() => _SchemaBrowserState();
}

class _SchemaBrowserState extends State<SchemaBrowser> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _expandedDatabases = {'app_dev'};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Filter tables...',
              prefixIcon: const Icon(Icons.search, size: 16),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 14),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          ),
        ),
        // Database/Table tree
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: MockData.databases.map((db) {
              final isExpanded = _expandedDatabases.contains(db);
              final isSelected = widget.selectedDatabase == db;
              final tables = MockData.tables
                  .where((t) => _searchQuery.isEmpty || t.toLowerCase().contains(_searchQuery))
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Database item
                  _TreeItem(
                    icon: Icons.storage_rounded,
                    iconColor: const Color(0xFF4EC9B0),
                    label: db,
                    isSelected: isSelected && widget.selectedTable == null,
                    isExpanded: isExpanded,
                    hasChildren: true,
                    onTap: () {
                      widget.onDatabaseSelected?.call(db);
                    },
                    onExpandToggle: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedDatabases.remove(db);
                        } else {
                          _expandedDatabases.add(db);
                        }
                      });
                    },
                  ),
                  // Tables
                  if (isExpanded)
                    ...tables.map((table) {
                      final isTableSelected = widget.selectedDatabase == db && widget.selectedTable == table;
                      return _TreeItem(
                        icon: Icons.table_chart_outlined,
                        iconColor: const Color(0xFF569CD6),
                        label: table,
                        isSelected: isTableSelected,
                        indent: 1,
                        onTap: () {
                          widget.onDatabaseSelected?.call(db);
                          widget.onTableSelected?.call(table);
                        },
                      );
                    }),
                ],
              );
            }).toList(),
          ),
        ),
        // Table info footer
        if (widget.selectedTable != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedTable!,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${MockData.columns.length} columns • ~1,234 rows',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: MockData.columns.take(4).map((col) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Text(
                        col['name'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TreeItem extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final bool hasChildren;
  final int indent;
  final VoidCallback? onTap;
  final VoidCallback? onExpandToggle;

  const _TreeItem({
    required this.icon,
    this.iconColor,
    required this.label,
    this.isSelected = false,
    this.isExpanded = false,
    this.hasChildren = false,
    this.indent = 0,
    this.onTap,
    this.onExpandToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 26,
        padding: EdgeInsets.only(left: 8.0 + (indent * 16)),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.2) : null,
        ),
        child: Row(
          children: [
            // Expand/collapse arrow
            if (hasChildren)
              GestureDetector(
                onTap: onExpandToggle,
                child: SizedBox(
                  width: 16,
                  child: Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 14,
                    color: theme.iconTheme.color,
                  ),
                ),
              )
            else
              const SizedBox(width: 16),
            // Icon
            Icon(icon, size: 14, color: iconColor ?? theme.iconTheme.color),
            const SizedBox(width: 6),
            // Label
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
