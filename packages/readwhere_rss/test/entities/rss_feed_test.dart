import 'package:readwhere_rss/readwhere_rss.dart';
import 'package:test/test.dart';

void main() {
  group('RssFeed', () {
    test('creates feed with required fields', () {
      const feed = RssFeed(
        id: 'feed-1',
        title: 'Test Feed',
        feedUrl: 'https://example.com/feed.xml',
        format: RssFeedFormat.rss2,
        items: [],
      );

      expect(feed.id, equals('feed-1'));
      expect(feed.title, equals('Test Feed'));
      expect(feed.feedUrl, equals('https://example.com/feed.xml'));
      expect(feed.format, equals(RssFeedFormat.rss2));
      expect(feed.items, isEmpty);
    });

    test('isRss2 returns true for RSS 2.0 format', () {
      const feed = RssFeed(
        id: '1',
        title: 'Feed',
        feedUrl: 'url',
        format: RssFeedFormat.rss2,
        items: [],
      );
      expect(feed.isRss2, isTrue);
      expect(feed.isRss1, isFalse);
      expect(feed.isAtom, isFalse);
    });

    test('isRss1 returns true for RSS 1.0 format', () {
      const feed = RssFeed(
        id: '1',
        title: 'Feed',
        feedUrl: 'url',
        format: RssFeedFormat.rss1,
        items: [],
      );
      expect(feed.isRss1, isTrue);
      expect(feed.isRss2, isFalse);
      expect(feed.isAtom, isFalse);
    });

    test('isAtom returns true for Atom format', () {
      const feed = RssFeed(
        id: '1',
        title: 'Feed',
        feedUrl: 'url',
        format: RssFeedFormat.atom,
        items: [],
      );
      expect(feed.isAtom, isTrue);
      expect(feed.isRss2, isFalse);
      expect(feed.isRss1, isFalse);
    });

    test(
      'hasSupportedItems returns true when items have supported enclosures',
      () {
        const enclosure = RssEnclosure(
          url: 'https://example.com/book.epub',
          type: 'application/epub+zip',
        );
        const item = RssItem(
          id: 'item-1',
          title: 'Item',
          enclosures: [enclosure],
        );
        const feed = RssFeed(
          id: '1',
          title: 'Feed',
          feedUrl: 'url',
          format: RssFeedFormat.rss2,
          items: [item],
        );

        expect(feed.hasSupportedItems, isTrue);
        expect(feed.hasEbookItems, isTrue);
        expect(feed.hasComicItems, isFalse);
      },
    );

    test('supportedItems filters items with supported enclosures', () {
      const ebookEnclosure = RssEnclosure(
        url: 'https://example.com/book.epub',
        type: 'application/epub+zip',
      );
      const audioEnclosure = RssEnclosure(
        url: 'https://example.com/audio.mp3',
        type: 'audio/mpeg',
      );
      const itemWithEbook = RssItem(
        id: 'item-1',
        title: 'Ebook Item',
        enclosures: [ebookEnclosure],
      );
      const itemWithAudio = RssItem(
        id: 'item-2',
        title: 'Audio Item',
        enclosures: [audioEnclosure],
      );
      const feed = RssFeed(
        id: '1',
        title: 'Feed',
        feedUrl: 'url',
        format: RssFeedFormat.rss2,
        items: [itemWithEbook, itemWithAudio],
      );

      expect(feed.supportedItems.length, equals(1));
      expect(feed.supportedItems.first.title, equals('Ebook Item'));
    });

    test('date returns pubDate if available', () {
      final pubDate = DateTime(2024, 1, 15);
      final feed = RssFeed(
        id: '1',
        title: 'Feed',
        feedUrl: 'url',
        format: RssFeedFormat.rss2,
        items: [],
        pubDate: pubDate,
      );

      expect(feed.date, equals(pubDate));
    });

    test('date returns lastBuildDate if pubDate not available', () {
      final lastBuildDate = DateTime(2024, 1, 10);
      final feed = RssFeed(
        id: '1',
        title: 'Feed',
        feedUrl: 'url',
        format: RssFeedFormat.rss2,
        items: [],
        lastBuildDate: lastBuildDate,
      );

      expect(feed.date, equals(lastBuildDate));
    });

    test('copyWith creates copy with updated fields', () {
      const feed = RssFeed(
        id: '1',
        title: 'Original',
        feedUrl: 'url',
        format: RssFeedFormat.rss2,
        items: [],
      );

      final copy = feed.copyWith(title: 'Updated');

      expect(copy.title, equals('Updated'));
      expect(copy.id, equals('1'));
      expect(copy.feedUrl, equals('url'));
    });

    test('equality works correctly', () {
      const feed1 = RssFeed(
        id: '1',
        title: 'Feed',
        feedUrl: 'url',
        format: RssFeedFormat.rss2,
        items: [],
      );
      const feed2 = RssFeed(
        id: '1',
        title: 'Feed',
        feedUrl: 'url',
        format: RssFeedFormat.rss2,
        items: [],
      );
      const feed3 = RssFeed(
        id: '2',
        title: 'Feed',
        feedUrl: 'url',
        format: RssFeedFormat.rss2,
        items: [],
      );

      expect(feed1, equals(feed2));
      expect(feed1, isNot(equals(feed3)));
    });

    test('itemCount returns correct count', () {
      const item = RssItem(id: 'item-1', title: 'Item');
      const feed = RssFeed(
        id: '1',
        title: 'Feed',
        feedUrl: 'url',
        format: RssFeedFormat.rss2,
        items: [item, item, item],
      );

      expect(feed.itemCount, equals(3));
    });
  });

  group('RssFeedFormat', () {
    test('enum has all expected values', () {
      expect(RssFeedFormat.values, contains(RssFeedFormat.rss2));
      expect(RssFeedFormat.values, contains(RssFeedFormat.rss1));
      expect(RssFeedFormat.values, contains(RssFeedFormat.atom));
      expect(RssFeedFormat.values, contains(RssFeedFormat.unknown));
    });
  });
}
