import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/domain/entities/annotation.dart';

void main() {
  group('Annotation', () {
    final testDate = DateTime(2024, 1, 1, 12, 0, 0);

    Annotation createTestAnnotation({
      String id = 'annotation-1',
      String bookId = 'book-1',
      String? chapterId,
      String cfiStart = 'epubcfi(/6/4[chap01]!/4/2/1:0)',
      String cfiEnd = 'epubcfi(/6/4[chap01]!/4/2/1:50)',
      String text = 'This is the highlighted text.',
      String? note,
      AnnotationColor color = AnnotationColor.yellow,
      DateTime? createdAt,
    }) {
      return Annotation(
        id: id,
        bookId: bookId,
        chapterId: chapterId,
        cfiStart: cfiStart,
        cfiEnd: cfiEnd,
        text: text,
        note: note,
        color: color,
        createdAt: createdAt ?? testDate,
      );
    }

    group('constructor', () {
      test('creates annotation with required fields', () {
        final annotation = createTestAnnotation();

        expect(annotation.id, equals('annotation-1'));
        expect(annotation.bookId, equals('book-1'));
        expect(annotation.cfiStart, equals('epubcfi(/6/4[chap01]!/4/2/1:0)'));
        expect(annotation.cfiEnd, equals('epubcfi(/6/4[chap01]!/4/2/1:50)'));
        expect(annotation.text, equals('This is the highlighted text.'));
        expect(annotation.color, equals(AnnotationColor.yellow));
        expect(annotation.createdAt, equals(testDate));
      });

      test('creates annotation with optional fields', () {
        final annotation = createTestAnnotation(
          chapterId: 'chapter-1',
          note: 'This is my note',
        );

        expect(annotation.chapterId, equals('chapter-1'));
        expect(annotation.note, equals('This is my note'));
      });

      test('optional fields default to null', () {
        final annotation = createTestAnnotation();

        expect(annotation.chapterId, isNull);
        expect(annotation.note, isNull);
      });
    });

    group('copyWith', () {
      test('creates new instance with changed fields', () {
        final annotation = createTestAnnotation();
        final newDate = DateTime(2024, 6, 15);

        final updated = annotation.copyWith(
          text: 'New highlighted text',
          color: AnnotationColor.blue,
          createdAt: newDate,
        );

        expect(updated.text, equals('New highlighted text'));
        expect(updated.color, equals(AnnotationColor.blue));
        expect(updated.createdAt, equals(newDate));
      });

      test('preserves unchanged fields', () {
        final annotation = createTestAnnotation(
          chapterId: 'chapter-1',
          note: 'My note',
        );

        final updated = annotation.copyWith(color: AnnotationColor.green);

        expect(updated.id, equals(annotation.id));
        expect(updated.bookId, equals(annotation.bookId));
        expect(updated.chapterId, equals(annotation.chapterId));
        expect(updated.cfiStart, equals(annotation.cfiStart));
        expect(updated.cfiEnd, equals(annotation.cfiEnd));
        expect(updated.text, equals(annotation.text));
        expect(updated.note, equals(annotation.note));
        expect(updated.createdAt, equals(annotation.createdAt));
      });

      test('can update all fields', () {
        final annotation = createTestAnnotation();
        final newDate = DateTime(2024, 12, 31);

        final updated = annotation.copyWith(
          id: 'annotation-2',
          bookId: 'book-2',
          chapterId: 'chapter-2',
          cfiStart: 'epubcfi(/6/8[chap02]!/4/2/1:0)',
          cfiEnd: 'epubcfi(/6/8[chap02]!/4/2/1:100)',
          text: 'Updated text',
          note: 'Updated note',
          color: AnnotationColor.purple,
          createdAt: newDate,
        );

        expect(updated.id, equals('annotation-2'));
        expect(updated.bookId, equals('book-2'));
        expect(updated.chapterId, equals('chapter-2'));
        expect(updated.cfiStart, equals('epubcfi(/6/8[chap02]!/4/2/1:0)'));
        expect(updated.cfiEnd, equals('epubcfi(/6/8[chap02]!/4/2/1:100)'));
        expect(updated.text, equals('Updated text'));
        expect(updated.note, equals('Updated note'));
        expect(updated.color, equals(AnnotationColor.purple));
        expect(updated.createdAt, equals(newDate));
      });
    });

    group('equality', () {
      test('equals same annotation with identical properties', () {
        final annotation1 = createTestAnnotation();
        final annotation2 = createTestAnnotation();

        expect(annotation1, equals(annotation2));
      });

      test('not equals annotation with different id', () {
        final annotation1 = createTestAnnotation(id: 'annotation-1');
        final annotation2 = createTestAnnotation(id: 'annotation-2');

        expect(annotation1, isNot(equals(annotation2)));
      });

      test('not equals annotation with different color', () {
        final annotation1 = createTestAnnotation(color: AnnotationColor.yellow);
        final annotation2 = createTestAnnotation(color: AnnotationColor.blue);

        expect(annotation1, isNot(equals(annotation2)));
      });

      test('hashCode is equal for equal annotations', () {
        final annotation1 = createTestAnnotation();
        final annotation2 = createTestAnnotation();

        expect(annotation1.hashCode, equals(annotation2.hashCode));
      });
    });

    group('toString', () {
      test('includes id, bookId, color', () {
        final annotation = createTestAnnotation();
        final str = annotation.toString();

        expect(str, contains('id: annotation-1'));
        expect(str, contains('bookId: book-1'));
        expect(str, contains('color: AnnotationColor.yellow'));
      });

      test('truncates text longer than 50 chars', () {
        final longText =
            'This is a very long highlighted text that should be truncated '
            'because it exceeds fifty characters.';
        final annotation = createTestAnnotation(text: longText);
        final str = annotation.toString();

        expect(str, contains('...'));
        expect(str.length, lessThan(longText.length + 100));
      });

      test('shows full text when 50 chars or less', () {
        final shortText = 'Short text';
        final annotation = createTestAnnotation(text: shortText);
        final str = annotation.toString();

        expect(str, contains('text: "Short text"'));
        expect(str, isNot(contains('...')));
      });
    });

    group('AnnotationColor enum', () {
      test('has yellow color', () {
        expect(AnnotationColor.values, contains(AnnotationColor.yellow));
      });

      test('has green color', () {
        expect(AnnotationColor.values, contains(AnnotationColor.green));
      });

      test('has blue color', () {
        expect(AnnotationColor.values, contains(AnnotationColor.blue));
      });

      test('has pink color', () {
        expect(AnnotationColor.values, contains(AnnotationColor.pink));
      });

      test('has purple color', () {
        expect(AnnotationColor.values, contains(AnnotationColor.purple));
      });

      test('has orange color', () {
        expect(AnnotationColor.values, contains(AnnotationColor.orange));
      });

      test('has exactly 6 colors', () {
        expect(AnnotationColor.values.length, equals(6));
      });
    });
  });
}
