import 'package:readwhere_rss/readwhere_rss.dart';
import 'package:test/test.dart';

void main() {
  group('RssEnclosure', () {
    test('isEbook returns true for EPUB MIME type', () {
      const enclosure = RssEnclosure(
        url: 'https://example.com/book.epub',
        type: 'application/epub+zip',
      );
      expect(enclosure.isEbook, isTrue);
      expect(enclosure.isComic, isFalse);
      expect(enclosure.isSupportedFormat, isTrue);
    });

    test('isEbook returns true for PDF MIME type', () {
      const enclosure = RssEnclosure(
        url: 'https://example.com/book.pdf',
        type: 'application/pdf',
      );
      expect(enclosure.isEbook, isTrue);
      expect(enclosure.isSupportedFormat, isTrue);
    });

    test('isComic returns true for CBZ MIME type', () {
      const enclosure = RssEnclosure(
        url: 'https://example.com/comic.cbz',
        type: 'application/x-cbz',
      );
      expect(enclosure.isComic, isTrue);
      expect(enclosure.isEbook, isFalse);
      expect(enclosure.isSupportedFormat, isTrue);
    });

    test('isEbook returns true for .epub extension', () {
      const enclosure = RssEnclosure(
        url: 'https://example.com/downloads/mybook.epub',
      );
      expect(enclosure.isEbook, isTrue);
    });

    test('isComic returns true for .cbr extension', () {
      const enclosure = RssEnclosure(
        url: 'https://example.com/comics/issue.cbr',
      );
      expect(enclosure.isComic, isTrue);
    });

    test('filename extracts file name from URL', () {
      const enclosure = RssEnclosure(
        url: 'https://example.com/downloads/my%20book.epub',
      );
      expect(enclosure.filename, equals('my book.epub'));
    });

    test('isSupportedFormat returns false for unsupported type', () {
      const enclosure = RssEnclosure(
        url: 'https://example.com/audio.mp3',
        type: 'audio/mpeg',
      );
      expect(enclosure.isSupportedFormat, isFalse);
    });

    test('equality works correctly', () {
      const e1 = RssEnclosure(url: 'https://example.com/book.epub');
      const e2 = RssEnclosure(url: 'https://example.com/book.epub');
      const e3 = RssEnclosure(url: 'https://example.com/other.epub');

      expect(e1, equals(e2));
      expect(e1, isNot(equals(e3)));
    });
  });
}
