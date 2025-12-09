import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../entities/opds_feed.dart';
import '../entities/opds_link.dart';
import '../models/opds_feed_model.dart';
import 'opds_exception.dart';

/// Callback for logging messages
typedef LogCallback = void Function(String message);

/// Service for fetching and parsing OPDS feeds
class OpdsClient {
  final http.Client _httpClient;

  /// Optional logging callback
  final LogCallback? onLog;

  /// Request timeout duration
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Timeout to use for requests
  final Duration timeout;

  /// User agent for requests
  final String userAgent;

  /// Creates an OPDS client
  ///
  /// [httpClient] is the HTTP client to use for requests.
  /// [userAgent] is the user agent string to send with requests.
  /// [timeout] is the timeout for HTTP requests.
  /// [onLog] is an optional callback for logging messages.
  OpdsClient(
    this._httpClient, {
    this.userAgent = 'ReadWhere/1.0 (OPDS Client)',
    this.timeout = defaultTimeout,
    this.onLog,
  });

  void _log(String message) {
    onLog?.call(message);
  }

  /// Validate an OPDS catalog URL and return the root feed
  ///
  /// This fetches the root feed and validates it's a valid OPDS catalog.
  /// Returns the parsed feed if valid.
  /// Throws [OpdsException] if the URL is invalid or unreachable.
  Future<OpdsFeed> validateCatalog(String url) async {
    try {
      final feed = await fetchFeed(url);
      return feed;
    } on OpdsException {
      rethrow;
    } catch (e) {
      throw OpdsException('Failed to validate catalog: $e', cause: e);
    }
  }

  /// Fetch and parse an OPDS feed
  ///
  /// [url] The URL of the OPDS feed
  /// Returns the parsed [OpdsFeed]
  /// Throws [OpdsException] on network or parsing errors
  Future<OpdsFeed> fetchFeed(String url) async {
    try {
      _log('OpdsClient: Fetching feed from $url');

      final response = await _httpClient
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/atom+xml, application/xml, text/xml, */*',
              'User-Agent': userAgent,
            },
          )
          .timeout(timeout);

      _log('OpdsClient: Response status ${response.statusCode}');

      if (response.statusCode != 200) {
        throw OpdsException(
          'Failed to fetch feed',
          statusCode: response.statusCode,
        );
      }

      // Check content type
      final contentType = response.headers['content-type'] ?? '';
      if (!_isValidContentType(contentType)) {
        _log('OpdsClient: Warning - Unexpected content type: $contentType');
      }

      // Parse the XML response
      final feed = OpdsFeedModel.fromXmlString(response.body, baseUrl: url);
      _log(
        'OpdsClient: Parsed feed "${feed.title}" with ${feed.entries.length} entries',
      );

      return feed;
    } on OpdsException {
      rethrow;
    } on FormatException catch (e) {
      throw OpdsException('Invalid OPDS feed format: ${e.message}', cause: e);
    } catch (e) {
      throw OpdsException('Network error: $e', cause: e);
    }
  }

  /// Fetch a feed with pagination support
  ///
  /// [url] Base URL of the feed
  /// [page] Page number (1-based, optional)
  Future<OpdsFeed> fetchFeedPage(String url, {int? page}) async {
    if (page == null || page <= 1) {
      return fetchFeed(url);
    }

    // Most OPDS servers use query parameters for pagination
    final uri = Uri.parse(url);
    final params = Map<String, String>.from(uri.queryParameters);
    params['page'] = page.toString();

    final pagedUri = uri.replace(queryParameters: params);
    return fetchFeed(pagedUri.toString());
  }

  /// Search within a catalog
  ///
  /// [rootFeed] The root feed (to get search URL template)
  /// [query] The search query
  /// Returns search results as an [OpdsFeed]
  Future<OpdsFeed> search(OpdsFeed rootFeed, String query) async {
    final searchLink = rootFeed.searchLink;
    if (searchLink == null) {
      throw OpdsException('Catalog does not support search');
    }

    // Get the OpenSearch description if needed
    String searchUrl;
    if (searchLink.type.contains('opensearchdescription')) {
      // Need to fetch and parse OpenSearch description
      searchUrl = await _getOpenSearchUrl(searchLink.href, query);
    } else {
      // Direct search URL with template
      searchUrl = _applySearchTemplate(searchLink.href, query);
    }

    return fetchFeed(searchUrl);
  }

  /// Search using a direct search URL
  ///
  /// [catalogUrl] The base catalog URL
  /// [searchPath] The search path/template
  /// [query] The search query
  Future<OpdsFeed> searchWithUrl(
    String catalogUrl,
    String searchPath,
    String query,
  ) async {
    final baseUri = Uri.parse(catalogUrl);
    String searchUrl;

    if (searchPath.startsWith('http')) {
      searchUrl = _applySearchTemplate(searchPath, query);
    } else {
      final resolvedUri = baseUri.resolve(searchPath);
      searchUrl = _applySearchTemplate(resolvedUri.toString(), query);
    }

    return fetchFeed(searchUrl);
  }

  /// Download a book from an acquisition link
  ///
  /// [link] The acquisition link
  /// [downloadDir] Directory where downloaded files should be saved
  /// [filename] Optional custom filename (without extension)
  /// [onProgress] Optional callback for download progress (0.0 to 1.0)
  /// Returns the path to the downloaded file
  Future<String> downloadBook(
    OpdsLink link,
    Directory downloadDir, {
    String? filename,
    void Function(double progress)? onProgress,
  }) async {
    _log('OpdsClient: Downloading book from ${link.href}');

    try {
      final request = http.Request('GET', Uri.parse(link.href));
      request.headers['User-Agent'] = userAgent;

      final response = await _httpClient.send(request).timeout(timeout);

      if (response.statusCode != 200) {
        throw OpdsException(
          'Failed to download book',
          statusCode: response.statusCode,
        );
      }

      // Get expected content length
      final contentLength = response.contentLength ?? 0;

      // Ensure download directory exists
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Generate filename
      final extension = link.fileExtension ?? 'epub';
      final finalFilename =
          filename ?? DateTime.now().millisecondsSinceEpoch.toString();
      final filePath = p.join(downloadDir.path, '$finalFilename.$extension');

      // Stream download to file
      final file = File(filePath);
      final sink = file.openWrite();

      int bytesReceived = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        bytesReceived += chunk.length;

        if (onProgress != null && contentLength > 0) {
          onProgress(bytesReceived / contentLength);
        }
      }

      await sink.close();

      _log('OpdsClient: Downloaded $bytesReceived bytes to $filePath');
      return filePath;
    } catch (e) {
      if (e is OpdsException) rethrow;
      throw OpdsException('Download failed: $e', cause: e);
    }
  }

  /// Resolve a relative cover URL against a base URL
  String resolveCoverUrl(String baseUrl, String? coverPath) {
    if (coverPath == null || coverPath.isEmpty) {
      return '';
    }

    if (coverPath.startsWith('http')) {
      return coverPath;
    }

    final baseUri = Uri.parse(baseUrl);
    return baseUri.resolve(coverPath).toString();
  }

  /// Check if content type is valid for OPDS
  bool _isValidContentType(String contentType) {
    const validTypes = [
      'application/atom+xml',
      'application/xml',
      'text/xml',
      'application/opds+xml',
    ];
    return validTypes.any((t) => contentType.contains(t));
  }

  /// Get actual search URL from OpenSearch description
  Future<String> _getOpenSearchUrl(String descriptionUrl, String query) async {
    try {
      final response = await _httpClient
          .get(Uri.parse(descriptionUrl), headers: {'User-Agent': userAgent})
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw OpdsException('Failed to fetch OpenSearch description');
      }

      // Parse OpenSearch XML to find URL template
      // Look for: <Url type="application/atom+xml" template="..."/>
      final body = response.body;
      final templateMatch = RegExp(r'template="([^"]+)"').firstMatch(body);
      if (templateMatch == null) {
        throw OpdsException(
          'No search template found in OpenSearch description',
        );
      }

      final template = templateMatch.group(1)!;
      return _applySearchTemplate(template, query);
    } catch (e) {
      if (e is OpdsException) rethrow;
      throw OpdsException('Failed to parse OpenSearch description: $e');
    }
  }

  /// Apply search query to URL template
  String _applySearchTemplate(String template, String query) {
    // OpenSearch uses {searchTerms} placeholder
    var url = template
        .replaceAll('{searchTerms}', Uri.encodeComponent(query))
        .replaceAll('{searchterms}', Uri.encodeComponent(query));

    // Some servers use simpler query parameter
    if (!url.contains(Uri.encodeComponent(query))) {
      final uri = Uri.parse(url);
      final params = Map<String, String>.from(uri.queryParameters);
      params['q'] = query;
      url = uri.replace(queryParameters: params).toString();
    }

    return url;
  }

  /// Close the HTTP client
  void dispose() {
    _httpClient.close();
  }
}
