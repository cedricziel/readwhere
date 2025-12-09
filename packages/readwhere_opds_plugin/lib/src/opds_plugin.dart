import 'dart:io';

import 'package:logging/logging.dart';
import 'package:readwhere_opds/readwhere_opds.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

/// OPDS catalog plugin using the readwhere_opds library.
///
/// This plugin provides OPDS 1.x and 2.0 catalog browsing with search
/// and ebook download support.
///
/// Implements the unified plugin architecture with [PluginBase] and
/// [CatalogBrowsingCapability] mixin.
class OpdsPlugin extends PluginBase with CatalogBrowsingCapability {
  late Logger _log;
  late OpdsClient _client;
  OpdsCacheInterface? _cache;
  Future<Directory> Function(String catalogId)? _getDownloadDir;

  /// Optional cache implementation.
  ///
  /// Set via [setCache] after initialization if caching is desired.
  void setCache(OpdsCacheInterface cache) => _cache = cache;

  /// Optional download directory provider.
  ///
  /// Set via [setDownloadDirectory] after initialization.
  void setDownloadDirectory(
    Future<Directory> Function(String catalogId) downloadDir,
  ) => _getDownloadDir = downloadDir;

  @override
  String get id => 'com.readwhere.opds';

  @override
  String get name => 'OPDS Catalog';

  @override
  String get description => 'Browse OPDS 1.x and 2.0 catalogs';

  @override
  String get version => '1.0.0';

  @override
  List<String> get capabilityNames => ['CatalogBrowsingCapability'];

  @override
  Set<PluginCatalogFeature> get catalogFeatures => {
    PluginCatalogFeature.browse,
    PluginCatalogFeature.search,
    PluginCatalogFeature.download,
    PluginCatalogFeature.pagination,
  };

  @override
  Future<void> initialize(PluginContext context) async {
    _log = context.logger;
    _client = OpdsClient(context.httpClient);
    _log.info('OPDS plugin initialized');
  }

  @override
  Future<void> dispose() async {
    _log.info('OPDS plugin disposed');
  }

  @override
  bool canHandleCatalog(CatalogInfo catalog) {
    return catalog.providerType == 'opds';
  }

  @override
  Future<ValidationResult> validate(CatalogInfo catalog) async {
    try {
      _log.info('Validating OPDS catalog: ${catalog.url}');

      final feed = await _client.validateCatalog(catalog.url);

      _log.info('OPDS catalog validated: ${feed.title}');

      return ValidationResult.success(
        serverName: feed.title,
        properties: {
          'feedId': feed.id,
          'feedKind': feed.kind.name,
          if (feed.subtitle != null) 'subtitle': feed.subtitle,
          if (feed.author != null) 'author': feed.author,
          'hasSearch': feed.hasSearch,
          'entryCount': feed.entries.length,
        },
      );
    } on OpdsException catch (e) {
      _log.warning('OPDS validation failed: ${e.message}');
      return ValidationResult.failure(
        error: e.message,
        errorCode: e.statusCode == 401 ? 'auth_failed' : 'validation_failed',
      );
    } catch (e) {
      _log.severe('OPDS validation error: $e');
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
    final url = path ?? catalog.url;
    _log.info('Browsing OPDS catalog: $url');

    // Use cache service with network-first strategy if available
    if (_cache != null) {
      final cachedResult = await _cache!.fetchFeed(
        catalogId: catalog.id,
        url: url,
        strategy: FetchStrategy.networkFirst,
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
    final feed = await _client.fetchFeed(url);

    _log.info('Fetched OPDS feed: ${feed.entries.length} entries');
    return feed.toBrowseResult();
  }

  @override
  Future<BrowseResult> search(
    CatalogInfo catalog,
    String query, {
    int? page,
  }) async {
    _log.info('Searching OPDS catalog: $query');

    // First get the root feed to find the search link
    final rootFeed = await _client.fetchFeed(catalog.url);

    if (!rootFeed.hasSearch) {
      throw UnsupportedError('This OPDS catalog does not support search');
    }

    final searchResult = await _client.search(rootFeed, query);

    _log.info('Search found ${searchResult.entries.length} entries');
    return searchResult.toBrowseResult();
  }

  @override
  Future<void> download(
    CatalogInfo catalog,
    CatalogFile file,
    String localPath, {
    PluginProgressCallback? onProgress,
  }) async {
    _log.info('Downloading OPDS file: ${file.href} -> $localPath');

    // Create OpdsLink from CatalogFile properties
    final link = OpdsLink(
      href: file.href,
      rel:
          file.properties['rel'] as String? ??
          'http://opds-spec.org/acquisition',
      type: file.mimeType,
      title: file.title,
      length: file.size,
      price: file.properties['price'] as String?,
      currency: file.properties['currency'] as String?,
    );

    // Determine download directory
    Directory downloadDir;
    if (_getDownloadDir != null) {
      downloadDir = await _getDownloadDir!(catalog.id);
    } else {
      // Default to temp directory
      downloadDir = Directory.systemTemp;
    }

    await _client.downloadBook(
      link,
      downloadDir,
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
