import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_pdf/readwhere_pdf.dart';

void main() {
  group('PdfMetadata', () {
    test('creates metadata with all fields', () {
      final creationDate = DateTime(2024, 1, 15);
      final modificationDate = DateTime(2024, 6, 20);

      final metadata = PdfMetadata(
        title: 'Test Document',
        author: 'John Doe',
        subject: 'Testing',
        keywords: 'test, pdf, document',
        creator: 'Test App',
        producer: 'PDF Library',
        creationDate: creationDate,
        modificationDate: modificationDate,
      );

      expect(metadata.title, 'Test Document');
      expect(metadata.author, 'John Doe');
      expect(metadata.subject, 'Testing');
      expect(metadata.keywords, 'test, pdf, document');
      expect(metadata.creator, 'Test App');
      expect(metadata.producer, 'PDF Library');
      expect(metadata.creationDate, creationDate);
      expect(metadata.modificationDate, modificationDate);
    });

    test('creates metadata with optional fields', () {
      const metadata = PdfMetadata(title: 'Simple Document');

      expect(metadata.title, 'Simple Document');
      expect(metadata.author, isNull);
      expect(metadata.subject, isNull);
      expect(metadata.keywords, isNull);
      expect(metadata.creator, isNull);
      expect(metadata.producer, isNull);
      expect(metadata.creationDate, isNull);
      expect(metadata.modificationDate, isNull);
    });

    group('PdfMetadata.empty()', () {
      test('creates metadata with all null fields', () {
        const metadata = PdfMetadata.empty();

        expect(metadata.title, isNull);
        expect(metadata.author, isNull);
        expect(metadata.subject, isNull);
        expect(metadata.keywords, isNull);
        expect(metadata.creator, isNull);
        expect(metadata.producer, isNull);
        expect(metadata.creationDate, isNull);
        expect(metadata.modificationDate, isNull);
      });
    });

    group('hasContent', () {
      test('returns false for empty metadata', () {
        const metadata = PdfMetadata.empty();
        expect(metadata.hasContent, isFalse);
      });

      test('returns false for default constructor with no fields', () {
        const metadata = PdfMetadata();
        expect(metadata.hasContent, isFalse);
      });

      test('returns true when title is set', () {
        const metadata = PdfMetadata(title: 'Title');
        expect(metadata.hasContent, isTrue);
      });

      test('returns true when author is set', () {
        const metadata = PdfMetadata(author: 'Author');
        expect(metadata.hasContent, isTrue);
      });

      test('returns true when subject is set', () {
        const metadata = PdfMetadata(subject: 'Subject');
        expect(metadata.hasContent, isTrue);
      });

      test('returns true when keywords is set', () {
        const metadata = PdfMetadata(keywords: 'keywords');
        expect(metadata.hasContent, isTrue);
      });

      test('returns true when creator is set', () {
        const metadata = PdfMetadata(creator: 'Creator');
        expect(metadata.hasContent, isTrue);
      });

      test('returns true when producer is set', () {
        const metadata = PdfMetadata(producer: 'Producer');
        expect(metadata.hasContent, isTrue);
      });

      test('returns true when creationDate is set', () {
        final metadata = PdfMetadata(creationDate: DateTime.now());
        expect(metadata.hasContent, isTrue);
      });

      test('returns true when modificationDate is set', () {
        final metadata = PdfMetadata(modificationDate: DateTime.now());
        expect(metadata.hasContent, isTrue);
      });
    });

    group('equality', () {
      test('equal metadata are equal', () {
        final date = DateTime(2024, 1, 1);
        final metadata1 = PdfMetadata(
          title: 'Test',
          author: 'Author',
          creationDate: date,
        );
        final metadata2 = PdfMetadata(
          title: 'Test',
          author: 'Author',
          creationDate: date,
        );

        expect(metadata1, equals(metadata2));
        expect(metadata1.hashCode, equals(metadata2.hashCode));
      });

      test('different metadata are not equal', () {
        const metadata1 = PdfMetadata(title: 'Test1');
        const metadata2 = PdfMetadata(title: 'Test2');

        expect(metadata1, isNot(equals(metadata2)));
      });

      test('empty metadata are equal', () {
        const metadata1 = PdfMetadata.empty();
        const metadata2 = PdfMetadata.empty();

        expect(metadata1, equals(metadata2));
        expect(metadata1.hashCode, equals(metadata2.hashCode));
      });
    });

    test('toString returns meaningful representation', () {
      const metadata = PdfMetadata(title: 'Test Title', author: 'Test Author');

      final str = metadata.toString();
      expect(str, contains('PdfMetadata'));
      expect(str, contains('title: Test Title'));
      expect(str, contains('author: Test Author'));
    });
  });
}
