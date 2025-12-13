import 'package:dio/dio.dart';
import 'package:readwhere_webdav/readwhere_webdav.dart';

import '../api/ocs_api_service.dart';
import '../storage/credential_storage.dart';
import 'nextcloud_file.dart';

/// Nextcloud-specific WebDAV adapter
///
/// Wraps the generic [WebDavClient] with Nextcloud-specific URL building
/// and authentication handling.
class NextcloudWebDav {
  final NextcloudCredentialStorage _storage;

  /// User-Agent for WebDAV requests
  final String userAgent;

  /// Dio client for HTTP requests
  final Dio _dio;

  NextcloudWebDav(
    this._storage, {
    this.userAgent = 'ReadWhere/1.0.0 Nextcloud-WebDAV',
    Dio? dio,
  }) : _dio = dio ?? Dio();

  /// Build a WebDAV client for a specific Nextcloud catalog
  Future<WebDavClient?> _buildClient({
    required String serverUrl,
    required String userId,
    required String catalogId,
    required String? username,
  }) async {
    final credential = await _storage.getCredential(catalogId);
    if (credential == null) return null;

    final baseUrl = _buildWebDavBaseUrl(serverUrl, userId);
    final auth = BasicAuth(
      username: username ?? userId,
      password: credential,
    );

    return WebDavClient(
      config: WebDavConfig(
        baseUrl: baseUrl,
        auth: auth,
        userAgent: userAgent,
        // Add OwnCloud/Nextcloud namespaces for enhanced metadata
        customNamespaces: {
          'oc': 'http://owncloud.org/ns',
          'nc': 'http://nextcloud.org/ns',
        },
        customProperties: {
          'oc': ['size'],
        },
      ),
      dio: _dio,
      pathExtractor: _extractRelativePath,
    );
  }

  /// List files and directories at the given path
  Future<List<NextcloudFile>> listDirectory({
    required String serverUrl,
    required String userId,
    required String catalogId,
    required String? username,
    required String path,
  }) async {
    final client = await _buildClient(
      serverUrl: serverUrl,
      userId: userId,
      catalogId: catalogId,
      username: username,
    );

    if (client == null) {
      throw WebDavException('No credentials found for catalog $catalogId');
    }

    final files = await client.listDirectory(path);
    return files.map((f) => NextcloudFile.fromWebDavFile(f)).toList();
  }

  /// Download a file from Nextcloud
  Future<DownloadResponse> downloadFile({
    required String serverUrl,
    required String userId,
    required String catalogId,
    required String? username,
    required String remotePath,
    required String localPath,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final client = await _buildClient(
      serverUrl: serverUrl,
      userId: userId,
      catalogId: catalogId,
      username: username,
    );

    if (client == null) {
      throw WebDavException('No credentials found for catalog $catalogId');
    }

    return client.downloadFile(
      remotePath,
      localPath,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  /// Check if a file has changed by comparing ETags
  Future<bool> hasFileChanged({
    required String serverUrl,
    required String userId,
    required String catalogId,
    required String? username,
    required String path,
    String? localEtag,
  }) async {
    if (localEtag == null) return true;

    final client = await _buildClient(
      serverUrl: serverUrl,
      userId: userId,
      catalogId: catalogId,
      username: username,
    );

    if (client == null) return true;

    return client.hasFileChanged(path, localEtag);
  }

  /// Get file metadata
  Future<NextcloudFile?> getFileInfo({
    required String serverUrl,
    required String userId,
    required String catalogId,
    required String? username,
    required String path,
  }) async {
    final client = await _buildClient(
      serverUrl: serverUrl,
      userId: userId,
      catalogId: catalogId,
      username: username,
    );

    if (client == null) return null;

    final file = await client.getFileInfo(path);
    return file != null ? NextcloudFile.fromWebDavFile(file) : null;
  }

  /// List files and directories using direct credentials (without storage lookup)
  ///
  /// This is useful for browsing before credentials are saved, such as
  /// during catalog setup when selecting a starting folder.
  Future<List<NextcloudFile>> listDirectoryWithCredentials({
    required String serverUrl,
    required String userId,
    required String username,
    required String password,
    required String path,
  }) async {
    final baseUrl = OcsApiService.normalizeUrl(serverUrl);
    final webdavUrl = '$baseUrl/remote.php/dav/files/$userId';

    final client = WebDavClient(
      config: WebDavConfig(
        baseUrl: webdavUrl,
        auth: BasicAuth(username: username, password: password),
        userAgent: userAgent,
        customNamespaces: {
          'oc': 'http://owncloud.org/ns',
          'nc': 'http://nextcloud.org/ns',
        },
        customProperties: {
          'oc': ['size'],
        },
      ),
      dio: _dio,
      pathExtractor: _extractRelativePath,
    );

    final files = await client.listDirectory(path);
    return files.map((f) => NextcloudFile.fromWebDavFile(f)).toList();
  }

  /// Build the WebDAV base URL for a Nextcloud server
  String _buildWebDavBaseUrl(String serverUrl, String userId) {
    final baseUrl = OcsApiService.normalizeUrl(serverUrl);
    return '$baseUrl/remote.php/dav/files/$userId';
  }

  /// Extract the relative path from a WebDAV href
  String _extractRelativePath(String href) {
    // Remove the WebDAV prefix to get relative path
    final match = RegExp(r'/remote\.php/dav/files/[^/]+(.*)').firstMatch(href);
    if (match != null) {
      var path = match.group(1) ?? '/';
      // Remove trailing slash for non-root paths
      if (path.length > 1 && path.endsWith('/')) {
        path = path.substring(0, path.length - 1);
      }
      return path.isEmpty ? '/' : path;
    }
    return href;
  }
}
