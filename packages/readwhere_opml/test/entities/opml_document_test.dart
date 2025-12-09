import 'package:readwhere_opml/readwhere_opml.dart';
import 'package:test/test.dart';

void main() {
  group('OpmlDocument', () {
    test('creates document with required fields', () {
      const doc = OpmlDocument(version: '2.0', outlines: []);

      expect(doc.version, equals('2.0'));
      expect(doc.head, isNull);
      expect(doc.outlines, isEmpty);
    });

    test('creates document with head', () {
      const head = OpmlHead(title: 'My Feeds');
      const doc = OpmlDocument(version: '2.0', head: head, outlines: []);

      expect(doc.head?.title, equals('My Feeds'));
      expect(doc.title, equals('My Feeds'));
    });

    test('empty factory creates OPML 2.0 document', () {
      final doc = OpmlDocument.empty(title: 'Empty');

      expect(doc.version, equals('2.0'));
      expect(doc.isVersion2, isTrue);
      expect(doc.isVersion1, isFalse);
      expect(doc.title, equals('Empty'));
      expect(doc.outlines, isEmpty);
    });

    test('isVersion1 and isVersion2 work correctly', () {
      const doc1 = OpmlDocument(version: '1.0', outlines: []);
      const doc2 = OpmlDocument(version: '2.0', outlines: []);

      expect(doc1.isVersion1, isTrue);
      expect(doc1.isVersion2, isFalse);
      expect(doc2.isVersion1, isFalse);
      expect(doc2.isVersion2, isTrue);
    });

    test('feedOutlines returns top-level feeds only', () {
      const feed1 = OpmlOutline(
        text: 'Feed 1',
        type: 'rss',
        xmlUrl: 'https://example.com/feed1.xml',
      );
      const feed2 = OpmlOutline(
        text: 'Feed 2',
        type: 'rss',
        xmlUrl: 'https://example.com/feed2.xml',
      );
      const nestedFeed = OpmlOutline(
        text: 'Nested Feed',
        type: 'rss',
        xmlUrl: 'https://example.com/nested.xml',
      );
      const folder = OpmlOutline(text: 'Folder', children: [nestedFeed]);

      const doc = OpmlDocument(
        version: '2.0',
        outlines: [feed1, feed2, folder],
      );

      final topLevelFeeds = doc.feedOutlines;
      expect(topLevelFeeds.length, equals(2));
    });

    test('allFeeds returns all feeds recursively', () {
      const feed1 = OpmlOutline(
        text: 'Feed 1',
        type: 'rss',
        xmlUrl: 'https://example.com/feed1.xml',
      );
      const nestedFeed = OpmlOutline(
        text: 'Nested Feed',
        type: 'rss',
        xmlUrl: 'https://example.com/nested.xml',
      );
      const deepFeed = OpmlOutline(
        text: 'Deep Feed',
        type: 'rss',
        xmlUrl: 'https://example.com/deep.xml',
      );
      const innerFolder = OpmlOutline(
        text: 'Inner Folder',
        children: [deepFeed],
      );
      const folder = OpmlOutline(
        text: 'Folder',
        children: [nestedFeed, innerFolder],
      );

      const doc = OpmlDocument(version: '2.0', outlines: [feed1, folder]);

      final allFeeds = doc.allFeeds;
      expect(allFeeds.length, equals(3));
    });

    test('feedCount returns total number of feeds', () {
      const feed1 = OpmlOutline(
        text: 'Feed 1',
        type: 'rss',
        xmlUrl: 'https://example.com/feed1.xml',
      );
      const feed2 = OpmlOutline(
        text: 'Feed 2',
        type: 'rss',
        xmlUrl: 'https://example.com/feed2.xml',
      );

      const doc = OpmlDocument(version: '2.0', outlines: [feed1, feed2]);

      expect(doc.feedCount, equals(2));
    });

    test('folderOutlines returns folders only', () {
      const feed = OpmlOutline(
        text: 'Feed',
        type: 'rss',
        xmlUrl: 'https://example.com/feed.xml',
      );
      const child = OpmlOutline(text: 'Child');
      const folder = OpmlOutline(text: 'Folder', children: [child]);

      const doc = OpmlDocument(version: '2.0', outlines: [feed, folder]);

      final folders = doc.folderOutlines;
      expect(folders.length, equals(1));
      expect(folders.first.text, equals('Folder'));
    });

    test('copyWith creates copy with updated fields', () {
      const doc = OpmlDocument(version: '1.0', outlines: []);

      final copy = doc.copyWith(version: '2.0');

      expect(copy.version, equals('2.0'));
      expect(copy.outlines, isEmpty);
    });

    test('equality works correctly', () {
      const doc1 = OpmlDocument(version: '2.0', outlines: []);
      const doc2 = OpmlDocument(version: '2.0', outlines: []);
      const doc3 = OpmlDocument(version: '1.0', outlines: []);

      expect(doc1, equals(doc2));
      expect(doc1, isNot(equals(doc3)));
    });
  });
}
