import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere/data/database/tables/bookmarks_table.dart';
import 'package:readwhere/data/repositories/bookmark_repository_impl.dart';
import 'package:readwhere/domain/entities/bookmark.dart';
import 'package:sqflite/sqflite.dart';

import '../../mocks/mock_repositories.mocks.dart';

void main() {
  group('BookmarkRepositoryImpl', () {
    late MockDatabaseHelper mockDatabaseHelper;
    late MockDatabase mockDatabase;
    late BookmarkRepositoryImpl repository;

    final testCreatedAt = DateTime(2024, 1, 15, 10, 30);

    final testBookmarkMap = {
      'id': 'bookmark-123',
      'book_id': 'book-456',
      'chapter_id': 'chapter-1',
      'cfi': 'epubcfi(/6/4!/4/2/1:0)',
      'title': 'Important Quote',
      'created_at': testCreatedAt.millisecondsSinceEpoch,
    };

    final testBookmark = Bookmark(
      id: 'bookmark-123',
      bookId: 'book-456',
      chapterId: 'chapter-1',
      cfi: 'epubcfi(/6/4!/4/2/1:0)',
      title: 'Important Quote',
      createdAt: testCreatedAt,
    );

    setUp(() {
      mockDatabaseHelper = MockDatabaseHelper();
      mockDatabase = MockDatabase();
      repository = BookmarkRepositoryImpl(mockDatabaseHelper);

      when(mockDatabaseHelper.database).thenAnswer((_) async => mockDatabase);
    });

    group('getBookmarksForBook', () {
      test('returns bookmarks for book ordered by created_at desc', () async {
        when(
          mockDatabase.query(
            BookmarksTable.tableName,
            where: '${BookmarksTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            orderBy: '${BookmarksTable.columnCreatedAt} DESC',
          ),
        ).thenAnswer((_) async => [testBookmarkMap]);

        final result = await repository.getBookmarksForBook('book-456');

        expect(result, hasLength(1));
        expect(result.first.id, equals('bookmark-123'));
        expect(result.first.bookId, equals('book-456'));
        expect(result.first.title, equals('Important Quote'));
      });

      test('returns empty list when no bookmarks for book', () async {
        when(
          mockDatabase.query(
            BookmarksTable.tableName,
            where: '${BookmarksTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            orderBy: '${BookmarksTable.columnCreatedAt} DESC',
          ),
        ).thenAnswer((_) async => []);

        final result = await repository.getBookmarksForBook('book-456');

        expect(result, isEmpty);
      });

      test('returns multiple bookmarks', () async {
        final bookmark2Map = {
          'id': 'bookmark-124',
          'book_id': 'book-456',
          'chapter_id': 'chapter-2',
          'cfi': 'epubcfi(/6/6!/4/2/1:0)',
          'title': 'Another Quote',
          'created_at': testCreatedAt.millisecondsSinceEpoch,
        };

        when(
          mockDatabase.query(
            BookmarksTable.tableName,
            where: '${BookmarksTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            orderBy: '${BookmarksTable.columnCreatedAt} DESC',
          ),
        ).thenAnswer((_) async => [testBookmarkMap, bookmark2Map]);

        final result = await repository.getBookmarksForBook('book-456');

        expect(result, hasLength(2));
      });

      test('throws exception on database error', () async {
        when(
          mockDatabase.query(
            BookmarksTable.tableName,
            where: '${BookmarksTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            orderBy: '${BookmarksTable.columnCreatedAt} DESC',
          ),
        ).thenThrow(Exception('Database error'));

        expect(
          () => repository.getBookmarksForBook('book-456'),
          throwsException,
        );
      });
    });

    group('addBookmark', () {
      test('adds bookmark and returns it', () async {
        when(
          mockDatabase.insert(
            BookmarksTable.tableName,
            any,
            conflictAlgorithm: ConflictAlgorithm.fail,
          ),
        ).thenAnswer((_) async => 1);

        final result = await repository.addBookmark(testBookmark);

        expect(result.id, equals(testBookmark.id));
        expect(result.bookId, equals(testBookmark.bookId));
        verify(
          mockDatabase.insert(
            BookmarksTable.tableName,
            any,
            conflictAlgorithm: ConflictAlgorithm.fail,
          ),
        ).called(1);
      });

      test('throws exception on insert failure', () async {
        when(
          mockDatabase.insert(
            BookmarksTable.tableName,
            any,
            conflictAlgorithm: ConflictAlgorithm.fail,
          ),
        ).thenThrow(Exception('Insert failed'));

        expect(() => repository.addBookmark(testBookmark), throwsException);
      });
    });

    group('deleteBookmark', () {
      test('deletes bookmark and returns true', () async {
        when(
          mockDatabase.delete(
            BookmarksTable.tableName,
            where: '${BookmarksTable.columnId} = ?',
            whereArgs: ['bookmark-123'],
          ),
        ).thenAnswer((_) async => 1);

        final result = await repository.deleteBookmark('bookmark-123');

        expect(result, isTrue);
      });

      test('returns false when bookmark not found', () async {
        when(
          mockDatabase.delete(
            BookmarksTable.tableName,
            where: '${BookmarksTable.columnId} = ?',
            whereArgs: ['non-existent'],
          ),
        ).thenAnswer((_) async => 0);

        final result = await repository.deleteBookmark('non-existent');

        expect(result, isFalse);
      });

      test('throws exception on database error', () async {
        when(
          mockDatabase.delete(
            BookmarksTable.tableName,
            where: '${BookmarksTable.columnId} = ?',
            whereArgs: ['bookmark-123'],
          ),
        ).thenThrow(Exception('Database error'));

        expect(
          () => repository.deleteBookmark('bookmark-123'),
          throwsException,
        );
      });
    });

    group('updateBookmark', () {
      test('updates bookmark and returns it', () async {
        when(
          mockDatabase.update(
            BookmarksTable.tableName,
            any,
            where: '${BookmarksTable.columnId} = ?',
            whereArgs: ['bookmark-123'],
          ),
        ).thenAnswer((_) async => 1);

        final updatedBookmark = testBookmark.copyWith(title: 'Updated Title');
        final result = await repository.updateBookmark(updatedBookmark);

        expect(result.id, equals(updatedBookmark.id));
        expect(result.title, equals('Updated Title'));
      });

      test('throws exception when bookmark not found', () async {
        when(
          mockDatabase.update(
            BookmarksTable.tableName,
            any,
            where: '${BookmarksTable.columnId} = ?',
            whereArgs: ['bookmark-123'],
          ),
        ).thenAnswer((_) async => 0);

        expect(() => repository.updateBookmark(testBookmark), throwsException);
      });

      test('throws exception on database error', () async {
        when(
          mockDatabase.update(
            BookmarksTable.tableName,
            any,
            where: '${BookmarksTable.columnId} = ?',
            whereArgs: ['bookmark-123'],
          ),
        ).thenThrow(Exception('Database error'));

        expect(() => repository.updateBookmark(testBookmark), throwsException);
      });
    });

    group('edge cases', () {
      test('handles bookmark with null chapterId', () async {
        final bookmarkWithNullChapter = {
          'id': 'bookmark-125',
          'book_id': 'book-456',
          'chapter_id': null,
          'cfi': 'epubcfi(/6/4!/4/2/1:0)',
          'title': 'No Chapter',
          'created_at': testCreatedAt.millisecondsSinceEpoch,
        };

        when(
          mockDatabase.query(
            BookmarksTable.tableName,
            where: '${BookmarksTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            orderBy: '${BookmarksTable.columnCreatedAt} DESC',
          ),
        ).thenAnswer((_) async => [bookmarkWithNullChapter]);

        final result = await repository.getBookmarksForBook('book-456');

        expect(result.first.chapterId, isNull);
      });

      test('handles bookmark with empty title', () async {
        final bookmarkWithEmptyTitle = {...testBookmarkMap, 'title': ''};

        when(
          mockDatabase.query(
            BookmarksTable.tableName,
            where: '${BookmarksTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            orderBy: '${BookmarksTable.columnCreatedAt} DESC',
          ),
        ).thenAnswer((_) async => [bookmarkWithEmptyTitle]);

        final result = await repository.getBookmarksForBook('book-456');

        expect(result.first.title, equals(''));
      });
    });
  });
}
