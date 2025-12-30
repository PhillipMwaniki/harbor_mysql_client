import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class QueryEditor extends StatefulWidget {
  final String initialQuery;
  final ValueChanged<String>? onQueryChanged;
  final VoidCallback? onExecute;
  final bool isExecuting;

  const QueryEditor({
    super.key,
    this.initialQuery = '',
    this.onQueryChanged,
    this.onExecute,
    this.isExecuting = false,
  });

  @override
  State<QueryEditor> createState() => _QueryEditorState();
}

class _QueryEditorState extends State<QueryEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  int _lineCount = 1;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _focusNode = FocusNode();
    _updateLineCount();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _updateLineCount();
    widget.onQueryChanged?.call(_controller.text);
  }

  void _updateLineCount() {
    final newCount = '\n'.allMatches(_controller.text).length + 1;
    if (newCount != _lineCount) {
      setState(() => _lineCount = newCount);
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Cmd/Ctrl + Enter to execute
      if (event.logicalKey == LogicalKeyboardKey.enter &&
          (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed)) {
        widget.onExecute?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      child: Container(
        color: AppTheme.editorBackground,
        child: Column(
          children: [
            // Toolbar
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  _ToolbarButton(
                    icon: widget.isExecuting ? Icons.stop : Icons.play_arrow,
                    label: widget.isExecuting ? 'Stop' : 'Run',
                    color: widget.isExecuting ? AppTheme.statusError : AppTheme.statusConnected,
                    onPressed: widget.onExecute,
                  ),
                  const SizedBox(width: 8),
                  _ToolbarButton(
                    icon: Icons.auto_fix_high,
                    label: 'Format',
                    onPressed: () {
                      // TODO: Format SQL
                    },
                  ),
                  const Spacer(),
                  Text(
                    'Ctrl+Enter to run',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            // Editor
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line numbers
                  Container(
                    width: 48,
                    padding: const EdgeInsets.only(top: 12, right: 8),
                    color: theme.colorScheme.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(
                        _lineCount,
                        (i) => SizedBox(
                          height: 20,
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontFamily: 'Consolas',
                              fontSize: 13,
                              color: AppTheme.editorLineNumber,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Code area
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: null,
                          style: const TextStyle(
                            fontFamily: 'Consolas',
                            fontSize: 13,
                            height: 1.5,
                            color: Color(0xFFD4D4D4),
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            fillColor: Colors.transparent,
                            filled: true,
                          ),
                          cursorColor: AppTheme.editorCursor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.iconTheme.color;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: effectiveColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: effectiveColor),
            ),
          ],
        ),
      ),
    );
  }
}
