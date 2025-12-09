import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/domain/entities/book.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

void main() {
  group('Book', () {
    final testDate = DateTime(2024, 1, 1);

    Book createTestBook({
      String id = '1',
      String title = 'Test Book',
      String author = 'Test Author',
      String filePath = '/path/to/book.epub',
      String? coverPath,
      String format = 'epub',
      int fileSize = 1024,
      DateTime? addedAt,
      DateTime? lastOpenedAt,
      bool isFavorite = false,
      double? readingProgress,
      EpubEncryptionType encryptionType = EpubEncryptionType.none,
      bool isFixedLayout = false,
      bool hasMediaOverlays = false,
    }) {
      return Book(
        id: id,
        title: title,
        author: author,
        filePath: filePath,
        coverPath: coverPath,
        format: format,
        fileSize: fileSize,
        addedAt: addedAt ?? testDate,
        lastOpenedAt: lastOpenedAt,
        isFavorite: isFavorite,
        readingProgress: readingProgress,
        encryptionType: encryptionType,
        isFixedLayout: isFixedLayout,
        hasMediaOverlays: hasMediaOverlays,
      );
    }

    group('constructor', () {
      test('creates book with required fields', () {
        final book = createTestBook();

        expect(book.id, equals('1'));
        expect(book.title, equals('Test Book'));
        expect(book.author, equals('Test Author'));
        expect(book.filePath, equals('/path/to/book.epub'));
        expect(book.format, equals('epub'));
        expect(book.fileSize, equals(1024));
        expect(book.addedAt, equals(testDate));
      });

      test('applies default values for optional fields', () {
        final book = createTestBook();

        expect(book.coverPath, isNull);
        expect(book.lastOpenedAt, isNull);
        expect(book.isFavorite, isFalse);
        expect(book.readingProgress, isNull);
        expect(book.encryptionType, equals(EpubEncryptionType.none));
        expect(book.isFixedLayout, isFalse);
        expect(book.hasMediaOverlays, isFalse);
      });

      test('accepts valid readingProgress of 0.0', () {
        final book = createTestBook(readingProgress: 0.0);
        expect(book.readingProgress, equals(0.0));
      });

      test('accepts valid readingProgress of 1.0', () {
        final book = createTestBook(readingProgress: 1.0);
        expect(book.readingProgress, equals(1.0));
      });

      test('accepts valid readingProgress between 0 and 1', () {
        final book = createTestBook(readingProgress: 0.5);
        expect(book.readingProgress, equals(0.5));
      });

      test('throws assertion error for readingProgress < 0', () {
        expect(
          () => createTestBook(readingProgress: -0.1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error for readingProgress > 1', () {
        expect(
          () => createTestBook(readingProgress: 1.1),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('hasDrm', () {
      test('returns false for no encryption', () {
        final book = createTestBook(encryptionType: EpubEncryptionType.none);
        expect(book.hasDrm, isFalse);
      });

      test('returns false for font obfuscation only', () {
        final book = createTestBook(
          encryptionType: EpubEncryptionType.fontObfuscation,
        );
        expect(book.hasDrm, isFalse);
      });

      test('returns true for Adobe DRM', () {
        final book = createTestBook(
          encryptionType: EpubEncryptionType.adobeDrm,
        );
        expect(book.hasDrm, isTrue);
      });

      test('returns true for Apple FairPlay', () {
        final book = createTestBook(
          encryptionType: EpubEncryptionType.appleFairPlay,
        );
        expect(book.hasDrm, isTrue);
      });

      test('returns true for LCP', () {
        final book = createTestBook(encryptionType: EpubEncryptionType.lcp);
        expect(book.hasDrm, isTrue);
      });

      test('returns true for unknown encryption', () {
        final book = createTestBook(encryptionType: EpubEncryptionType.unknown);
        expect(book.hasDrm, isTrue);
      });
    });

    group('copyWith', () {
      test('creates new instance with changed fields', () {
        final book = createTestBook();
        final newDate = DateTime(2024, 6, 15);

        final updated = book.copyWith(
          title: 'New Title',
          isFavorite: true,
          lastOpenedAt: newDate,
        );

        expect(updated.title, equals('New Title'));
        expect(updated.isFavorite, isTrue);
        expect(updated.lastOpenedAt, equals(newDate));
      });

      test('preserves unchanged fields', () {
        final book = createTestBook(
          coverPath: '/path/to/cover.jpg',
          readingProgress: 0.5,
        );

        final updated = book.copyWith(title: 'New Title');

        expect(updated.id, equals(book.id));
        expect(updated.author, equals(book.author));
        expect(updated.filePath, equals(book.filePath));
        expect(updated.coverPath, equals(book.coverPath));
        expect(updated.format, equals(book.format));
        expect(updated.fileSize, equals(book.fileSize));
        expect(updated.addedAt, equals(book.addedAt));
        expect(updated.readingProgress, equals(book.readingProgress));
      });

      test('can update all fields', () {
        final book = createTestBook();
        final newDate = DateTime(2024, 12, 31);

        final updated = book.copyWith(
          id: '2',
          title: 'Updated Title',
          author: 'Updated Author',
          filePath: '/new/path.epub',
          coverPath: '/new/cover.jpg',
          format: 'pdf',
          fileSize: 2048,
          addedAt: newDate,
          lastOpenedAt: newDate,
          isFavorite: true,
          readingProgress: 0.75,
          encryptionType: EpubEncryptionType.lcp,
          isFixedLayout: true,
          hasMediaOverlays: true,
        );

        expect(updated.id, equals('2'));
        expect(updated.title, equals('Updated Title'));
        expect(updated.author, equals('Updated Author'));
        expect(updated.filePath, equals('/new/path.epub'));
        expect(updated.coverPath, equals('/new/cover.jpg'));
        expect(updated.format, equals('pdf'));
        expect(updated.fileSize, equals(2048));
        expect(updated.addedAt, equals(newDate));
        expect(updated.lastOpenedAt, equals(newDate));
        expect(updated.isFavorite, isTrue);
        expect(updated.readingProgress, equals(0.75));
        expect(updated.encryptionType, equals(EpubEncryptionType.lcp));
        expect(updated.isFixedLayout, isTrue);
        expect(updated.hasMediaOverlays, isTrue);
      });
    });

    group('equality', () {
      test('equals same book with identical properties', () {
        final book1 = createTestBook();
        final book2 = createTestBook();

        expect(book1, equals(book2));
      });

      test('not equals book with different id', () {
        final book1 = createTestBook(id: '1');
        final book2 = createTestBook(id: '2');

        expect(book1, isNot(equals(book2)));
      });

      test('not equals book with different title', () {
        final book1 = createTestBook(title: 'Title 1');
        final book2 = createTestBook(title: 'Title 2');

        expect(book1, isNot(equals(book2)));
      });

      test('hashCode is equal for equal books', () {
        final book1 = createTestBook();
        final book2 = createTestBook();

        expect(book1.hashCode, equals(book2.hashCode));
      });
    });

    group('toString', () {
      test('includes id, title, author, format', () {
        final book = createTestBook();
        final str = book.toString();

        expect(str, contains('id: 1'));
        expect(str, contains('title: Test Book'));
        expect(str, contains('author: Test Author'));
        expect(str, contains('format: epub'));
      });

      test('shows progress when set', () {
        final book = createTestBook(readingProgress: 0.5);
        final str = book.toString();

        expect(str, contains('progress: 0.50'));
      });

      test('shows "none" when progress is null', () {
        final book = createTestBook(readingProgress: null);
        final str = book.toString();

        expect(str, contains('progress: none'));
      });
    });
  });
}
