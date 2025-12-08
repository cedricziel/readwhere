import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/data/models/reading_progress_model.dart';
import 'package:readwhere/domain/entities/reading_progress.dart';

void main() {
  group('ReadingProgressModel', () {
    final testUpdatedAt = DateTime(2024, 1, 15, 10, 30);

    group('constructor', () {
      test('creates reading progress model with all fields', () {
        final model = ReadingProgressModel(
          id: 'progress-123',
          bookId: 'book-456',
          chapterId: 'chapter-1',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          progress: 0.75,
          updatedAt: testUpdatedAt,
        );

        expect(model.id, equals('progress-123'));
        expect(model.bookId, equals('book-456'));
        expect(model.chapterId, equals('chapter-1'));
        expect(model.cfi, equals('epubcfi(/6/4!/4/2/1:0)'));
        expect(model.progress, equals(0.75));
        expect(model.updatedAt, equals(testUpdatedAt));
      });

      test(
        'creates reading progress model with nullable chapterId as null',
        () {
          final model = ReadingProgressModel(
            id: 'progress-123',
            bookId: 'book-456',
            cfi: 'epubcfi(/6/4!/4/2/1:0)',
            progress: 0.5,
            updatedAt: testUpdatedAt,
          );

          expect(model.chapterId, isNull);
        },
      );
    });

    group('fromMap', () {
      test('parses all fields correctly', () {
        final map = {
          'id': 'progress-123',
          'book_id': 'book-456',
          'chapter_id': 'chapter-1',
          'cfi': 'epubcfi(/6/4!/4/2/1:0)',
          'progress': 0.75,
          'updated_at': testUpdatedAt.millisecondsSinceEpoch,
        };

        final model = ReadingProgressModel.fromMap(map);

        expect(model.id, equals('progress-123'));
        expect(model.bookId, equals('book-456'));
        expect(model.chapterId, equals('chapter-1'));
        expect(model.cfi, equals('epubcfi(/6/4!/4/2/1:0)'));
        expect(model.progress, equals(0.75));
        expect(
          model.updatedAt.millisecondsSinceEpoch,
          equals(testUpdatedAt.millisecondsSinceEpoch),
        );
      });

      test('parses null chapterId', () {
        final map = {
          'id': 'progress-123',
          'book_id': 'book-456',
          'chapter_id': null,
          'cfi': 'epubcfi(/6/4!/4/2/1:0)',
          'progress': 0.5,
          'updated_at': testUpdatedAt.millisecondsSinceEpoch,
        };

        final model = ReadingProgressModel.fromMap(map);
        expect(model.chapterId, isNull);
      });

      test('handles missing optional fields', () {
        final map = {
          'id': 'progress-123',
          'book_id': 'book-456',
          'cfi': 'epubcfi(/6/4!/4/2/1:0)',
          'progress': 0.5,
          'updated_at': testUpdatedAt.millisecondsSinceEpoch,
        };

        final model = ReadingProgressModel.fromMap(map);
        expect(model.chapterId, isNull);
      });

      test('handles null cfi with empty string default', () {
        final map = {
          'id': 'progress-123',
          'book_id': 'book-456',
          'cfi': null,
          'progress': 0.5,
          'updated_at': testUpdatedAt.millisecondsSinceEpoch,
        };

        final model = ReadingProgressModel.fromMap(map);
        expect(model.cfi, equals(''));
      });

      test('parses progress as double from int', () {
        final map = {
          'id': 'progress-123',
          'book_id': 'book-456',
          'cfi': 'epubcfi(/6/4!/4/2/1:0)',
          'progress': 1, // int instead of double
          'updated_at': testUpdatedAt.millisecondsSinceEpoch,
        };

        final model = ReadingProgressModel.fromMap(map);

        expect(model.progress, equals(1.0));
        expect(model.progress, isA<double>());
      });

      test('parses zero progress', () {
        final map = {
          'id': 'progress-123',
          'book_id': 'book-456',
          'cfi': 'epubcfi(/6/4!/4/2/1:0)',
          'progress': 0.0,
          'updated_at': testUpdatedAt.millisecondsSinceEpoch,
        };

        final model = ReadingProgressModel.fromMap(map);
        expect(model.progress, equals(0.0));
      });

      test('parses full progress', () {
        final map = {
          'id': 'progress-123',
          'book_id': 'book-456',
          'cfi': 'epubcfi(/6/4!/4/2/1:0)',
          'progress': 1.0,
          'updated_at': testUpdatedAt.millisecondsSinceEpoch,
        };

        final model = ReadingProgressModel.fromMap(map);
        expect(model.progress, equals(1.0));
      });
    });

    group('toMap', () {
      test('serializes all fields correctly', () {
        final model = ReadingProgressModel(
          id: 'progress-123',
          bookId: 'book-456',
          chapterId: 'chapter-1',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          progress: 0.75,
          updatedAt: testUpdatedAt,
        );

        final map = model.toMap();

        expect(map['id'], equals('progress-123'));
        expect(map['book_id'], equals('book-456'));
        expect(map['chapter_id'], equals('chapter-1'));
        expect(map['cfi'], equals('epubcfi(/6/4!/4/2/1:0)'));
        expect(map['progress'], equals(0.75));
        expect(map['updated_at'], equals(testUpdatedAt.millisecondsSinceEpoch));
      });

      test('serializes null chapterId', () {
        final model = ReadingProgressModel(
          id: 'progress-123',
          bookId: 'book-456',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          progress: 0.5,
          updatedAt: testUpdatedAt,
        );

        final map = model.toMap();
        expect(map['chapter_id'], isNull);
      });

      test('serializes extreme progress values', () {
        final modelZero = ReadingProgressModel(
          id: 'progress-1',
          bookId: 'book-1',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          progress: 0.0,
          updatedAt: testUpdatedAt,
        );

        final modelComplete = ReadingProgressModel(
          id: 'progress-2',
          bookId: 'book-2',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          progress: 1.0,
          updatedAt: testUpdatedAt,
        );

        expect(modelZero.toMap()['progress'], equals(0.0));
        expect(modelComplete.toMap()['progress'], equals(1.0));
      });

      test('serializes empty cfi', () {
        final model = ReadingProgressModel(
          id: 'progress-123',
          bookId: 'book-456',
          cfi: '',
          progress: 0.5,
          updatedAt: testUpdatedAt,
        );

        final map = model.toMap();
        expect(map['cfi'], equals(''));
      });
    });

    group('fromEntity', () {
      test('converts ReadingProgress entity to ReadingProgressModel', () {
        final progress = ReadingProgress(
          id: 'progress-123',
          bookId: 'book-456',
          chapterId: 'chapter-1',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          progress: 0.75,
          updatedAt: testUpdatedAt,
        );

        final model = ReadingProgressModel.fromEntity(progress);

        expect(model.id, equals(progress.id));
        expect(model.bookId, equals(progress.bookId));
        expect(model.chapterId, equals(progress.chapterId));
        expect(model.cfi, equals(progress.cfi));
        expect(model.progress, equals(progress.progress));
        expect(model.updatedAt, equals(progress.updatedAt));
      });

      test('converts ReadingProgress entity with null chapterId', () {
        final progress = ReadingProgress(
          id: 'progress-123',
          bookId: 'book-456',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          progress: 0.5,
          updatedAt: testUpdatedAt,
        );

        final model = ReadingProgressModel.fromEntity(progress);
        expect(model.chapterId, isNull);
      });
    });

    group('toEntity', () {
      test('converts ReadingProgressModel to ReadingProgress entity', () {
        final model = ReadingProgressModel(
          id: 'progress-123',
          bookId: 'book-456',
          chapterId: 'chapter-1',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          progress: 0.75,
          updatedAt: testUpdatedAt,
        );

        final progress = model.toEntity();

        expect(progress.id, equals(model.id));
        expect(progress.bookId, equals(model.bookId));
        expect(progress.chapterId, equals(model.chapterId));
        expect(progress.cfi, equals(model.cfi));
        expect(progress.progress, equals(model.progress));
        expect(progress.updatedAt, equals(model.updatedAt));
      });

      test('converts ReadingProgressModel with null chapterId', () {
        final model = ReadingProgressModel(
          id: 'progress-123',
          bookId: 'book-456',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          progress: 0.5,
          updatedAt: testUpdatedAt,
        );

        final progress = model.toEntity();
        expect(progress.chapterId, isNull);
      });
    });

    group('round-trip', () {
      test('toMap then fromMap preserves all data', () {
        final original = ReadingProgressModel(
          id: 'progress-123',
          bookId: 'book-456',
          chapterId: 'chapter-1',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          progress: 0.75,
          updatedAt: testUpdatedAt,
        );

        final map = original.toMap();
        final restored = ReadingProgressModel.fromMap(map);

        expect(restored.id, equals(original.id));
        expect(restored.bookId, equals(original.bookId));
        expect(restored.chapterId, equals(original.chapterId));
        expect(restored.cfi, equals(original.cfi));
        expect(restored.progress, equals(original.progress));
        expect(
          restored.updatedAt.millisecondsSinceEpoch,
          equals(original.updatedAt.millisecondsSinceEpoch),
        );
      });

      test('fromEntity then toEntity preserves all data', () {
        final original = ReadingProgress(
          id: 'progress-123',
          bookId: 'book-456',
          chapterId: 'chapter-1',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          progress: 0.75,
          updatedAt: testUpdatedAt,
        );

        final model = ReadingProgressModel.fromEntity(original);
        final restored = model.toEntity();

        expect(restored, equals(original));
      });

      test('handles precision in progress values', () {
        final original = ReadingProgressModel(
          id: 'progress-123',
          bookId: 'book-456',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          progress: 0.123456789,
          updatedAt: testUpdatedAt,
        );

        final map = original.toMap();
        final restored = ReadingProgressModel.fromMap(map);

        expect(restored.progress, equals(original.progress));
      });

      test('round-trip with null chapterId', () {
        final original = ReadingProgressModel(
          id: 'progress-123',
          bookId: 'book-456',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
          progress: 0.5,
          updatedAt: testUpdatedAt,
        );

        final map = original.toMap();
        final restored = ReadingProgressModel.fromMap(map);

        expect(restored.chapterId, isNull);
      });
    });
  });
}
