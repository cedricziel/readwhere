import 'dart:io';

import 'package:readwhere_plugin/readwhere_plugin.dart';
import 'package:readwhere_rss/readwhere_rss.dart';

import '../adapters/rss_catalog_adapters.dart';
import '../cache/rss_cache_interface.dart';

/// RSS implementation of [CatalogProvider].
///
/// Provides access to RSS and Atom feeds for browsing
/// and downloading ebooks/comics from enclosures.
class RssCatalogProvider implements CatalogProvider {
  /// Creates a catalog provider with the given client.
  ///
  /// [client] is the RSS HTTP client for fetching feeds.
  /// [cache] is an optional cache implementation.
  /// [downloadDirectory] is a function that returns the directory
  /// to save downloaded files.
  RssCatalogProvider(this._client, {RssCacheInterface? cache}) : _cache = cache;

  final RssClient _client;
  final RssCacheInterface? _cache;

  @override
  String get id => 'rss';

  @override
  String get name => 'RSS Feed';

  @override
  String get description => 'Browse RSS and Atom feeds for ebooks and comics';

  @override
  Set<CatalogCapability> get capabilities => {
    CatalogCapability.browse,
    CatalogCapability.download,
    CatalogCapability.noAuth,
    CatalogCapability.basicAuth,
  };

  @override
  bool canHandle(CatalogInfo catalog) {
    return catalog.providerType == id || catalog.providerType == 'rss';
  }

  /// Get username from catalog's provider config
  String? _getUsername(CatalogInfo catalog) {
    return catalog.providerConfig['username'] as String?;
  }

  /// Get password from catalog's provider config
  String? _getPassword(CatalogInfo catalog) {
    return catalog.providerConfig['password'] as String?;
  }

  @override
  Future<ValidationResult> validate(CatalogInfo catalog) async {
    try {
      final feed = await _client.validateFeed(
        catalog.url,
        username: _getUsername(catalog),
        password: _getPassword(catalog),
      );

      return ValidationResult.success(
        serverName: feed.title,
        properties: {
          'feedId': feed.id,
          'feedFormat': feed.format.name,
          if (feed.description != null) 'description': feed.description,
          if (feed.author != null) 'author': feed.author,
          'totalItems': feed.items.length,
          'supportedItems': feed.supportedItems.length,
          'hasSupportedContent': feed.hasSupportedItems,
        },
      );
    } on RssAuthException catch (e) {
      return ValidationResult.failure(
        error: e.message,
        errorCode: 'auth_failed',
      );
    } on RssException catch (e) {
      return ValidationResult.failure(
        error: e.message,
        errorCode: 'validation_failed',
      );
    } catch (e) {
      return ValidationResult.failure(
        error: e.toString(),
        errorCode: 'validation_failed',
      );
    }
  }

  @override
  Future<BrowseResult> browse(
    CatalogInfo catalog, {
    String? path,
    int? page,
  }) async {
    // RSS feeds don't have navigation paths - always fetch the feed URL
    final url = catalog.url;

    // Use cache if available
    if (_cache != null) {
      final cachedResult = await _cache.fetchFeed(
        catalogId: catalog.id,
        url: url,
        strategy: RssFetchStrategy.networkFirst,
      );

      return cachedResult.feed.toBrowseResult().copyWith(
        properties: {
          ...cachedResult.feed.toBrowseResult().properties,
          'isFromCache': cachedResult.isFromCache,
          if (cachedResult.cachedAt != null)
            'cachedAt': cachedResult.cachedAt!.toIso8601String(),
          if (cachedResult.expiresAt != null)
            'expiresAt': cachedResult.expiresAt!.toIso8601String(),
        },
      );
    }

    // Direct fetch without caching
    final feed = await _client.fetchFeed(
      url,
      username: _getUsername(catalog),
      password: _getPassword(catalog),
    );
    return feed.toBrowseResult();
  }

  @override
  Future<BrowseResult> search(
    CatalogInfo catalog,
    String query, {
    int? page,
  }) async {
    // RSS feeds don't support search
    throw UnsupportedError('RSS feeds do not support search');
  }

  @override
  Future<void> download(
    CatalogInfo catalog,
    CatalogFile file,
    String localPath, {
    ProgressCallback? onProgress,
  }) async {
    // Ensure the target directory exists
    final targetFile = File(localPath);
    await targetFile.parent.create(recursive: true);

    await _client.downloadEnclosure(
      file.href,
      localPath,
      username: _getUsername(catalog),
      password: _getPassword(catalog),
      onProgress: onProgress != null
          ? (progress) {
              final total = file.size ?? 100;
              final received = (progress * total).toInt();
              onProgress(received, total);
            }
          : null,
    );
  }

  @override
  bool hasCapability(CatalogCapability capability) =>
      capabilities.contains(capability);

  @override
  bool get supportsSearch => false;

  @override
  bool get supportsPagination => false;

  @override
  bool get supportsDownload => hasCapability(CatalogCapability.download);

  @override
  bool get supportsProgressSync => false;
}
