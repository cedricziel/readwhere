import 'package:readwhere_plugin/readwhere_plugin.dart';

import '../api/nextcloud_client.dart';
import '../api/ocs_api_service.dart';
import '../webdav/nextcloud_file_adapter.dart';

/// Nextcloud implementation of [CatalogProvider].
///
/// Provides access to ebooks stored on a Nextcloud server via WebDAV.
/// Supports browsing directories and downloading files.
///
/// Note: Nextcloud doesn't support search through WebDAV, so the search
/// capability is not advertised.
class NextcloudCatalogProvider implements CatalogProvider {
  /// Creates a catalog provider with the given Nextcloud client.
  NextcloudCatalogProvider(this._client);

  final NextcloudClient _client;

  @override
  String get id => 'nextcloud';

  @override
  String get name => 'Nextcloud';

  @override
  String get description => 'Browse and download ebooks from Nextcloud';

  @override
  Set<CatalogCapability> get capabilities => {
        CatalogCapability.browse,
        CatalogCapability.download,
        CatalogCapability.basicAuth,
        CatalogCapability.oauthAuth,
      };

  @override
  bool canHandle(CatalogInfo catalog) {
    return catalog.providerType == id || catalog.providerType == 'nextcloud';
  }

  @override
  Future<ValidationResult> validate(CatalogInfo catalog) async {
    try {
      final serverUrl = catalog.url;
      final username = catalog.providerConfig['username'] as String?;
      final credential = await _client.storage.getCredential(catalog.id);

      if (credential == null) {
        return const ValidationResult.failure(
          error: 'No credentials found for this catalog',
          errorCode: 'auth_required',
        );
      }

      // Validate by getting server info
      final serverInfo = await _client.validateAppPassword(
        serverUrl,
        username ?? '',
        credential,
      );

      return ValidationResult.success(
        serverName: serverInfo.serverName,
        serverVersion: serverInfo.version,
        properties: {
          'userId': serverInfo.userId,
          'displayName': serverInfo.displayName,
          'email': serverInfo.email,
        },
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
    final serverUrl = OcsApiService.normalizeUrl(catalog.url);
    final userId = catalog.providerConfig['userId'] as String?;
    final username = catalog.providerConfig['username'] as String?;
    final booksFolder = catalog.providerConfig['booksFolder'] as String? ?? '/';

    if (userId == null) {
      throw StateError('userId is required in providerConfig');
    }

    // Determine the actual path to browse
    final browsePath = path ?? booksFolder;

    final files = await _client.listDirectory(
      serverUrl: serverUrl,
      userId: userId,
      catalogId: catalog.id,
      username: username,
      path: browsePath,
    );

    // Create adapter for converting files to entries
    final adapter = NextcloudFileAdapter(
      serverUrl: serverUrl,
      userId: userId,
    );

    // Get parent path for navigation
    final parentPath = _getParentPath(browsePath);

    return adapter.toBrowseResult(
      files,
      title: _getTitleFromPath(browsePath),
      parentPath: parentPath != booksFolder ? parentPath : null,
    );
  }

  @override
  Future<BrowseResult> search(
    CatalogInfo catalog,
    String query, {
    int? page,
  }) async {
    throw UnsupportedError(
      'Nextcloud provider does not support search. '
      'Check capabilities before calling search.',
    );
  }

  @override
  Future<void> download(
    CatalogInfo catalog,
    CatalogFile file,
    String localPath, {
    ProgressCallback? onProgress,
  }) async {
    final serverUrl = OcsApiService.normalizeUrl(catalog.url);
    final userId = catalog.providerConfig['userId'] as String?;
    final username = catalog.providerConfig['username'] as String?;

    if (userId == null) {
      throw StateError('userId is required in providerConfig');
    }

    // Extract the path from file properties or href
    final remotePath = file.properties['path'] as String? ??
        _extractPathFromUrl(file.href, userId);

    await _client.downloadFile(
      serverUrl: serverUrl,
      userId: userId,
      catalogId: catalog.id,
      username: username,
      remotePath: remotePath,
      localPath: localPath,
      onProgress: onProgress,
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

  // Helper methods

  String? _getParentPath(String path) {
    if (path == '/' || path.isEmpty) return null;
    final lastSlash = path.lastIndexOf('/');
    if (lastSlash <= 0) return '/';
    return path.substring(0, lastSlash);
  }

  String _getTitleFromPath(String path) {
    if (path == '/' || path.isEmpty) return 'Root';
    final lastSlash = path.lastIndexOf('/');
    if (lastSlash == -1 || lastSlash == path.length - 1) {
      return path;
    }
    return path.substring(lastSlash + 1);
  }

  String _extractPathFromUrl(String url, String userId) {
    // Extract path from WebDAV URL
    final match = RegExp('/remote\\.php/dav/files/$userId(.*)').firstMatch(url);
    return match?.group(1) ?? url;
  }
}
