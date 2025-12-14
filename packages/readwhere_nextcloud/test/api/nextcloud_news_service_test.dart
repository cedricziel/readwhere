import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';

import 'nextcloud_news_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late MockClient mockClient;
  late NextcloudNewsService service;

  const serverUrl = 'https://cloud.example.com';
  const username = 'testuser';
  const password = 'app-password-123';
  late String auth;

  setUp(() {
    mockClient = MockClient();
    service = NextcloudNewsService(mockClient);
    auth = NextcloudNewsService.createAuth(username, password);
  });

  group('createAuth', () {
    test('creates valid base64 encoded auth string', () {
      final result = NextcloudNewsService.createAuth('user', 'pass');
      final decoded = utf8.decode(base64Decode(result));
      expect(decoded, 'user:pass');
    });

    test('handles special characters in password', () {
      final result = NextcloudNewsService.createAuth('user', 'p@ss:word!');
      final decoded = utf8.decode(base64Decode(result));
      expect(decoded, 'user:p@ss:word!');
    });
  });

  group('checkAvailability', () {
    test('returns available when version endpoint returns 200', () async {
      when(mockClient.get(
        Uri.parse('$serverUrl/index.php/apps/news/api/v1-3/version'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({'version': '24.0.0'}),
            200,
          ));

      final result = await service.checkAvailability(serverUrl, auth);

      expect(result.isAvailable, true);
      expect(result.status, NewsAppStatus.available);
      expect(result.version, '24.0.0');
      expect(result.errorMessage, isNull);
    });

    test('tries alternate URL when first returns 404', () async {
      // First URL returns 404
      when(mockClient.get(
        Uri.parse('$serverUrl/index.php/apps/news/api/v1-3/version'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('Not found', 404));

      // Alternate URL returns 200
      when(mockClient.get(
        Uri.parse('$serverUrl/apps/news/api/v1-3/version'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({'version': '24.0.0'}),
            200,
          ));

      final result = await service.checkAvailability(serverUrl, auth);

      expect(result.isAvailable, true);
      expect(result.status, NewsAppStatus.available);
      verify(mockClient.get(
        Uri.parse('$serverUrl/apps/news/api/v1-3/version'),
        headers: anyNamed('headers'),
      )).called(1);
    });

    test('returns notInstalled when both URLs return 404', () async {
      when(mockClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('Not found', 404));

      final result = await service.checkAvailability(serverUrl, auth);

      expect(result.isAvailable, false);
      expect(result.status, NewsAppStatus.notInstalled);
    });

    test('returns error with message when auth fails', () async {
      when(mockClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('Unauthorized', 401));

      final result = await service.checkAvailability(serverUrl, auth);

      expect(result.isAvailable, false);
      expect(result.status, NewsAppStatus.error);
      expect(result.errorMessage, 'Authentication failed');
    });

    test('returns error on unexpected status code', () async {
      when(mockClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('Server error', 500));

      final result = await service.checkAvailability(serverUrl, auth);

      expect(result.isAvailable, false);
      expect(result.status, NewsAppStatus.error);
      expect(result.errorMessage, contains('500'));
    });

    test('returns error on network exception', () async {
      when(mockClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenThrow(http.ClientException('Connection refused'));

      final result = await service.checkAvailability(serverUrl, auth);

      expect(result.isAvailable, false);
      expect(result.status, NewsAppStatus.error);
      expect(result.errorMessage, contains('Network error'));
    });
  });

  group('getFeeds', () {
    test('returns parsed feeds on success', () async {
      final responseBody = jsonEncode({
        'feeds': [
          {
            'id': 1,
            'url': 'https://blog.example.com/feed',
            'title': 'Example Blog',
            'faviconLink': 'https://blog.example.com/favicon.ico',
            'unreadCount': 5,
          },
          {
            'id': 2,
            'url': 'https://news.example.com/rss',
            'title': 'News Feed',
            'unreadCount': 10,
          },
        ],
        'starredCount': 3,
        'newestItemId': 42,
      });

      when(mockClient.get(
        Uri.parse('$serverUrl/index.php/apps/news/api/v1-3/feeds'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(responseBody, 200));

      final result = await service.getFeeds(serverUrl, auth);

      expect(result.feeds.length, 2);
      expect(result.feeds[0].id, 1);
      expect(result.feeds[0].url, 'https://blog.example.com/feed');
      expect(result.feeds[0].title, 'Example Blog');
      expect(result.feeds[0].unreadCount, 5);
      expect(result.feeds[1].id, 2);
      expect(result.starredCount, 3);
      expect(result.newestItemId, 42);
    });

    test('handles empty feeds list', () async {
      when(mockClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({'feeds': [], 'starredCount': 0}),
            200,
          ));

      final result = await service.getFeeds(serverUrl, auth);

      expect(result.feeds, isEmpty);
      expect(result.starredCount, 0);
    });

    test('throws NextcloudException on error status', () async {
      when(mockClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('Forbidden', 403));

      expect(
        () => service.getFeeds(serverUrl, auth),
        throwsA(isA<NextcloudException>()),
      );
    });

    test('throws NextcloudException on network error', () async {
      when(mockClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenThrow(http.ClientException('Connection lost'));

      expect(
        () => service.getFeeds(serverUrl, auth),
        throwsA(isA<NextcloudException>()),
      );
    });
  });

  group('getItems', () {
    test('returns parsed items with default parameters', () async {
      final responseBody = jsonEncode({
        'items': [
          {
            'id': 100,
            'guid': 'article-guid-1',
            'guidHash': 'hash1',
            'title': 'Article 1',
            'feedId': 1,
            'unread': true,
            'starred': false,
            'lastModified': 1700000000,
          },
          {
            'id': 101,
            'guid': 'article-guid-2',
            'guidHash': 'hash2',
            'title': 'Article 2',
            'feedId': 1,
            'unread': false,
            'starred': true,
            'lastModified': 1700001000,
          },
        ],
      });

      when(mockClient.get(
        argThat(predicate<Uri>((uri) =>
            uri.path.contains('/items') && uri.queryParameters['type'] == '3')),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(responseBody, 200));

      final result = await service.getItems(serverUrl, auth);

      expect(result.length, 2);
      expect(result[0].id, 100);
      expect(result[0].title, 'Article 1');
      expect(result[0].unread, true);
      expect(result[1].id, 101);
      expect(result[1].starred, true);
    });

    test('passes feed filter parameters correctly', () async {
      when(mockClient.get(
        argThat(predicate<Uri>((uri) {
          return uri.queryParameters['type'] == '0' &&
              uri.queryParameters['id'] == '5' &&
              uri.queryParameters['getRead'] == 'true' &&
              uri.queryParameters['batchSize'] == '50';
        })),
        headers: anyNamed('headers'),
      )).thenAnswer(
          (_) async => http.Response(jsonEncode({'items': []}), 200));

      await service.getItems(
        serverUrl,
        auth,
        type: 0,
        id: 5,
        getRead: true,
        batchSize: 50,
      );

      verify(mockClient.get(
        argThat(predicate<Uri>((uri) =>
            uri.queryParameters['type'] == '0' &&
            uri.queryParameters['id'] == '5')),
        headers: anyNamed('headers'),
      )).called(1);
    });

    test('includes offset parameter when provided', () async {
      when(mockClient.get(
        argThat(predicate<Uri>(
            (uri) => uri.queryParameters['offset'] == '100')),
        headers: anyNamed('headers'),
      )).thenAnswer(
          (_) async => http.Response(jsonEncode({'items': []}), 200));

      await service.getItems(serverUrl, auth, offset: 100);

      verify(mockClient.get(
        argThat(predicate<Uri>(
            (uri) => uri.queryParameters['offset'] == '100')),
        headers: anyNamed('headers'),
      )).called(1);
    });

    test('throws NextcloudException on error', () async {
      when(mockClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('Error', 500));

      expect(
        () => service.getItems(serverUrl, auth),
        throwsA(isA<NextcloudException>()),
      );
    });
  });

  group('getUpdatedItems', () {
    test('passes lastModified parameter', () async {
      when(mockClient.get(
        argThat(predicate<Uri>((uri) =>
            uri.path.contains('/items/updated') &&
            uri.queryParameters['lastModified'] == '1699999999')),
        headers: anyNamed('headers'),
      )).thenAnswer(
          (_) async => http.Response(jsonEncode({'items': []}), 200));

      await service.getUpdatedItems(
        serverUrl,
        auth,
        lastModified: 1699999999,
      );

      verify(mockClient.get(
        argThat(predicate<Uri>((uri) =>
            uri.queryParameters['lastModified'] == '1699999999')),
        headers: anyNamed('headers'),
      )).called(1);
    });
  });

  group('markItemRead', () {
    test('calls correct endpoint with PUT', () async {
      when(mockClient.put(
        Uri.parse('$serverUrl/index.php/apps/news/api/v1-3/items/42/read'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('', 200));

      await service.markItemRead(serverUrl, auth, 42);

      verify(mockClient.put(
        Uri.parse('$serverUrl/index.php/apps/news/api/v1-3/items/42/read'),
        headers: anyNamed('headers'),
      )).called(1);
    });

    test('throws NextcloudException on error', () async {
      when(mockClient.put(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('Error', 404));

      expect(
        () => service.markItemRead(serverUrl, auth, 42),
        throwsA(isA<NextcloudException>()),
      );
    });
  });

  group('markItemUnread', () {
    test('calls correct endpoint', () async {
      when(mockClient.put(
        Uri.parse('$serverUrl/index.php/apps/news/api/v1-3/items/42/unread'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('', 200));

      await service.markItemUnread(serverUrl, auth, 42);

      verify(mockClient.put(
        Uri.parse('$serverUrl/index.php/apps/news/api/v1-3/items/42/unread'),
        headers: anyNamed('headers'),
      )).called(1);
    });
  });

  group('markItemsRead', () {
    test('sends item IDs in request body', () async {
      when(mockClient.put(
        Uri.parse(
            '$serverUrl/index.php/apps/news/api/v1-3/items/read/multiple'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('', 200));

      await service.markItemsRead(serverUrl, auth, [1, 2, 3]);

      verify(mockClient.put(
        any,
        headers: anyNamed('headers'),
        body: jsonEncode({'itemIds': [1, 2, 3]}),
      )).called(1);
    });

    test('does nothing with empty list', () async {
      await service.markItemsRead(serverUrl, auth, []);

      verifyNever(mockClient.put(any, headers: anyNamed('headers')));
    });
  });

  group('starItem', () {
    test('calls correct endpoint with feedId and guidHash', () async {
      when(mockClient.put(
        Uri.parse(
            '$serverUrl/index.php/apps/news/api/v1-3/items/5/abc123/star'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('', 200));

      await service.starItem(serverUrl, auth, 5, 'abc123');

      verify(mockClient.put(
        Uri.parse(
            '$serverUrl/index.php/apps/news/api/v1-3/items/5/abc123/star'),
        headers: anyNamed('headers'),
      )).called(1);
    });
  });

  group('unstarItem', () {
    test('calls correct endpoint', () async {
      when(mockClient.put(
        Uri.parse(
            '$serverUrl/index.php/apps/news/api/v1-3/items/5/abc123/unstar'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('', 200));

      await service.unstarItem(serverUrl, auth, 5, 'abc123');

      verify(mockClient.put(
        Uri.parse(
            '$serverUrl/index.php/apps/news/api/v1-3/items/5/abc123/unstar'),
        headers: anyNamed('headers'),
      )).called(1);
    });
  });
}
