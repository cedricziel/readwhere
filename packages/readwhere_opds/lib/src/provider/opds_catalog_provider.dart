import 'dart:io';

import 'package:readwhere_plugin/readwhere_plugin.dart';

import '../adapters/opds_adapters.dart';
import '../cache/opds_cache_interface.dart';
import '../client/opds_client.dart';
import '../client/opds_exception.dart';
import '../entities/opds_link.dart';

/// OPDS implementation of [CatalogProvider].
///
/// Provides access to OPDS 1.x and 2.0 catalogs for browsing,
/// searching, and downloading ebooks.
class OpdsCatalogProvider implements CatalogProvider {
  /// Creates a catalog provider with the given services.
  ///
  /// [client] is the OPDS HTTP client for fetching feeds.
  /// [cache] is an optional cache implementation. If not provided,
  /// a [NoOpCache] is used which fetches directly from network.
  /// [downloadDirectory] is a function that returns the directory
  /// to save downloaded files. This allows the main app to control
  /// where downloads are stored.
  OpdsCatalogProvider(
    this._client, {
    OpdsCacheInterface? cache,
    Future<Directory> Function(String catalogId)? downloadDirectory,
  }) : _cache = cache,
       _getDownloadDir = downloadDirectory;

  final OpdsClient _client;
  final OpdsCacheInterface? _cache;
  final Future<Directory> Function(String catalogId)? _getDownloadDir;

  @override
  String get id => 'opds';

  @override
  String get name => 'OPDS Catalog';

  @override
  String get description => 'Browse OPDS 1.x and 2.0 catalogs';

  @override
  Set<CatalogCapability> get capabilities => {
    CatalogCapability.browse,
    CatalogCapability.search,
    CatalogCapability.download,
    CatalogCapability.pagination,
    CatalogCapability.noAuth,
    CatalogCapability.basicAuth,
  };

  @override
  bool canHandle(CatalogInfo catalog) {
    return catalog.providerType == id || catalog.providerType == 'opds';
  }

  @override
  Future<ValidationResult> validate(CatalogInfo catalog) async {
    try {
      final feed = await _client.validateCatalog(catalog.url);
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
      return ValidationResult.failure(
        error: e.message,
        errorCode: e.statusCode == 401 ? 'auth_failed' : 'validation_failed',
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
    final url = path ?? catalog.url;

    // Use cache service with network-first strategy if available
    if (_cache != null) {
      final cachedResult = await _cache.fetchFeed(
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
    return feed.toBrowseResult();
  }

  @override
  Future<BrowseResult> search(
    CatalogInfo catalog,
    String query, {
    int? page,
  }) async {
    // First get the root feed to find the search link
    final rootFeed = await _client.fetchFeed(catalog.url);

    if (!rootFeed.hasSearch) {
      throw UnsupportedError('This OPDS catalog does not support search');
    }

    final searchResult = await _client.search(rootFeed, query);
    return searchResult.toBrowseResult();
  }

  @override
  Future<void> download(
    CatalogInfo catalog,
    CatalogFile file,
    String localPath, {
    ProgressCallback? onProgress,
  }) async {
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
      downloadDir = await _getDownloadDir(catalog.id);
    } else {
      // Default to a temp directory
      downloadDir = Directory.systemTemp;
    }

    await _client.downloadBook(
      link,
      downloadDir,
      onProgress: onProgress != null
          ? (progress) {
              // Convert from 0.0-1.0 double to received/total int format
              final total = file.size ?? 100;
              final received = (progress * total).toInt();
              onProgress(received, total);
            }
          : null,
    );
  }

  // CatalogProvider interface implementations
  @override
  bool hasCapability(CatalogCapability capability) =>
      capabilities.contains(capability);

  @override
  bool get supportsSearch => hasCapability(CatalogCapability.search);

  @override
  bool get supportsPagination => hasCapability(CatalogCapability.pagination);

  @override
  bool get supportsDownload => hasCapability(CatalogCapability.download);

  @override
  bool get supportsProgressSync =>
      hasCapability(CatalogCapability.progressSync);
}
