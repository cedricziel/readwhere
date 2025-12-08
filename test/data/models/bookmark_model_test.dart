import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/data/models/bookmark_model.dart';
import 'package:readwhere/domain/entities/bookmark.dart';

void main() {
  group('BookmarkModel', () {
    final testCreatedAt = DateTime(2024, 1, 15, 10, 30);

    group('constructor', () {
      test('creates bookmark model with all fields', () {
        final model = BookmarkModel(
          id: 'bookmark-123',
          bookId: 'book-456',
          chapterId: 'chapter-1',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          title: 'Important Quote',
          createdAt: testCreatedAt,
        );

        expect(model.id, equals('bookmark-123'));
        expect(model.bookId, equals('book-456'));
        expect(model.chapterId, equals('chapter-1'));
        expect(model.cfi, equals('epubcfi(/6/4!/4/2/1:0)'));
        expect(model.title, equals('Important Quote'));
        expect(model.createdAt, equals(testCreatedAt));
      });

      test('creates bookmark model with nullable chapterId as null', () {
        final model = BookmarkModel(
          id: 'bookmark-123',
          bookId: 'book-456',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          title: 'Bookmark',
          createdAt: testCreatedAt,
        );

        expect(model.chapterId, isNull);
      });
    });

    group('fromMap', () {
      test('parses all fields correctly', () {
        final map = {
          'id': 'bookmark-123',
          'book_id': 'book-456',
          'chapter_id': 'chapter-1',
          'cfi': 'epubcfi(/6/4!/4/2/1:0)',
          'title': 'Important Quote',
          'created_at': testCreatedAt.millisecondsSinceEpoch,
        };

        final model = BookmarkModel.fromMap(map);

        expect(model.id, equals('bookmark-123'));
        expect(model.bookId, equals('book-456'));
        expect(model.chapterId, equals('chapter-1'));
        expect(model.cfi, equals('epubcfi(/6/4!/4/2/1:0)'));
        expect(model.title, equals('Important Quote'));
        expect(
          model.createdAt.millisecondsSinceEpoch,
          equals(testCreatedAt.millisecondsSinceEpoch),
        );
      });

      test('parses null chapterId', () {
        final map = {
          'id': 'bookmark-123',
          'book_id': 'book-456',
          'chapter_id': null,
          'cfi': 'epubcfi(/6/4!/4/2/1:0)',
          'title': 'Bookmark',
          'created_at': testCreatedAt.millisecondsSinceEpoch,
        };

        final model = BookmarkModel.fromMap(map);
        expect(model.chapterId, isNull);
      });

      test('handles missing optional fields', () {
        final map = {
          'id': 'bookmark-123',
          'book_id': 'book-456',
          'cfi': 'epubcfi(/6/4!/4/2/1:0)',
          'title': 'Bookmark',
          'created_at': testCreatedAt.millisecondsSinceEpoch,
        };

        final model = BookmarkModel.fromMap(map);
        expect(model.chapterId, isNull);
      });

      test('handles null cfi with empty string default', () {
        final map = {
          'id': 'bookmark-123',
          'book_id': 'book-456',
          'cfi': null,
          'title': 'Bookmark',
          'created_at': testCreatedAt.millisecondsSinceEpoch,
        };

        final model = BookmarkModel.fromMap(map);
        expect(model.cfi, equals(''));
      });

      test('handles null title with empty string default', () {
        final map = {
          'id': 'bookmark-123',
          'book_id': 'book-456',
          'cfi': 'epubcfi(/6/4!/4/2/1:0)',
          'title': null,
          'created_at': testCreatedAt.millisecondsSinceEpoch,
        };

        final model = BookmarkModel.fromMap(map);
        expect(model.title, equals(''));
      });
    });

    group('toMap', () {
      test('serializes all fields correctly', () {
        final model = BookmarkModel(
          id: 'bookmark-123',
          bookId: 'book-456',
          chapterId: 'chapter-1',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          title: 'Important Quote',
          createdAt: testCreatedAt,
        );

        final map = model.toMap();

        expect(map['id'], equals('bookmark-123'));
        expect(map['book_id'], equals('book-456'));
        expect(map['chapter_id'], equals('chapter-1'));
        expect(map['cfi'], equals('epubcfi(/6/4!/4/2/1:0)'));
        expect(map['title'], equals('Important Quote'));
        expect(map['created_at'], equals(testCreatedAt.millisecondsSinceEpoch));
      });

      test('serializes null chapterId', () {
        final model = BookmarkModel(
          id: 'bookmark-123',
          bookId: 'book-456',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          title: 'Bookmark',
          createdAt: testCreatedAt,
        );

        final map = model.toMap();
        expect(map['chapter_id'], isNull);
      });

      test('serializes empty strings', () {
        final model = BookmarkModel(
          id: 'bookmark-123',
          bookId: 'book-456',
          cfi: '',
          title: '',
          createdAt: testCreatedAt,
        );

        final map = model.toMap();
        expect(map['cfi'], equals(''));
        expect(map['title'], equals(''));
      });
    });

    group('fromEntity', () {
      test('converts Bookmark entity to BookmarkModel', () {
        final bookmark = Bookmark(
          id: 'bookmark-123',
          bookId: 'book-456',
          chapterId: 'chapter-1',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          title: 'Important Quote',
          createdAt: testCreatedAt,
        );

        final model = BookmarkModel.fromEntity(bookmark);

        expect(model.id, equals(bookmark.id));
        expect(model.bookId, equals(bookmark.bookId));
        expect(model.chapterId, equals(bookmark.chapterId));
        expect(model.cfi, equals(bookmark.cfi));
        expect(model.title, equals(bookmark.title));
        expect(model.createdAt, equals(bookmark.createdAt));
      });

      test('converts Bookmark entity with null chapterId', () {
        final bookmark = Bookmark(
          id: 'bookmark-123',
          bookId: 'book-456',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          title: 'Bookmark',
          createdAt: testCreatedAt,
        );

        final model = BookmarkModel.fromEntity(bookmark);
        expect(model.chapterId, isNull);
      });
    });

    group('toEntity', () {
      test('converts BookmarkModel to Bookmark entity', () {
        final model = BookmarkModel(
          id: 'bookmark-123',
          bookId: 'book-456',
          chapterId: 'chapter-1',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          title: 'Important Quote',
          createdAt: testCreatedAt,
        );

        final bookmark = model.toEntity();

        expect(bookmark.id, equals(model.id));
        expect(bookmark.bookId, equals(model.bookId));
        expect(bookmark.chapterId, equals(model.chapterId));
        expect(bookmark.cfi, equals(model.cfi));
        expect(bookmark.title, equals(model.title));
        expect(bookmark.createdAt, equals(model.createdAt));
      });

      test('converts BookmarkModel with null chapterId', () {
        final model = BookmarkModel(
          id: 'bookmark-123',
          bookId: 'book-456',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          title: 'Bookmark',
          createdAt: testCreatedAt,
        );

        final bookmark = model.toEntity();
        expect(bookmark.chapterId, isNull);
      });
    });

    group('round-trip', () {
      test('toMap then fromMap preserves all data', () {
        final original = BookmarkModel(
          id: 'bookmark-123',
          bookId: 'book-456',
          chapterId: 'chapter-1',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          title: 'Important Quote',
          createdAt: testCreatedAt,
        );

        final map = original.toMap();
        final restored = BookmarkModel.fromMap(map);

        expect(restored.id, equals(original.id));
        expect(restored.bookId, equals(original.bookId));
        expect(restored.chapterId, equals(original.chapterId));
        expect(restored.cfi, equals(original.cfi));
        expect(restored.title, equals(original.title));
        expect(
          restored.createdAt.millisecondsSinceEpoch,
          equals(original.createdAt.millisecondsSinceEpoch),
        );
      });

      test('fromEntity then toEntity preserves all data', () {
        final original = Bookmark(
          id: 'bookmark-123',
          bookId: 'book-456',
          chapterId: 'chapter-1',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          title: 'Important Quote',
          createdAt: testCreatedAt,
        );

        final model = BookmarkModel.fromEntity(original);
        final restored = model.toEntity();

        expect(restored, equals(original));
      });

      test('round-trip with null chapterId', () {
        final original = BookmarkModel(
          id: 'bookmark-123',
          bookId: 'book-456',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          title: 'Bookmark',
          createdAt: testCreatedAt,
        );

        final map = original.toMap();
        final restored = BookmarkModel.fromMap(map);

        expect(restored.chapterId, isNull);
      });
    });
  });
}
