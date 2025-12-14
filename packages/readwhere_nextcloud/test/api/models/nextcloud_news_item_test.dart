import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';

void main() {
  group('NextcloudNewsItem', () {
    test('creates instance with required parameters', () {
      const item = NextcloudNewsItem(
        id: 1,
        guid: 'https://example.com/article/1',
        guidHash: 'abc123',
        title: 'Test Article',
        feedId: 5,
        lastModified: 1700000000,
      );

      expect(item.id, 1);
      expect(item.guid, 'https://example.com/article/1');
      expect(item.guidHash, 'abc123');
      expect(item.title, 'Test Article');
      expect(item.feedId, 5);
      expect(item.lastModified, 1700000000);
      expect(item.unread, true);
      expect(item.starred, false);
      expect(item.url, isNull);
      expect(item.body, isNull);
    });

    test('creates instance with all parameters', () {
      const item = NextcloudNewsItem(
        id: 42,
        guid: 'unique-guid-123',
        guidHash: 'hash456',
        url: 'https://blog.example.com/post/42',
        title: 'Full Article',
        author: 'John Doe',
        pubDate: 1699900000,
        updatedDate: 1699950000,
        body: '<p>Article content</p>',
        enclosureMime: 'audio/mp3',
        enclosureLink: 'https://example.com/podcast.mp3',
        mediaThumbnail: 'https://example.com/thumb.jpg',
        feedId: 10,
        unread: false,
        starred: true,
        lastModified: 1700000000,
        fingerprint: 'fp789',
        contentHash: 'ch012',
      );

      expect(item.id, 42);
      expect(item.guid, 'unique-guid-123');
      expect(item.guidHash, 'hash456');
      expect(item.url, 'https://blog.example.com/post/42');
      expect(item.title, 'Full Article');
      expect(item.author, 'John Doe');
      expect(item.pubDate, 1699900000);
      expect(item.updatedDate, 1699950000);
      expect(item.body, '<p>Article content</p>');
      expect(item.enclosureMime, 'audio/mp3');
      expect(item.enclosureLink, 'https://example.com/podcast.mp3');
      expect(item.mediaThumbnail, 'https://example.com/thumb.jpg');
      expect(item.feedId, 10);
      expect(item.unread, false);
      expect(item.starred, true);
      expect(item.lastModified, 1700000000);
      expect(item.fingerprint, 'fp789');
      expect(item.contentHash, 'ch012');
    });

    group('computed properties', () {
      test('isRead returns inverse of unread', () {
        const unreadItem = NextcloudNewsItem(
          id: 1,
          guid: 'g1',
          guidHash: 'h1',
          title: 'Unread',
          feedId: 1,
          lastModified: 0,
          unread: true,
        );

        const readItem = NextcloudNewsItem(
          id: 2,
          guid: 'g2',
          guidHash: 'h2',
          title: 'Read',
          feedId: 1,
          lastModified: 0,
          unread: false,
        );

        expect(unreadItem.isRead, false);
        expect(readItem.isRead, true);
      });

      test('isStarred returns starred value', () {
        const starredItem = NextcloudNewsItem(
          id: 1,
          guid: 'g1',
          guidHash: 'h1',
          title: 'Starred',
          feedId: 1,
          lastModified: 0,
          starred: true,
        );

        const unstarredItem = NextcloudNewsItem(
          id: 2,
          guid: 'g2',
          guidHash: 'h2',
          title: 'Unstarred',
          feedId: 1,
          lastModified: 0,
          starred: false,
        );

        expect(starredItem.isStarred, true);
        expect(unstarredItem.isStarred, false);
      });

      test('pubDateTime converts Unix timestamp to DateTime', () {
        const item = NextcloudNewsItem(
          id: 1,
          guid: 'g1',
          guidHash: 'h1',
          title: 'Test',
          feedId: 1,
          lastModified: 0,
          pubDate: 1700000000, // 2023-11-14 22:13:20 UTC
        );

        final dateTime = item.pubDateTime;
        expect(dateTime, isNotNull);
        expect(dateTime!.year, 2023);
        expect(dateTime.month, 11);
        expect(dateTime.day, 14);
      });

      test('pubDateTime returns null when pubDate is null', () {
        const item = NextcloudNewsItem(
          id: 1,
          guid: 'g1',
          guidHash: 'h1',
          title: 'Test',
          feedId: 1,
          lastModified: 0,
        );

        expect(item.pubDateTime, isNull);
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'id': 1,
          'guid': 'guid-123',
          'guidHash': 'hash-456',
          'url': 'https://example.com/article',
          'title': 'Article Title',
          'author': 'Jane Smith',
          'pubDate': 1700000000,
          'updatedDate': 1700001000,
          'body': '<p>Content</p>',
          'enclosureMime': 'image/jpeg',
          'enclosureLink': 'https://example.com/image.jpg',
          'mediaThumbnail': 'https://example.com/thumb.jpg',
          'feedId': 5,
          'unread': false,
          'starred': true,
          'lastModified': 1700002000,
          'fingerprint': 'fp-abc',
          'contentHash': 'ch-xyz',
        };

        final item = NextcloudNewsItem.fromJson(json);

        expect(item.id, 1);
        expect(item.guid, 'guid-123');
        expect(item.guidHash, 'hash-456');
        expect(item.url, 'https://example.com/article');
        expect(item.title, 'Article Title');
        expect(item.author, 'Jane Smith');
        expect(item.pubDate, 1700000000);
        expect(item.updatedDate, 1700001000);
        expect(item.body, '<p>Content</p>');
        expect(item.enclosureMime, 'image/jpeg');
        expect(item.enclosureLink, 'https://example.com/image.jpg');
        expect(item.mediaThumbnail, 'https://example.com/thumb.jpg');
        expect(item.feedId, 5);
        expect(item.unread, false);
        expect(item.starred, true);
        expect(item.lastModified, 1700002000);
        expect(item.fingerprint, 'fp-abc');
        expect(item.contentHash, 'ch-xyz');
      });

      test('parses minimal JSON with defaults', () {
        final json = {
          'id': 1,
          'feedId': 1,
        };

        final item = NextcloudNewsItem.fromJson(json);

        expect(item.id, 1);
        expect(item.guid, '');
        expect(item.guidHash, '');
        expect(item.title, '');
        expect(item.feedId, 1);
        expect(item.unread, true);
        expect(item.starred, false);
        expect(item.lastModified, 0);
      });

      test('handles null boolean values with defaults', () {
        final json = {
          'id': 1,
          'feedId': 1,
          'unread': null,
          'starred': null,
        };

        final item = NextcloudNewsItem.fromJson(json);

        expect(item.unread, true);
        expect(item.starred, false);
      });
    });

    group('toJson', () {
      test('serializes complete item', () {
        const item = NextcloudNewsItem(
          id: 1,
          guid: 'g1',
          guidHash: 'h1',
          url: 'https://example.com',
          title: 'Title',
          author: 'Author',
          pubDate: 1700000000,
          body: 'Body',
          feedId: 5,
          unread: false,
          starred: true,
          lastModified: 1700001000,
        );

        final json = item.toJson();

        expect(json['id'], 1);
        expect(json['guid'], 'g1');
        expect(json['guidHash'], 'h1');
        expect(json['url'], 'https://example.com');
        expect(json['title'], 'Title');
        expect(json['author'], 'Author');
        expect(json['pubDate'], 1700000000);
        expect(json['body'], 'Body');
        expect(json['feedId'], 5);
        expect(json['unread'], false);
        expect(json['starred'], true);
        expect(json['lastModified'], 1700001000);
      });

      test('omits null optional fields', () {
        const item = NextcloudNewsItem(
          id: 1,
          guid: 'g1',
          guidHash: 'h1',
          title: 'Title',
          feedId: 5,
          lastModified: 0,
        );

        final json = item.toJson();

        expect(json.containsKey('url'), false);
        expect(json.containsKey('author'), false);
        expect(json.containsKey('pubDate'), false);
        expect(json.containsKey('body'), false);
        expect(json.containsKey('enclosureMime'), false);
        expect(json.containsKey('fingerprint'), false);
      });
    });

    group('equality', () {
      test('equal items have same hashCode', () {
        const item1 = NextcloudNewsItem(
          id: 1,
          guid: 'g1',
          guidHash: 'h1',
          title: 'Title',
          feedId: 5,
          lastModified: 1000,
        );
        const item2 = NextcloudNewsItem(
          id: 1,
          guid: 'g1',
          guidHash: 'h1',
          title: 'Title',
          feedId: 5,
          lastModified: 1000,
        );

        expect(item1, equals(item2));
        expect(item1.hashCode, item2.hashCode);
      });

      test('different ids are not equal', () {
        const item1 = NextcloudNewsItem(
          id: 1,
          guid: 'g1',
          guidHash: 'h1',
          title: 'Title',
          feedId: 5,
          lastModified: 1000,
        );
        const item2 = NextcloudNewsItem(
          id: 2,
          guid: 'g1',
          guidHash: 'h1',
          title: 'Title',
          feedId: 5,
          lastModified: 1000,
        );

        expect(item1, isNot(equals(item2)));
      });

      test('different read state are not equal', () {
        const item1 = NextcloudNewsItem(
          id: 1,
          guid: 'g1',
          guidHash: 'h1',
          title: 'Title',
          feedId: 5,
          lastModified: 1000,
          unread: true,
        );
        const item2 = NextcloudNewsItem(
          id: 1,
          guid: 'g1',
          guidHash: 'h1',
          title: 'Title',
          feedId: 5,
          lastModified: 1000,
          unread: false,
        );

        expect(item1, isNot(equals(item2)));
      });
    });
  });
}
