import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../data/services/background_sync_manager.dart';
import '../../../../data/services/nextcloud_news_sync_service.dart';
import '../../../../domain/entities/catalog.dart';
import '../../../providers/catalogs_provider.dart';
import '../../../providers/sync_settings_provider.dart';
import '../../../widgets/adaptive/adaptive_button.dart';
import 'nextcloud_folder_picker_dialog.dart';

/// Settings dialog for Nextcloud catalog configuration.
///
/// Allows users to:
/// - Change the starting folder for file browsing
/// - Enable/disable News app sync (if available on server)
class NextcloudCatalogSettingsDialog extends StatefulWidget {
  final Catalog catalog;

  const NextcloudCatalogSettingsDialog({super.key, required this.catalog});

  /// Shows the settings dialog and returns the updated catalog if changes were made.
  static Future<Catalog?> show({
    required BuildContext context,
    required Catalog catalog,
  }) async {
    return showDialog<Catalog>(
      context: context,
      builder: (context) => NextcloudCatalogSettingsDialog(catalog: catalog),
    );
  }

  @override
  State<NextcloudCatalogSettingsDialog> createState() =>
      _NextcloudCatalogSettingsDialogState();
}

class _NextcloudCatalogSettingsDialogState
    extends State<NextcloudCatalogSettingsDialog> {
  late Catalog _catalog;
  bool _isCheckingNews = false;
  bool _isSaving = false;
  String? _error;
  bool _globalSyncEnabled = false;
  bool _feedSyncEnabled = true;

  @override
  void initState() {
    super.initState();
    _catalog = widget.catalog;

    // Check sync settings
    _checkSyncSettings();

    // Check News app availability if not yet checked
    if (_catalog.newsAppAvailable == null) {
      _checkNewsAvailability();
    }
  }

  void _checkSyncSettings() {
    if (sl.isRegistered<SyncSettingsProvider>()) {
      final syncSettings = sl<SyncSettingsProvider>();
      setState(() {
        _globalSyncEnabled = syncSettings.syncEnabled;
        _feedSyncEnabled = syncSettings.feedSyncEnabled;
      });
    }
  }

  Future<void> _checkNewsAvailability() async {
    setState(() {
      _isCheckingNews = true;
      _error = null;
    });

    try {
      final syncService = sl<NextcloudNewsSyncService>();
      final updatedCatalog = await syncService.updateNewsAvailability(_catalog);

      if (mounted) {
        setState(() {
          _catalog = updatedCatalog;
          _isCheckingNews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingNews = false;
          // Don't show error, just leave newsAppAvailable as null
        });
      }
    }
  }

  Future<void> _openFolderPicker() async {
    final newPath = await NextcloudFolderPickerDialog.showForExistingCatalog(
      context: context,
      catalog: _catalog,
    );

    if (newPath != null && mounted) {
      // Skip update if same folder selected
      if (newPath == _catalog.booksFolder ||
          (newPath == '/' &&
              (_catalog.booksFolder == null ||
                  _catalog.booksFolder!.isEmpty))) {
        return;
      }

      setState(() {
        _catalog = _catalog.copyWith(
          booksFolder: newPath == '/' ? '' : newPath,
        );
      });
    }
  }

  Future<void> _toggleNewsSyncEnabled(bool value) async {
    setState(() {
      _catalog = _catalog.copyWith(newsSyncEnabled: value);
    });
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final provider = sl<CatalogsProvider>();
      final result = await provider.updateCatalog(_catalog);

      if (result != null && mounted) {
        // If News sync was just enabled, schedule an initial sync
        if (_catalog.newsSyncEnabled && !widget.catalog.newsSyncEnabled) {
          _scheduleInitialNewsSync();
        }
        Navigator.of(context).pop(result);
      } else if (mounted) {
        setState(() {
          _error = 'Failed to save settings';
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _scheduleInitialNewsSync() async {
    try {
      // Check if BackgroundSyncManager is registered
      if (sl.isRegistered<BackgroundSyncManager>()) {
        final syncManager = await sl.getAsync<BackgroundSyncManager>();
        await syncManager.scheduleNextcloudNewsSync(catalogId: _catalog.id);
      }
    } catch (e) {
      // Ignore errors, sync will happen on next background run
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog.adaptive(
      title: Text(_catalog.name),
      content: Material(
        // Material wrapper needed for InkWell inside CupertinoAlertDialog
        type: MaterialType.transparency,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Starting folder section
              Text('Starting Folder', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              InkWell(
                onTap: _openFolderPicker,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.folder, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _catalog.booksFolder?.isNotEmpty == true
                              ? _catalog.booksFolder!
                              : '/ (Home)',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // News sync section
              Text(
                'RSS Feeds from News App',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              _buildNewsSyncSection(theme),

              // Error message
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        AdaptiveTextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AdaptiveFilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildNewsSyncSection(ThemeData theme) {
    if (_isCheckingNews) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Checking News app availability...',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    if (_catalog.newsAppAvailable == false) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: theme.colorScheme.outline,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'News app not available',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Install the News app on your Nextcloud server to sync RSS feeds.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // News app is available - show toggle
    final showSyncWarning =
        _catalog.newsSyncEnabled && (!_globalSyncEnabled || !_feedSyncEnabled);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.rss_feed,
                color: _catalog.newsSyncEnabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync feeds from News app',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      'Import RSS subscriptions and sync read status',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _catalog.newsSyncEnabled,
                onChanged: _toggleNewsSyncEnabled,
              ),
            ],
          ),
        ),
        if (showSyncWarning) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.onTertiaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Enable "Sync" and "Feed sync" in Settings > Sync for this to work.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
