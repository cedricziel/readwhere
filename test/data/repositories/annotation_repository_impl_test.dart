import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere/data/database/tables/annotations_table.dart';
import 'package:readwhere/data/repositories/annotation_repository_impl.dart';
import 'package:readwhere/domain/entities/annotation.dart';
import 'package:sqflite/sqflite.dart';

import '../../mocks/mock_repositories.mocks.dart';

void main() {
  group('AnnotationRepositoryImpl', () {
    late MockDatabaseHelper mockDatabaseHelper;
    late MockDatabase mockDatabase;
    late AnnotationRepositoryImpl repository;

    final testCreatedAt = DateTime(2024, 1, 15, 10, 30);

    final testAnnotationMap = {
      'id': 'annotation-123',
      'book_id': 'book-456',
      'chapter_id': 'chapter-1',
      'cfi_start': 'epubcfi(/6/4!/4/2/1:0)',
      'cfi_end': 'epubcfi(/6/4!/4/2/1:50)',
      'text': 'This is highlighted text',
      'note': 'My note about this passage',
      'color': 'yellow',
      'created_at': testCreatedAt.millisecondsSinceEpoch,
    };

    final testAnnotation = Annotation(
      id: 'annotation-123',
      bookId: 'book-456',
      chapterId: 'chapter-1',
      cfiStart: 'epubcfi(/6/4!/4/2/1:0)',
      cfiEnd: 'epubcfi(/6/4!/4/2/1:50)',
      text: 'This is highlighted text',
      note: 'My note about this passage',
      color: AnnotationColor.yellow,
      createdAt: testCreatedAt,
    );

    setUp(() {
      mockDatabaseHelper = MockDatabaseHelper();
      mockDatabase = MockDatabase();
      repository = AnnotationRepositoryImpl(mockDatabaseHelper);

      when(mockDatabaseHelper.database).thenAnswer((_) async => mockDatabase);
    });

    group('getAnnotationsForBook', () {
      test('returns annotations for book ordered by created_at desc', () async {
        when(
          mockDatabase.query(
            AnnotationsTable.tableName,
            where: '${AnnotationsTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            orderBy: '${AnnotationsTable.columnCreatedAt} DESC',
          ),
        ).thenAnswer((_) async => [testAnnotationMap]);

        final result = await repository.getAnnotationsForBook('book-456');

        expect(result, hasLength(1));
        expect(result.first.id, equals('annotation-123'));
        expect(result.first.bookId, equals('book-456'));
        expect(result.first.text, equals('This is highlighted text'));
        expect(result.first.color, equals(AnnotationColor.yellow));
      });

      test('returns empty list when no annotations for book', () async {
        when(
          mockDatabase.query(
            AnnotationsTable.tableName,
            where: '${AnnotationsTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            orderBy: '${AnnotationsTable.columnCreatedAt} DESC',
          ),
        ).thenAnswer((_) async => []);

        final result = await repository.getAnnotationsForBook('book-456');

        expect(result, isEmpty);
      });

      test('returns multiple annotations', () async {
        final annotation2Map = {
          'id': 'annotation-124',
          'book_id': 'book-456',
          'chapter_id': 'chapter-2',
          'cfi_start': 'epubcfi(/6/6!/4/2/1:0)',
          'cfi_end': 'epubcfi(/6/6!/4/2/1:30)',
          'text': 'Another highlight',
          'note': null,
          'color': 'blue',
          'created_at': testCreatedAt.millisecondsSinceEpoch,
        };

        when(
          mockDatabase.query(
            AnnotationsTable.tableName,
            where: '${AnnotationsTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            orderBy: '${AnnotationsTable.columnCreatedAt} DESC',
          ),
        ).thenAnswer((_) async => [testAnnotationMap, annotation2Map]);

        final result = await repository.getAnnotationsForBook('book-456');

        expect(result, hasLength(2));
      });

      test('throws exception on database error', () async {
        when(
          mockDatabase.query(
            AnnotationsTable.tableName,
            where: '${AnnotationsTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            orderBy: '${AnnotationsTable.columnCreatedAt} DESC',
          ),
        ).thenThrow(Exception('Database error'));

        expect(
          () => repository.getAnnotationsForBook('book-456'),
          throwsException,
        );
      });
    });

    group('getAnnotationsForChapter', () {
      test('returns annotations for chapter ordered by cfi_start', () async {
        when(
          mockDatabase.query(
            AnnotationsTable.tableName,
            where:
                '${AnnotationsTable.columnBookId} = ? AND ${AnnotationsTable.columnChapterId} = ?',
            whereArgs: ['book-456', 'chapter-1'],
            orderBy: '${AnnotationsTable.columnCfiStart} ASC',
          ),
        ).thenAnswer((_) async => [testAnnotationMap]);

        final result = await repository.getAnnotationsForChapter(
          'book-456',
          'chapter-1',
        );

        expect(result, hasLength(1));
        expect(result.first.chapterId, equals('chapter-1'));
      });

      test('returns empty list when no annotations for chapter', () async {
        when(
          mockDatabase.query(
            AnnotationsTable.tableName,
            where:
                '${AnnotationsTable.columnBookId} = ? AND ${AnnotationsTable.columnChapterId} = ?',
            whereArgs: ['book-456', 'chapter-1'],
            orderBy: '${AnnotationsTable.columnCfiStart} ASC',
          ),
        ).thenAnswer((_) async => []);

        final result = await repository.getAnnotationsForChapter(
          'book-456',
          'chapter-1',
        );

        expect(result, isEmpty);
      });

      test('throws exception on database error', () async {
        when(
          mockDatabase.query(
            AnnotationsTable.tableName,
            where:
                '${AnnotationsTable.columnBookId} = ? AND ${AnnotationsTable.columnChapterId} = ?',
            whereArgs: ['book-456', 'chapter-1'],
            orderBy: '${AnnotationsTable.columnCfiStart} ASC',
          ),
        ).thenThrow(Exception('Database error'));

        expect(
          () => repository.getAnnotationsForChapter('book-456', 'chapter-1'),
          throwsException,
        );
      });
    });

    group('addAnnotation', () {
      test('adds annotation and returns it', () async {
        when(
          mockDatabase.insert(
            AnnotationsTable.tableName,
            any,
            conflictAlgorithm: ConflictAlgorithm.fail,
          ),
        ).thenAnswer((_) async => 1);

        final result = await repository.addAnnotation(testAnnotation);

        expect(result.id, equals(testAnnotation.id));
        expect(result.bookId, equals(testAnnotation.bookId));
        expect(result.text, equals(testAnnotation.text));
        verify(
          mockDatabase.insert(
            AnnotationsTable.tableName,
            any,
            conflictAlgorithm: ConflictAlgorithm.fail,
          ),
        ).called(1);
      });

      test('throws exception on insert failure', () async {
        when(
          mockDatabase.insert(
            AnnotationsTable.tableName,
            any,
            conflictAlgorithm: ConflictAlgorithm.fail,
          ),
        ).thenThrow(Exception('Insert failed'));

        expect(() => repository.addAnnotation(testAnnotation), throwsException);
      });
    });

    group('deleteAnnotation', () {
      test('deletes annotation and returns true', () async {
        when(
          mockDatabase.delete(
            AnnotationsTable.tableName,
            where: '${AnnotationsTable.columnId} = ?',
            whereArgs: ['annotation-123'],
          ),
        ).thenAnswer((_) async => 1);

        final result = await repository.deleteAnnotation('annotation-123');

        expect(result, isTrue);
      });

      test('returns false when annotation not found', () async {
        when(
          mockDatabase.delete(
            AnnotationsTable.tableName,
            where: '${AnnotationsTable.columnId} = ?',
            whereArgs: ['non-existent'],
          ),
        ).thenAnswer((_) async => 0);

        final result = await repository.deleteAnnotation('non-existent');

        expect(result, isFalse);
      });

      test('throws exception on database error', () async {
        when(
          mockDatabase.delete(
            AnnotationsTable.tableName,
            where: '${AnnotationsTable.columnId} = ?',
            whereArgs: ['annotation-123'],
          ),
        ).thenThrow(Exception('Database error'));

        expect(
          () => repository.deleteAnnotation('annotation-123'),
          throwsException,
        );
      });
    });

    group('updateAnnotation', () {
      test('updates annotation and returns it', () async {
        when(
          mockDatabase.update(
            AnnotationsTable.tableName,
            any,
            where: '${AnnotationsTable.columnId} = ?',
            whereArgs: ['annotation-123'],
          ),
        ).thenAnswer((_) async => 1);

        final updatedAnnotation = testAnnotation.copyWith(
          note: 'Updated note',
          color: AnnotationColor.blue,
        );
        final result = await repository.updateAnnotation(updatedAnnotation);

        expect(result.id, equals(updatedAnnotation.id));
        expect(result.note, equals('Updated note'));
        expect(result.color, equals(AnnotationColor.blue));
      });

      test('throws exception when annotation not found', () async {
        when(
          mockDatabase.update(
            AnnotationsTable.tableName,
            any,
            where: '${AnnotationsTable.columnId} = ?',
            whereArgs: ['annotation-123'],
          ),
        ).thenAnswer((_) async => 0);

        expect(
          () => repository.updateAnnotation(testAnnotation),
          throwsException,
        );
      });

      test('throws exception on database error', () async {
        when(
          mockDatabase.update(
            AnnotationsTable.tableName,
            any,
            where: '${AnnotationsTable.columnId} = ?',
            whereArgs: ['annotation-123'],
          ),
        ).thenThrow(Exception('Database error'));

        expect(
          () => repository.updateAnnotation(testAnnotation),
          throwsException,
        );
      });
    });

    group('deleteAnnotationsForBook', () {
      test('deletes all annotations for book and returns count', () async {
        when(
          mockDatabase.delete(
            AnnotationsTable.tableName,
            where: '${AnnotationsTable.columnBookId} = ?',
            whereArgs: ['book-456'],
          ),
        ).thenAnswer((_) async => 5);

        final result = await repository.deleteAnnotationsForBook('book-456');

        expect(result, equals(5));
      });

      test('returns 0 when no annotations to delete', () async {
        when(
          mockDatabase.delete(
            AnnotationsTable.tableName,
            where: '${AnnotationsTable.columnBookId} = ?',
            whereArgs: ['book-456'],
          ),
        ).thenAnswer((_) async => 0);

        final result = await repository.deleteAnnotationsForBook('book-456');

        expect(result, equals(0));
      });

      test('throws exception on database error', () async {
        when(
          mockDatabase.delete(
            AnnotationsTable.tableName,
            where: '${AnnotationsTable.columnBookId} = ?',
            whereArgs: ['book-456'],
          ),
        ).thenThrow(Exception('Database error'));

        expect(
          () => repository.deleteAnnotationsForBook('book-456'),
          throwsException,
        );
      });
    });

    group('edge cases', () {
      test('handles annotation with null chapterId', () async {
        final annotationWithNullChapter = {
          ...testAnnotationMap,
          'chapter_id': null,
        };

        when(
          mockDatabase.query(
            AnnotationsTable.tableName,
            where: '${AnnotationsTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            orderBy: '${AnnotationsTable.columnCreatedAt} DESC',
          ),
        ).thenAnswer((_) async => [annotationWithNullChapter]);

        final result = await repository.getAnnotationsForBook('book-456');

        expect(result.first.chapterId, isNull);
      });

      test('handles annotation with null note', () async {
        final annotationWithNullNote = {...testAnnotationMap, 'note': null};

        when(
          mockDatabase.query(
            AnnotationsTable.tableName,
            where: '${AnnotationsTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            orderBy: '${AnnotationsTable.columnCreatedAt} DESC',
          ),
        ).thenAnswer((_) async => [annotationWithNullNote]);

        final result = await repository.getAnnotationsForBook('book-456');

        expect(result.first.note, isNull);
      });

      test('handles annotation with empty text', () async {
        final annotationWithEmptyText = {...testAnnotationMap, 'text': ''};

        when(
          mockDatabase.query(
            AnnotationsTable.tableName,
            where: '${AnnotationsTable.columnBookId} = ?',
            whereArgs: ['book-456'],
            orderBy: '${AnnotationsTable.columnCreatedAt} DESC',
          ),
        ).thenAnswer((_) async => [annotationWithEmptyText]);

        final result = await repository.getAnnotationsForBook('book-456');

        expect(result.first.text, equals(''));
      });

      test('handles all annotation colors', () async {
        for (final color in AnnotationColor.values) {
          final annotationMap = {
            ...testAnnotationMap,
            'id': 'annotation-${color.name}',
            'color': color.name,
          };

          when(
            mockDatabase.query(
              AnnotationsTable.tableName,
              where: '${AnnotationsTable.columnBookId} = ?',
              whereArgs: ['book-456'],
              orderBy: '${AnnotationsTable.columnCreatedAt} DESC',
            ),
          ).thenAnswer((_) async => [annotationMap]);

          final result = await repository.getAnnotationsForBook('book-456');

          expect(result.first.color, equals(color));
        }
      });
    });
  });
}
