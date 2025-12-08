import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/domain/entities/reading_progress.dart';

void main() {
  group('ReadingProgress', () {
    final testDate = DateTime(2024, 1, 1, 12, 0, 0);

    ReadingProgress createTestProgress({
      String id = 'progress-1',
      String bookId = 'book-1',
      String? chapterId,
      String cfi = 'epubcfi(/6/4[chap01]!/4/2/1:0)',
      double progress = 0.5,
      DateTime? updatedAt,
    }) {
      return ReadingProgress(
        id: id,
        bookId: bookId,
        chapterId: chapterId,
        cfi: cfi,
        progress: progress,
        updatedAt: updatedAt ?? testDate,
      );
    }

    group('constructor', () {
      test('creates progress with required fields', () {
        final progress = createTestProgress();

        expect(progress.id, equals('progress-1'));
        expect(progress.bookId, equals('book-1'));
        expect(progress.cfi, equals('epubcfi(/6/4[chap01]!/4/2/1:0)'));
        expect(progress.progress, equals(0.5));
        expect(progress.updatedAt, equals(testDate));
      });

      test('creates progress with optional chapterId', () {
        final progress = createTestProgress(chapterId: 'chapter-1');

        expect(progress.chapterId, equals('chapter-1'));
      });

      test('chapterId defaults to null', () {
        final progress = createTestProgress();

        expect(progress.chapterId, isNull);
      });

      test('accepts valid progress of 0.0', () {
        final progress = createTestProgress(progress: 0.0);
        expect(progress.progress, equals(0.0));
      });

      test('accepts valid progress of 1.0', () {
        final progress = createTestProgress(progress: 1.0);
        expect(progress.progress, equals(1.0));
      });

      test('accepts valid progress between 0 and 1', () {
        final progress = createTestProgress(progress: 0.75);
        expect(progress.progress, equals(0.75));
      });

      test('throws assertion error for progress < 0', () {
        expect(
          () => createTestProgress(progress: -0.1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error for progress > 1', () {
        expect(
          () => createTestProgress(progress: 1.1),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('copyWith', () {
      test('creates new instance with changed fields', () {
        final progress = createTestProgress();
        final newDate = DateTime(2024, 6, 15);

        final updated = progress.copyWith(progress: 0.75, updatedAt: newDate);

        expect(updated.progress, equals(0.75));
        expect(updated.updatedAt, equals(newDate));
      });

      test('preserves unchanged fields', () {
        final progress = createTestProgress(chapterId: 'chapter-1');

        final updated = progress.copyWith(progress: 0.9);

        expect(updated.id, equals(progress.id));
        expect(updated.bookId, equals(progress.bookId));
        expect(updated.chapterId, equals(progress.chapterId));
        expect(updated.cfi, equals(progress.cfi));
      });

      test('can update all fields', () {
        final progress = createTestProgress();
        final newDate = DateTime(2024, 12, 31);

        final updated = progress.copyWith(
          id: 'progress-2',
          bookId: 'book-2',
          chapterId: 'chapter-2',
          cfi: 'epubcfi(/6/8[chap02]!/4/2/1:0)',
          progress: 1.0,
          updatedAt: newDate,
        );

        expect(updated.id, equals('progress-2'));
        expect(updated.bookId, equals('book-2'));
        expect(updated.chapterId, equals('chapter-2'));
        expect(updated.cfi, equals('epubcfi(/6/8[chap02]!/4/2/1:0)'));
        expect(updated.progress, equals(1.0));
        expect(updated.updatedAt, equals(newDate));
      });
    });

    group('equality', () {
      test('equals same progress with identical properties', () {
        final progress1 = createTestProgress();
        final progress2 = createTestProgress();

        expect(progress1, equals(progress2));
      });

      test('not equals progress with different id', () {
        final progress1 = createTestProgress(id: 'progress-1');
        final progress2 = createTestProgress(id: 'progress-2');

        expect(progress1, isNot(equals(progress2)));
      });

      test('not equals progress with different progress value', () {
        final progress1 = createTestProgress(progress: 0.5);
        final progress2 = createTestProgress(progress: 0.7);

        expect(progress1, isNot(equals(progress2)));
      });

      test('hashCode is equal for equal progress', () {
        final progress1 = createTestProgress();
        final progress2 = createTestProgress();

        expect(progress1.hashCode, equals(progress2.hashCode));
      });
    });

    group('toString', () {
      test('includes bookId, progress, cfi, updatedAt', () {
        final progress = createTestProgress();
        final str = progress.toString();

        expect(str, contains('bookId: book-1'));
        expect(str, contains('progress: 0.50'));
        expect(str, contains('cfi:'));
        expect(str, contains('updatedAt:'));
      });
    });
  });
}
