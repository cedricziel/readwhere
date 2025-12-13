import 'progress_sync_protocol.dart';

/// Result of a catalog sync operation
class CatalogSyncResult {
  /// ID of the catalog that was synced
  final String catalogId;

  /// Number of feeds refreshed
  final int feedsRefreshed;

  /// Number of entries updated
  final int entriesUpdated;

  /// Number of entries added
  final int entriesAdded;

  /// Number of entries removed
  final int entriesRemoved;

  /// Whether the cache was invalidated
  final bool cacheInvalidated;

  /// Errors that occurred during sync
  final List<SyncError> errors;

  /// When the sync completed
  final DateTime syncedAt;

  const CatalogSyncResult({
    required this.catalogId,
    required this.feedsRefreshed,
    required this.entriesUpdated,
    required this.entriesAdded,
    required this.entriesRemoved,
    required this.cacheInvalidated,
    required this.errors,
    required this.syncedAt,
  });

  /// Whether any errors occurred
  bool get hasErrors => errors.isNotEmpty;

  /// Whether the sync was successful
  bool get isSuccessful => errors.isEmpty;

  @override
  String toString() =>
      'CatalogSyncResult(catalog: $catalogId, feeds: $feedsRefreshed, '
      'entries: +$entriesAdded ~$entriesUpdated -$entriesRemoved)';
}

/// Protocol for synchronizing catalog data with remote servers
///
/// Implementations handle refreshing OPDS, Kavita, and other catalog
/// types with their remote servers.
abstract class CatalogSyncProtocol {
  /// Refresh all feeds for a catalog
  ///
  /// [catalogId] The catalog to refresh
  Future<CatalogSyncResult> refreshCatalog(String catalogId);

  /// Refresh a specific feed URL
  ///
  /// [catalogId] The catalog this feed belongs to
  /// [feedUrl] The URL of the feed to refresh
  Future<CatalogSyncResult> refreshFeed({
    required String catalogId,
    required String feedUrl,
  });

  /// Prefetch feeds for offline access
  ///
  /// [catalogId] The catalog to prefetch from
  /// [feedUrls] List of feed URLs to prefetch
  Future<void> prefetchFeeds({
    required String catalogId,
    required List<String> feedUrls,
  });

  /// Invalidate cache for a catalog
  ///
  /// [catalogId] The catalog whose cache should be invalidated
  Future<void> invalidateCache(String catalogId);

  /// Clean up expired cache entries
  ///
  /// Returns the number of entries cleaned up
  Future<int> cleanupExpiredCache();

  /// Get last sync time for a catalog
  ///
  /// [catalogId] The catalog to check
  Future<DateTime?> getLastSyncTime(String catalogId);
}
