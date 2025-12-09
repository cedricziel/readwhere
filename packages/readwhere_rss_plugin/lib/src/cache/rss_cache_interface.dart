import 'package:readwhere_rss/readwhere_rss.dart';

/// Strategy for fetching cached content.
enum RssFetchStrategy {
  /// Always fetch from network, ignore cache
  networkOnly,

  /// Try cache first, fall back to network
  cacheFirst,

  /// Try network first, fall back to cache
  networkFirst,

  /// Only use cache, don't fetch from network
  cacheOnly,
}

/// Result of a cached fetch operation.
class RssCachedFetchResult {
  /// The fetched feed
  final RssFeed feed;

  /// Whether the result was served from cache
  final bool isFromCache;

  /// When this feed was cached (if from cache)
  final DateTime? cachedAt;

  /// When this cache entry expires
  final DateTime? expiresAt;

  const RssCachedFetchResult({
    required this.feed,
    required this.isFromCache,
    this.cachedAt,
    this.expiresAt,
  });
}

/// Interface for RSS feed caching.
///
/// Implementations can provide disk or memory caching for feeds.
abstract class RssCacheInterface {
  /// Fetch a feed with caching support.
  ///
  /// [catalogId] identifies the catalog for cache partitioning.
  /// [url] is the feed URL to fetch.
  /// [strategy] determines how cache is used.
  Future<RssCachedFetchResult> fetchFeed({
    required String catalogId,
    required String url,
    required RssFetchStrategy strategy,
  });

  /// Invalidate cached data for a specific URL.
  Future<void> invalidate(String catalogId, String url);

  /// Invalidate all cached data for a catalog.
  Future<void> invalidateAll(String catalogId);

  /// Clear all cached data.
  Future<void> clearAll();
}

/// A no-op cache that always fetches from network.
class NoOpRssCache implements RssCacheInterface {
  final RssClient _client;

  NoOpRssCache(this._client);

  @override
  Future<RssCachedFetchResult> fetchFeed({
    required String catalogId,
    required String url,
    required RssFetchStrategy strategy,
  }) async {
    final feed = await _client.fetchFeed(url);
    return RssCachedFetchResult(feed: feed, isFromCache: false);
  }

  @override
  Future<void> invalidate(String catalogId, String url) async {}

  @override
  Future<void> invalidateAll(String catalogId) async {}

  @override
  Future<void> clearAll() async {}
}
