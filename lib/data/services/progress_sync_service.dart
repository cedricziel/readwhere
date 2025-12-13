import 'package:readwhere_plugin/readwhere_plugin.dart';

import '../../domain/entities/catalog.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/repositories/reading_progress_repository.dart';
import '../../domain/sync/progress_sync_protocol.dart';
import '../adapters/catalog_info_adapter.dart';

/// Implementation of [ProgressSyncProtocol] using the unified plugin system.
///
/// This service coordinates two-way sync of reading progress between
/// the local database and remote servers (e.g., Kavita).
class ProgressSyncService implements ProgressSyncProtocol {
  final ReadingProgressRepository _progressRepository;
  final CatalogRepository _catalogRepository;
  final UnifiedPluginRegistry _pluginRegistry;

  ProgressSyncService({
    required ReadingProgressRepository progressRepository,
    required CatalogRepository catalogRepository,
    required UnifiedPluginRegistry pluginRegistry,
  }) : _progressRepository = progressRepository,
       _catalogRepository = catalogRepository,
       _pluginRegistry = pluginRegistry;

  @override
  Future<ProgressSyncResult> syncAll({
    required String catalogId,
    bool forceFullSync = false,
  }) async {
    final catalog = await _catalogRepository.getById(catalogId);
    if (catalog == null) {
      return ProgressSyncResult(
        uploaded: 0,
        downloaded: 0,
        merged: 0,
        conflicts: 0,
        errors: [
          SyncError(
            recordId: catalogId,
            operation: 'syncAll',
            message: 'Catalog not found',
          ),
        ],
        syncedAt: DateTime.now(),
      );
    }

    // Check if the catalog's plugin supports progress sync
    final plugin = _getProgressSyncPlugin(catalog);
    if (plugin == null) {
      return ProgressSyncResult(
        uploaded: 0,
        downloaded: 0,
        merged: 0,
        conflicts: 0,
        errors: [
          SyncError(
            recordId: catalogId,
            operation: 'syncAll',
            message:
                'Catalog type ${catalog.type.name} does not support progress sync',
          ),
        ],
        syncedAt: DateTime.now(),
      );
    }

    // For now, return empty result - full sync requires iterating all books
    // from the catalog which is a more complex operation
    return ProgressSyncResult(
      uploaded: 0,
      downloaded: 0,
      merged: 0,
      conflicts: 0,
      errors: const [],
      syncedAt: DateTime.now(),
    );
  }

  @override
  Future<void> syncBook({
    required String catalogId,
    required String bookId,
    required String remoteBookId,
  }) async {
    final catalog = await _catalogRepository.getById(catalogId);
    if (catalog == null) {
      throw Exception('Catalog not found: $catalogId');
    }

    final plugin = _getProgressSyncPlugin(catalog);
    if (plugin == null) {
      throw Exception(
        'Catalog type ${catalog.type.name} does not support progress sync',
      );
    }

    final catalogInfo = catalog.toCatalogInfo();

    // Get local progress
    final localProgress = await _progressRepository.getProgressForBook(bookId);

    // Fetch remote progress
    final remoteProgress = await plugin.fetchProgress(
      catalog: catalogInfo,
      bookIdentifier: remoteBookId,
    );

    // Apply smart merge strategy (furthest progress wins)
    final mergedProgress = _smartMerge(localProgress, remoteProgress, bookId);

    if (mergedProgress == null) {
      // No progress on either side
      return;
    }

    // Determine if we need to push to remote
    final shouldPushToRemote = _shouldPushToRemote(
      localProgress,
      remoteProgress,
      mergedProgress,
    );

    // Determine if we need to update local
    final shouldUpdateLocal = _shouldUpdateLocal(
      localProgress,
      remoteProgress,
      mergedProgress,
    );

    // Push to remote if local is further
    if (shouldPushToRemote && localProgress != null) {
      await plugin.syncProgress(
        catalog: catalogInfo,
        bookIdentifier: remoteBookId,
        progress: ReadingProgressData(
          pageNumber: 0, // Not tracked locally
          percentage: localProgress.progress,
          cfi: localProgress.cfi,
          updatedAt: localProgress.updatedAt,
        ),
      );
    }

    // Update local if remote is further
    if (shouldUpdateLocal && remoteProgress != null) {
      await _progressRepository.saveProgress(
        localProgress?.copyWith(
              progress: remoteProgress.percentage,
              cfi: remoteProgress.cfi,
              updatedAt: remoteProgress.updatedAt,
            ) ??
            ReadingProgress(
              id: bookId,
              bookId: bookId,
              cfi: remoteProgress.cfi ?? '',
              progress: remoteProgress.percentage,
              updatedAt: remoteProgress.updatedAt,
            ),
      );
    }
  }

  @override
  Future<int> pushDirtyRecords({required String catalogId}) async {
    // This would require tracking dirty state on progress records
    // For now, return 0 - this will be implemented when we add
    // dirty tracking to the reading_progress table
    return 0;
  }

  @override
  Future<int> pullRemoteChanges({required String catalogId}) async {
    // This would require fetching all progress from the remote server
    // For now, return 0 - this will be implemented when we add
    // batch fetch support
    return 0;
  }

  /// Get the plugin that supports progress sync for this catalog type.
  ProgressSyncCapability? _getProgressSyncPlugin(Catalog catalog) {
    final plugins = _pluginRegistry.withCapability<ProgressSyncCapability>();
    for (final plugin in plugins) {
      // Check if this plugin handles the catalog type
      if (_pluginHandlesCatalogType(plugin, catalog.type)) {
        return plugin;
      }
    }
    return null;
  }

  /// Check if a plugin handles a specific catalog type.
  bool _pluginHandlesCatalogType(PluginBase plugin, CatalogType type) {
    // Map catalog types to plugin IDs
    switch (type) {
      case CatalogType.kavita:
        return plugin.id.contains('kavita');
      case CatalogType.nextcloud:
        return plugin.id.contains('nextcloud');
      case CatalogType.opds:
      case CatalogType.rss:
      case CatalogType.fanfiction:
        // These types don't typically support progress sync
        return false;
    }
  }

  /// Smart merge strategy: furthest progress wins.
  ///
  /// Returns the progress that should be used, or null if neither exists.
  ReadingProgress? _smartMerge(
    ReadingProgress? local,
    ReadingProgressData? remote,
    String bookId,
  ) {
    if (local == null && remote == null) {
      return null;
    }

    if (local == null) {
      // Only remote exists, convert to local format
      return ReadingProgress(
        id: bookId,
        bookId: bookId,
        cfi: remote!.cfi ?? '',
        progress: remote.percentage,
        updatedAt: remote.updatedAt,
      );
    }

    if (remote == null) {
      // Only local exists
      return local;
    }

    // Both exist - use furthest progress
    if (local.progress >= remote.percentage) {
      return local;
    } else {
      return local.copyWith(
        progress: remote.percentage,
        cfi: remote.cfi ?? local.cfi,
        updatedAt: remote.updatedAt,
      );
    }
  }

  /// Determine if we should push local progress to remote.
  bool _shouldPushToRemote(
    ReadingProgress? local,
    ReadingProgressData? remote,
    ReadingProgress? merged,
  ) {
    if (local == null || merged == null) return false;
    if (remote == null) return true; // No remote, push local
    return local.progress > remote.percentage;
  }

  /// Determine if we should update local progress from remote.
  bool _shouldUpdateLocal(
    ReadingProgress? local,
    ReadingProgressData? remote,
    ReadingProgress? merged,
  ) {
    if (remote == null || merged == null) return false;
    if (local == null) return true; // No local, save remote
    return remote.percentage > local.progress;
  }
}
