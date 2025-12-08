import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere/data/database/tables/reading_progress_table.dart';
import 'package:readwhere/data/repositories/reading_progress_repository_impl.dart';
import 'package:readwhere/domain/entities/reading_progress.dart';
import 'package:sqflite/sqflite.dart';

import '../../mocks/mock_repositories.mocks.dart';

void main() {
  group('ReadingProgressRepositoryImpl', () {
    late MockDatabaseHelper mockDatabaseHelper;
    late MockDatabase mockDatabase;
    late ReadingProgressRepositoryImpl repository;

    final testUpdatedAt = DateTime(2024, 1, 15, 10, 30);

    final testProgressMap = {
      'id': 'progress-123',
      'book_id': 'book-456',
      'chapter_id': 'chapter-1',
      'cfi': 'epubcfi(/6/4!/4/2/1:0)',
      'progress': 0.75,
      'updated_at': testUpdatedAt.millisecondsSinceEpoch,
    };

    final testProgress = ReadingProgress(
      id: 'progress-123',
      bookId: 'book-456',
      chapterId: 'chapter-1',
      cfi: 'epubcfi(/6/4!/4/2/1:0)',
      progress: 0.75,
      updatedAt: testUpdatedAt,
    );

    setUp(() {
      mockDatabaseHelper = MockDatabaseHelper();
      mockDatabase = MockDatabase();
      repository = ReadingProgressRepositoryImpl(mockDatabaseHelper);

      when(mockDatabaseHelper.database).thenAnswer((_) async => mockDatabase);
    });

    group('getProgressForBook', () {
      test('returns progress when found', () async {
        when(
          mockDatabase.query(
            ReadingProgressTable.tableName,
            where: '${ReadingProgressTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            limit: 1,
          ),
        ).thenAnswer((_) async => [testProgressMap]);

        final result = await repository.getProgressForBook('book-456');

        expect(result, isNotNull);
        expect(result!.id, equals('progress-123'));
        expect(result.bookId, equals('book-456'));
        expect(result.progress, equals(0.75));
      });

      test('returns null when no progress found', () async {
        when(
          mockDatabase.query(
            ReadingProgressTable.tableName,
            where: '${ReadingProgressTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            limit: 1,
          ),
        ).thenAnswer((_) async => []);

        final result = await repository.getProgressForBook('book-456');

        expect(result, isNull);
      });

      test('throws exception on database error', () async {
        when(
          mockDatabase.query(
            ReadingProgressTable.tableName,
            where: '${ReadingProgressTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            limit: 1,
          ),
        ).thenThrow(Exception('Database error'));

        expect(
          () => repository.getProgressForBook('book-456'),
          throwsException,
        );
      });
    });

    group('saveProgress', () {
      test('inserts new progress when none exists', () async {
        // First query returns empty (no existing progress)
        when(
          mockDatabase.query(
            ReadingProgressTable.tableName,
            where: '${ReadingProgressTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            limit: 1,
          ),
        ).thenAnswer((_) async => []);

        when(
          mockDatabase.insert(
            ReadingProgressTable.tableName,
            any,
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).thenAnswer((_) async => 1);

        final result = await repository.saveProgress(testProgress);

        expect(result.id, equals(testProgress.id));
        verify(
          mockDatabase.insert(
            ReadingProgressTable.tableName,
            any,
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).called(1);
      });

      test('updates existing progress', () async {
        // First query returns existing progress
        when(
          mockDatabase.query(
            ReadingProgressTable.tableName,
            where: '${ReadingProgressTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            limit: 1,
          ),
        ).thenAnswer((_) async => [testProgressMap]);

        when(
          mockDatabase.update(
            ReadingProgressTable.tableName,
            any,
            where: '${ReadingProgressTable.columnBookId} = ?',
            whereArgs: ['book-456'],
          ),
        ).thenAnswer((_) async => 1);

        final updatedProgress = testProgress.copyWith(progress: 0.9);
        final result = await repository.saveProgress(updatedProgress);

        expect(result.progress, equals(0.9));
        verify(
          mockDatabase.update(
            ReadingProgressTable.tableName,
            any,
            where: '${ReadingProgressTable.columnBookId} = ?',
            whereArgs: ['book-456'],
          ),
        ).called(1);
      });

      test('throws exception on database error', () async {
        when(
          mockDatabase.query(
            ReadingProgressTable.tableName,
            where: '${ReadingProgressTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            limit: 1,
          ),
        ).thenThrow(Exception('Database error'));

        expect(() => repository.saveProgress(testProgress), throwsException);
      });
    });

    group('deleteProgressForBook', () {
      test('deletes progress and returns true', () async {
        when(
          mockDatabase.delete(
            ReadingProgressTable.tableName,
            where: '${ReadingProgressTable.columnBookId} = ?',
            whereArgs: ['book-456'],
          ),
        ).thenAnswer((_) async => 1);

        final result = await repository.deleteProgressForBook('book-456');

        expect(result, isTrue);
      });

      test('returns false when no progress found', () async {
        when(
          mockDatabase.delete(
            ReadingProgressTable.tableName,
            where: '${ReadingProgressTable.columnBookId} = ?',
            whereArgs: ['non-existent'],
          ),
        ).thenAnswer((_) async => 0);

        final result = await repository.deleteProgressForBook('non-existent');

        expect(result, isFalse);
      });

      test('throws exception on database error', () async {
        when(
          mockDatabase.delete(
            ReadingProgressTable.tableName,
            where: '${ReadingProgressTable.columnBookId} = ?',
            whereArgs: ['book-456'],
          ),
        ).thenThrow(Exception('Database error'));

        expect(
          () => repository.deleteProgressForBook('book-456'),
          throwsException,
        );
      });
    });

    group('edge cases', () {
      test('handles progress with null chapterId', () async {
        final progressWithNullChapter = {
          'id': 'progress-124',
          'book_id': 'book-456',
          'chapter_id': null,
          'cfi': 'epubcfi(/6/4!/4/2/1:0)',
          'progress': 0.5,
          'updated_at': testUpdatedAt.millisecondsSinceEpoch,
        };

        when(
          mockDatabase.query(
            ReadingProgressTable.tableName,
            where: '${ReadingProgressTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            limit: 1,
          ),
        ).thenAnswer((_) async => [progressWithNullChapter]);

        final result = await repository.getProgressForBook('book-456');

        expect(result!.chapterId, isNull);
      });

      test('handles zero progress', () async {
        final zeroProgressMap = {...testProgressMap, 'progress': 0.0};

        when(
          mockDatabase.query(
            ReadingProgressTable.tableName,
            where: '${ReadingProgressTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            limit: 1,
          ),
        ).thenAnswer((_) async => [zeroProgressMap]);

        final result = await repository.getProgressForBook('book-456');

        expect(result!.progress, equals(0.0));
      });

      test('handles complete progress', () async {
        final completeProgressMap = {...testProgressMap, 'progress': 1.0};

        when(
          mockDatabase.query(
            ReadingProgressTable.tableName,
            where: '${ReadingProgressTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            limit: 1,
          ),
        ).thenAnswer((_) async => [completeProgressMap]);

        final result = await repository.getProgressForBook('book-456');

        expect(result!.progress, equals(1.0));
      });

      test('handles progress as int from database', () async {
        final intProgressMap = {...testProgressMap, 'progress': 1};

        when(
          mockDatabase.query(
            ReadingProgressTable.tableName,
            where: '${ReadingProgressTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            limit: 1,
          ),
        ).thenAnswer((_) async => [intProgressMap]);

        final result = await repository.getProgressForBook('book-456');

        expect(result!.progress, equals(1.0));
        expect(result.progress, isA<double>());
      });

      test('handles empty cfi', () async {
        final emptyCfiMap = {...testProgressMap, 'cfi': ''};

        when(
          mockDatabase.query(
            ReadingProgressTable.tableName,
            where: '${ReadingProgressTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            limit: 1,
          ),
        ).thenAnswer((_) async => [emptyCfiMap]);

        final result = await repository.getProgressForBook('book-456');

        expect(result!.cfi, equals(''));
      });
    });
  });
}
