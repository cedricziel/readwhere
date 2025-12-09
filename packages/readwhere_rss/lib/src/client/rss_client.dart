import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../entities/rss_feed.dart';
import '../models/feed_detector.dart';
import 'rss_exception.dart';

/// HTTP client for fetching RSS/Atom feeds
class RssClient {
  /// The HTTP client to use
  final http.Client _httpClient;

  /// Default timeout for requests
  final Duration timeout;

  /// User agent string
  final String userAgent;

  RssClient(
    this._httpClient, {
    this.timeout = const Duration(seconds: 30),
    this.userAgent = 'ReadWhere RSS Client/1.0',
  });

  /// Fetch and parse a feed from a URL
  ///
  /// Throws [RssFetchException] if the feed cannot be fetched.
  /// Throws [RssParseException] if the feed cannot be parsed.
  /// Throws [RssAuthException] if authentication fails.
  Future<RssFeed> fetchFeed(
    String url, {
    String? username,
    String? password,
  }) async {
    final content = await _fetchContent(
      url,
      username: username,
      password: password,
    );

    try {
      return FeedDetector.parse(content, url);
    } catch (e) {
      throw RssParseException('Failed to parse feed', url: url, cause: e);
    }
  }

  /// Validate that a URL points to a valid feed
  ///
  /// Returns the parsed feed if valid.
  /// Throws appropriate exceptions if invalid.
  Future<RssFeed> validateFeed(
    String url, {
    String? username,
    String? password,
  }) async {
    return fetchFeed(url, username: username, password: password);
  }

  /// Check if a URL points to a valid feed without throwing
  Future<bool> isValidFeed(
    String url, {
    String? username,
    String? password,
  }) async {
    try {
      await fetchFeed(url, username: username, password: password);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Download an enclosure to a file
  ///
  /// [url] - The URL of the enclosure to download
  /// [targetPath] - The local file path to save to
  /// [onProgress] - Optional progress callback (0.0 to 1.0)
  /// [username] - Optional username for basic auth
  /// [password] - Optional password for basic auth
  Future<File> downloadEnclosure(
    String url,
    String targetPath, {
    void Function(double progress)? onProgress,
    String? username,
    String? password,
  }) async {
    final request = http.Request('GET', Uri.parse(url));
    _addHeaders(request, username: username, password: password);

    final http.StreamedResponse response;
    try {
      response = await _httpClient.send(request).timeout(timeout);
    } catch (e) {
      throw RssDownloadException('Failed to connect', url: url, cause: e);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw RssAuthException('Authentication required or forbidden', url: url);
    }

    if (response.statusCode != 200) {
      throw RssDownloadException(
        'HTTP error',
        url: url,
        statusCode: response.statusCode,
      );
    }

    final file = File(targetPath);
    final sink = file.openWrite();

    try {
      final totalBytes = response.contentLength ?? 0;
      var receivedBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        if (onProgress != null && totalBytes > 0) {
          onProgress(receivedBytes / totalBytes);
        }
      }
    } finally {
      await sink.close();
    }

    return file;
  }

  /// Fetch raw content from a URL
  Future<String> _fetchContent(
    String url, {
    String? username,
    String? password,
  }) async {
    final request = http.Request('GET', Uri.parse(url));
    _addHeaders(request, username: username, password: password);

    final http.StreamedResponse response;
    try {
      response = await _httpClient.send(request).timeout(timeout);
    } catch (e) {
      throw RssFetchException('Failed to connect', url: url, cause: e);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw RssAuthException('Authentication required or forbidden', url: url);
    }

    if (response.statusCode != 200) {
      throw RssFetchException(
        'HTTP error',
        url: url,
        statusCode: response.statusCode,
      );
    }

    try {
      return await response.stream.bytesToString();
    } catch (e) {
      throw RssFetchException('Failed to read response', url: url, cause: e);
    }
  }

  void _addHeaders(http.Request request, {String? username, String? password}) {
    request.headers['User-Agent'] = userAgent;
    request.headers['Accept'] =
        'application/rss+xml, application/atom+xml, application/xml, text/xml, */*';

    if (username != null && password != null) {
      final credentials = base64Encode(utf8.encode('$username:$password'));
      request.headers['Authorization'] = 'Basic $credentials';
    }
  }

  /// Close the HTTP client
  void close() {
    _httpClient.close();
  }
}
