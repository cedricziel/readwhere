import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Exception thrown when Kavita API operations fail
class KavitaApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic cause;

  KavitaApiException(this.message, {this.statusCode, this.cause});

  @override
  String toString() =>
      'KavitaApiException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

/// Server information from Kavita
class KavitaServerInfo {
  final String serverName;
  final String version;

  KavitaServerInfo({required this.serverName, required this.version});

  factory KavitaServerInfo.fromJson(Map<String, dynamic> json) {
    return KavitaServerInfo(
      serverName: json['installId'] as String? ?? 'Kavita Server',
      version: json['kavitaVersion'] as String? ?? 'Unknown',
    );
  }
}

/// Reading progress from Kavita
class KavitaProgress {
  final int chapterId;
  final int pageNum;
  final int volumeId;
  final int seriesId;
  final int libraryId;
  final String? bookScrollId;
  final DateTime? lastModified;

  KavitaProgress({
    required this.chapterId,
    required this.pageNum,
    required this.volumeId,
    required this.seriesId,
    required this.libraryId,
    this.bookScrollId,
    this.lastModified,
  });

  factory KavitaProgress.fromJson(Map<String, dynamic> json) {
    return KavitaProgress(
      chapterId: json['chapterId'] as int? ?? 0,
      pageNum: json['pageNum'] as int? ?? 0,
      volumeId: json['volumeId'] as int? ?? 0,
      seriesId: json['seriesId'] as int? ?? 0,
      libraryId: json['libraryId'] as int? ?? 0,
      bookScrollId: json['bookScrollId'] as String?,
      lastModified: json['lastModified'] != null
          ? DateTime.tryParse(json['lastModified'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapterId': chapterId,
      'pageNum': pageNum,
      'volumeId': volumeId,
      'seriesId': seriesId,
      'libraryId': libraryId,
      if (bookScrollId != null) 'bookScrollId': bookScrollId,
    };
  }
}

/// Service for interacting with Kavita's REST API
///
/// This service handles:
/// - Server authentication validation
/// - Reading progress sync (get and update)
/// - Server information retrieval
class KavitaApiService {
  final http.Client _httpClient;

  /// Request timeout duration
  static const Duration _timeout = Duration(seconds: 30);

  /// User agent for requests
  static const String _userAgent = 'ReadWhere/1.0 (Kavita Client)';

  KavitaApiService(this._httpClient);

  /// Validate API key and get server info
  ///
  /// [serverUrl] The base URL of the Kavita server
  /// [apiKey] The user's OPDS API key
  /// Returns server info if authentication is successful
  Future<KavitaServerInfo> authenticate(String serverUrl, String apiKey) async {
    final baseUrl = _normalizeUrl(serverUrl);

    try {
      // First, get a JWT token using the API key
      final token = await _getJwtToken(baseUrl, apiKey);

      // Then get server info
      return _getServerInfo(baseUrl, token);
    } catch (e) {
      if (e is KavitaApiException) rethrow;
      throw KavitaApiException('Authentication failed: $e', cause: e);
    }
  }

  /// Get JWT token using OPDS API key
  Future<String> _getJwtToken(String baseUrl, String apiKey) async {
    // Kavita uses the OPDS API key for authentication
    // The API key can be used directly in API calls via header
    // or we can get a JWT token

    final response = await _httpClient
        .post(
          Uri.parse('$baseUrl/api/Account/login-with-apikey'),
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': _userAgent,
          },
          body: jsonEncode({'apiKey': apiKey}),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw KavitaApiException(
        'Invalid API key',
        statusCode: response.statusCode,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['token'] as String? ?? '';
  }

  /// Get server information
  Future<KavitaServerInfo> _getServerInfo(String baseUrl, String token) async {
    final response = await _httpClient
        .get(
          Uri.parse('$baseUrl/api/Server/server-info'),
          headers: {'Authorization': 'Bearer $token', 'User-Agent': _userAgent},
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw KavitaApiException(
        'Failed to get server info',
        statusCode: response.statusCode,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return KavitaServerInfo.fromJson(json);
  }

  /// Get reading progress for a chapter
  ///
  /// [serverUrl] The base URL of the Kavita server
  /// [apiKey] The user's OPDS API key
  /// [chapterId] The Kavita chapter ID
  Future<KavitaProgress?> getProgress(
    String serverUrl,
    String apiKey,
    int chapterId,
  ) async {
    final baseUrl = _normalizeUrl(serverUrl);

    try {
      final token = await _getJwtToken(baseUrl, apiKey);

      final response = await _httpClient
          .get(
            Uri.parse('$baseUrl/api/Reader/get-progress?chapterId=$chapterId'),
            headers: {
              'Authorization': 'Bearer $token',
              'User-Agent': _userAgent,
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 404) {
        return null; // No progress recorded yet
      }

      if (response.statusCode != 200) {
        throw KavitaApiException(
          'Failed to get progress',
          statusCode: response.statusCode,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return KavitaProgress.fromJson(json);
    } catch (e) {
      debugPrint('KavitaApiService: Error getting progress: $e');
      if (e is KavitaApiException) rethrow;
      throw KavitaApiException('Failed to get progress: $e', cause: e);
    }
  }

  /// Update reading progress for a chapter
  ///
  /// [serverUrl] The base URL of the Kavita server
  /// [apiKey] The user's OPDS API key
  /// [progress] The progress to save
  Future<void> updateProgress(
    String serverUrl,
    String apiKey,
    KavitaProgress progress,
  ) async {
    final baseUrl = _normalizeUrl(serverUrl);

    try {
      final token = await _getJwtToken(baseUrl, apiKey);

      final response = await _httpClient
          .post(
            Uri.parse('$baseUrl/api/Reader/progress'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'User-Agent': _userAgent,
            },
            body: jsonEncode(progress.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw KavitaApiException(
          'Failed to update progress',
          statusCode: response.statusCode,
        );
      }

      debugPrint(
        'KavitaApiService: Progress updated for chapter ${progress.chapterId}',
      );
    } catch (e) {
      debugPrint('KavitaApiService: Error updating progress: $e');
      if (e is KavitaApiException) rethrow;
      throw KavitaApiException('Failed to update progress: $e', cause: e);
    }
  }

  /// Mark a chapter as read
  ///
  /// [serverUrl] The base URL of the Kavita server
  /// [apiKey] The user's OPDS API key
  /// [seriesId] The series ID
  /// [volumeId] The volume ID
  /// [chapterId] The chapter ID
  Future<void> markChapterRead(
    String serverUrl,
    String apiKey, {
    required int seriesId,
    required int volumeId,
    required int chapterId,
  }) async {
    final baseUrl = _normalizeUrl(serverUrl);

    try {
      final token = await _getJwtToken(baseUrl, apiKey);

      final response = await _httpClient
          .post(
            Uri.parse('$baseUrl/api/Reader/mark-chapter-read'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'User-Agent': _userAgent,
            },
            body: jsonEncode({
              'seriesId': seriesId,
              'volumeId': volumeId,
              'chapterId': chapterId,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw KavitaApiException(
          'Failed to mark chapter as read',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is KavitaApiException) rethrow;
      throw KavitaApiException('Failed to mark chapter as read: $e', cause: e);
    }
  }

  /// Normalize server URL (remove trailing slash, ensure https)
  String _normalizeUrl(String url) {
    var normalized = url.trim();

    // Remove trailing slash
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }

  /// Close the HTTP client
  void dispose() {
    _httpClient.close();
  }
}
