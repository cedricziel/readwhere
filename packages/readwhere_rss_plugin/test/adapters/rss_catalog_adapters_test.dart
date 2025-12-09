import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';
import 'package:readwhere_rss/readwhere_rss.dart';
import 'package:readwhere_rss_plugin/readwhere_rss_plugin.dart';

void main() {
  group('RssItemAdapter', () {
    test('adapts basic item properties', () {
      const item = RssItem(
        id: 'item-1',
        title: 'Test Item',
        description: 'A description',
        author: 'John Doe',
        thumbnailUrl: 'https://example.com/thumb.jpg',
      );

      final adapter = RssItemAdapter(item);

      expect(adapter.id, equals('item-1'));
      expect(adapter.title, equals('Test Item'));
      expect(adapter.summary, equals('A description'));
      expect(adapter.subtitle, equals('John Doe'));
      expect(adapter.thumbnailUrl, equals('https://example.com/thumb.jpg'));
    });

    test('type is book when has supported enclosures', () {
      const enclosure = RssEnclosure(
        url: 'https://example.com/book.epub',
        type: 'application/epub+zip',
      );
      const item = RssItem(
        id: 'item-1',
        title: 'Item',
        enclosures: [enclosure],
      );

      final adapter = RssItemAdapter(item);

      expect(adapter.type, equals(CatalogEntryType.book));
    });

    test('type is navigation when no supported enclosures', () {
      const item = RssItem(id: 'item-1', title: 'Item');

      final adapter = RssItemAdapter(item);

      expect(adapter.type, equals(CatalogEntryType.navigation));
    });

    test('files contains supported enclosures as CatalogFile', () {
      const epub = RssEnclosure(
        url: 'https://example.com/book.epub',
        type: 'application/epub+zip',
        length: 1234567,
      );
      const cbz = RssEnclosure(
        url: 'https://example.com/comic.cbz',
        type: 'application/x-cbz',
      );
      const mp3 = RssEnclosure(
        url: 'https://example.com/audio.mp3',
        type: 'audio/mpeg',
      );
      const item = RssItem(
        id: 'item-1',
        title: 'Item',
        enclosures: [epub, cbz, mp3],
      );

      final adapter = RssItemAdapter(item);

      expect(adapter.files.length, equals(2)); // Only epub and cbz
      expect(adapter.files[0].href, equals('https://example.com/book.epub'));
      expect(adapter.files[0].mimeType, equals('application/epub+zip'));
      expect(adapter.files[0].size, equals(1234567));
    });

    test('first file is marked as primary', () {
      const epub = RssEnclosure(
        url: 'https://example.com/book.epub',
        type: 'application/epub+zip',
      );
      const pdf = RssEnclosure(
        url: 'https://example.com/book.pdf',
        type: 'application/pdf',
      );
      const item = RssItem(
        id: 'item-1',
        title: 'Item',
        enclosures: [epub, pdf],
      );

      final adapter = RssItemAdapter(item);

      expect(adapter.files[0].isPrimary, isTrue);
      expect(adapter.files[1].isPrimary, isFalse);
    });

    test('links includes alternate link', () {
      const item = RssItem(
        id: 'item-1',
        title: 'Item',
        link: 'https://example.com/article',
      );

      final adapter = RssItemAdapter(item);

      expect(adapter.links.length, equals(1));
      expect(adapter.links[0].href, equals('https://example.com/article'));
      expect(adapter.links[0].rel, equals('alternate'));
    });

    test('links includes comments link', () {
      const item = RssItem(
        id: 'item-1',
        title: 'Item',
        link: 'https://example.com/article',
        commentsUrl: 'https://example.com/comments',
      );

      final adapter = RssItemAdapter(item);

      expect(adapter.links.length, equals(2));
      expect(adapter.links[1].href, equals('https://example.com/comments'));
      expect(adapter.links[1].rel, equals('replies'));
    });
  });

  group('rssFeedToBrowseResult', () {
    test('converts feed to browse result', () {
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
        id: 'feed-1',
        title: 'Test Feed',
        description: 'A test feed',
        feedUrl: 'https://example.com/feed.xml',
        format: RssFeedFormat.rss2,
        items: [item],
      );

      final result = rssFeedToBrowseResult(feed);

      expect(result.title, equals('Test Feed'));
      expect(result.entries.length, equals(1));
      expect(result.totalEntries, equals(1));
      expect(result.page, equals(1));
      expect(result.hasNextPage, isFalse);
      expect(result.hasPreviousPage, isFalse);
    });

    test('filters out items without supported enclosures', () {
      const supportedItem = RssItem(
        id: 'item-1',
        title: 'Supported',
        enclosures: [
          RssEnclosure(
            url: 'https://example.com/book.epub',
            type: 'application/epub+zip',
          ),
        ],
      );
      const unsupportedItem = RssItem(
        id: 'item-2',
        title: 'Unsupported',
        enclosures: [
          RssEnclosure(
            url: 'https://example.com/audio.mp3',
            type: 'audio/mpeg',
          ),
        ],
      );
      const noEnclosureItem = RssItem(id: 'item-3', title: 'No Enclosure');
      const feed = RssFeed(
        id: 'feed-1',
        title: 'Feed',
        feedUrl: 'url',
        format: RssFeedFormat.rss2,
        items: [supportedItem, unsupportedItem, noEnclosureItem],
      );

      final result = rssFeedToBrowseResult(feed);

      expect(result.entries.length, equals(1));
      expect(result.entries[0].title, equals('Supported'));
    });

    test('includes feed metadata in properties', () {
      const feed = RssFeed(
        id: 'feed-1',
        title: 'Test Feed',
        description: 'Description',
        author: 'Author',
        imageUrl: 'https://example.com/image.png',
        language: 'en-us',
        feedUrl: 'https://example.com/feed.xml',
        format: RssFeedFormat.rss2,
        items: [],
      );

      final result = rssFeedToBrowseResult(feed);

      expect(result.properties['feedId'], equals('feed-1'));
      expect(result.properties['feedFormat'], equals('rss2'));
      expect(result.properties['description'], equals('Description'));
      expect(result.properties['author'], equals('Author'));
      expect(
        result.properties['imageUrl'],
        equals('https://example.com/image.png'),
      );
      expect(result.properties['language'], equals('en-us'));
    });

    test('empty search links for RSS', () {
      const feed = RssFeed(
        id: 'feed-1',
        title: 'Feed',
        feedUrl: 'url',
        format: RssFeedFormat.rss2,
        items: [],
      );

      final result = rssFeedToBrowseResult(feed);

      expect(result.searchLinks, isEmpty);
    });
  });

  group('RssFeed.toBrowseResult extension', () {
    test('converts feed using extension method', () {
      const feed = RssFeed(
        id: 'feed-1',
        title: 'Test Feed',
        feedUrl: 'url',
        format: RssFeedFormat.atom,
        items: [],
      );

      final result = feed.toBrowseResult();

      expect(result.title, equals('Test Feed'));
      expect(result.properties['feedFormat'], equals('atom'));
    });
  });

  group('RssItem.toEntry extension', () {
    test('converts item using extension method', () {
      const item = RssItem(id: 'item-1', title: 'Test Item');

      final entry = item.toEntry();

      expect(entry.id, equals('item-1'));
      expect(entry.title, equals('Test Item'));
    });
  });
}
