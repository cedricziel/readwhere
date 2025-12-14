import 'dart:convert';

import 'package:http/http.dart' as http;

import '../exceptions/nextcloud_exception.dart';
import 'models/nextcloud_news_feed.dart';
import 'models/nextcloud_news_item.dart';
import 'ocs_api_service.dart';

/// Status of the Nextcloud News app availability
enum NewsAppStatus {
  /// News app is available and accessible
  available,

  /// News app is not installed or not enabled
  notInstalled,

  /// Could not determine status (network error, etc.)
  error,
}

/// Result of checking News app availability
class NewsAppAvailabilityResult {
  final NewsAppStatus status;
  final String? version;
  final String? errorMessage;

  const NewsAppAvailabilityResult({
    required this.status,
    this.version,
    this.errorMessage,
  });

  bool get isAvailable => status == NewsAppStatus.available;
}

/// Result of fetching feeds from Nextcloud News
class NewsFedsResult {
  final List<NextcloudNewsFeed> feeds;
  final int starredCount;
  final int? newestItemId;

  const NewsFedsResult({
    required this.feeds,
    this.starredCount = 0,
    this.newestItemId,
  });
}

/// Service for Nextcloud News API interactions
///
/// API Base: {server}/index.php/apps/news/api/v1-3/
/// Authentication: HTTP Basic Auth with username:appPassword
class NextcloudNewsService {
  final http.Client _client;

  /// User-Agent header for all requests
  final String userAgent;

  /// API version path segment
  static const String _apiVersion = 'v1-3';

  NextcloudNewsService(
    this._client, {
    this.userAgent = 'ReadWhere/1.0.0 Nextcloud',
  });

  /// Common headers for News API requests
  Map<String, String> _headers(String auth) => {
        'Authorization': 'Basic $auth',
        'Accept': 'application/json',
        'User-Agent': userAgent,
      };

  /// Build the API base URL
  ///
  /// Tries with index.php first, then without if that fails
  String _apiBaseUrl(String serverUrl) {
    final baseUrl = OcsApiService.normalizeUrl(serverUrl);
    return '$baseUrl/index.php/apps/news/api/$_apiVersion';
  }

  /// Alternative API base URL without index.php (for URL rewriting)
  String _apiBaseUrlAlt(String serverUrl) {
    final baseUrl = OcsApiService.normalizeUrl(serverUrl);
    return '$baseUrl/apps/news/api/$_apiVersion';
  }

  /// Create Basic Auth header value from credentials
  static String createAuth(String username, String appPassword) {
    return base64Encode(utf8.encode('$username:$appPassword'));
  }

  /// Check if the Nextcloud News app is available on the server
  ///
  /// Tries both URL variants (with and without index.php)
  Future<NewsAppAvailabilityResult> checkAvailability(
    String serverUrl,
    String auth,
  ) async {
    // Try with index.php first
    var result = await _checkAvailabilityAtUrl(
      '${_apiBaseUrl(serverUrl)}/version',
      auth,
    );

    // If failed, try without index.php
    if (!result.isAvailable && result.status == NewsAppStatus.notInstalled) {
      result = await _checkAvailabilityAtUrl(
        '${_apiBaseUrlAlt(serverUrl)}/version',
        auth,
      );
    }

    return result;
  }

  Future<NewsAppAvailabilityResult> _checkAvailabilityAtUrl(
    String url,
    String auth,
  ) async {
    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: _headers(auth),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return NewsAppAvailabilityResult(
          status: NewsAppStatus.available,
          version: data['version'] as String?,
        );
      } else if (response.statusCode == 404) {
        return const NewsAppAvailabilityResult(
          status: NewsAppStatus.notInstalled,
        );
      } else if (response.statusCode == 401) {
        return const NewsAppAvailabilityResult(
          status: NewsAppStatus.error,
          errorMessage: 'Authentication failed',
        );
      } else {
        return NewsAppAvailabilityResult(
          status: NewsAppStatus.error,
          errorMessage: 'Unexpected status: ${response.statusCode}',
        );
      }
    } on http.ClientException catch (e) {
      return NewsAppAvailabilityResult(
        status: NewsAppStatus.error,
        errorMessage: 'Network error: ${e.message}',
      );
    } on FormatException catch (e) {
      return NewsAppAvailabilityResult(
        status: NewsAppStatus.error,
        errorMessage: 'Invalid response: ${e.message}',
      );
    }
  }

  /// Get all subscribed feeds
  ///
  /// Returns list of feeds with metadata including unread counts
  Future<NewsFedsResult> getFeeds(
    String serverUrl,
    String auth,
  ) async {
    final url = '${_apiBaseUrl(serverUrl)}/feeds';

    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: _headers(auth),
      );

      if (response.statusCode != 200) {
        throw NextcloudException(
          'Failed to fetch feeds',
          statusCode: response.statusCode,
          response: response.body,
        );
      }

      final data = jsonDecode(response.body);
      final feedsList = data['feeds'] as List<dynamic>? ?? [];

      return NewsFedsResult(
        feeds: feedsList
            .map((f) => NextcloudNewsFeed.fromJson(f as Map<String, dynamic>))
            .toList(),
        starredCount: data['starredCount'] as int? ?? 0,
        newestItemId: data['newestItemId'] as int?,
      );
    } on http.ClientException catch (e) {
      throw NextcloudException('Network error: ${e.message}', cause: e);
    } on FormatException catch (e) {
      throw NextcloudException('Invalid server response: ${e.message}',
          cause: e);
    }
  }

  /// Get items (articles) from feeds
  ///
  /// Parameters:
  /// - [batchSize]: Number of items to return (-1 for all, default 100)
  /// - [offset]: Item ID offset for pagination
  /// - [type]: Filter type (0=feed, 1=folder, 2=starred, 3=all)
  /// - [id]: Feed or folder ID (required when type is 0 or 1)
  /// - [getRead]: Include read items (default true)
  /// - [oldestFirst]: Sort order (default false = newest first)
  Future<List<NextcloudNewsItem>> getItems(
    String serverUrl,
    String auth, {
    int batchSize = 100,
    int? offset,
    int type = 3, // 3 = all items from all feeds
    int? id,
    bool getRead = true,
    bool oldestFirst = false,
  }) async {
    final queryParams = <String, String>{
      'batchSize': batchSize.toString(),
      'type': type.toString(),
      'getRead': getRead.toString(),
      'oldestFirst': oldestFirst.toString(),
    };

    if (offset != null) {
      queryParams['offset'] = offset.toString();
    }
    if (id != null) {
      queryParams['id'] = id.toString();
    }

    final uri = Uri.parse('${_apiBaseUrl(serverUrl)}/items')
        .replace(queryParameters: queryParams);

    try {
      final response = await _client.get(
        uri,
        headers: _headers(auth),
      );

      if (response.statusCode != 200) {
        throw NextcloudException(
          'Failed to fetch items',
          statusCode: response.statusCode,
          response: response.body,
        );
      }

      final data = jsonDecode(response.body);
      final itemsList = data['items'] as List<dynamic>? ?? [];

      return itemsList
          .map((i) => NextcloudNewsItem.fromJson(i as Map<String, dynamic>))
          .toList();
    } on http.ClientException catch (e) {
      throw NextcloudException('Network error: ${e.message}', cause: e);
    } on FormatException catch (e) {
      throw NextcloudException('Invalid server response: ${e.message}',
          cause: e);
    }
  }

  /// Get items updated since a specific timestamp
  ///
  /// Useful for delta sync to only fetch changed items
  Future<List<NextcloudNewsItem>> getUpdatedItems(
    String serverUrl,
    String auth, {
    required int lastModified,
    int type = 3,
  }) async {
    final queryParams = <String, String>{
      'lastModified': lastModified.toString(),
      'type': type.toString(),
    };

    final uri = Uri.parse('${_apiBaseUrl(serverUrl)}/items/updated')
        .replace(queryParameters: queryParams);

    try {
      final response = await _client.get(
        uri,
        headers: _headers(auth),
      );

      if (response.statusCode != 200) {
        throw NextcloudException(
          'Failed to fetch updated items',
          statusCode: response.statusCode,
          response: response.body,
        );
      }

      final data = jsonDecode(response.body);
      final itemsList = data['items'] as List<dynamic>? ?? [];

      return itemsList
          .map((i) => NextcloudNewsItem.fromJson(i as Map<String, dynamic>))
          .toList();
    } on http.ClientException catch (e) {
      throw NextcloudException('Network error: ${e.message}', cause: e);
    } on FormatException catch (e) {
      throw NextcloudException('Invalid server response: ${e.message}',
          cause: e);
    }
  }

  // ============================================================
  // Methods below are for future two-way sync (stubbed for now)
  // ============================================================

  /// Mark a single item as read
  Future<void> markItemRead(
    String serverUrl,
    String auth,
    int itemId,
  ) async {
    final url = '${_apiBaseUrl(serverUrl)}/items/$itemId/read';

    try {
      final response = await _client.put(
        Uri.parse(url),
        headers: _headers(auth),
      );

      if (response.statusCode != 200) {
        throw NextcloudException(
          'Failed to mark item as read',
          statusCode: response.statusCode,
          response: response.body,
        );
      }
    } on http.ClientException catch (e) {
      throw NextcloudException('Network error: ${e.message}', cause: e);
    }
  }

  /// Mark a single item as unread
  Future<void> markItemUnread(
    String serverUrl,
    String auth,
    int itemId,
  ) async {
    final url = '${_apiBaseUrl(serverUrl)}/items/$itemId/unread';

    try {
      final response = await _client.put(
        Uri.parse(url),
        headers: _headers(auth),
      );

      if (response.statusCode != 200) {
        throw NextcloudException(
          'Failed to mark item as unread',
          statusCode: response.statusCode,
          response: response.body,
        );
      }
    } on http.ClientException catch (e) {
      throw NextcloudException('Network error: ${e.message}', cause: e);
    }
  }

  /// Mark multiple items as read
  Future<void> markItemsRead(
    String serverUrl,
    String auth,
    List<int> itemIds,
  ) async {
    if (itemIds.isEmpty) return;

    final url = '${_apiBaseUrl(serverUrl)}/items/read/multiple';

    try {
      final response = await _client.put(
        Uri.parse(url),
        headers: {
          ..._headers(auth),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'itemIds': itemIds}),
      );

      if (response.statusCode != 200) {
        throw NextcloudException(
          'Failed to mark items as read',
          statusCode: response.statusCode,
          response: response.body,
        );
      }
    } on http.ClientException catch (e) {
      throw NextcloudException('Network error: ${e.message}', cause: e);
    }
  }

  /// Star an item
  Future<void> starItem(
    String serverUrl,
    String auth,
    int feedId,
    String guidHash,
  ) async {
    final url = '${_apiBaseUrl(serverUrl)}/items/$feedId/$guidHash/star';

    try {
      final response = await _client.put(
        Uri.parse(url),
        headers: _headers(auth),
      );

      if (response.statusCode != 200) {
        throw NextcloudException(
          'Failed to star item',
          statusCode: response.statusCode,
          response: response.body,
        );
      }
    } on http.ClientException catch (e) {
      throw NextcloudException('Network error: ${e.message}', cause: e);
    }
  }

  /// Unstar an item
  Future<void> unstarItem(
    String serverUrl,
    String auth,
    int feedId,
    String guidHash,
  ) async {
    final url = '${_apiBaseUrl(serverUrl)}/items/$feedId/$guidHash/unstar';

    try {
      final response = await _client.put(
        Uri.parse(url),
        headers: _headers(auth),
      );

      if (response.statusCode != 200) {
        throw NextcloudException(
          'Failed to unstar item',
          statusCode: response.statusCode,
          response: response.body,
        );
      }
    } on http.ClientException catch (e) {
      throw NextcloudException('Network error: ${e.message}', cause: e);
    }
  }
}
