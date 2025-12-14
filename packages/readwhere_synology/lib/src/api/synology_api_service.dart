import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../exceptions/synology_exception.dart';
import 'models/list_result.dart';
import 'models/login_result.dart';
import 'models/search_result.dart';
import 'models/synology_file.dart';

/// Low-level service for Synology Drive API operations.
class SynologyApiService {
  /// Creates a new [SynologyApiService].
  SynologyApiService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const String _apiPath = '/api/SynologyDrive/default/v2';

  /// Normalizes a server URL.
  static String normalizeUrl(String url) {
    var normalized = url.trim();

    // Remove trailing slashes
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    // Add https:// if no scheme
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }

    return normalized;
  }

  /// Authenticates with the Synology NAS.
  ///
  /// Returns a [LoginResult] with session ID on success.
  Future<LoginResult> login(
    String serverUrl,
    String account,
    String password,
  ) async {
    final url = '${normalizeUrl(serverUrl)}$_apiPath/login';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        data: json.encode({
          'format': 'sid',
          'account': account,
          'passwd': password,
        }),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.data == null) {
        throw const SynologyException('Empty response from server');
      }

      return LoginResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Login failed');
    }
  }

  /// Logs out from the Synology NAS.
  Future<void> logout(String serverUrl, String sessionId) async {
    final url = '${normalizeUrl(serverUrl)}$_apiPath/logout';

    try {
      await _dio.post<Map<String, dynamic>>(
        url,
        data: json.encode({'_sid': sessionId}),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
    } on DioException catch (e) {
      // Ignore logout errors - session might already be expired
      if (e.response?.statusCode != 200) {
        // Log but don't throw
      }
    }
  }

  /// Lists files in a directory.
  ///
  /// [path] can be:
  /// - `/mydrive/...` for personal files
  /// - `/team-folders/...` for shared team folders
  /// - `id:{file_id}` for a specific folder by ID
  Future<ListResult> listFiles(
    String serverUrl,
    String sessionId, {
    required String path,
    String sortBy = 'name',
    String sortDirection = 'asc',
    int offset = 0,
    int limit = 0,
    List<String>? extensions,
    List<String>? types,
  }) async {
    final url = '${normalizeUrl(serverUrl)}$_apiPath/files/list';

    final queryParams = <String, dynamic>{
      'path': path,
      'sort_by': sortBy,
      'sort_direction': sortDirection,
      'offset': offset,
    };
    if (limit > 0) {
      queryParams['limit'] = limit;
    }

    final body = <String, dynamic>{};
    if (extensions != null && extensions.isNotEmpty) {
      body['filter'] = {'extensions': extensions};
    }
    if (types != null && types.isNotEmpty) {
      body['filter'] = {
        ...body['filter'] as Map<String, dynamic>? ?? {},
        'type': types,
      };
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        queryParameters: queryParams,
        data: json.encode(body),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Cookie': 'id=$sessionId',
          },
        ),
      );

      if (response.data == null) {
        throw const SynologyException('Empty response from server');
      }

      final result = ListResult.fromJson(response.data!);
      if (!result.success) {
        throw SynologyException(
          'Failed to list files',
          errorCode: result.errorCode,
        );
      }

      return result;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to list files');
    }
  }

  /// Gets metadata for a single file.
  Future<SynologyFile> getFileMetadata(
    String serverUrl,
    String sessionId,
    String path,
  ) async {
    final url = '${normalizeUrl(serverUrl)}$_apiPath/files';

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        url,
        queryParameters: {'path': path},
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Cookie': 'id=$sessionId',
          },
        ),
      );

      if (response.data == null) {
        throw const SynologyException('Empty response from server');
      }

      final success = response.data!['success'] as bool? ?? false;
      if (!success) {
        final error = response.data!['error'] as Map<String, dynamic>?;
        throw SynologyException(
          'Failed to get file metadata',
          errorCode: error?['code'] as int?,
        );
      }

      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const SynologyException('No file data in response');
      }

      return SynologyFile.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get file metadata');
    }
  }

  /// Downloads a file.
  ///
  /// Returns the file content as bytes.
  Future<Uint8List> downloadFile(
    String serverUrl,
    String sessionId,
    String path, {
    void Function(int received, int total)? onProgress,
  }) async {
    final url = '${normalizeUrl(serverUrl)}$_apiPath/files/download';

    try {
      final response = await _dio.post<ResponseBody>(
        url,
        data: json.encode({
          'files': [path],
          'force_download': true,
        }),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/octet-stream',
            'Cookie': 'id=$sessionId',
          },
          responseType: ResponseType.stream,
        ),
      );

      final bytes = <int>[];
      final stream = response.data?.stream;
      if (stream == null) {
        throw const SynologyException('No download stream');
      }

      final total = int.tryParse(
            response.headers.value('content-length') ?? '',
          ) ??
          -1;
      var received = 0;

      await for (final chunk in stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }

      return Uint8List.fromList(bytes);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to download file');
    }
  }

  /// Downloads a file to a local path.
  Future<File> downloadFileTo(
    String serverUrl,
    String sessionId,
    String remotePath,
    String localPath, {
    void Function(int received, int total)? onProgress,
  }) async {
    final url = '${normalizeUrl(serverUrl)}$_apiPath/files/download';

    try {
      await _dio.download(
        url,
        localPath,
        data: json.encode({
          'files': [remotePath],
          'force_download': true,
        }),
        options: Options(
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Cookie': 'id=$sessionId',
          },
        ),
        onReceiveProgress: onProgress,
      );

      return File(localPath);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to download file');
    }
  }

  /// Searches for files.
  Future<SearchResult> search(
    String serverUrl,
    String sessionId, {
    required String keyword,
    String? fileType,
    String location = 'mydrive',
    String sortBy = 'score',
    String sortDirection = 'desc',
    int offset = 0,
    int limit = 100,
  }) async {
    final url = '${normalizeUrl(serverUrl)}$_apiPath/files/search';

    final body = <String, dynamic>{
      'keyword': keyword,
      'location': location,
    };
    if (fileType != null) {
      body['file_type'] = fileType;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        queryParameters: {
          'sort_by': sortBy,
          'sort_direction': sortDirection,
          'offset': offset,
          'limit': limit,
        },
        data: json.encode(body),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Cookie': 'id=$sessionId',
          },
        ),
      );

      if (response.data == null) {
        throw const SynologyException('Empty response from server');
      }

      final result = SearchResult.fromJson(response.data!);
      if (!result.success) {
        throw SynologyException(
          'Search failed',
          errorCode: result.errorCode,
        );
      }

      return result;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Search failed');
    }
  }

  /// Creates a folder.
  Future<SynologyFile> createFolder(
    String serverUrl,
    String sessionId,
    String path, {
    String conflictAction = 'autorename',
  }) async {
    final url = '${normalizeUrl(serverUrl)}$_apiPath/files';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        queryParameters: {
          'type': 'folder',
          'path': path,
          'conflict_action': conflictAction,
        },
        data: json.encode({}),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Cookie': 'id=$sessionId',
          },
        ),
      );

      if (response.data == null) {
        throw const SynologyException('Empty response from server');
      }

      final success = response.data!['success'] as bool? ?? false;
      if (!success) {
        final error = response.data!['error'] as Map<String, dynamic>?;
        throw SynologyException(
          'Failed to create folder',
          errorCode: error?['code'] as int?,
        );
      }

      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const SynologyException('No folder data in response');
      }

      return SynologyFile.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to create folder');
    }
  }

  SynologyException _handleDioError(DioException e, String message) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    String? errorMessage;
    int? errorCode;

    if (responseData is Map<String, dynamic>) {
      final error = responseData['error'] as Map<String, dynamic>?;
      errorCode = error?['code'] as int?;
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Connection timeout';
    } else if (e.type == DioExceptionType.connectionError) {
      errorMessage = 'Connection failed - check server URL';
    }

    return SynologyException(
      errorMessage ?? message,
      statusCode: statusCode,
      errorCode: errorCode,
      response: responseData?.toString(),
      cause: e,
    );
  }
}
