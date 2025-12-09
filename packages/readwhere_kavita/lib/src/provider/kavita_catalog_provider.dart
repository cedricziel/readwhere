import 'dart:io';

import 'package:readwhere_opds/readwhere_opds.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

import '../api/kavita_api_client.dart';
import '../api/kavita_exception.dart';

/// Kavita implementation of [CatalogProvider].
///
/// Kavita servers use OPDS for browsing and downloading, but have
/// additional API endpoints for authentication and progress sync.
class KavitaCatalogProvider implements CatalogProvider {
  /// Creates a catalog provider with the given services.
  ///
  /// [kavitaApiClient] handles Kavita REST API operations (auth, progress sync).
  /// [opdsClient] handles OPDS operations (browse, search, download).
  /// [cache] is an optional cache implementation for OPDS feeds.
  /// [downloadDirectory] is a function that returns the download directory for a catalog.
  KavitaCatalogProvider(
    this._kavitaApiClient,
    this._opdsClient, {
    OpdsCacheInterface? cache,
    Future<Directory> Function(String catalogId)? downloadDirectory,
  }) : _cache = cache,
       _downloadDirectory = downloadDirectory;

  final KavitaApiClient _kavitaApiClient;
  final OpdsClient _opdsClient;
  final OpdsCacheInterface? _cache;
  final Future<Directory> Function(String catalogId)? _downloadDirectory;

  @override
  String get id => 'kavita';

  @override
  String get name => 'Kavita Server';

  @override
  String get description =>
      'Browse Kavita libraries via OPDS with progress sync';

  @override
  Set<CatalogCapability> get capabilities => {
    CatalogCapability.browse,
    CatalogCapability.search,
    CatalogCapability.download,
    CatalogCapability.pagination,
    CatalogCapability.apiKeyAuth,
    CatalogCapability.progressSync,
  };

  @override
  bool canHandle(CatalogInfo catalog) {
    return catalog.providerType == id || catalog.providerType == 'kavita';
  }

  @override
  Future<ValidationResult> validate(CatalogInfo catalog) async {
    final apiKey = catalog.providerConfig['apiKey'] as String?;
    if (apiKey == null || apiKey.isEmpty) {
      return ValidationResult.failure(
        error: 'API key is required for Kavita servers',
        errorCode: 'missing_api_key',
      );
    }

    try {
      // Use Kavita API to validate the API key
      final serverInfo = await _kavitaApiClient.authenticate(
        catalog.url,
        apiKey,
      );

      // Also validate the OPDS endpoint
      final opdsUrl = _getOpdsUrl(catalog.url, apiKey);
      final feed = await _opdsClient.validateCatalog(opdsUrl);

      return ValidationResult.success(
        serverName: serverInfo.serverName,
        properties: {
          'feedId': feed.id,
          'feedKind': feed.kind.name,
          'kavitaVersion': serverInfo.version,
          if (feed.subtitle != null) 'subtitle': feed.subtitle,
          if (feed.author != null) 'author': feed.author,
          'hasSearch': feed.hasSearch,
          'entryCount': feed.entries.length,
        },
      );
    } on KavitaApiException catch (e) {
      return ValidationResult.failure(
        error: e.message,
        errorCode: e.statusCode == 401 ? 'auth_failed' : 'validation_failed',
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
    final apiKey = catalog.providerConfig['apiKey'] as String?;
    final opdsUrl = _getOpdsUrl(catalog.url, apiKey ?? '');
    final url = path ?? opdsUrl;

    // Use cache if available, otherwise fetch directly
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

    // No cache, fetch directly
    final feed = await _opdsClient.fetchFeed(url);
    return feed.toBrowseResult();
  }

  @override
  Future<BrowseResult> search(
    CatalogInfo catalog,
    String query, {
    int? page,
  }) async {
    final apiKey = catalog.providerConfig['apiKey'] as String?;
    final opdsUrl = _getOpdsUrl(catalog.url, apiKey ?? '');

    // First get the root feed to find the search link
    final rootFeed = await _opdsClient.fetchFeed(opdsUrl);

    if (!rootFeed.hasSearch) {
      throw UnsupportedError('This Kavita catalog does not support search');
    }

    final searchResult = await _opdsClient.search(rootFeed, query);
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
    if (_downloadDirectory != null) {
      downloadDir = await _downloadDirectory(catalog.id);
    } else {
      // Default to a temp directory
      downloadDir = Directory.systemTemp;
    }

    await _opdsClient.downloadBook(
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

  /// Get the OPDS URL for a Kavita server.
  ///
  /// Kavita OPDS URL format: {server}/api/opds/{apiKey}
  String _getOpdsUrl(String serverUrl, String apiKey) {
    final baseUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    return '$baseUrl/api/opds/$apiKey';
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
