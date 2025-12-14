import 'package:logging/logging.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';
import 'package:readwhere_synology/readwhere_synology.dart';

/// Synology Drive plugin for file browsing and downloading.
///
/// This plugin provides Synology Drive integration with:
/// - File and folder browsing
/// - Search functionality
/// - File downloads with progress tracking
/// - Session-based authentication
///
/// Implements the unified plugin architecture with [PluginBase],
/// [CatalogBrowsingCapability], and [AccountCapability] mixins.
class SynologyPlugin extends PluginBase
    with CatalogBrowsingCapability, AccountCapability {
  late Logger _log;
  late SynologyClient _client;
  SynologySessionStorage? _storage;

  @override
  String get id => 'com.readwhere.synology';

  @override
  String get name => 'Synology Drive';

  @override
  String get description => 'Browse and download books from Synology Drive';

  @override
  String get version => '1.0.0';

  @override
  List<String> get capabilityNames => [
    'CatalogBrowsingCapability',
    'AccountCapability',
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
  Set<AuthType> get supportedAuthTypes => {AuthType.basic};

  @override
  Future<void> initialize(PluginContext context) async {
    _log = context.logger;
    _storage = SecureSynologySessionStorage();
    _client = SynologyClient.create(storage: _storage!);
    _log.info('Synology plugin initialized');
  }

  @override
  Future<void> dispose() async {
    _log.info('Synology plugin disposed');
  }

  @override
  bool canHandleCatalog(CatalogInfo catalog) {
    return catalog.providerType == 'synology';
  }

  @override
  Future<ValidationResult> validate(CatalogInfo catalog) async {
    final username = catalog.providerConfig['username'] as String?;
    final password = catalog.providerConfig['password'] as String?;

    if (username == null || username.isEmpty) {
      return ValidationResult.failure(
        error: 'Username is required for Synology Drive',
        errorCode: 'missing_username',
      );
    }

    if (password == null || password.isEmpty) {
      return ValidationResult.failure(
        error: 'Password is required for Synology Drive',
        errorCode: 'missing_password',
      );
    }

    try {
      _log.info('Validating Synology server: ${catalog.url}');

      // Validate connection
      await _client.validateConnection(catalog.url, username, password);

      _log.info('Synology server validated');

      return ValidationResult.success(
        serverName: 'Synology NAS',
        properties: {'serverUrl': catalog.url},
      );
    } on SynologyException catch (e) {
      _log.warning('Synology validation failed: ${e.message}');
      return ValidationResult.failure(
        error: e.message,
        errorCode: e.isAuthError ? 'auth_failed' : 'validation_failed',
      );
    } catch (e) {
      _log.severe('Synology validation error: $e');
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
    final username = catalog.providerConfig['username'] as String?;
    final password = catalog.providerConfig['password'] as String?;

    if (username == null || password == null) {
      throw StateError('Credentials not available');
    }

    // Ensure we have an active session
    await _ensureSession(catalog.id, catalog.url, username, password);

    final browsePath = path ?? '/mydrive';

    _log.info('Browsing Synology: $browsePath');

    try {
      final result = await _client.listDirectory(
        catalog.id,
        browsePath,
        offset: page != null ? page * 100 : 0,
        limit: 100,
      );

      _log.info('Fetched ${result.items.length} items from Synology');

      return BrowseResult(
        entries: result.items.map(_toEntry).toList(),
        hasNextPage: result.hasMore(page ?? 0 * 100, 100),
        page: page ?? 1,
        totalEntries: result.total,
        properties: {'total': result.total, 'path': browsePath},
      );
    } on SynologyException catch (e) {
      _log.warning('Synology browse failed: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<BrowseResult> search(
    CatalogInfo catalog,
    String query, {
    int? page,
  }) async {
    final username = catalog.providerConfig['username'] as String?;
    final password = catalog.providerConfig['password'] as String?;

    if (username == null || password == null) {
      throw StateError('Credentials not available');
    }

    await _ensureSession(catalog.id, catalog.url, username, password);

    _log.info('Searching Synology: $query');

    try {
      final result = await _client.search(
        catalog.id,
        query,
        offset: page != null ? page * 100 : 0,
        limit: 100,
      );

      _log.info('Search found ${result.items.length} items');

      return BrowseResult(
        entries: result.items.map(_toEntry).toList(),
        hasNextPage: result.hasMore(page ?? 0 * 100, 100),
        page: page ?? 1,
        totalEntries: result.total,
        properties: {'total': result.total, 'searchTime': result.searchTime},
      );
    } on SynologyException catch (e) {
      _log.warning('Synology search failed: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> download(
    CatalogInfo catalog,
    CatalogFile file,
    String localPath, {
    PluginProgressCallback? onProgress,
  }) async {
    final username = catalog.providerConfig['username'] as String?;
    final password = catalog.providerConfig['password'] as String?;

    if (username == null || password == null) {
      throw StateError('Credentials not available');
    }

    await _ensureSession(catalog.id, catalog.url, username, password);

    _log.info('Downloading Synology file: ${file.href} -> $localPath');

    try {
      await _client.downloadFile(
        catalog.id,
        file.href,
        localPath,
        onProgress: onProgress,
      );

      _log.info('Download complete: $localPath');
    } on SynologyException catch (e) {
      _log.warning('Synology download failed: ${e.message}');
      rethrow;
    }
  }

  // ===== AccountCapability =====

  @override
  Future<AccountInfo> authenticate(
    String serverUrl,
    AuthCredentials credentials,
  ) async {
    if (credentials is! BasicAuthCredentials) {
      throw ArgumentError(
        'Synology Drive requires username/password authentication',
      );
    }

    _log.info('Authenticating with Synology server: $serverUrl');

    final session = await _client.authenticate(
      catalogId: 'temp-auth',
      serverUrl: serverUrl,
      account: credentials.username,
      password: credentials.password,
    );

    return SynologyPluginAccountInfo(
      serverUrl: session.serverUrl,
      sessionId: session.sessionId,
      username: credentials.username,
    );
  }

  @override
  Future<void> logout(AccountInfo account) async {
    final synologyAccount = account as SynologyPluginAccountInfo;
    await _client.logout(synologyAccount.catalogId);
    _log.info('Logged out from Synology: ${account.displayName}');
  }

  /// Ensures we have an active session for the catalog.
  Future<void> _ensureSession(
    String catalogId,
    String serverUrl,
    String username,
    String password,
  ) async {
    if (!await _client.hasActiveSession(catalogId)) {
      await _client.authenticate(
        catalogId: catalogId,
        serverUrl: serverUrl,
        account: username,
        password: password,
      );
    }
  }

  /// Converts a Synology file to a catalog entry.
  CatalogEntry _toEntry(SynologyFile file) {
    if (file.isDirectory) {
      return DefaultCatalogEntry(
        id: file.fileId,
        title: file.name,
        type: CatalogEntryType.navigation,
        links: [
          CatalogLink(
            href: file.path,
            rel: 'subsection',
            type: 'application/atom+xml;type=feed',
          ),
        ],
        properties: {'fileId': file.fileId, 'isDirectory': true},
      );
    }

    return DefaultCatalogEntry(
      id: file.fileId,
      title: file.name,
      type: file.isSupportedBook
          ? CatalogEntryType.book
          : CatalogEntryType.book, // All files are treated as books
      properties: {
        'fileId': file.fileId,
        'path': file.path,
        'size': file.size,
        'hash': file.hash,
        'modifiedTime': file.modifiedTime?.toIso8601String(),
      },
      links: [
        CatalogLink(
          href: file.path,
          rel: 'http://opds-spec.org/acquisition',
          type: file.mimeType,
        ),
      ],
      files: [
        CatalogFile(
          href: file.path,
          title: file.name,
          mimeType: file.mimeType,
          size: file.size,
        ),
      ],
    );
  }
}

/// AccountInfo implementation for Synology plugin.
class SynologyPluginAccountInfo implements AccountInfo {
  /// Creates a Synology account info.
  const SynologyPluginAccountInfo({
    required this.serverUrl,
    required this.sessionId,
    required this.username,
    this.catalogId = '',
  });

  /// The Synology NAS server URL.
  final String serverUrl;

  /// The active session ID.
  final String sessionId;

  /// The username.
  final String username;

  @override
  final String catalogId;

  @override
  AuthType get authType => AuthType.basic;

  @override
  String get userId => username;

  @override
  String get displayName => 'Synology ($username)';

  @override
  bool get isAuthenticated => sessionId.isNotEmpty;

  @override
  Map<String, dynamic> get providerData => {
    'serverUrl': serverUrl,
    'sessionId': sessionId,
    'username': username,
  };
}
