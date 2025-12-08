import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/domain/entities/import_result.dart';
import 'package:readwhere/domain/entities/book.dart';
import 'package:readwhere/domain/entities/book_metadata.dart';

void main() {
  group('ImportResult', () {
    final testDate = DateTime(2024, 1, 1);

    Book createTestBook({String id = '1', String title = 'Test Book'}) {
      return Book(
        id: id,
        title: title,
        author: 'Test Author',
        filePath: '/path/to/book.epub',
        format: 'epub',
        fileSize: 1024,
        addedAt: testDate,
      );
    }

    group('success factory', () {
      test('creates successful import result with book', () {
        final book = createTestBook();
        final result = ImportResult.success(book: book);

        expect(result.success, isTrue);
        expect(result.book, equals(book));
        expect(result.errorReason, isNull);
        expect(result.errorDetails, isNull);
        expect(result.warnings, isEmpty);
      });

      test('creates successful import result with warnings', () {
        final book = createTestBook();
        final warnings = ['Missing cover image', 'Invalid metadata field'];
        final result = ImportResult.success(book: book, warnings: warnings);

        expect(result.success, isTrue);
        expect(result.book, equals(book));
        expect(result.warnings, equals(warnings));
        expect(result.hasWarnings, isTrue);
      });

      test('creates successful import result without warnings', () {
        final book = createTestBook();
        final result = ImportResult.success(book: book);

        expect(result.warnings, isEmpty);
        expect(result.hasWarnings, isFalse);
      });
    });

    group('failed factory', () {
      test('creates failed import result with reason', () {
        final result = ImportResult.failed(reason: 'File not found');

        expect(result.success, isFalse);
        expect(result.book, isNull);
        expect(result.errorReason, equals('File not found'));
        expect(result.errorDetails, isNull);
        expect(result.warnings, isEmpty);
      });

      test('creates failed import result with reason and details', () {
        final result = ImportResult.failed(
          reason: 'Invalid EPUB',
          details: 'Missing container.xml in META-INF',
        );

        expect(result.success, isFalse);
        expect(result.errorReason, equals('Invalid EPUB'));
        expect(
          result.errorDetails,
          equals('Missing container.xml in META-INF'),
        );
      });

      test('failed result has no warnings', () {
        final result = ImportResult.failed(reason: 'Error');

        expect(result.warnings, isEmpty);
        expect(result.hasWarnings, isFalse);
      });
    });

    group('hasWarnings', () {
      test('returns true when warnings exist', () {
        final book = createTestBook();
        final result = ImportResult.success(
          book: book,
          warnings: ['Warning 1'],
        );

        expect(result.hasWarnings, isTrue);
      });

      test('returns false when warnings are empty', () {
        final book = createTestBook();
        final result = ImportResult.success(book: book);

        expect(result.hasWarnings, isFalse);
      });

      test('returns false for failed result', () {
        final result = ImportResult.failed(reason: 'Error');

        expect(result.hasWarnings, isFalse);
      });
    });

    group('equality', () {
      test('equals same success result with identical book', () {
        final book = createTestBook();
        final result1 = ImportResult.success(book: book);
        final result2 = ImportResult.success(book: book);

        expect(result1, equals(result2));
      });

      test('equals same success result with identical warnings', () {
        final book = createTestBook();
        final warnings = ['Warning 1'];
        final result1 = ImportResult.success(book: book, warnings: warnings);
        final result2 = ImportResult.success(book: book, warnings: warnings);

        expect(result1, equals(result2));
      });

      test('equals same failed result with identical reason', () {
        final result1 = ImportResult.failed(reason: 'Error');
        final result2 = ImportResult.failed(reason: 'Error');

        expect(result1, equals(result2));
      });

      test('not equals success vs failed', () {
        final book = createTestBook();
        final successResult = ImportResult.success(book: book);
        final failedResult = ImportResult.failed(reason: 'Error');

        expect(successResult, isNot(equals(failedResult)));
      });

      test('not equals different books', () {
        final book1 = createTestBook(id: '1');
        final book2 = createTestBook(id: '2');
        final result1 = ImportResult.success(book: book1);
        final result2 = ImportResult.success(book: book2);

        expect(result1, isNot(equals(result2)));
      });

      test('not equals different error reasons', () {
        final result1 = ImportResult.failed(reason: 'Error 1');
        final result2 = ImportResult.failed(reason: 'Error 2');

        expect(result1, isNot(equals(result2)));
      });

      test('not equals different warnings', () {
        final book = createTestBook();
        final result1 = ImportResult.success(
          book: book,
          warnings: ['Warning 1'],
        );
        final result2 = ImportResult.success(
          book: book,
          warnings: ['Warning 2'],
        );

        expect(result1, isNot(equals(result2)));
      });

      test('hashCode is equal for equal results', () {
        final book = createTestBook();
        final result1 = ImportResult.success(book: book);
        final result2 = ImportResult.success(book: book);

        expect(result1.hashCode, equals(result2.hashCode));
      });
    });

    group('common use cases', () {
      test('successful import with DRM warning', () {
        final book = Book(
          id: '1',
          title: 'Protected Book',
          author: 'Author',
          filePath: '/path/to/book.epub',
          format: 'epub',
          fileSize: 1024,
          addedAt: testDate,
          encryptionType: EpubEncryptionType.fontObfuscation,
        );

        final result = ImportResult.success(
          book: book,
          warnings: ['Font obfuscation detected - fonts may not display'],
        );

        expect(result.success, isTrue);
        expect(result.book!.encryptionType, EpubEncryptionType.fontObfuscation);
        expect(result.hasWarnings, isTrue);
        expect(result.warnings.first, contains('Font obfuscation'));
      });

      test('failed import due to DRM', () {
        final result = ImportResult.failed(
          reason: 'DRM protected',
          details: 'Adobe DRM detected. This book cannot be read.',
        );

        expect(result.success, isFalse);
        expect(result.errorReason, equals('DRM protected'));
        expect(result.errorDetails, contains('Adobe DRM'));
      });

      test('failed import due to invalid file', () {
        final result = ImportResult.failed(
          reason: 'Invalid file format',
          details: 'Expected EPUB but found PDF magic bytes',
        );

        expect(result.success, isFalse);
        expect(result.book, isNull);
      });
    });
  });
}
