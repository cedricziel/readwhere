import 'dart:io';

import 'package:logging/logging.dart';
import 'package:readwhere_kavita/readwhere_kavita.dart';
import 'package:readwhere_opds/readwhere_opds.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

/// Kavita server plugin using the readwhere_kavita and readwhere_opds libraries.
///
/// This plugin provides Kavita server integration with:
/// - OPDS catalog browsing
/// - API key authentication
/// - Reading progress sync
///
/// Implements the unified plugin architecture with [PluginBase],
/// [CatalogBrowsingCapability], [AccountCapability], and [ProgressSyncCapability]
/// mixins.
class KavitaPlugin extends PluginBase
    with CatalogBrowsingCapability, AccountCapability, ProgressSyncCapability {
  late Logger _log;
  late KavitaApiClient _kavitaClient;
  late OpdsClient _opdsClient;
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
  String get id => 'com.readwhere.kavita';

  @override
  String get name => 'Kavita Server';

  @override
  String get description =>
      'Browse Kavita libraries via OPDS with progress sync';

  @override
  String get version => '1.0.0';

  @override
  List<String> get capabilityNames => [
    'CatalogBrowsingCapability',
    'AccountCapability',
    'ProgressSyncCapability',
  ];

  // ===== CatalogBrowsingCapability =====

  @override
  Set<PluginCatalogFeature> get catalogFeatures => {
    PluginCatalogFeature.browse,
    PluginCatalogFeature.search,
    PluginCatalogFeature.download,
    PluginCatalogFeature.pagination,
  };

  // ===== AccountCapability =====

  @override
  Set<AuthType> get supportedAuthTypes => {AuthType.apiKey};

  @override
  Future<void> initialize(PluginContext context) async {
    _log = context.logger;
    _kavitaClient = KavitaApiClient(context.httpClient);
    _opdsClient = OpdsClient(context.httpClient);
    _log.info('Kavita plugin initialized');
  }

  @override
  Future<void> dispose() async {
    _kavitaClient.dispose();
    _log.info('Kavita plugin disposed');
  }

  @override
  bool canHandleCatalog(CatalogInfo catalog) {
    return catalog.providerType == 'kavita';
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
      _log.info('Validating Kavita server: ${catalog.url}');

      // Use Kavita API to validate the API key
      final serverInfo = await _kavitaClient.authenticate(catalog.url, apiKey);

      // Also validate the OPDS endpoint
      final opdsUrl = _getOpdsUrl(catalog.url, apiKey);
      final feed = await _opdsClient.validateCatalog(opdsUrl);

      _log.info('Kavita server validated: ${serverInfo.serverName}');

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
      _log.warning('Kavita validation failed: ${e.message}');
      return ValidationResult.failure(
        error: e.message,
        errorCode: e.statusCode == 401 ? 'auth_failed' : 'validation_failed',
      );
    } on OpdsException catch (e) {
      _log.warning('OPDS validation failed: ${e.message}');
      return ValidationResult.failure(
        error: e.message,
        errorCode: e.statusCode == 401 ? 'auth_failed' : 'validation_failed',
      );
    } catch (e) {
      _log.severe('Kavita validation error: $e');
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

    _log.info('Browsing Kavita catalog: $url');

    // Use cache if available
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

    // No cache, fetch directly
    final feed = await _opdsClient.fetchFeed(url);

    _log.info('Fetched Kavita feed: ${feed.entries.length} entries');
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

    _log.info('Searching Kavita catalog: $query');

    // First get the root feed to find the search link
    final rootFeed = await _opdsClient.fetchFeed(opdsUrl);

    if (!rootFeed.hasSearch) {
      throw UnsupportedError('This Kavita catalog does not support search');
    }

    final searchResult = await _opdsClient.search(rootFeed, query);

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
    _log.info('Downloading Kavita file: ${file.href} -> $localPath');

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

    await _opdsClient.downloadBook(
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

  // ===== AccountCapability =====

  @override
  Future<AccountInfo> authenticate(
    String serverUrl,
    AuthCredentials credentials,
  ) async {
    if (credentials is! ApiKeyCredentials) {
      throw ArgumentError('Kavita requires API key authentication');
    }

    _log.info('Authenticating with Kavita server: $serverUrl');

    final serverInfo = await _kavitaClient.authenticate(
      serverUrl,
      credentials.apiKey,
    );

    return KavitaPluginAccountInfo(
      serverUrl: serverUrl,
      serverName: serverInfo.serverName,
      serverVersion: serverInfo.version,
      apiKey: credentials.apiKey,
    );
  }

  @override
  Future<void> logout(AccountInfo account) async {
    // Kavita API key auth doesn't require logout
    _log.info('Logged out from Kavita: ${account.displayName}');
  }

  // ===== ProgressSyncCapability =====

  @override
  Future<void> syncProgress({
    required CatalogInfo catalog,
    required String bookIdentifier,
    required ReadingProgressData progress,
  }) async {
    final apiKey = catalog.providerConfig['apiKey'] as String?;
    if (apiKey == null) {
      throw StateError('API key is required for progress sync');
    }

    // Parse Kavita book identifier format: kavita:chapterId:volumeId:seriesId:libraryId
    final ids = _parseKavitaBookId(bookIdentifier);

    _log.info(
      'Syncing progress for chapter ${ids.chapterId}: ${progress.percentage * 100}%',
    );

    await _kavitaClient.updateProgress(
      catalog.url,
      apiKey,
      KavitaProgress(
        chapterId: ids.chapterId,
        pageNum: progress.pageNumber,
        volumeId: ids.volumeId ?? 0,
        seriesId: ids.seriesId ?? 0,
        libraryId: ids.libraryId ?? 0,
      ),
    );
  }

  @override
  Future<ReadingProgressData?> fetchProgress({
    required CatalogInfo catalog,
    required String bookIdentifier,
  }) async {
    final apiKey = catalog.providerConfig['apiKey'] as String?;
    if (apiKey == null) {
      throw StateError('API key is required for progress fetch');
    }

    // Parse Kavita book identifier
    final ids = _parseKavitaBookId(bookIdentifier);

    _log.info('Fetching progress for chapter ${ids.chapterId}');

    final progress = await _kavitaClient.getProgress(
      catalog.url,
      apiKey,
      ids.chapterId,
    );

    if (progress == null) return null;

    return ReadingProgressData(
      pageNumber: progress.pageNum,
      percentage: progress.pageNum > 0 ? progress.pageNum / 100.0 : 0.0,
      updatedAt: progress.lastModified ?? DateTime.now(),
      isComplete: progress.pageNum >= 100,
    );
  }

  @override
  Future<void> markAsComplete({
    required CatalogInfo catalog,
    required String bookIdentifier,
  }) async {
    final apiKey = catalog.providerConfig['apiKey'] as String?;
    if (apiKey == null) {
      throw StateError('API key is required to mark as complete');
    }

    final ids = _parseKavitaBookId(bookIdentifier);

    _log.info('Marking chapter ${ids.chapterId} as read');

    await _kavitaClient.markChapterRead(
      catalog.url,
      apiKey,
      chapterId: ids.chapterId,
      volumeId: ids.volumeId ?? 0,
      seriesId: ids.seriesId ?? 0,
    );
  }

  /// Parse Kavita book identifier.
  ///
  /// Expected format: kavita:chapterId[:volumeId:seriesId:libraryId]
  _KavitaBookIds _parseKavitaBookId(String bookIdentifier) {
    final parts = bookIdentifier.split(':');
    if (parts.length < 2 || parts[0] != 'kavita') {
      throw ArgumentError(
        'Invalid Kavita book identifier: $bookIdentifier. '
        'Expected format: kavita:chapterId[:volumeId:seriesId:libraryId]',
      );
    }

    final chapterId = int.tryParse(parts[1]);
    if (chapterId == null) {
      throw ArgumentError('Invalid chapter ID in identifier: $bookIdentifier');
    }

    return _KavitaBookIds(
      chapterId: chapterId,
      volumeId: parts.length > 2 ? int.tryParse(parts[2]) : null,
      seriesId: parts.length > 3 ? int.tryParse(parts[3]) : null,
      libraryId: parts.length > 4 ? int.tryParse(parts[4]) : null,
    );
  }
}

/// Parsed Kavita book IDs.
class _KavitaBookIds {
  final int chapterId;
  final int? volumeId;
  final int? seriesId;
  final int? libraryId;

  _KavitaBookIds({
    required this.chapterId,
    this.volumeId,
    this.seriesId,
    this.libraryId,
  });
}

/// AccountInfo implementation for Kavita plugin.
class KavitaPluginAccountInfo implements AccountInfo {
  /// Creates a Kavita account info.
  const KavitaPluginAccountInfo({
    required this.serverUrl,
    required this.serverName,
    required this.serverVersion,
    required this.apiKey,
  });

  /// The Kavita server URL.
  final String serverUrl;

  /// The server name/install ID.
  final String serverName;

  /// The Kavita server version.
  final String serverVersion;

  /// The user's API key.
  final String apiKey;

  @override
  String get catalogId => '';

  @override
  AuthType get authType => AuthType.apiKey;

  @override
  String get userId => 'kavita-user';

  @override
  String get displayName => serverName;

  @override
  bool get isAuthenticated => true;

  @override
  Map<String, dynamic> get providerData => {
    'serverUrl': serverUrl,
    'serverName': serverName,
    'serverVersion': serverVersion,
    'apiKey': apiKey,
  };
}
