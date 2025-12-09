import 'package:readwhere_rss/readwhere_rss.dart';
import 'package:test/test.dart';

void main() {
  group('RssItem', () {
    test('creates item with required fields', () {
      const item = RssItem(id: 'item-1', title: 'Test Item');

      expect(item.id, equals('item-1'));
      expect(item.title, equals('Test Item'));
      expect(item.enclosures, isEmpty);
      expect(item.categories, isEmpty);
    });

    test('creates item with all fields', () {
      final pubDate = DateTime(2024, 1, 15);
      const enclosure = RssEnclosure(
        url: 'https://example.com/book.epub',
        type: 'application/epub+zip',
      );
      const category = RssCategory(label: 'Fiction');

      final item = RssItem(
        id: 'item-1',
        title: 'Test Item',
        description: 'Description',
        content: 'Full content',
        link: 'https://example.com/item',
        author: 'Author Name',
        authorEmail: 'author@example.com',
        pubDate: pubDate,
        updated: pubDate,
        enclosures: [enclosure],
        categories: [category],
        thumbnailUrl: 'https://example.com/thumb.jpg',
        commentsUrl: 'https://example.com/comments',
        sourceTitle: 'Source Feed',
        sourceUrl: 'https://example.com/source',
      );

      expect(item.description, equals('Description'));
      expect(item.content, equals('Full content'));
      expect(item.link, equals('https://example.com/item'));
      expect(item.author, equals('Author Name'));
      expect(item.authorEmail, equals('author@example.com'));
      expect(item.pubDate, equals(pubDate));
      expect(item.enclosures.length, equals(1));
      expect(item.categories.length, equals(1));
      expect(item.thumbnailUrl, equals('https://example.com/thumb.jpg'));
    });

    test('hasEbookEnclosures returns true when item has ebook enclosure', () {
      const enclosure = RssEnclosure(
        url: 'https://example.com/book.epub',
        type: 'application/epub+zip',
      );
      const item = RssItem(
        id: 'item-1',
        title: 'Item',
        enclosures: [enclosure],
      );

      expect(item.hasEbookEnclosures, isTrue);
      expect(item.hasComicEnclosures, isFalse);
      expect(item.hasSupportedEnclosures, isTrue);
    });

    test('hasComicEnclosures returns true when item has comic enclosure', () {
      const enclosure = RssEnclosure(
        url: 'https://example.com/comic.cbz',
        type: 'application/x-cbz',
      );
      const item = RssItem(
        id: 'item-1',
        title: 'Item',
        enclosures: [enclosure],
      );

      expect(item.hasComicEnclosures, isTrue);
      expect(item.hasEbookEnclosures, isFalse);
      expect(item.hasSupportedEnclosures, isTrue);
    });

    test('ebookEnclosures filters ebook enclosures', () {
      const epub = RssEnclosure(
        url: 'https://example.com/book.epub',
        type: 'application/epub+zip',
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

      expect(item.ebookEnclosures.length, equals(1));
      expect(item.ebookEnclosures.first.url, contains('epub'));
    });

    test('comicEnclosures filters comic enclosures', () {
      const epub = RssEnclosure(
        url: 'https://example.com/book.epub',
        type: 'application/epub+zip',
      );
      const cbz = RssEnclosure(
        url: 'https://example.com/comic.cbz',
        type: 'application/x-cbz',
      );
      const cbr = RssEnclosure(
        url: 'https://example.com/comic.cbr',
        type: 'application/x-cbr',
      );
      const item = RssItem(
        id: 'item-1',
        title: 'Item',
        enclosures: [epub, cbz, cbr],
      );

      expect(item.comicEnclosures.length, equals(2));
    });

    test('supportedEnclosures includes both ebooks and comics', () {
      const epub = RssEnclosure(
        url: 'https://example.com/book.epub',
        type: 'application/epub+zip',
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

      expect(item.supportedEnclosures.length, equals(2));
    });

    test('date returns pubDate if available', () {
      final pubDate = DateTime(2024, 1, 15);
      final item = RssItem(id: 'item-1', title: 'Item', pubDate: pubDate);

      expect(item.date, equals(pubDate));
    });

    test('date returns updated if pubDate not available', () {
      final updated = DateTime(2024, 1, 10);
      final item = RssItem(id: 'item-1', title: 'Item', updated: updated);

      expect(item.date, equals(updated));
    });

    test('bestContent returns content if available', () {
      const item = RssItem(
        id: 'item-1',
        title: 'Item',
        content: 'Full content',
        description: 'Short description',
      );

      expect(item.bestContent, equals('Full content'));
    });

    test('bestContent returns description if content not available', () {
      const item = RssItem(
        id: 'item-1',
        title: 'Item',
        description: 'Short description',
      );

      expect(item.bestContent, equals('Short description'));
    });

    test('copyWith creates copy with updated fields', () {
      const item = RssItem(id: 'item-1', title: 'Original');

      final copy = item.copyWith(title: 'Updated');

      expect(copy.title, equals('Updated'));
      expect(copy.id, equals('item-1'));
    });

    test('equality works correctly', () {
      const item1 = RssItem(id: 'item-1', title: 'Item');
      const item2 = RssItem(id: 'item-1', title: 'Item');
      const item3 = RssItem(id: 'item-2', title: 'Item');

      expect(item1, equals(item2));
      expect(item1, isNot(equals(item3)));
    });
  });
}
