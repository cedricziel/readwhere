import 'package:readwhere_opml/readwhere_opml.dart';
import 'package:test/test.dart';

void main() {
  group('OpmlOutline', () {
    test('creates outline with minimal fields', () {
      const outline = OpmlOutline(text: 'Test Feed');

      expect(outline.text, equals('Test Feed'));
      expect(outline.xmlUrl, isNull);
      expect(outline.children, isEmpty);
    });

    test('creates feed outline with all fields', () {
      const outline = OpmlOutline(
        text: 'My Feed',
        title: 'My Feed Title',
        type: 'rss',
        xmlUrl: 'https://example.com/feed.xml',
        htmlUrl: 'https://example.com',
        description: 'A great feed',
        language: 'en-us',
        version: 'RSS2',
        category: 'Technology',
      );

      expect(outline.text, equals('My Feed'));
      expect(outline.title, equals('My Feed Title'));
      expect(outline.type, equals('rss'));
      expect(outline.xmlUrl, equals('https://example.com/feed.xml'));
      expect(outline.htmlUrl, equals('https://example.com'));
      expect(outline.description, equals('A great feed'));
      expect(outline.language, equals('en-us'));
    });

    test('isFeed returns true for RSS outline with xmlUrl', () {
      const outline = OpmlOutline(
        text: 'Feed',
        type: 'rss',
        xmlUrl: 'https://example.com/feed.xml',
      );

      expect(outline.isFeed, isTrue);
    });

    test('isFeed returns false without type', () {
      const outline = OpmlOutline(
        text: 'Feed',
        xmlUrl: 'https://example.com/feed.xml',
      );

      expect(outline.isFeed, isFalse);
    });

    test('isFeed returns false without xmlUrl', () {
      const outline = OpmlOutline(text: 'Feed', type: 'rss');

      expect(outline.isFeed, isFalse);
    });

    test('isFolder returns true when has children', () {
      const child = OpmlOutline(text: 'Child');
      const outline = OpmlOutline(text: 'Folder', children: [child]);

      expect(outline.isFolder, isTrue);
    });

    test('isFolder returns false when no children', () {
      const outline = OpmlOutline(text: 'Not a folder');

      expect(outline.isFolder, isFalse);
    });

    test('isLink returns true for link type with htmlUrl', () {
      const outline = OpmlOutline(
        text: 'Link',
        type: 'link',
        htmlUrl: 'https://example.com',
      );

      expect(outline.isLink, isTrue);
    });

    test('displayName prefers text', () {
      const outline = OpmlOutline(
        text: 'Text',
        title: 'Title',
        xmlUrl: 'https://example.com/feed.xml',
      );

      expect(outline.displayName, equals('Text'));
    });

    test('displayName falls back to title', () {
      const outline = OpmlOutline(
        title: 'Title',
        xmlUrl: 'https://example.com/feed.xml',
      );

      expect(outline.displayName, equals('Title'));
    });

    test('displayName falls back to xmlUrl', () {
      const outline = OpmlOutline(xmlUrl: 'https://example.com/feed.xml');

      expect(outline.displayName, equals('https://example.com/feed.xml'));
    });

    test('displayName returns Untitled when nothing set', () {
      const outline = OpmlOutline();

      expect(outline.displayName, equals('Untitled'));
    });

    test('getAllFeeds returns this if is feed', () {
      const outline = OpmlOutline(
        text: 'Feed',
        type: 'rss',
        xmlUrl: 'https://example.com/feed.xml',
      );

      final feeds = outline.getAllFeeds();

      expect(feeds.length, equals(1));
      expect(feeds.first, equals(outline));
    });

    test('getAllFeeds returns nested feeds', () {
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
      const folder = OpmlOutline(text: 'Folder', children: [feed1, feed2]);

      final feeds = folder.getAllFeeds();

      expect(feeds.length, equals(2));
    });

    test('copyWith creates copy with updated fields', () {
      const outline = OpmlOutline(text: 'Original', type: 'rss');

      final copy = outline.copyWith(text: 'Updated');

      expect(copy.text, equals('Updated'));
      expect(copy.type, equals('rss'));
    });

    test('equality works correctly', () {
      const outline1 = OpmlOutline(
        text: 'Feed',
        type: 'rss',
        xmlUrl: 'https://example.com/feed.xml',
      );
      const outline2 = OpmlOutline(
        text: 'Feed',
        type: 'rss',
        xmlUrl: 'https://example.com/feed.xml',
      );
      const outline3 = OpmlOutline(
        text: 'Different',
        type: 'rss',
        xmlUrl: 'https://example.com/other.xml',
      );

      expect(outline1, equals(outline2));
      expect(outline1, isNot(equals(outline3)));
    });

    test('custom attributes are preserved', () {
      const outline = OpmlOutline(
        text: 'Feed',
        customAttributes: {'myAttr': 'myValue'},
      );

      expect(outline.customAttributes['myAttr'], equals('myValue'));
    });
  });
}
