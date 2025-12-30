import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppToolbar extends StatelessWidget {
  final String? connectionName;
  final bool isConnected;
  final VoidCallback? onConnectionTap;
  final VoidCallback? onDisconnect;
  final VoidCallback? onRefresh;

  const AppToolbar({
    super.key,
    this.connectionName,
    this.isConnected = false,
    this.onConnectionTap,
    this.onDisconnect,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          // App logo/title
          Row(
            children: [
              Icon(
                Icons.anchor,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Harbor',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Connection selector
          _ConnectionButton(
            connectionName: connectionName,
            isConnected: isConnected,
            onTap: onConnectionTap,
          ),
          const SizedBox(width: 8),
          // Quick actions
          if (isConnected) ...[
            _ToolbarIconButton(
              icon: Icons.refresh,
              tooltip: 'Refresh',
              onPressed: onRefresh,
            ),
            _ToolbarIconButton(
              icon: Icons.logout,
              tooltip: 'Disconnect',
              onPressed: onDisconnect,
            ),
          ],
          const Spacer(),
          // Status indicator
          _ConnectionStatus(isConnected: isConnected),
        ],
      ),
    );
  }
}

class _ConnectionButton extends StatelessWidget {
  final String? connectionName;
  final bool isConnected;
  final VoidCallback? onTap;

  const _ConnectionButton({
    this.connectionName,
    this.isConnected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected ? AppTheme.statusConnected : AppTheme.statusDisconnected,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              connectionName ?? 'No Connection',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.expand_more,
              size: 16,
              color: theme.iconTheme.color,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: theme.iconTheme.color),
        ),
      ),
    );
  }
}

class _ConnectionStatus extends StatelessWidget {
  final bool isConnected;

  const _ConnectionStatus({this.isConnected = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected ? AppTheme.statusConnected : AppTheme.statusDisconnected,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isConnected ? 'Connected' : 'Disconnected',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isConnected ? AppTheme.statusConnected : AppTheme.statusDisconnected,
          ),
        ),
      ],
    );
  }
}
