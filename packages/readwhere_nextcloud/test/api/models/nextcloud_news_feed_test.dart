import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';

void main() {
  group('NextcloudNewsFeed', () {
    test('creates instance with required parameters', () {
      const feed = NextcloudNewsFeed(
        id: 1,
        url: 'https://example.com/feed.xml',
        title: 'Example Feed',
      );

      expect(feed.id, 1);
      expect(feed.url, 'https://example.com/feed.xml');
      expect(feed.title, 'Example Feed');
      expect(feed.faviconLink, isNull);
      expect(feed.unreadCount, 0);
      expect(feed.pinned, false);
    });

    test('creates instance with all parameters', () {
      const feed = NextcloudNewsFeed(
        id: 42,
        url: 'https://blog.example.com/rss',
        title: 'Tech Blog',
        faviconLink: 'https://blog.example.com/favicon.ico',
        added: 1700000000,
        nextUpdateTime: 1700003600,
        folderId: 5,
        unreadCount: 10,
        ordering: 0,
        link: 'https://blog.example.com',
        pinned: true,
        updateErrorCount: 2,
        lastUpdateError: 'Connection timeout',
      );

      expect(feed.id, 42);
      expect(feed.url, 'https://blog.example.com/rss');
      expect(feed.title, 'Tech Blog');
      expect(feed.faviconLink, 'https://blog.example.com/favicon.ico');
      expect(feed.added, 1700000000);
      expect(feed.nextUpdateTime, 1700003600);
      expect(feed.folderId, 5);
      expect(feed.unreadCount, 10);
      expect(feed.ordering, 0);
      expect(feed.link, 'https://blog.example.com');
      expect(feed.pinned, true);
      expect(feed.updateErrorCount, 2);
      expect(feed.lastUpdateError, 'Connection timeout');
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'id': 1,
          'url': 'https://example.com/feed',
          'title': 'Test Feed',
          'faviconLink': 'https://example.com/icon.png',
          'added': 1699999999,
          'nextUpdateTime': 1700000000,
          'folderId': 3,
          'unreadCount': 5,
          'ordering': 1,
          'link': 'https://example.com',
          'pinned': true,
          'updateErrorCount': 0,
          'lastUpdateError': null,
        };

        final feed = NextcloudNewsFeed.fromJson(json);

        expect(feed.id, 1);
        expect(feed.url, 'https://example.com/feed');
        expect(feed.title, 'Test Feed');
        expect(feed.faviconLink, 'https://example.com/icon.png');
        expect(feed.added, 1699999999);
        expect(feed.nextUpdateTime, 1700000000);
        expect(feed.folderId, 3);
        expect(feed.unreadCount, 5);
        expect(feed.ordering, 1);
        expect(feed.link, 'https://example.com');
        expect(feed.pinned, true);
        expect(feed.updateErrorCount, 0);
        expect(feed.lastUpdateError, isNull);
      });

      test('parses minimal JSON with defaults', () {
        final json = {
          'id': 1,
          'url': 'https://example.com/feed',
        };

        final feed = NextcloudNewsFeed.fromJson(json);

        expect(feed.id, 1);
        expect(feed.url, 'https://example.com/feed');
        expect(feed.title, ''); // defaults to empty string
        expect(feed.faviconLink, isNull);
        expect(feed.unreadCount, 0);
        expect(feed.pinned, false);
        expect(feed.updateErrorCount, 0);
      });

      test('handles null title', () {
        final json = {
          'id': 1,
          'url': 'https://example.com/feed',
          'title': null,
        };

        final feed = NextcloudNewsFeed.fromJson(json);
        expect(feed.title, '');
      });
    });

    group('toJson', () {
      test('serializes complete feed', () {
        const feed = NextcloudNewsFeed(
          id: 1,
          url: 'https://example.com/feed',
          title: 'Test',
          faviconLink: 'https://example.com/icon.png',
          added: 1700000000,
          folderId: 2,
          unreadCount: 3,
          pinned: true,
          updateErrorCount: 1,
          lastUpdateError: 'Error message',
        );

        final json = feed.toJson();

        expect(json['id'], 1);
        expect(json['url'], 'https://example.com/feed');
        expect(json['title'], 'Test');
        expect(json['faviconLink'], 'https://example.com/icon.png');
        expect(json['added'], 1700000000);
        expect(json['folderId'], 2);
        expect(json['unreadCount'], 3);
        expect(json['pinned'], true);
        expect(json['updateErrorCount'], 1);
        expect(json['lastUpdateError'], 'Error message');
      });

      test('omits null optional fields', () {
        const feed = NextcloudNewsFeed(
          id: 1,
          url: 'https://example.com/feed',
          title: 'Test',
        );

        final json = feed.toJson();

        expect(json.containsKey('faviconLink'), false);
        expect(json.containsKey('added'), false);
        expect(json.containsKey('folderId'), false);
        expect(json.containsKey('lastUpdateError'), false);
      });
    });

    group('equality', () {
      test('equal feeds have same hashCode', () {
        const feed1 = NextcloudNewsFeed(
          id: 1,
          url: 'https://example.com/feed',
          title: 'Test',
        );
        const feed2 = NextcloudNewsFeed(
          id: 1,
          url: 'https://example.com/feed',
          title: 'Test',
        );

        expect(feed1, equals(feed2));
        expect(feed1.hashCode, feed2.hashCode);
      });

      test('different ids are not equal', () {
        const feed1 = NextcloudNewsFeed(
          id: 1,
          url: 'https://example.com/feed',
          title: 'Test',
        );
        const feed2 = NextcloudNewsFeed(
          id: 2,
          url: 'https://example.com/feed',
          title: 'Test',
        );

        expect(feed1, isNot(equals(feed2)));
      });
    });
  });
}
