import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/data/models/book_model.dart';
import 'package:readwhere/domain/entities/book.dart';
import 'package:readwhere/domain/entities/book_metadata.dart';

void main() {
  group('BookModel', () {
    final testAddedAt = DateTime(2024, 1, 15, 10, 30);
    final testLastOpenedAt = DateTime(2024, 1, 20, 14, 45);

    group('constructor', () {
      test('creates book model with all fields', () {
        final model = BookModel(
          id: 'book-123',
          title: 'Test Book',
          author: 'Test Author',
          filePath: '/path/to/book.epub',
          coverPath: '/path/to/cover.jpg',
          format: 'epub',
          fileSize: 1024000,
          addedAt: testAddedAt,
          lastOpenedAt: testLastOpenedAt,
          isFavorite: true,
          readingProgress: 0.5,
          encryptionType: EpubEncryptionType.adobeDrm,
          isFixedLayout: true,
          hasMediaOverlays: true,
        );

        expect(model.id, equals('book-123'));
        expect(model.title, equals('Test Book'));
        expect(model.author, equals('Test Author'));
        expect(model.filePath, equals('/path/to/book.epub'));
        expect(model.coverPath, equals('/path/to/cover.jpg'));
        expect(model.format, equals('epub'));
        expect(model.fileSize, equals(1024000));
        expect(model.addedAt, equals(testAddedAt));
        expect(model.lastOpenedAt, equals(testLastOpenedAt));
        expect(model.isFavorite, isTrue);
        expect(model.readingProgress, equals(0.5));
        expect(model.encryptionType, equals(EpubEncryptionType.adobeDrm));
        expect(model.isFixedLayout, isTrue);
        expect(model.hasMediaOverlays, isTrue);
      });

      test('creates book model with default values', () {
        final model = BookModel(
          id: 'book-123',
          title: 'Test Book',
          author: 'Test Author',
          filePath: '/path/to/book.epub',
          format: 'epub',
          fileSize: 1024000,
          addedAt: testAddedAt,
        );

        expect(model.coverPath, isNull);
        expect(model.lastOpenedAt, isNull);
        expect(model.isFavorite, isFalse);
        expect(model.readingProgress, isNull);
        expect(model.encryptionType, equals(EpubEncryptionType.none));
        expect(model.isFixedLayout, isFalse);
        expect(model.hasMediaOverlays, isFalse);
      });
    });

    group('fromMap', () {
      test('parses all fields correctly', () {
        final map = {
          'id': 'book-123',
          'title': 'Test Book',
          'author': 'Test Author',
          'file_path': '/path/to/book.epub',
          'cover_path': '/path/to/cover.jpg',
          'format': 'epub',
          'file_size': 2048000,
          'added_at': testAddedAt.millisecondsSinceEpoch,
          'last_opened_at': testLastOpenedAt.millisecondsSinceEpoch,
          'is_favorite': 1,
          'encryption_type': 'adobeDrm',
          'is_fixed_layout': 1,
          'has_media_overlays': 1,
        };

        final model = BookModel.fromMap(map);

        expect(model.id, equals('book-123'));
        expect(model.title, equals('Test Book'));
        expect(model.author, equals('Test Author'));
        expect(model.filePath, equals('/path/to/book.epub'));
        expect(model.coverPath, equals('/path/to/cover.jpg'));
        expect(model.format, equals('epub'));
        expect(model.fileSize, equals(2048000));
        expect(
          model.addedAt.millisecondsSinceEpoch,
          equals(testAddedAt.millisecondsSinceEpoch),
        );
        expect(
          model.lastOpenedAt?.millisecondsSinceEpoch,
          equals(testLastOpenedAt.millisecondsSinceEpoch),
        );
        expect(model.isFavorite, isTrue);
        expect(model.encryptionType, equals(EpubEncryptionType.adobeDrm));
        expect(model.isFixedLayout, isTrue);
        expect(model.hasMediaOverlays, isTrue);
      });

      test('parses isFavorite as 0 to false', () {
        final map = {
          'id': 'book-123',
          'title': 'Test Book',
          'author': 'Test Author',
          'file_path': '/path/to/book.epub',
          'format': 'epub',
          'file_size': 1024000,
          'added_at': testAddedAt.millisecondsSinceEpoch,
          'is_favorite': 0,
        };

        final model = BookModel.fromMap(map);
        expect(model.isFavorite, isFalse);
      });

      test('parses null optional fields', () {
        final map = {
          'id': 'book-123',
          'title': 'Test Book',
          'author': '',
          'file_path': '/path/to/book.epub',
          'format': 'epub',
          'file_size': 0,
          'added_at': testAddedAt.millisecondsSinceEpoch,
          'is_favorite': 0,
          'cover_path': null,
          'last_opened_at': null,
          'encryption_type': null,
          'is_fixed_layout': null,
          'has_media_overlays': null,
        };

        final model = BookModel.fromMap(map);

        expect(model.coverPath, isNull);
        expect(model.lastOpenedAt, isNull);
      });

      test('parses lcp encryption type', () {
        final map = {
          'id': 'book-123',
          'title': 'Test Book',
          'author': 'Author',
          'file_path': '/path/to/book.epub',
          'format': 'epub',
          'file_size': 1024,
          'added_at': testAddedAt.millisecondsSinceEpoch,
          'is_favorite': 0,
          'encryption_type': 'lcp',
        };

        final model = BookModel.fromMap(map);
        expect(model.encryptionType, equals(EpubEncryptionType.lcp));
      });

      test('parses appleFairPlay encryption type', () {
        final map = {
          'id': 'book-123',
          'title': 'Test Book',
          'author': 'Author',
          'file_path': '/path/to/book.epub',
          'format': 'epub',
          'file_size': 1024,
          'added_at': testAddedAt.millisecondsSinceEpoch,
          'is_favorite': 0,
          'encryption_type': 'appleFairPlay',
        };

        final model = BookModel.fromMap(map);
        expect(model.encryptionType, equals(EpubEncryptionType.appleFairPlay));
      });

      test('parses fontObfuscation encryption type', () {
        final map = {
          'id': 'book-123',
          'title': 'Test Book',
          'author': 'Author',
          'file_path': '/path/to/book.epub',
          'format': 'epub',
          'file_size': 1024,
          'added_at': testAddedAt.millisecondsSinceEpoch,
          'is_favorite': 0,
          'encryption_type': 'fontObfuscation',
        };

        final model = BookModel.fromMap(map);
        expect(
          model.encryptionType,
          equals(EpubEncryptionType.fontObfuscation),
        );
      });

      test('parses unknown encryption type', () {
        final map = {
          'id': 'book-123',
          'title': 'Test Book',
          'author': 'Author',
          'file_path': '/path/to/book.epub',
          'format': 'epub',
          'file_size': 1024,
          'added_at': testAddedAt.millisecondsSinceEpoch,
          'is_favorite': 0,
          'encryption_type': 'unknown',
        };

        final model = BookModel.fromMap(map);
        expect(model.encryptionType, equals(EpubEncryptionType.unknown));
      });

      test('defaults unrecognized encryption string to none', () {
        final map = {
          'id': 'book-123',
          'title': 'Test Book',
          'author': 'Author',
          'file_path': '/path/to/book.epub',
          'format': 'epub',
          'file_size': 1024,
          'added_at': testAddedAt.millisecondsSinceEpoch,
          'is_favorite': 0,
          'encryption_type': 'some_future_type',
        };

        final model = BookModel.fromMap(map);
        expect(model.encryptionType, equals(EpubEncryptionType.none));
      });

      test('handles missing author with empty string default', () {
        final map = {
          'id': 'book-123',
          'title': 'Test Book',
          'author': null,
          'file_path': '/path/to/book.epub',
          'format': 'epub',
          'file_size': 1024,
          'added_at': testAddedAt.millisecondsSinceEpoch,
          'is_favorite': 0,
        };

        final model = BookModel.fromMap(map);
        expect(model.author, equals(''));
      });
    });

    group('toMap', () {
      test('serializes all fields correctly', () {
        final model = BookModel(
          id: 'book-123',
          title: 'Test Book',
          author: 'Test Author',
          filePath: '/path/to/book.epub',
          coverPath: '/path/to/cover.jpg',
          format: 'epub',
          fileSize: 1024000,
          addedAt: testAddedAt,
          lastOpenedAt: testLastOpenedAt,
          isFavorite: true,
          readingProgress: 0.5,
          encryptionType: EpubEncryptionType.adobeDrm,
          isFixedLayout: true,
          hasMediaOverlays: true,
        );

        final map = model.toMap();

        expect(map['id'], equals('book-123'));
        expect(map['title'], equals('Test Book'));
        expect(map['author'], equals('Test Author'));
        expect(map['file_path'], equals('/path/to/book.epub'));
        expect(map['cover_path'], equals('/path/to/cover.jpg'));
        expect(map['format'], equals('epub'));
        expect(map['file_size'], equals(1024000));
        expect(map['added_at'], equals(testAddedAt.millisecondsSinceEpoch));
        expect(
          map['last_opened_at'],
          equals(testLastOpenedAt.millisecondsSinceEpoch),
        );
        expect(map['is_favorite'], equals(1));
        expect(map['encryption_type'], equals('adobeDrm'));
        expect(map['is_fixed_layout'], equals(1));
        expect(map['has_media_overlays'], equals(1));
      });

      test('serializes isFavorite false as 0', () {
        final model = BookModel(
          id: 'book-123',
          title: 'Test Book',
          author: 'Test Author',
          filePath: '/path/to/book.epub',
          format: 'epub',
          fileSize: 1024000,
          addedAt: testAddedAt,
          isFavorite: false,
        );

        final map = model.toMap();
        expect(map['is_favorite'], equals(0));
      });

      test('serializes null lastOpenedAt', () {
        final model = BookModel(
          id: 'book-123',
          title: 'Test Book',
          author: 'Test Author',
          filePath: '/path/to/book.epub',
          format: 'epub',
          fileSize: 1024000,
          addedAt: testAddedAt,
        );

        final map = model.toMap();
        expect(map['last_opened_at'], isNull);
      });

      test('serializes all encryption types', () {
        for (final encType in EpubEncryptionType.values) {
          final model = BookModel(
            id: 'book-123',
            title: 'Test Book',
            author: 'Test Author',
            filePath: '/path/to/book.epub',
            format: 'epub',
            fileSize: 1024000,
            addedAt: testAddedAt,
            encryptionType: encType,
          );

          final map = model.toMap();
          expect(map['encryption_type'], equals(encType.name));
        }
      });

      test('serializes boolean fields as integers', () {
        final model = BookModel(
          id: 'book-123',
          title: 'Test Book',
          author: 'Test Author',
          filePath: '/path/to/book.epub',
          format: 'epub',
          fileSize: 1024000,
          addedAt: testAddedAt,
          isFixedLayout: false,
          hasMediaOverlays: false,
        );

        final map = model.toMap();
        expect(map['is_fixed_layout'], equals(0));
        expect(map['has_media_overlays'], equals(0));
      });
    });

    group('fromEntity', () {
      test('converts Book entity to BookModel', () {
        final book = Book(
          id: 'book-123',
          title: 'Test Book',
          author: 'Test Author',
          filePath: '/path/to/book.epub',
          coverPath: '/path/to/cover.jpg',
          format: 'epub',
          fileSize: 1024000,
          addedAt: testAddedAt,
          lastOpenedAt: testLastOpenedAt,
          isFavorite: true,
          readingProgress: 0.5,
          encryptionType: EpubEncryptionType.lcp,
          isFixedLayout: true,
          hasMediaOverlays: true,
        );

        final model = BookModel.fromEntity(book);

        expect(model.id, equals(book.id));
        expect(model.title, equals(book.title));
        expect(model.author, equals(book.author));
        expect(model.filePath, equals(book.filePath));
        expect(model.coverPath, equals(book.coverPath));
        expect(model.format, equals(book.format));
        expect(model.fileSize, equals(book.fileSize));
        expect(model.addedAt, equals(book.addedAt));
        expect(model.lastOpenedAt, equals(book.lastOpenedAt));
        expect(model.isFavorite, equals(book.isFavorite));
        expect(model.readingProgress, equals(book.readingProgress));
        expect(model.encryptionType, equals(book.encryptionType));
        expect(model.isFixedLayout, equals(book.isFixedLayout));
        expect(model.hasMediaOverlays, equals(book.hasMediaOverlays));
      });

      test('converts Book entity with default values', () {
        final book = Book(
          id: 'book-123',
          title: 'Test Book',
          author: 'Test Author',
          filePath: '/path/to/book.epub',
          format: 'epub',
          fileSize: 1024000,
          addedAt: testAddedAt,
        );

        final model = BookModel.fromEntity(book);

        expect(model.coverPath, isNull);
        expect(model.lastOpenedAt, isNull);
        expect(model.isFavorite, isFalse);
        expect(model.readingProgress, isNull);
        expect(model.encryptionType, equals(EpubEncryptionType.none));
        expect(model.isFixedLayout, isFalse);
        expect(model.hasMediaOverlays, isFalse);
      });
    });

    group('toEntity', () {
      test('converts BookModel to Book entity', () {
        final model = BookModel(
          id: 'book-123',
          title: 'Test Book',
          author: 'Test Author',
          filePath: '/path/to/book.epub',
          coverPath: '/path/to/cover.jpg',
          format: 'epub',
          fileSize: 1024000,
          addedAt: testAddedAt,
          lastOpenedAt: testLastOpenedAt,
          isFavorite: true,
          readingProgress: 0.5,
          encryptionType: EpubEncryptionType.adobeDrm,
          isFixedLayout: true,
          hasMediaOverlays: true,
        );

        final book = model.toEntity();

        expect(book.id, equals(model.id));
        expect(book.title, equals(model.title));
        expect(book.author, equals(model.author));
        expect(book.filePath, equals(model.filePath));
        expect(book.coverPath, equals(model.coverPath));
        expect(book.format, equals(model.format));
        expect(book.fileSize, equals(model.fileSize));
        expect(book.addedAt, equals(model.addedAt));
        expect(book.lastOpenedAt, equals(model.lastOpenedAt));
        expect(book.isFavorite, equals(model.isFavorite));
        expect(book.readingProgress, equals(model.readingProgress));
        expect(book.encryptionType, equals(model.encryptionType));
        expect(book.isFixedLayout, equals(model.isFixedLayout));
        expect(book.hasMediaOverlays, equals(model.hasMediaOverlays));
      });
    });

    group('round-trip', () {
      test('toMap then fromMap preserves all data', () {
        final original = BookModel(
          id: 'book-123',
          title: 'Test Book',
          author: 'Test Author',
          filePath: '/path/to/book.epub',
          coverPath: '/path/to/cover.jpg',
          format: 'epub',
          fileSize: 1024000,
          addedAt: testAddedAt,
          lastOpenedAt: testLastOpenedAt,
          isFavorite: true,
          encryptionType: EpubEncryptionType.lcp,
          isFixedLayout: true,
          hasMediaOverlays: true,
        );

        final map = original.toMap();
        final restored = BookModel.fromMap(map);

        expect(restored.id, equals(original.id));
        expect(restored.title, equals(original.title));
        expect(restored.author, equals(original.author));
        expect(restored.filePath, equals(original.filePath));
        expect(restored.coverPath, equals(original.coverPath));
        expect(restored.format, equals(original.format));
        expect(restored.fileSize, equals(original.fileSize));
        expect(
          restored.addedAt.millisecondsSinceEpoch,
          equals(original.addedAt.millisecondsSinceEpoch),
        );
        expect(
          restored.lastOpenedAt?.millisecondsSinceEpoch,
          equals(original.lastOpenedAt?.millisecondsSinceEpoch),
        );
        expect(restored.isFavorite, equals(original.isFavorite));
        expect(restored.encryptionType, equals(original.encryptionType));
        expect(restored.isFixedLayout, equals(original.isFixedLayout));
        expect(restored.hasMediaOverlays, equals(original.hasMediaOverlays));
      });

      test('fromEntity then toEntity preserves all data', () {
        final original = Book(
          id: 'book-123',
          title: 'Test Book',
          author: 'Test Author',
          filePath: '/path/to/book.epub',
          coverPath: '/path/to/cover.jpg',
          format: 'epub',
          fileSize: 1024000,
          addedAt: testAddedAt,
          lastOpenedAt: testLastOpenedAt,
          isFavorite: true,
          readingProgress: 0.5,
          encryptionType: EpubEncryptionType.adobeDrm,
          isFixedLayout: true,
          hasMediaOverlays: true,
        );

        final model = BookModel.fromEntity(original);
        final restored = model.toEntity();

        expect(restored, equals(original));
      });
    });

    group('hasDrm', () {
      test('returns true for adobeDrm', () {
        final model = BookModel(
          id: 'book-123',
          title: 'Test Book',
          author: 'Test Author',
          filePath: '/path/to/book.epub',
          format: 'epub',
          fileSize: 1024000,
          addedAt: testAddedAt,
          encryptionType: EpubEncryptionType.adobeDrm,
        );

        expect(model.hasDrm, isTrue);
      });

      test('returns true for lcp', () {
        final model = BookModel(
          id: 'book-123',
          title: 'Test Book',
          author: 'Test Author',
          filePath: '/path/to/book.epub',
          format: 'epub',
          fileSize: 1024000,
          addedAt: testAddedAt,
          encryptionType: EpubEncryptionType.lcp,
        );

        expect(model.hasDrm, isTrue);
      });

      test('returns false for none', () {
        final model = BookModel(
          id: 'book-123',
          title: 'Test Book',
          author: 'Test Author',
          filePath: '/path/to/book.epub',
          format: 'epub',
          fileSize: 1024000,
          addedAt: testAddedAt,
          encryptionType: EpubEncryptionType.none,
        );

        expect(model.hasDrm, isFalse);
      });

      test('returns false for fontObfuscation', () {
        final model = BookModel(
          id: 'book-123',
          title: 'Test Book',
          author: 'Test Author',
          filePath: '/path/to/book.epub',
          format: 'epub',
          fileSize: 1024000,
          addedAt: testAddedAt,
          encryptionType: EpubEncryptionType.fontObfuscation,
        );

        expect(model.hasDrm, isFalse);
      });
    });
  });
}
