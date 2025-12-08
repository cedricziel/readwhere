import '../../data/models/opds/cached_opds_feed_model.dart';
import '../entities/opds_feed.dart';

/// Statistics about cached data
class CacheStats {
  /// Number of cached feeds
  final int feedCount;

  /// Number of cached entries
  final int entryCount;

  /// Approximate total size in bytes
  final int totalSizeBytes;

  /// Oldest cache timestamp
  final DateTime? oldestCache;

  /// Newest cache timestamp
  final DateTime? newestCache;

  const CacheStats({
    required this.feedCount,
    required this.entryCount,
    required this.totalSizeBytes,
    this.oldestCache,
    this.newestCache,
  });

  /// Empty stats
  static const empty = CacheStats(
    feedCount: 0,
    entryCount: 0,
    totalSizeBytes: 0,
  );
}

/// Repository interface for OPDS feed caching
abstract class OpdsCacheRepository {
  /// Get a cached feed by catalog ID and URL
  ///
  /// Returns null if no cache exists for the given URL
  Future<CachedFeedResult?> getCachedFeed(String catalogId, String url);

  /// Store a feed in the cache
  ///
  /// This will replace any existing cache for the same URL
  Future<void> cacheFeed(String catalogId, String url, OpdsFeed feed);

  /// Check if a fresh (non-expired) cache exists for the given URL
  Future<bool> hasFreshCache(String catalogId, String url);

  /// Delete cache for a specific feed URL
  Future<void> deleteFeedCache(String catalogId, String url);

  /// Delete all cache for a catalog
  Future<void> deleteCatalogCache(String catalogId);

  /// Delete all expired cache entries across all catalogs
  ///
  /// Returns the number of feeds deleted
  Future<int> deleteExpiredCache();

  /// Get cache statistics for a catalog
  Future<CacheStats> getCacheStats(String catalogId);

  /// Get overall cache statistics
  Future<CacheStats> getAllCacheStats();

  /// Delete all cache
  Future<void> clearAllCache();
}
