import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart';

import '../../domain/entities/catalog.dart';
import '../../domain/entities/nextcloud_file.dart';
import 'secure_storage_service.dart';

/// Exception thrown when WebDAV operations fail
class WebDavException implements Exception {
  final String message;
  final int? statusCode;

  WebDavException(this.message, {this.statusCode});

  @override
  String toString() => 'WebDavException: $message (status: $statusCode)';
}

/// Service for Nextcloud WebDAV file operations
///
/// Handles directory listing (PROPFIND) and file downloads (GET).
class NextcloudWebDavService {
  final Dio _dio;
  final SecureStorageService _secureStorage;

  NextcloudWebDavService(this._secureStorage, {Dio? dio}) : _dio = dio ?? Dio();

  /// List files and directories at the given path
  ///
  /// Uses PROPFIND to retrieve directory contents with metadata.
  Future<List<NextcloudFile>> listDirectory(
    Catalog catalog,
    String path,
  ) async {
    final credential = await _secureStorage.getCredential(catalog.id);
    if (credential == null) {
      throw WebDavException('No credentials found for catalog ${catalog.id}');
    }

    final webdavPath = _buildWebDavPath(catalog, path);
    final auth = base64Encode(utf8.encode('${catalog.username}:$credential'));

    try {
      final response = await _dio.request<String>(
        webdavPath,
        options: Options(
          method: 'PROPFIND',
          headers: {
            'Authorization': 'Basic $auth',
            'Depth': '1',
            'Content-Type': 'application/xml',
          },
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status < 500,
        ),
        data: _propfindRequestBody,
      );

      if (response.statusCode != 207) {
        throw WebDavException(
          'Failed to list directory',
          statusCode: response.statusCode,
        );
      }

      return _parsePropfindResponse(response.data!, path);
    } on DioException catch (e) {
      throw WebDavException('Network error: ${e.message}');
    }
  }

  /// Download a file from Nextcloud
  ///
  /// Supports progress callback for UI updates.
  Future<File> downloadFile(
    Catalog catalog,
    String remotePath,
    String localPath, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final credential = await _secureStorage.getCredential(catalog.id);
    if (credential == null) {
      throw WebDavException('No credentials found for catalog ${catalog.id}');
    }

    final webdavPath = _buildWebDavPath(catalog, remotePath);
    final auth = base64Encode(utf8.encode('${catalog.username}:$credential'));

    try {
      await _dio.download(
        webdavPath,
        localPath,
        options: Options(headers: {'Authorization': 'Basic $auth'}),
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
      );

      return File(localPath);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw WebDavException('Download cancelled');
      }
      throw WebDavException('Download failed: ${e.message}');
    }
  }

  /// Check if a file has changed by comparing ETags
  Future<bool> hasFileChanged(
    Catalog catalog,
    String path,
    String? localEtag,
  ) async {
    if (localEtag == null) return true;

    final credential = await _secureStorage.getCredential(catalog.id);
    if (credential == null) return true;

    final webdavPath = _buildWebDavPath(catalog, path);
    final auth = base64Encode(utf8.encode('${catalog.username}:$credential'));

    try {
      final response = await _dio.head(
        webdavPath,
        options: Options(
          headers: {'Authorization': 'Basic $auth'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final remoteEtag = response.headers.value('etag');
      return remoteEtag != localEtag;
    } catch (_) {
      return true;
    }
  }

  /// Get file metadata (size, ETag, last modified)
  Future<NextcloudFile?> getFileInfo(Catalog catalog, String path) async {
    final files = await listDirectory(catalog, path);
    // The PROPFIND with Depth: 1 on a file returns just that file
    return files.isNotEmpty ? files.first : null;
  }

  /// Build the full WebDAV URL for a path
  String _buildWebDavPath(Catalog catalog, String path) {
    final baseUrl = catalog.url.endsWith('/')
        ? catalog.url.substring(0, catalog.url.length - 1)
        : catalog.url;

    final userId = catalog.userId ?? catalog.username ?? '';
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;

    return '$baseUrl/remote.php/dav/files/$userId/$cleanPath';
  }

  /// PROPFIND request body for listing files
  static const String _propfindRequestBody = '''<?xml version="1.0"?>
<d:propfind xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns" xmlns:nc="http://nextcloud.org/ns">
  <d:prop>
    <d:displayname/>
    <d:getcontenttype/>
    <d:getcontentlength/>
    <d:getlastmodified/>
    <d:getetag/>
    <d:resourcetype/>
    <oc:size/>
  </d:prop>
</d:propfind>''';

  /// Parse PROPFIND XML response into NextcloudFile objects
  List<NextcloudFile> _parsePropfindResponse(String xmlData, String basePath) {
    final document = XmlDocument.parse(xmlData);
    final responses = document.findAllElements('d:response');

    final files = <NextcloudFile>[];
    var isFirst = true;

    for (final response in responses) {
      // Skip the first entry (the directory itself)
      if (isFirst) {
        isFirst = false;
        continue;
      }

      final href = response.findElements('d:href').firstOrNull?.innerText ?? '';
      final propstat = response.findElements('d:propstat').firstOrNull;
      final prop = propstat?.findElements('d:prop').firstOrNull;

      if (prop == null) continue;

      final displayName = prop
          .findElements('d:displayname')
          .firstOrNull
          ?.innerText;
      final contentType = prop
          .findElements('d:getcontenttype')
          .firstOrNull
          ?.innerText;
      final contentLength = prop
          .findElements('d:getcontentlength')
          .firstOrNull
          ?.innerText;
      final lastModified = prop
          .findElements('d:getlastmodified')
          .firstOrNull
          ?.innerText;
      final etag = prop.findElements('d:getetag').firstOrNull?.innerText;
      final resourceType = prop.findElements('d:resourcetype').firstOrNull;
      final ocSize = prop.findElements('oc:size').firstOrNull?.innerText;

      final isDirectory =
          resourceType?.findElements('d:collection').isNotEmpty ?? false;

      // Extract file name from href
      final decodedHref = Uri.decodeFull(href);
      final name =
          displayName ??
          decodedHref.split('/').where((s) => s.isNotEmpty).lastOrNull ??
          '';

      // Build the relative path
      final path = _extractRelativePath(decodedHref);

      files.add(
        NextcloudFile(
          path: path,
          name: name,
          isDirectory: isDirectory,
          size: contentLength != null
              ? int.tryParse(contentLength)
              : (ocSize != null ? int.tryParse(ocSize) : null),
          lastModified: lastModified != null
              ? _parseHttpDate(lastModified)
              : null,
          mimeType: isDirectory ? null : contentType,
          etag: etag?.replaceAll('"', ''),
        ),
      );
    }

    // Sort: directories first, then by name
    files.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return files;
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

  /// Parse HTTP date format
  DateTime? _parseHttpDate(String date) {
    try {
      return HttpDate.parse(date);
    } catch (_) {
      return null;
    }
  }
}
