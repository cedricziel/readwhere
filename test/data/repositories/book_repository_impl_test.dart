import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere/data/database/tables/books_table.dart';
import 'package:readwhere/data/repositories/book_repository_impl.dart';
import 'package:readwhere/domain/entities/book.dart';
import 'package:sqflite/sqflite.dart';

import '../../mocks/mock_repositories.mocks.dart';

void main() {
  group('BookRepositoryImpl', () {
    late MockDatabaseHelper mockDatabaseHelper;
    late MockDatabase mockDatabase;
    late BookRepositoryImpl repository;

    final testAddedAt = DateTime(2024, 1, 15, 10, 30);
    final testLastOpenedAt = DateTime(2024, 1, 20, 15, 45);

    final testBookMap = {
      'id': 'book-123',
      'title': 'Test Book',
      'author': 'Test Author',
      'file_path': '/path/to/book.epub',
      'cover_path': '/path/to/cover.jpg',
      'format': 'epub',
      'file_size': 2048000,
      'added_at': testAddedAt.millisecondsSinceEpoch,
      'last_opened_at': testLastOpenedAt.millisecondsSinceEpoch,
      'is_favorite': 0,
      'encryption_type': 'none',
      'is_fixed_layout': 0,
      'has_media_overlays': 0,
    };

    final testBook = Book(
      id: 'book-123',
      title: 'Test Book',
      author: 'Test Author',
      filePath: '/path/to/book.epub',
      coverPath: '/path/to/cover.jpg',
      format: 'epub',
      fileSize: 2048000,
      addedAt: testAddedAt,
      lastOpenedAt: testLastOpenedAt,
      isFavorite: false,
    );

    setUp(() {
      mockDatabaseHelper = MockDatabaseHelper();
      mockDatabase = MockDatabase();
      repository = BookRepositoryImpl(mockDatabaseHelper);

      when(mockDatabaseHelper.database).thenAnswer((_) async => mockDatabase);
    });

    group('getAll', () {
      test('returns list of books ordered by added_at desc', () async {
        when(
          mockDatabase.query(
            BooksTable.tableName,
            orderBy: '${BooksTable.columnAddedAt} DESC',
          ),
        ).thenAnswer((_) async => [testBookMap]);

        final result = await repository.getAll();

        expect(result, hasLength(1));
        expect(result.first.id, equals('book-123'));
        expect(result.first.title, equals('Test Book'));
        verify(
          mockDatabase.query(
            BooksTable.tableName,
            orderBy: '${BooksTable.columnAddedAt} DESC',
          ),
        ).called(1);
      });

      test('returns empty list when no books exist', () async {
        when(
          mockDatabase.query(
            BooksTable.tableName,
            orderBy: '${BooksTable.columnAddedAt} DESC',
          ),
        ).thenAnswer((_) async => []);

        final result = await repository.getAll();

        expect(result, isEmpty);
      });

      test('throws exception on database error', () async {
        when(
          mockDatabase.query(
            BooksTable.tableName,
            orderBy: '${BooksTable.columnAddedAt} DESC',
          ),
        ).thenThrow(Exception('Database error'));

        expect(() => repository.getAll(), throwsException);
      });
    });

    group('getById', () {
      test('returns book when found', () async {
        when(
          mockDatabase.query(
            BooksTable.tableName,
            where: '${BooksTable.columnId} = ?',
            whereArgs: ['book-123'],
            limit: 1,
          ),
        ).thenAnswer((_) async => [testBookMap]);

        final result = await repository.getById('book-123');

        expect(result, isNotNull);
        expect(result!.id, equals('book-123'));
        expect(result.title, equals('Test Book'));
      });

      test('returns null when book not found', () async {
        when(
          mockDatabase.query(
            BooksTable.tableName,
            where: '${BooksTable.columnId} = ?',
            whereArgs: ['non-existent'],
            limit: 1,
          ),
        ).thenAnswer((_) async => []);

        final result = await repository.getById('non-existent');

        expect(result, isNull);
      });

      test('throws exception on database error', () async {
        when(
          mockDatabase.query(
            BooksTable.tableName,
            where: '${BooksTable.columnId} = ?',
            whereArgs: ['book-123'],
            limit: 1,
          ),
        ).thenThrow(Exception('Database error'));

        expect(() => repository.getById('book-123'), throwsException);
      });
    });

    group('insert', () {
      test('inserts book and returns it', () async {
        when(
          mockDatabase.insert(
            BooksTable.tableName,
            any,
            conflictAlgorithm: ConflictAlgorithm.fail,
          ),
        ).thenAnswer((_) async => 1);

        final result = await repository.insert(testBook);

        expect(result.id, equals(testBook.id));
        verify(
          mockDatabase.insert(
            BooksTable.tableName,
            any,
            conflictAlgorithm: ConflictAlgorithm.fail,
          ),
        ).called(1);
      });

      test('throws exception when book already exists', () async {
        when(
          mockDatabase.insert(
            BooksTable.tableName,
            any,
            conflictAlgorithm: ConflictAlgorithm.fail,
          ),
        ).thenThrow(Exception('UNIQUE constraint failed'));

        expect(() => repository.insert(testBook), throwsException);
      });
    });

    group('update', () {
      test('updates book and returns it', () async {
        when(
          mockDatabase.update(
            BooksTable.tableName,
            any,
            where: '${BooksTable.columnId} = ?',
            whereArgs: ['book-123'],
          ),
        ).thenAnswer((_) async => 1);

        final result = await repository.update(testBook);

        expect(result.id, equals(testBook.id));
        verify(
          mockDatabase.update(
            BooksTable.tableName,
            any,
            where: '${BooksTable.columnId} = ?',
            whereArgs: ['book-123'],
          ),
        ).called(1);
      });

      test('throws exception when book not found', () async {
        when(
          mockDatabase.update(
            BooksTable.tableName,
            any,
            where: '${BooksTable.columnId} = ?',
            whereArgs: ['book-123'],
          ),
        ).thenAnswer((_) async => 0);

        expect(() => repository.update(testBook), throwsException);
      });
    });

    group('delete', () {
      test('deletes book and returns true', () async {
        when(
          mockDatabase.delete(
            BooksTable.tableName,
            where: '${BooksTable.columnId} = ?',
            whereArgs: ['book-123'],
          ),
        ).thenAnswer((_) async => 1);

        final result = await repository.delete('book-123');

        expect(result, isTrue);
      });

      test('returns false when book not found', () async {
        when(
          mockDatabase.delete(
            BooksTable.tableName,
            where: '${BooksTable.columnId} = ?',
            whereArgs: ['non-existent'],
          ),
        ).thenAnswer((_) async => 0);

        final result = await repository.delete('non-existent');

        expect(result, isFalse);
      });

      test('throws exception on database error', () async {
        when(
          mockDatabase.delete(
            BooksTable.tableName,
            where: '${BooksTable.columnId} = ?',
            whereArgs: ['book-123'],
          ),
        ).thenThrow(Exception('Database error'));

        expect(() => repository.delete('book-123'), throwsException);
      });
    });

    group('getRecent', () {
      test('returns recent books with default limit', () async {
        when(
          mockDatabase.query(
            BooksTable.tableName,
            where: '${BooksTable.columnLastOpenedAt} IS NOT NULL',
            orderBy: '${BooksTable.columnLastOpenedAt} DESC',
            limit: 10,
          ),
        ).thenAnswer((_) async => [testBookMap]);

        final result = await repository.getRecent();

        expect(result, hasLength(1));
        expect(result.first.id, equals('book-123'));
      });

      test('returns recent books with custom limit', () async {
        when(
          mockDatabase.query(
            BooksTable.tableName,
            where: '${BooksTable.columnLastOpenedAt} IS NOT NULL',
            orderBy: '${BooksTable.columnLastOpenedAt} DESC',
            limit: 5,
          ),
        ).thenAnswer((_) async => [testBookMap]);

        final result = await repository.getRecent(limit: 5);

        expect(result, hasLength(1));
      });

      test('returns empty list when no recently opened books', () async {
        when(
          mockDatabase.query(
            BooksTable.tableName,
            where: '${BooksTable.columnLastOpenedAt} IS NOT NULL',
            orderBy: '${BooksTable.columnLastOpenedAt} DESC',
            limit: 10,
          ),
        ).thenAnswer((_) async => []);

        final result = await repository.getRecent();

        expect(result, isEmpty);
      });
    });

    group('getFavorites', () {
      test('returns favorite books ordered by title', () async {
        final favoriteBookMap = {...testBookMap, 'is_favorite': 1};
        when(
          mockDatabase.query(
            BooksTable.tableName,
            where: '${BooksTable.columnIsFavorite} = ?',
            whereArgs: [1],
            orderBy: '${BooksTable.columnTitle} ASC',
          ),
        ).thenAnswer((_) async => [favoriteBookMap]);

        final result = await repository.getFavorites();

        expect(result, hasLength(1));
        expect(result.first.isFavorite, isTrue);
      });

      test('returns empty list when no favorites', () async {
        when(
          mockDatabase.query(
            BooksTable.tableName,
            where: '${BooksTable.columnIsFavorite} = ?',
            whereArgs: [1],
            orderBy: '${BooksTable.columnTitle} ASC',
          ),
        ).thenAnswer((_) async => []);

        final result = await repository.getFavorites();

        expect(result, isEmpty);
      });
    });

    group('search', () {
      test('searches by title and author', () async {
        when(
          mockDatabase.query(
            BooksTable.tableName,
            where:
                '${BooksTable.columnTitle} LIKE ? OR ${BooksTable.columnAuthor} LIKE ?',
            whereArgs: ['%test%', '%test%'],
            orderBy: '${BooksTable.columnTitle} ASC',
          ),
        ).thenAnswer((_) async => [testBookMap]);

        final result = await repository.search('test');

        expect(result, hasLength(1));
        expect(result.first.title, equals('Test Book'));
      });

      test('returns empty list for no matches', () async {
        when(
          mockDatabase.query(
            BooksTable.tableName,
            where:
                '${BooksTable.columnTitle} LIKE ? OR ${BooksTable.columnAuthor} LIKE ?',
            whereArgs: ['%xyz%', '%xyz%'],
            orderBy: '${BooksTable.columnTitle} ASC',
          ),
        ).thenAnswer((_) async => []);

        final result = await repository.search('xyz');

        expect(result, isEmpty);
      });
    });

    group('updateLastOpened', () {
      test('updates last opened timestamp', () async {
        when(
          mockDatabase.update(
            BooksTable.tableName,
            any,
            where: '${BooksTable.columnId} = ?',
            whereArgs: ['book-123'],
          ),
        ).thenAnswer((_) async => 1);

        await repository.updateLastOpened('book-123');

        verify(
          mockDatabase.update(
            BooksTable.tableName,
            any,
            where: '${BooksTable.columnId} = ?',
            whereArgs: ['book-123'],
          ),
        ).called(1);
      });

      test('throws exception when book not found', () async {
        when(
          mockDatabase.update(
            BooksTable.tableName,
            any,
            where: '${BooksTable.columnId} = ?',
            whereArgs: ['non-existent'],
          ),
        ).thenAnswer((_) async => 0);

        expect(
          () => repository.updateLastOpened('non-existent'),
          throwsException,
        );
      });
    });

    group('toggleFavorite', () {
      test('toggles favorite from false to true', () async {
        // Setup for getById call
        when(
          mockDatabase.query(
            BooksTable.tableName,
            where: '${BooksTable.columnId} = ?',
            whereArgs: ['book-123'],
            limit: 1,
          ),
        ).thenAnswer((_) async => [testBookMap]); // is_favorite: 0

        // Setup for update call
        when(
          mockDatabase.update(
            BooksTable.tableName,
            {BooksTable.columnIsFavorite: 1},
            where: '${BooksTable.columnId} = ?',
            whereArgs: ['book-123'],
          ),
        ).thenAnswer((_) async => 1);

        final result = await repository.toggleFavorite('book-123');

        expect(result.isFavorite, isTrue);
      });

      test('toggles favorite from true to false', () async {
        final favoriteBookMap = {...testBookMap, 'is_favorite': 1};

        when(
          mockDatabase.query(
            BooksTable.tableName,
            where: '${BooksTable.columnId} = ?',
            whereArgs: ['book-123'],
            limit: 1,
          ),
        ).thenAnswer((_) async => [favoriteBookMap]);

        when(
          mockDatabase.update(
            BooksTable.tableName,
            {BooksTable.columnIsFavorite: 0},
            where: '${BooksTable.columnId} = ?',
            whereArgs: ['book-123'],
          ),
        ).thenAnswer((_) async => 1);

        final result = await repository.toggleFavorite('book-123');

        expect(result.isFavorite, isFalse);
      });

      test('throws exception when book not found', () async {
        when(
          mockDatabase.query(
            BooksTable.tableName,
            where: '${BooksTable.columnId} = ?',
            whereArgs: ['non-existent'],
            limit: 1,
          ),
        ).thenAnswer((_) async => []);

        expect(
          () => repository.toggleFavorite('non-existent'),
          throwsException,
        );
      });
    });
  });
}
