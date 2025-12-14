import '../../domain/entities/catalog.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/repositories/opds_cache_repository.dart';
import '../../domain/sync/catalog_sync_protocol.dart';
import '../../domain/sync/progress_sync_protocol.dart';
import 'opds_cache_service.dart';

/// Implementation of [CatalogSyncProtocol] for OPDS and Kavita catalogs.
///
/// This service handles refreshing catalog feeds and managing the cache
/// for offline access.
class CatalogSyncService implements CatalogSyncProtocol {
  final CatalogRepository _catalogRepository;
  final OpdsCacheService _opdsCacheService;
  final OpdsCacheRepository _cacheRepository;

  /// Track last sync times per catalog (in-memory, could be persisted)
  final Map<String, DateTime> _lastSyncTimes = {};

  CatalogSyncService({
    required CatalogRepository catalogRepository,
    required OpdsCacheService opdsCacheService,
    required OpdsCacheRepository cacheRepository,
  }) : _catalogRepository = catalogRepository,
       _opdsCacheService = opdsCacheService,
       _cacheRepository = cacheRepository;

  @override
  Future<CatalogSyncResult> refreshCatalog(String catalogId) async {
    final catalog = await _catalogRepository.getById(catalogId);
    if (catalog == null) {
      return CatalogSyncResult(
        catalogId: catalogId,
        feedsRefreshed: 0,
        entriesUpdated: 0,
        entriesAdded: 0,
        entriesRemoved: 0,
        cacheInvalidated: false,
        errors: [
          SyncError(
            recordId: catalogId,
            operation: 'refreshCatalog',
            message: 'Catalog not found',
          ),
        ],
        syncedAt: DateTime.now(),
      );
    }

    // Refresh the main feed
    return refreshFeed(catalogId: catalogId, feedUrl: catalog.opdsUrl);
  }

  @override
  Future<CatalogSyncResult> refreshFeed({
    required String catalogId,
    required String feedUrl,
  }) async {
    final errors = <SyncError>[];
    var entriesAdded = 0;
    var entriesUpdated = 0;

    try {
      // Get stats before refresh
      final statsBefore = await _cacheRepository.getCacheStats(catalogId);

      // Force refresh from network
      final result = await _opdsCacheService.refreshFeed(catalogId, feedUrl);

      // Get stats after refresh
      final statsAfter = await _cacheRepository.getCacheStats(catalogId);

      // Calculate changes (approximate - we don't track individual entries)
      final entryDelta = statsAfter.entryCount - statsBefore.entryCount;
      if (entryDelta > 0) {
        entriesAdded = entryDelta;
      } else if (entryDelta < 0) {
        // This shouldn't happen on refresh, but handle it
        entriesUpdated = statsAfter.entryCount;
      } else {
        // Same count, assume updates
        entriesUpdated = result.feed.entries.length;
      }

      // Record sync time
      _lastSyncTimes[catalogId] = DateTime.now();

      return CatalogSyncResult(
        catalogId: catalogId,
        feedsRefreshed: 1,
        entriesUpdated: entriesUpdated,
        entriesAdded: entriesAdded,
        entriesRemoved: 0,
        cacheInvalidated: false,
        errors: errors,
        syncedAt: DateTime.now(),
      );
    } catch (e) {
      errors.add(
        SyncError(
          recordId: feedUrl,
          operation: 'refreshFeed',
          message: e.toString(),
        ),
      );

      return CatalogSyncResult(
        catalogId: catalogId,
        feedsRefreshed: 0,
        entriesUpdated: 0,
        entriesAdded: 0,
        entriesRemoved: 0,
        cacheInvalidated: false,
        errors: errors,
        syncedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> prefetchFeeds({
    required String catalogId,
    required List<String> feedUrls,
  }) async {
    for (final url in feedUrls) {
      try {
        await _opdsCacheService.prefetchFeed(catalogId, url);
      } catch (_) {
        // Prefetch failures are silently ignored
      }
    }
  }

  @override
  Future<void> invalidateCache(String catalogId) async {
    await _cacheRepository.deleteCatalogCache(catalogId);
    _lastSyncTimes.remove(catalogId);
  }

  @override
  Future<int> cleanupExpiredCache() async {
    return _cacheRepository.deleteExpiredCache();
  }

  @override
  Future<DateTime?> getLastSyncTime(String catalogId) async {
    return _lastSyncTimes[catalogId];
  }

  /// Sync all catalogs
  ///
  /// Returns results for each catalog that was synced.
  Future<List<CatalogSyncResult>> syncAllCatalogs() async {
    final catalogs = await _catalogRepository.getAll();
    final results = <CatalogSyncResult>[];

    for (final catalog in catalogs) {
      // Only sync catalogs that support OPDS
      if (_supportsOpdsSyn(catalog)) {
        final result = await refreshCatalog(catalog.id);
        results.add(result);
      }
    }

    return results;
  }

  /// Check if a catalog supports OPDS sync
  bool _supportsOpdsSyn(Catalog catalog) {
    switch (catalog.type) {
      case CatalogType.opds:
      case CatalogType.kavita:
        return true;
      case CatalogType.nextcloud:
      case CatalogType.rss:
      case CatalogType.fanfiction:
      case CatalogType.synology:
        return false;
    }
  }

  /// Check if a catalog needs sync based on time elapsed
  Future<bool> needsSync(
    String catalogId, {
    Duration threshold = const Duration(hours: 1),
  }) async {
    final lastSync = await getLastSyncTime(catalogId);
    if (lastSync == null) return true;

    return DateTime.now().difference(lastSync) > threshold;
  }
}
