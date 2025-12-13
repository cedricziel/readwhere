import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../data/services/background_sync_manager.dart';

/// A widget that displays the current sync status.
///
/// Shows an icon indicating:
/// - Idle: No active sync
/// - Syncing: Sync in progress (animated)
/// - Error: Last sync failed (with error info on tap)
///
/// Can be placed in an app bar or status area.
class SyncStatusIndicator extends StatefulWidget {
  /// Whether to show the text label alongside the icon
  final bool showLabel;

  /// Callback when the indicator is tapped
  final VoidCallback? onTap;

  const SyncStatusIndicator({super.key, this.showLabel = false, this.onTap});

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  StreamSubscription<SyncStatus>? _statusSubscription;
  SyncStatus _status = SyncStatus.idle;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _initializeSubscription();
  }

  Future<void> _initializeSubscription() async {
    if (!sl.isRegistered<BackgroundSyncManager>()) return;

    try {
      final syncManager = await sl.getAsync<BackgroundSyncManager>();
      _status = syncManager.status;
      _lastError = syncManager.lastError;

      if (_status == SyncStatus.syncing) {
        _animationController.repeat();
      }

      _statusSubscription = syncManager.statusStream.listen((status) {
        if (!mounted) return;
        setState(() {
          _status = status;
          _lastError = syncManager.lastError;
        });

        if (status == SyncStatus.syncing) {
          _animationController.repeat();
        } else {
          _animationController.stop();
          _animationController.reset();
        }
      });

      if (mounted) setState(() {});
    } catch (_) {
      // Sync manager not available
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = _buildIcon(context);
    final label = _getStatusLabel();

    if (widget.showLabel) {
      return InkWell(
        onTap: widget.onTap ?? _showStatusDialog,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 4),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
    }

    return IconButton(
      icon: icon,
      onPressed: widget.onTap ?? _showStatusDialog,
      tooltip: label,
    );
  }

  Widget _buildIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (_status) {
      case SyncStatus.idle:
        return Icon(Icons.cloud_done, color: colorScheme.outline, size: 20);
      case SyncStatus.syncing:
        return RotationTransition(
          turns: _animationController,
          child: Icon(Icons.sync, color: colorScheme.primary, size: 20),
        );
      case SyncStatus.error:
        return Icon(Icons.cloud_off, color: colorScheme.error, size: 20);
    }
  }

  String _getStatusLabel() {
    switch (_status) {
      case SyncStatus.idle:
        return 'Synced';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.error:
        return 'Sync Error';
    }
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            _buildIcon(context),
            const SizedBox(width: 8),
            Text(_getStatusLabel()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_status == SyncStatus.error && _lastError != null) ...[
              Text(
                'Last error:',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              Text(
                _lastError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
            ],
            FutureBuilder<BackgroundSyncManager>(
              future: sl.isRegistered<BackgroundSyncManager>()
                  ? sl.getAsync<BackgroundSyncManager>()
                  : Future.error('Not available'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final lastSync = snapshot.data!.lastSyncTime;
                if (lastSync == null) {
                  return const Text('No sync history');
                }

                return Text('Last sync: ${_formatDateTime(lastSync)}');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (_status == SyncStatus.error)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _clearErrorAndSync();
              },
              child: const Text('Retry'),
            ),
          if (_status != SyncStatus.syncing)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _triggerSync();
              },
              child: const Text('Sync Now'),
            ),
        ],
      ),
    );
  }

  Future<void> _triggerSync() async {
    if (!sl.isRegistered<BackgroundSyncManager>()) return;

    try {
      final syncManager = await sl.getAsync<BackgroundSyncManager>();
      await syncManager.syncNow();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      }
    }
  }

  Future<void> _clearErrorAndSync() async {
    if (!sl.isRegistered<BackgroundSyncManager>()) return;

    try {
      final syncManager = await sl.getAsync<BackgroundSyncManager>();
      syncManager.clearError();
      await syncManager.syncNow();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
