import 'dart:io';

import 'package:logging/logging.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';
import 'package:readwhere_rss/readwhere_rss.dart';

import 'adapters/rss_catalog_adapters.dart';
import 'cache/rss_cache_interface.dart';

/// RSS catalog plugin using the readwhere_rss library.
///
/// This plugin provides RSS and Atom feed browsing with ebook/comic
/// download support from enclosures.
///
/// Implements the unified plugin architecture with [PluginBase] and
/// [CatalogBrowsingCapability] mixin.
class RssPlugin extends PluginBase with CatalogBrowsingCapability {
  late Logger _log;
  late RssClient _client;
  RssCacheInterface? _cache;

  /// Optional cache implementation.
  ///
  /// Set via [setCache] after initialization if caching is desired.
  void setCache(RssCacheInterface cache) => _cache = cache;

  @override
  String get id => 'com.readwhere.rss';

  @override
  String get name => 'RSS Feed';

  @override
  String get description => 'Browse RSS and Atom feeds for ebooks and comics';

  @override
  String get version => '1.0.0';

  @override
  List<String> get capabilityNames => ['CatalogBrowsingCapability'];

  @override
  Set<PluginCatalogFeature> get catalogFeatures => {
    PluginCatalogFeature.browse,
    PluginCatalogFeature.download,
  };

  @override
  Future<void> initialize(PluginContext context) async {
    _log = context.logger;
    _client = RssClient(context.httpClient);
    _log.info('RSS plugin initialized');
  }

  @override
  Future<void> dispose() async {
    _log.info('RSS plugin disposed');
  }

  @override
  bool canHandleCatalog(CatalogInfo catalog) {
    return catalog.providerType == 'rss';
  }

  /// Get username from catalog's provider config.
  String? _getUsername(CatalogInfo catalog) {
    return catalog.providerConfig['username'] as String?;
  }

  /// Get password from catalog's provider config.
  String? _getPassword(CatalogInfo catalog) {
    return catalog.providerConfig['password'] as String?;
  }

  @override
  Future<ValidationResult> validate(CatalogInfo catalog) async {
    try {
      _log.info('Validating RSS feed: ${catalog.url}');

      final feed = await _client.validateFeed(
        catalog.url,
        username: _getUsername(catalog),
        password: _getPassword(catalog),
      );

      _log.info('RSS feed validated: ${feed.title}');

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
      _log.warning('RSS auth failed: ${e.message}');
      return ValidationResult.failure(
        error: e.message,
        errorCode: 'auth_failed',
      );
    } on RssException catch (e) {
      _log.warning('RSS validation failed: ${e.message}');
      return ValidationResult.failure(
        error: e.message,
        errorCode: 'validation_failed',
      );
    } catch (e) {
      _log.severe('RSS validation error: $e');
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
    _log.info('Browsing RSS feed: $url');

    // Use cache if available
    if (_cache != null) {
      final cachedResult = await _cache!.fetchFeed(
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

    _log.info('Fetched RSS feed: ${feed.items.length} items');
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
    PluginProgressCallback? onProgress,
  }) async {
    _log.info('Downloading RSS enclosure: ${file.href} -> $localPath');

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

    _log.info('Download complete: $localPath');
  }
}
