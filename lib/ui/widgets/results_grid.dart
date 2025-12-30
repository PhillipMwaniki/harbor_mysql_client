import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class ResultsGrid extends StatefulWidget {
  final List<Map<String, dynamic>> columns;
  final List<Map<String, dynamic>> rows;
  final int? selectedRow;
  final ValueChanged<int>? onRowSelected;

  const ResultsGrid({
    super.key,
    required this.columns,
    required this.rows,
    this.selectedRow,
    this.onRowSelected,
  });

  @override
  State<ResultsGrid> createState() => _ResultsGridState();
}

class _ResultsGridState extends State<ResultsGrid> {
  final _horizontalController = ScrollController();
  final _verticalController = ScrollController();
  final List<double> _columnWidths = [];
  int? _hoveredRow;
  int? _resizingColumn;
  double _resizeStartX = 0;
  double _resizeStartWidth = 0;

  @override
  void initState() {
    super.initState();
    _initColumnWidths();
  }

  @override
  void didUpdateWidget(ResultsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.columns != widget.columns) {
      _initColumnWidths();
    }
  }

  void _initColumnWidths() {
    _columnWidths.clear();
    for (final col in widget.columns) {
      final name = col['name'] as String;
      final type = col['type'] as String;
      // Estimate width based on column name and type
      double width = (name.length * 8.0 + 40).clamp(80.0, 200.0);
      if (type.contains('text') || type.contains('varchar')) {
        width = width.clamp(120.0, 250.0);
      }
      _columnWidths.add(width);
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  void _copyCell(String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.columns.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.table_rows_outlined, size: 48, color: theme.iconTheme.color),
            const SizedBox(height: 16),
            Text('No results', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('Run a query to see results here', style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Status bar
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              Text(
                '${widget.rows.length} rows',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              Text(
                '${widget.columns.length} columns',
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              if (widget.selectedRow != null)
                Text(
                  'Row ${widget.selectedRow! + 1} selected',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        // Grid
        Expanded(
          child: GestureDetector(
            onPanUpdate: _resizingColumn != null ? _handleColumnResize : null,
            onPanEnd: _resizingColumn != null ? (_) => setState(() => _resizingColumn = null) : null,
            child: Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              child: Scrollbar(
                controller: _verticalController,
                thumbVisibility: true,
                notificationPredicate: (notification) => notification.depth == 1,
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _columnWidths.fold<double>(0.0, (sum, w) => sum + w),
                    child: Column(
                      children: [
                        // Header row
                        _buildHeaderRow(theme),
                        // Data rows
                        Expanded(
                          child: ListView.builder(
                            controller: _verticalController,
                            itemCount: widget.rows.length,
                            itemExtent: 28,
                            itemBuilder: (context, index) => _buildDataRow(theme, index),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(ThemeData theme) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.gridHeader,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: List.generate(widget.columns.length, (i) {
          final col = widget.columns[i];
          return _buildHeaderCell(theme, col, i);
        }),
      ),
    );
  }

  Widget _buildHeaderCell(ThemeData theme, Map<String, dynamic> col, int index) {
    final name = col['name'] as String;
    final type = col['type'] as String;
    final key = col['key'] as String?;

    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _resizingColumn = index;
          _resizeStartX = details.globalPosition.dx;
          _resizeStartWidth = _columnWidths[index];
        });
      },
      child: Container(
        width: _columnWidths[index],
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: theme.dividerColor)),
        ),
        child: Row(
          children: [
            if (key == 'PRI')
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.key, size: 12, color: AppTheme.syntaxKeyword),
              ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    type,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 9),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Resize handle
            MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: Container(
                width: 4,
                color: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(ThemeData theme, int rowIndex) {
    final row = widget.rows[rowIndex];
    final isSelected = widget.selectedRow == rowIndex;
    final isHovered = _hoveredRow == rowIndex;

    Color bgColor;
    if (isSelected) {
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.3);
    } else if (isHovered) {
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.1);
    } else {
      bgColor = rowIndex.isEven ? AppTheme.gridRowEven : AppTheme.gridRowOdd;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRow = rowIndex),
      onExit: (_) => setState(() => _hoveredRow = null),
      child: GestureDetector(
        onTap: () => widget.onRowSelected?.call(rowIndex),
        child: Container(
          height: 28,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3))),
          ),
          child: Row(
            children: List.generate(widget.columns.length, (colIndex) {
              final colName = widget.columns[colIndex]['name'] as String;
              final value = row[colName];
              return _buildDataCell(theme, value, colIndex);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(ThemeData theme, dynamic value, int colIndex) {
    final isNull = value == null;
    final displayValue = isNull ? 'NULL' : value.toString();

    return GestureDetector(
      onDoubleTap: () => _copyCell(displayValue),
      child: Container(
        width: _columnWidths[colIndex],
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3))),
        ),
        child: Text(
          displayValue,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'Consolas',
            color: isNull ? AppTheme.gridNull : null,
            fontStyle: isNull ? FontStyle.italic : null,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _handleColumnResize(DragUpdateDetails details) {
    if (_resizingColumn == null) return;
    final delta = details.globalPosition.dx - _resizeStartX;
    setState(() {
      _columnWidths[_resizingColumn!] = (_resizeStartWidth + delta).clamp(50.0, 500.0);
    });
  }
}
