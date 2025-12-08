import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/domain/entities/bookmark.dart';

void main() {
  group('Bookmark', () {
    final testDate = DateTime(2024, 1, 1, 12, 0, 0);

    Bookmark createTestBookmark({
      String id = 'bookmark-1',
      String bookId = 'book-1',
      String? chapterId,
      String cfi = 'epubcfi(/6/4[chap01]!/4/2/1:0)',
      String title = 'Chapter 1 Bookmark',
      DateTime? createdAt,
    }) {
      return Bookmark(
        id: id,
        bookId: bookId,
        chapterId: chapterId,
        cfi: cfi,
        title: title,
        createdAt: createdAt ?? testDate,
      );
    }

    group('constructor', () {
      test('creates bookmark with required fields', () {
        final bookmark = createTestBookmark();

        expect(bookmark.id, equals('bookmark-1'));
        expect(bookmark.bookId, equals('book-1'));
        expect(bookmark.cfi, equals('epubcfi(/6/4[chap01]!/4/2/1:0)'));
        expect(bookmark.title, equals('Chapter 1 Bookmark'));
        expect(bookmark.createdAt, equals(testDate));
      });

      test('creates bookmark with optional chapterId', () {
        final bookmark = createTestBookmark(chapterId: 'chapter-1');

        expect(bookmark.chapterId, equals('chapter-1'));
      });

      test('chapterId defaults to null', () {
        final bookmark = createTestBookmark();

        expect(bookmark.chapterId, isNull);
      });
    });

    group('copyWith', () {
      test('creates new instance with changed fields', () {
        final bookmark = createTestBookmark();
        final newDate = DateTime(2024, 6, 15);

        final updated = bookmark.copyWith(
          title: 'Updated Bookmark',
          createdAt: newDate,
        );

        expect(updated.title, equals('Updated Bookmark'));
        expect(updated.createdAt, equals(newDate));
      });

      test('preserves unchanged fields', () {
        final bookmark = createTestBookmark(chapterId: 'chapter-1');

        final updated = bookmark.copyWith(title: 'New Title');

        expect(updated.id, equals(bookmark.id));
        expect(updated.bookId, equals(bookmark.bookId));
        expect(updated.chapterId, equals(bookmark.chapterId));
        expect(updated.cfi, equals(bookmark.cfi));
        expect(updated.createdAt, equals(bookmark.createdAt));
      });

      test('can update all fields', () {
        final bookmark = createTestBookmark();
        final newDate = DateTime(2024, 12, 31);

        final updated = bookmark.copyWith(
          id: 'bookmark-2',
          bookId: 'book-2',
          chapterId: 'chapter-2',
          cfi: 'epubcfi(/6/8[chap02]!/4/2/1:0)',
          title: 'New Title',
          createdAt: newDate,
        );

        expect(updated.id, equals('bookmark-2'));
        expect(updated.bookId, equals('book-2'));
        expect(updated.chapterId, equals('chapter-2'));
        expect(updated.cfi, equals('epubcfi(/6/8[chap02]!/4/2/1:0)'));
        expect(updated.title, equals('New Title'));
        expect(updated.createdAt, equals(newDate));
      });
    });

    group('equality', () {
      test('equals same bookmark with identical properties', () {
        final bookmark1 = createTestBookmark();
        final bookmark2 = createTestBookmark();

        expect(bookmark1, equals(bookmark2));
      });

      test('not equals bookmark with different id', () {
        final bookmark1 = createTestBookmark(id: 'bookmark-1');
        final bookmark2 = createTestBookmark(id: 'bookmark-2');

        expect(bookmark1, isNot(equals(bookmark2)));
      });

      test('not equals bookmark with different cfi', () {
        final bookmark1 = createTestBookmark(cfi: 'epubcfi(/6/4)');
        final bookmark2 = createTestBookmark(cfi: 'epubcfi(/6/8)');

        expect(bookmark1, isNot(equals(bookmark2)));
      });

      test('hashCode is equal for equal bookmarks', () {
        final bookmark1 = createTestBookmark();
        final bookmark2 = createTestBookmark();

        expect(bookmark1.hashCode, equals(bookmark2.hashCode));
      });
    });

    group('toString', () {
      test('includes id, title, bookId, createdAt', () {
        final bookmark = createTestBookmark();
        final str = bookmark.toString();

        expect(str, contains('id: bookmark-1'));
        expect(str, contains('title: Chapter 1 Bookmark'));
        expect(str, contains('bookId: book-1'));
        expect(str, contains('createdAt:'));
      });
    });
  });
}
