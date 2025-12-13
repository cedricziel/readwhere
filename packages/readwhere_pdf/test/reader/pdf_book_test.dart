import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_pdf/readwhere_pdf.dart';

void main() {
  group('PdfBook', () {
    test('creates book with required fields', () {
      const metadata = PdfMetadata(title: 'Test Book', author: 'Test Author');
      const pages = [
        PdfPage(index: 0, width: 612.0, height: 792.0),
        PdfPage(index: 1, width: 612.0, height: 792.0),
      ];

      const book = PdfBook(metadata: metadata, pageCount: 2, pages: pages);

      expect(book.metadata, metadata);
      expect(book.pageCount, 2);
      expect(book.pages, hasLength(2));
      expect(book.outline, isNull);
      expect(book.isEncrypted, isFalse);
      expect(book.requiresPassword, isFalse);
    });

    test('creates book with all fields', () {
      const metadata = PdfMetadata(title: 'Encrypted Book');
      const pages = [PdfPage(index: 0, width: 612.0, height: 792.0)];
      const outline = [PdfOutlineEntry(title: 'Chapter 1', pageIndex: 0)];

      const book = PdfBook(
        metadata: metadata,
        pageCount: 1,
        pages: pages,
        outline: outline,
        isEncrypted: true,
        requiresPassword: true,
      );

      expect(book.outline, isNotNull);
      expect(book.outline, hasLength(1));
      expect(book.isEncrypted, isTrue);
      expect(book.requiresPassword, isTrue);
    });

    group('PdfBook.empty()', () {
      test('creates empty book with default values', () {
        const book = PdfBook.empty();

        expect(book.pageCount, 0);
        expect(book.pages, isEmpty);
        expect(book.outline, isNull);
        expect(book.isEncrypted, isFalse);
        expect(book.requiresPassword, isFalse);
        expect(book.metadata.hasContent, isFalse);
      });
    });

    group('convenience getters', () {
      test('title returns metadata title', () {
        const metadata = PdfMetadata(title: 'My Title');
        const book = PdfBook(metadata: metadata, pageCount: 0, pages: []);

        expect(book.title, 'My Title');
      });

      test('author returns metadata author', () {
        const metadata = PdfMetadata(author: 'My Author');
        const book = PdfBook(metadata: metadata, pageCount: 0, pages: []);

        expect(book.author, 'My Author');
      });

      test('subject returns metadata subject', () {
        const metadata = PdfMetadata(subject: 'My Subject');
        const book = PdfBook(metadata: metadata, pageCount: 0, pages: []);

        expect(book.subject, 'My Subject');
      });

      test('creator returns metadata creator', () {
        const metadata = PdfMetadata(creator: 'My Creator');
        const book = PdfBook(metadata: metadata, pageCount: 0, pages: []);

        expect(book.creator, 'My Creator');
      });

      test('producer returns metadata producer', () {
        const metadata = PdfMetadata(producer: 'My Producer');
        const book = PdfBook(metadata: metadata, pageCount: 0, pages: []);

        expect(book.producer, 'My Producer');
      });

      test('creationDate returns metadata creationDate', () {
        final date = DateTime(2024, 1, 1);
        final metadata = PdfMetadata(creationDate: date);
        final book = PdfBook(metadata: metadata, pageCount: 0, pages: const []);

        expect(book.creationDate, date);
      });

      test('modificationDate returns metadata modificationDate', () {
        final date = DateTime(2024, 6, 1);
        final metadata = PdfMetadata(modificationDate: date);
        final book = PdfBook(metadata: metadata, pageCount: 0, pages: const []);

        expect(book.modificationDate, date);
      });

      test('getters return null for empty metadata', () {
        const book = PdfBook.empty();

        expect(book.title, isNull);
        expect(book.author, isNull);
        expect(book.subject, isNull);
        expect(book.creator, isNull);
        expect(book.producer, isNull);
        expect(book.creationDate, isNull);
        expect(book.modificationDate, isNull);
      });
    });

    group('hasOutline', () {
      test('returns true when outline is not null and not empty', () {
        const outline = [PdfOutlineEntry(title: 'Chapter 1', pageIndex: 0)];
        const book = PdfBook(
          metadata: PdfMetadata.empty(),
          pageCount: 0,
          pages: [],
          outline: outline,
        );

        expect(book.hasOutline, isTrue);
      });

      test('returns false when outline is null', () {
        const book = PdfBook(
          metadata: PdfMetadata.empty(),
          pageCount: 0,
          pages: [],
          outline: null,
        );

        expect(book.hasOutline, isFalse);
      });

      test('returns false when outline is empty', () {
        const book = PdfBook(
          metadata: PdfMetadata.empty(),
          pageCount: 0,
          pages: [],
          outline: [],
        );

        expect(book.hasOutline, isFalse);
      });
    });

    group('getPage', () {
      test('returns page at valid index', () {
        const pages = [
          PdfPage(index: 0, width: 612.0, height: 792.0),
          PdfPage(index: 1, width: 595.0, height: 842.0),
        ];
        const book = PdfBook(
          metadata: PdfMetadata.empty(),
          pageCount: 2,
          pages: pages,
        );

        final page0 = book.getPage(0);
        final page1 = book.getPage(1);

        expect(page0, isNotNull);
        expect(page0!.index, 0);
        expect(page0.width, 612.0);

        expect(page1, isNotNull);
        expect(page1!.index, 1);
        expect(page1.width, 595.0);
      });

      test('returns null for negative index', () {
        const book = PdfBook(
          metadata: PdfMetadata.empty(),
          pageCount: 1,
          pages: [PdfPage(index: 0, width: 612.0, height: 792.0)],
        );

        expect(book.getPage(-1), isNull);
      });

      test('returns null for index >= page count', () {
        const book = PdfBook(
          metadata: PdfMetadata.empty(),
          pageCount: 1,
          pages: [PdfPage(index: 0, width: 612.0, height: 792.0)],
        );

        expect(book.getPage(1), isNull);
        expect(book.getPage(100), isNull);
      });

      test('returns null for empty book', () {
        const book = PdfBook.empty();

        expect(book.getPage(0), isNull);
      });
    });

    group('equality', () {
      test('equal books are equal', () {
        const metadata = PdfMetadata(title: 'Test');
        const pages = [PdfPage(index: 0, width: 612.0, height: 792.0)];
        const book1 = PdfBook(metadata: metadata, pageCount: 1, pages: pages);
        const book2 = PdfBook(metadata: metadata, pageCount: 1, pages: pages);

        expect(book1, equals(book2));
        expect(book1.hashCode, equals(book2.hashCode));
      });

      test('different books are not equal', () {
        const book1 = PdfBook(
          metadata: PdfMetadata(title: 'Book 1'),
          pageCount: 1,
          pages: [PdfPage(index: 0, width: 612.0, height: 792.0)],
        );
        const book2 = PdfBook(
          metadata: PdfMetadata(title: 'Book 2'),
          pageCount: 1,
          pages: [PdfPage(index: 0, width: 612.0, height: 792.0)],
        );

        expect(book1, isNot(equals(book2)));
      });
    });

    test('toString returns meaningful representation', () {
      const book = PdfBook(
        metadata: PdfMetadata(title: 'Test Book', author: 'Test Author'),
        pageCount: 10,
        pages: [],
        isEncrypted: true,
      );

      final str = book.toString();
      expect(str, contains('PdfBook'));
      expect(str, contains('title: Test Book'));
      expect(str, contains('author: Test Author'));
      expect(str, contains('pageCount: 10'));
      expect(str, contains('isEncrypted: true'));
    });
  });
}
