import '../entities/opds_feed.dart';

/// Result from cache fetch operations
class CachedFeedResult {
  /// The fetched OPDS feed
  final OpdsFeed feed;

  /// Whether the result came from cache
  final bool isFromCache;

  /// When the feed was cached (if from cache)
  final DateTime? cachedAt;

  /// When the cached data expires (if from cache)
  final DateTime? expiresAt;

  /// Creates a cached feed result
  CachedFeedResult({
    required this.feed,
    required this.isFromCache,
    this.cachedAt,
    this.expiresAt,
  });

  /// Creates a result from a network fetch
  factory CachedFeedResult.fromNetwork(OpdsFeed feed) {
    return CachedFeedResult(feed: feed, isFromCache: false);
  }

  /// Creates a result from cache
  factory CachedFeedResult.fromCache(
    OpdsFeed feed, {
    DateTime? cachedAt,
    DateTime? expiresAt,
  }) {
    return CachedFeedResult(
      feed: feed,
      isFromCache: true,
      cachedAt: cachedAt,
      expiresAt: expiresAt,
    );
  }
}

/// Fetch strategy for cache operations
enum FetchStrategy {
  /// Try cache first, then network on cache miss
  cacheFirst,

  /// Try network first, fallback to cache on failure
  networkFirst,

  /// Only use cache, fail if not cached
  cacheOnly,

  /// Only use network, don't cache
  networkOnly,
}

/// Abstract interface for OPDS feed caching.
///
/// The main app can inject a concrete implementation (e.g., SQLite-based).
/// The package provides a [NoOpCache] for when caching is not needed.
abstract class OpdsCacheInterface {
  /// Fetch feed with specified caching strategy.
  ///
  /// [catalogId] identifies which catalog this feed belongs to.
  /// [url] is the URL of the OPDS feed to fetch.
  /// [strategy] determines how to use the cache.
  Future<CachedFeedResult> fetchFeed({
    required String catalogId,
    required String url,
    required FetchStrategy strategy,
  });

  /// Clear all cached data for a specific catalog.
  Future<void> clearCache(String catalogId);

  /// Clear all cached OPDS data.
  Future<void> clearAllCaches();
}

/// No-op cache implementation for when caching is not needed.
///
/// Always fetches from network and doesn't cache anything.
class NoOpCache implements OpdsCacheInterface {
  /// Function to fetch feed from network
  final Future<OpdsFeed> Function(String url) fetchFromNetwork;

  /// Creates a no-op cache with the given network fetch function
  NoOpCache({required this.fetchFromNetwork});

  @override
  Future<CachedFeedResult> fetchFeed({
    required String catalogId,
    required String url,
    required FetchStrategy strategy,
  }) async {
    if (strategy == FetchStrategy.cacheOnly) {
      throw StateError('NoOpCache does not support cacheOnly strategy');
    }
    final feed = await fetchFromNetwork(url);
    return CachedFeedResult.fromNetwork(feed);
  }

  @override
  Future<void> clearCache(String catalogId) async {
    // No-op
  }

  @override
  Future<void> clearAllCaches() async {
    // No-op
  }
}
