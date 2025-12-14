import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/service_locator.dart';
import '../../../data/services/background_sync_manager.dart';
import '../../providers/sync_settings_provider.dart';
import '../../widgets/adaptive/adaptive_button.dart';

/// A settings section for configuring background sync options.
///
/// Provides controls for:
/// - Master sync toggle
/// - WiFi-only sync preference
/// - Sync interval selection
/// - Individual sync type toggles (progress, catalogs, feeds)
/// - Manual sync trigger
/// - Sync status display
class SyncSettingsSection extends StatelessWidget {
  const SyncSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncSettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMasterToggle(context, settings),
            if (settings.syncEnabled) ...[
              const Divider(indent: 16, endIndent: 16),
              _buildWifiOnlyToggle(context, settings),
              _buildIntervalSelector(context, settings),
              const Divider(indent: 16, endIndent: 16),
              _buildSubheader(context, 'Sync Types'),
              _buildProgressSyncToggle(context, settings),
              _buildCatalogSyncToggle(context, settings),
              _buildFeedSyncToggle(context, settings),
              const Divider(indent: 16, endIndent: 16),
              _buildSyncActions(context, settings),
            ],
          ],
        );
      },
    );
  }

  /// Builds the master sync enable/disable toggle
  Widget _buildMasterToggle(
    BuildContext context,
    SyncSettingsProvider settings,
  ) {
    return SwitchListTile(
      title: const Text('Background Sync'),
      subtitle: Text(
        settings.syncEnabled
            ? 'Automatically sync when online'
            : 'Manual sync only',
      ),
      value: settings.syncEnabled,
      onChanged: (value) => settings.setSyncEnabled(value),
    );
  }

  /// Builds the WiFi-only toggle
  Widget _buildWifiOnlyToggle(
    BuildContext context,
    SyncSettingsProvider settings,
  ) {
    return SwitchListTile(
      title: const Text('WiFi Only'),
      subtitle: const Text('Only sync when connected to WiFi'),
      value: settings.wifiOnly,
      onChanged: (value) => settings.setWifiOnly(value),
    );
  }

  /// Builds the sync interval selector
  Widget _buildIntervalSelector(
    BuildContext context,
    SyncSettingsProvider settings,
  ) {
    final intervals = {
      15: '15 minutes',
      30: '30 minutes',
      60: '1 hour',
      120: '2 hours',
    };

    return ListTile(
      title: const Text('Sync Interval'),
      subtitle: Text(
        intervals[settings.syncIntervalMinutes] ??
            '${settings.syncIntervalMinutes} minutes',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showIntervalDialog(context, settings, intervals),
    );
  }

  /// Shows a dialog to select sync interval
  void _showIntervalDialog(
    BuildContext context,
    SyncSettingsProvider settings,
    Map<int, String> intervals,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Sync Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals.entries.map((entry) {
            final isSelected = entry.key == settings.syncIntervalMinutes;
            return ListTile(
              title: Text(entry.value),
              leading: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onTap: () {
                settings.setSyncInterval(entry.key);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          AdaptiveTextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Builds a subheader
  Widget _buildSubheader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  /// Builds the progress sync toggle
  Widget _buildProgressSyncToggle(
    BuildContext context,
    SyncSettingsProvider settings,
  ) {
    return SwitchListTile(
      title: const Text('Reading Progress'),
      subtitle: const Text('Sync reading position across devices'),
      value: settings.progressSyncEnabled,
      onChanged: (value) => settings.setProgressSyncEnabled(value),
    );
  }

  /// Builds the catalog sync toggle
  Widget _buildCatalogSyncToggle(
    BuildContext context,
    SyncSettingsProvider settings,
  ) {
    return SwitchListTile(
      title: const Text('Catalogs'),
      subtitle: const Text('Refresh OPDS and Kavita catalogs'),
      value: settings.catalogSyncEnabled,
      onChanged: (value) => settings.setCatalogSyncEnabled(value),
    );
  }

  /// Builds the feed sync toggle
  Widget _buildFeedSyncToggle(
    BuildContext context,
    SyncSettingsProvider settings,
  ) {
    return SwitchListTile(
      title: const Text('RSS Feeds'),
      subtitle: const Text('Fetch new feed items'),
      value: settings.feedSyncEnabled,
      onChanged: (value) => settings.setFeedSyncEnabled(value),
    );
  }

  /// Builds the sync actions section
  Widget _buildSyncActions(
    BuildContext context,
    SyncSettingsProvider settings,
  ) {
    return FutureBuilder<bool>(
      future: _isSyncManagerAvailable(),
      builder: (context, snapshot) {
        final isAvailable = snapshot.data ?? false;

        if (!isAvailable) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [_buildSyncNowButton(context), _buildLastSyncInfo(context)],
        );
      },
    );
  }

  /// Check if BackgroundSyncManager is available
  Future<bool> _isSyncManagerAvailable() async {
    return sl.isRegistered<BackgroundSyncManager>();
  }

  /// Builds the "Sync Now" button
  Widget _buildSyncNowButton(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.sync),
      title: const Text('Sync Now'),
      subtitle: const Text('Trigger immediate sync'),
      trailing: _SyncNowButton(),
    );
  }

  /// Builds the last sync info display
  Widget _buildLastSyncInfo(BuildContext context) {
    return FutureBuilder<BackgroundSyncManager>(
      future: sl.getAsync<BackgroundSyncManager>(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final syncManager = snapshot.data!;
        final lastSync = syncManager.lastSyncTime;

        return ListTile(
          leading: const Icon(Icons.schedule),
          title: const Text('Last Sync'),
          subtitle: Text(
            lastSync != null ? _formatDateTime(lastSync) : 'Never',
          ),
        );
      },
    );
  }

  /// Format a DateTime for display
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

/// A button that triggers an immediate sync
class _SyncNowButton extends StatefulWidget {
  @override
  State<_SyncNowButton> createState() => _SyncNowButtonState();
}

class _SyncNowButtonState extends State<_SyncNowButton> {
  bool _isSyncing = false;

  Future<void> _triggerSync() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      final syncManager = await sl.getAsync<BackgroundSyncManager>();
      await syncManager.syncNow();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isSyncing
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : AdaptiveIconButton(icon: Icons.sync, onPressed: _triggerSync);
  }
}
