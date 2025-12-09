import 'dart:io';

import 'package:dio/dio.dart';

import '../auth/webdav_auth.dart';
import '../exceptions/webdav_exception.dart';
import '../models/webdav_file.dart';
import '../models/webdav_response.dart';
import '../xml/propfind_builder.dart';
import '../xml/propfind_parser.dart';
import 'webdav_config.dart';

/// A generic WebDAV client for file operations
///
/// Supports PROPFIND (directory listing), GET (download), and HEAD operations.
/// Authentication is handled via pluggable [WebDavAuth] implementations.
class WebDavClient {
  /// Client configuration
  final WebDavConfig config;

  /// HTTP client
  final Dio _dio;

  /// Optional custom path extractor for PROPFIND responses
  ///
  /// Use this to extract relative paths from WebDAV hrefs when the server
  /// returns full URLs or has a custom path structure.
  final String Function(String href)? pathExtractor;

  WebDavClient({
    required this.config,
    Dio? dio,
    this.pathExtractor,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                headers: {'User-Agent': config.userAgent},
                connectTimeout: Duration(milliseconds: config.timeoutMs),
                receiveTimeout: Duration(milliseconds: config.timeoutMs),
              ),
            );

  /// List files and directories at the given path
  ///
  /// Uses PROPFIND with Depth: 1 to retrieve directory contents.
  Future<List<WebDavFile>> listDirectory(String path) async {
    final url = _buildUrl(path);
    final requestBody = _buildPropfindBody();

    try {
      final response = await _dio.request<String>(
        url,
        options: Options(
          method: 'PROPFIND',
          headers: {
            ..._getAuthHeaders(),
            ...config.customHeaders,
            'Depth': '1',
            'Content-Type': 'application/xml',
          },
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status < 500,
        ),
        data: requestBody,
      );

      if (response.statusCode == 401) {
        await config.auth.onAuthenticationFailed();
        throw WebDavException(
          'Authentication failed',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode != 207) {
        throw WebDavException(
          'Failed to list directory: HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      return PropfindParser.parse(
        response.data!,
        basePath: path,
        skipFirst: true,
        pathExtractor: pathExtractor,
      );
    } on DioException catch (e) {
      throw WebDavException(
        'Network error: ${e.message}',
        cause: e,
      );
    }
  }

  /// Download a file to a local path
  ///
  /// [remotePath] - Path on the WebDAV server
  /// [localPath] - Local file path to save to
  /// [onProgress] - Optional progress callback (received bytes, total bytes)
  /// [cancelToken] - Optional cancellation token
  Future<DownloadResponse> downloadFile(
    String remotePath,
    String localPath, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final url = _buildUrl(remotePath);

    try {
      final response = await _dio.download(
        url,
        localPath,
        options: Options(
          headers: {
            ..._getAuthHeaders(),
            ...config.customHeaders,
          },
        ),
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
      );

      return DownloadResponse(
        localPath: localPath,
        etag: response.headers.value('etag')?.replaceAll('"', ''),
        contentType: response.headers.value('content-type'),
        size: int.tryParse(response.headers.value('content-length') ?? ''),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw WebDavException('Download cancelled');
      }
      throw WebDavException(
        'Download failed: ${e.message}',
        cause: e,
      );
    }
  }

  /// Get file metadata via HEAD request
  Future<HeadResponse> head(String path) async {
    final url = _buildUrl(path);

    try {
      final response = await _dio.head<void>(
        url,
        options: Options(
          headers: {
            ..._getAuthHeaders(),
            ...config.customHeaders,
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 401) {
        await config.auth.onAuthenticationFailed();
        throw WebDavException(
          'Authentication failed',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode != 200) {
        throw WebDavException(
          'HEAD request failed: HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      return HeadResponse(
        etag: response.headers.value('etag')?.replaceAll('"', ''),
        contentType: response.headers.value('content-type'),
        contentLength:
            int.tryParse(response.headers.value('content-length') ?? ''),
        lastModified:
            _parseLastModified(response.headers.value('last-modified')),
      );
    } on DioException catch (e) {
      throw WebDavException(
        'HEAD request failed: ${e.message}',
        cause: e,
      );
    }
  }

  /// Check if a file has changed by comparing ETags
  ///
  /// Returns true if the file has changed or if [localEtag] is null.
  Future<bool> hasFileChanged(String path, String? localEtag) async {
    if (localEtag == null) return true;

    try {
      final headResponse = await head(path);
      return headResponse.etag != localEtag;
    } catch (_) {
      // If we can't check, assume it has changed
      return true;
    }
  }

  /// Get file info via PROPFIND
  ///
  /// This is more expensive than [head] but returns more metadata.
  Future<WebDavFile?> getFileInfo(String path) async {
    final url = _buildUrl(path);
    final requestBody = _buildPropfindBody();

    try {
      final response = await _dio.request<String>(
        url,
        options: Options(
          method: 'PROPFIND',
          headers: {
            ..._getAuthHeaders(),
            ...config.customHeaders,
            'Depth': '0',
            'Content-Type': 'application/xml',
          },
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status < 500,
        ),
        data: requestBody,
      );

      if (response.statusCode != 207) {
        return null;
      }

      final files = PropfindParser.parse(
        response.data!,
        basePath: path,
        skipFirst: false,
        pathExtractor: pathExtractor,
      );

      return files.isNotEmpty ? files.first : null;
    } catch (_) {
      return null;
    }
  }

  /// Build full URL from a path
  String _buildUrl(String path) {
    final base = config.normalizedBaseUrl;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return cleanPath.isEmpty ? base : '$base/$cleanPath';
  }

  /// Get authentication headers
  Map<String, String> _getAuthHeaders() => config.auth.headers;

  /// Build PROPFIND request body
  String _buildPropfindBody() {
    if (config.customNamespaces.isEmpty && config.customProperties.isEmpty) {
      return PropfindBuilder.standard();
    }

    return PropfindBuilder.build(
      customNamespaces: config.customNamespaces,
      customProperties: config.customProperties,
    );
  }

  /// Parse Last-Modified header
  DateTime? _parseLastModified(String? value) {
    if (value == null) return null;
    try {
      return HttpDate.parse(value);
    } catch (_) {
      return null;
    }
  }
}
