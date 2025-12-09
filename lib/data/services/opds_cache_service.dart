import 'package:readwhere_opds/readwhere_opds.dart';

import '../../domain/repositories/opds_cache_repository.dart';

/// Exception thrown when cache is required but not available
class CacheNotFoundException implements Exception {
  final String url;
  final String? message;

  CacheNotFoundException(this.url, [this.message]);

  @override
  String toString() =>
      'CacheNotFoundException: No cache found for $url${message != null ? ' - $message' : ''}';
}

/// Service for cache-aware OPDS feed fetching
///
/// Implements [OpdsCacheInterface] from the readwhere_opds package.
class OpdsCacheService implements OpdsCacheInterface {
  final OpdsClient _opdsClient;
  final OpdsCacheRepository _cacheRepository;

  OpdsCacheService({
    required OpdsClient opdsClient,
    required OpdsCacheRepository cacheRepository,
  }) : _opdsClient = opdsClient,
       _cacheRepository = cacheRepository;

  /// Check if a cached result is still fresh (not expired)
  bool _isFresh(CachedFeedResult cached) {
    if (!cached.isFromCache) return true;
    if (cached.expiresAt == null) return false;
    return DateTime.now().isBefore(cached.expiresAt!);
  }

  /// Fetch feed with configurable strategy
  ///
  /// [catalogId] - The ID of the catalog
  /// [url] - The URL of the feed to fetch
  /// [strategy] - The caching strategy to use (default: networkFirst)
  @override
  Future<CachedFeedResult> fetchFeed({
    required String catalogId,
    required String url,
    required FetchStrategy strategy,
  }) async {
    switch (strategy) {
      case FetchStrategy.cacheFirst:
        return _fetchCacheFirst(catalogId, url);

      case FetchStrategy.networkFirst:
        return _fetchNetworkFirst(catalogId, url);

      case FetchStrategy.cacheOnly:
        return _fetchCacheOnly(catalogId, url);

      case FetchStrategy.networkOnly:
        return _fetchNetworkOnly(catalogId, url);
    }
  }

  /// Try cache first, fall back to network if cache is stale or missing
  Future<CachedFeedResult> _fetchCacheFirst(
    String catalogId,
    String url,
  ) async {
    // Check if we have fresh cache
    final cached = await _cacheRepository.getCachedFeed(catalogId, url);
    if (cached != null && _isFresh(cached)) {
      return cached;
    }

    // Cache is stale or missing, try network
    try {
      return await _fetchNetworkOnly(catalogId, url, cacheResult: true);
    } catch (e) {
      // Network failed, return stale cache if available
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  /// Try network first, fall back to cache on failure
  Future<CachedFeedResult> _fetchNetworkFirst(
    String catalogId,
    String url,
  ) async {
    try {
      return await _fetchNetworkOnly(catalogId, url, cacheResult: true);
    } catch (e) {
      // Network failed, try cache
      final cached = await _cacheRepository.getCachedFeed(catalogId, url);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  /// Only use cache
  Future<CachedFeedResult> _fetchCacheOnly(String catalogId, String url) async {
    final cached = await _cacheRepository.getCachedFeed(catalogId, url);
    if (cached != null) {
      return cached;
    }
    throw CacheNotFoundException(url, 'No cached data available');
  }

  /// Only use network
  Future<CachedFeedResult> _fetchNetworkOnly(
    String catalogId,
    String url, {
    bool cacheResult = false,
  }) async {
    final feed = await _opdsClient.fetchFeed(url);

    if (cacheResult) {
      await _cacheRepository.cacheFeed(catalogId, url, feed);
    }

    return CachedFeedResult(
      feed: feed,
      isFromCache: false,
      cachedAt: null,
      expiresAt: null,
    );
  }

  /// Pre-fetch and cache a feed (for background caching)
  Future<void> prefetchFeed(String catalogId, String url) async {
    try {
      await _fetchNetworkOnly(catalogId, url, cacheResult: true);
    } catch (_) {
      // Ignore errors during prefetch
    }
  }

  /// Force refresh cache for a feed
  Future<CachedFeedResult> refreshFeed(String catalogId, String url) async {
    return _fetchNetworkOnly(catalogId, url, cacheResult: true);
  }

  /// Check if a fresh cache exists
  Future<bool> hasFreshCache(String catalogId, String url) async {
    return _cacheRepository.hasFreshCache(catalogId, url);
  }

  /// Get cache statistics for a catalog
  Future<CacheStats> getCacheStats(String catalogId) async {
    return _cacheRepository.getCacheStats(catalogId);
  }

  /// Get overall cache statistics
  Future<CacheStats> getAllCacheStats() async {
    return _cacheRepository.getAllCacheStats();
  }

  /// Delete all expired cache entries
  Future<int> cleanupExpiredCache() async {
    return _cacheRepository.deleteExpiredCache();
  }

  /// Clear all cache for a catalog (implements OpdsCacheInterface)
  @override
  Future<void> clearCache(String catalogId) async {
    await _cacheRepository.deleteCatalogCache(catalogId);
  }

  /// Clear all caches (implements OpdsCacheInterface)
  @override
  Future<void> clearAllCaches() async {
    await _cacheRepository.clearAllCache();
  }
}
