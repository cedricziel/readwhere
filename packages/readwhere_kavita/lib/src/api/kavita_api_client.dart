import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/kavita_progress.dart';
import '../models/kavita_server_info.dart';
import 'kavita_exception.dart';

/// Callback for logging messages
typedef LogCallback = void Function(String message);

/// Service for interacting with Kavita's REST API
///
/// This service handles:
/// - Server authentication validation
/// - Reading progress sync (get and update)
/// - Server information retrieval
class KavitaApiClient {
  final http.Client _httpClient;

  /// Optional logging callback
  final LogCallback? onLog;

  /// Request timeout duration
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Timeout to use for requests
  final Duration timeout;

  /// User agent for requests
  final String userAgent;

  /// Creates a Kavita API client
  ///
  /// [httpClient] is the HTTP client to use for requests.
  /// [userAgent] is the user agent string to send with requests.
  /// [timeout] is the timeout for HTTP requests.
  /// [onLog] is an optional callback for logging messages.
  KavitaApiClient(
    this._httpClient, {
    this.userAgent = 'ReadWhere/1.0 (Kavita Client)',
    this.timeout = defaultTimeout,
    this.onLog,
  });

  void _log(String message) {
    onLog?.call(message);
  }

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
            'User-Agent': userAgent,
          },
          body: jsonEncode({'apiKey': apiKey}),
        )
        .timeout(timeout);

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
          headers: {'Authorization': 'Bearer $token', 'User-Agent': userAgent},
        )
        .timeout(timeout);

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
              'User-Agent': userAgent,
            },
          )
          .timeout(timeout);

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
      _log('KavitaApiClient: Error getting progress: $e');
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
              'User-Agent': userAgent,
            },
            body: jsonEncode(progress.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw KavitaApiException(
          'Failed to update progress',
          statusCode: response.statusCode,
        );
      }

      _log(
        'KavitaApiClient: Progress updated for chapter ${progress.chapterId}',
      );
    } catch (e) {
      _log('KavitaApiClient: Error updating progress: $e');
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
              'User-Agent': userAgent,
            },
            body: jsonEncode({
              'seriesId': seriesId,
              'volumeId': volumeId,
              'chapterId': chapterId,
            }),
          )
          .timeout(timeout);

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
