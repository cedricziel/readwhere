import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/data/models/annotation_model.dart';
import 'package:readwhere/domain/entities/annotation.dart';

void main() {
  group('AnnotationModel', () {
    final testCreatedAt = DateTime(2024, 1, 15, 10, 30);

    group('constructor', () {
      test('creates annotation model with all fields', () {
        final model = AnnotationModel(
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

        expect(model.id, equals('annotation-123'));
        expect(model.bookId, equals('book-456'));
        expect(model.chapterId, equals('chapter-1'));
        expect(model.cfiStart, equals('epubcfi(/6/4!/4/2/1:0)'));
        expect(model.cfiEnd, equals('epubcfi(/6/4!/4/2/1:50)'));
        expect(model.text, equals('This is highlighted text'));
        expect(model.note, equals('My note about this passage'));
        expect(model.color, equals(AnnotationColor.yellow));
        expect(model.createdAt, equals(testCreatedAt));
      });

      test('creates annotation model with nullable fields as null', () {
        final model = AnnotationModel(
          id: 'annotation-123',
          bookId: 'book-456',
          cfiStart: 'epubcfi(/6/4!/4/2/1:0)',
          cfiEnd: 'epubcfi(/6/4!/4/2/1:50)',
          text: 'Highlighted',
          color: AnnotationColor.blue,
          createdAt: testCreatedAt,
        );

        expect(model.chapterId, isNull);
        expect(model.note, isNull);
      });
    });

    group('fromMap', () {
      test('parses all fields correctly', () {
        final map = {
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

        final model = AnnotationModel.fromMap(map);

        expect(model.id, equals('annotation-123'));
        expect(model.bookId, equals('book-456'));
        expect(model.chapterId, equals('chapter-1'));
        expect(model.cfiStart, equals('epubcfi(/6/4!/4/2/1:0)'));
        expect(model.cfiEnd, equals('epubcfi(/6/4!/4/2/1:50)'));
        expect(model.text, equals('This is highlighted text'));
        expect(model.note, equals('My note about this passage'));
        expect(model.color, equals(AnnotationColor.yellow));
        expect(
          model.createdAt.millisecondsSinceEpoch,
          equals(testCreatedAt.millisecondsSinceEpoch),
        );
      });

      test('parses all color values', () {
        for (final color in AnnotationColor.values) {
          final map = {
            'id': 'annotation-123',
            'book_id': 'book-456',
            'cfi_start': '',
            'cfi_end': '',
            'text': 'Text',
            'color': color.name,
            'created_at': testCreatedAt.millisecondsSinceEpoch,
          };

          final model = AnnotationModel.fromMap(map);
          expect(model.color, equals(color));
        }
      });

      test('parses null chapterId', () {
        final map = {
          'id': 'annotation-123',
          'book_id': 'book-456',
          'chapter_id': null,
          'cfi_start': 'epubcfi(/6/4!/4/2/1:0)',
          'cfi_end': 'epubcfi(/6/4!/4/2/1:50)',
          'text': 'Highlighted',
          'color': 'green',
          'created_at': testCreatedAt.millisecondsSinceEpoch,
        };

        final model = AnnotationModel.fromMap(map);
        expect(model.chapterId, isNull);
      });

      test('parses null note', () {
        final map = {
          'id': 'annotation-123',
          'book_id': 'book-456',
          'cfi_start': 'epubcfi(/6/4!/4/2/1:0)',
          'cfi_end': 'epubcfi(/6/4!/4/2/1:50)',
          'text': 'Highlighted',
          'note': null,
          'color': 'blue',
          'created_at': testCreatedAt.millisecondsSinceEpoch,
        };

        final model = AnnotationModel.fromMap(map);
        expect(model.note, isNull);
      });

      test('handles null cfi_start with empty string default', () {
        final map = {
          'id': 'annotation-123',
          'book_id': 'book-456',
          'cfi_start': null,
          'cfi_end': 'epubcfi(/6/4!/4/2/1:50)',
          'text': 'Highlighted',
          'color': 'pink',
          'created_at': testCreatedAt.millisecondsSinceEpoch,
        };

        final model = AnnotationModel.fromMap(map);
        expect(model.cfiStart, equals(''));
      });

      test('handles null cfi_end with empty string default', () {
        final map = {
          'id': 'annotation-123',
          'book_id': 'book-456',
          'cfi_start': 'epubcfi(/6/4!/4/2/1:0)',
          'cfi_end': null,
          'text': 'Highlighted',
          'color': 'purple',
          'created_at': testCreatedAt.millisecondsSinceEpoch,
        };

        final model = AnnotationModel.fromMap(map);
        expect(model.cfiEnd, equals(''));
      });

      test('handles null text with empty string default', () {
        final map = {
          'id': 'annotation-123',
          'book_id': 'book-456',
          'cfi_start': 'epubcfi(/6/4!/4/2/1:0)',
          'cfi_end': 'epubcfi(/6/4!/4/2/1:50)',
          'text': null,
          'color': 'orange',
          'created_at': testCreatedAt.millisecondsSinceEpoch,
        };

        final model = AnnotationModel.fromMap(map);
        expect(model.text, equals(''));
      });

      test('handles null color with yellow default', () {
        final map = {
          'id': 'annotation-123',
          'book_id': 'book-456',
          'cfi_start': 'epubcfi(/6/4!/4/2/1:0)',
          'cfi_end': 'epubcfi(/6/4!/4/2/1:50)',
          'text': 'Highlighted',
          'color': null,
          'created_at': testCreatedAt.millisecondsSinceEpoch,
        };

        final model = AnnotationModel.fromMap(map);
        expect(model.color, equals(AnnotationColor.yellow));
      });

      test('handles invalid color with yellow default', () {
        final map = {
          'id': 'annotation-123',
          'book_id': 'book-456',
          'cfi_start': 'epubcfi(/6/4!/4/2/1:0)',
          'cfi_end': 'epubcfi(/6/4!/4/2/1:50)',
          'text': 'Highlighted',
          'color': 'invalid_color',
          'created_at': testCreatedAt.millisecondsSinceEpoch,
        };

        final model = AnnotationModel.fromMap(map);
        expect(model.color, equals(AnnotationColor.yellow));
      });

      test('handles empty color string with yellow default', () {
        final map = {
          'id': 'annotation-123',
          'book_id': 'book-456',
          'cfi_start': 'epubcfi(/6/4!/4/2/1:0)',
          'cfi_end': 'epubcfi(/6/4!/4/2/1:50)',
          'text': 'Highlighted',
          'color': '',
          'created_at': testCreatedAt.millisecondsSinceEpoch,
        };

        final model = AnnotationModel.fromMap(map);
        expect(model.color, equals(AnnotationColor.yellow));
      });
    });

    group('toMap', () {
      test('serializes all fields correctly', () {
        final model = AnnotationModel(
          id: 'annotation-123',
          bookId: 'book-456',
          chapterId: 'chapter-1',
          cfiStart: 'epubcfi(/6/4!/4/2/1:0)',
          cfiEnd: 'epubcfi(/6/4!/4/2/1:50)',
          text: 'This is highlighted text',
          note: 'My note about this passage',
          color: AnnotationColor.green,
          createdAt: testCreatedAt,
        );

        final map = model.toMap();

        expect(map['id'], equals('annotation-123'));
        expect(map['book_id'], equals('book-456'));
        expect(map['chapter_id'], equals('chapter-1'));
        expect(map['cfi_start'], equals('epubcfi(/6/4!/4/2/1:0)'));
        expect(map['cfi_end'], equals('epubcfi(/6/4!/4/2/1:50)'));
        expect(map['text'], equals('This is highlighted text'));
        expect(map['note'], equals('My note about this passage'));
        expect(map['color'], equals('green'));
        expect(map['created_at'], equals(testCreatedAt.millisecondsSinceEpoch));
      });

      test('serializes all color values correctly', () {
        for (final color in AnnotationColor.values) {
          final model = AnnotationModel(
            id: 'annotation-123',
            bookId: 'book-456',
            cfiStart: '',
            cfiEnd: '',
            text: 'Text',
            color: color,
            createdAt: testCreatedAt,
          );

          final map = model.toMap();
          expect(map['color'], equals(color.name));
        }
      });

      test('serializes null chapterId', () {
        final model = AnnotationModel(
          id: 'annotation-123',
          bookId: 'book-456',
          cfiStart: 'epubcfi(/6/4!/4/2/1:0)',
          cfiEnd: 'epubcfi(/6/4!/4/2/1:50)',
          text: 'Highlighted',
          color: AnnotationColor.blue,
          createdAt: testCreatedAt,
        );

        final map = model.toMap();
        expect(map['chapter_id'], isNull);
      });

      test('serializes null note', () {
        final model = AnnotationModel(
          id: 'annotation-123',
          bookId: 'book-456',
          cfiStart: 'epubcfi(/6/4!/4/2/1:0)',
          cfiEnd: 'epubcfi(/6/4!/4/2/1:50)',
          text: 'Highlighted',
          color: AnnotationColor.pink,
          createdAt: testCreatedAt,
        );

        final map = model.toMap();
        expect(map['note'], isNull);
      });

      test('serializes empty strings', () {
        final model = AnnotationModel(
          id: 'annotation-123',
          bookId: 'book-456',
          cfiStart: '',
          cfiEnd: '',
          text: '',
          color: AnnotationColor.purple,
          createdAt: testCreatedAt,
        );

        final map = model.toMap();
        expect(map['cfi_start'], equals(''));
        expect(map['cfi_end'], equals(''));
        expect(map['text'], equals(''));
      });
    });

    group('fromEntity', () {
      test('converts Annotation entity to AnnotationModel', () {
        final annotation = Annotation(
          id: 'annotation-123',
          bookId: 'book-456',
          chapterId: 'chapter-1',
          cfiStart: 'epubcfi(/6/4!/4/2/1:0)',
          cfiEnd: 'epubcfi(/6/4!/4/2/1:50)',
          text: 'This is highlighted text',
          note: 'My note',
          color: AnnotationColor.orange,
          createdAt: testCreatedAt,
        );

        final model = AnnotationModel.fromEntity(annotation);

        expect(model.id, equals(annotation.id));
        expect(model.bookId, equals(annotation.bookId));
        expect(model.chapterId, equals(annotation.chapterId));
        expect(model.cfiStart, equals(annotation.cfiStart));
        expect(model.cfiEnd, equals(annotation.cfiEnd));
        expect(model.text, equals(annotation.text));
        expect(model.note, equals(annotation.note));
        expect(model.color, equals(annotation.color));
        expect(model.createdAt, equals(annotation.createdAt));
      });

      test('converts Annotation entity with null optional fields', () {
        final annotation = Annotation(
          id: 'annotation-123',
          bookId: 'book-456',
          cfiStart: 'epubcfi(/6/4!/4/2/1:0)',
          cfiEnd: 'epubcfi(/6/4!/4/2/1:50)',
          text: 'Highlighted',
          color: AnnotationColor.yellow,
          createdAt: testCreatedAt,
        );

        final model = AnnotationModel.fromEntity(annotation);
        expect(model.chapterId, isNull);
        expect(model.note, isNull);
      });
    });

    group('toEntity', () {
      test('converts AnnotationModel to Annotation entity', () {
        final model = AnnotationModel(
          id: 'annotation-123',
          bookId: 'book-456',
          chapterId: 'chapter-1',
          cfiStart: 'epubcfi(/6/4!/4/2/1:0)',
          cfiEnd: 'epubcfi(/6/4!/4/2/1:50)',
          text: 'This is highlighted text',
          note: 'My note',
          color: AnnotationColor.green,
          createdAt: testCreatedAt,
        );

        final annotation = model.toEntity();

        expect(annotation.id, equals(model.id));
        expect(annotation.bookId, equals(model.bookId));
        expect(annotation.chapterId, equals(model.chapterId));
        expect(annotation.cfiStart, equals(model.cfiStart));
        expect(annotation.cfiEnd, equals(model.cfiEnd));
        expect(annotation.text, equals(model.text));
        expect(annotation.note, equals(model.note));
        expect(annotation.color, equals(model.color));
        expect(annotation.createdAt, equals(model.createdAt));
      });

      test('converts AnnotationModel with null optional fields', () {
        final model = AnnotationModel(
          id: 'annotation-123',
          bookId: 'book-456',
          cfiStart: 'epubcfi(/6/4!/4/2/1:0)',
          cfiEnd: 'epubcfi(/6/4!/4/2/1:50)',
          text: 'Highlighted',
          color: AnnotationColor.blue,
          createdAt: testCreatedAt,
        );

        final annotation = model.toEntity();
        expect(annotation.chapterId, isNull);
        expect(annotation.note, isNull);
      });
    });

    group('round-trip', () {
      test('toMap then fromMap preserves all data', () {
        final original = AnnotationModel(
          id: 'annotation-123',
          bookId: 'book-456',
          chapterId: 'chapter-1',
          cfiStart: 'epubcfi(/6/4!/4/2/1:0)',
          cfiEnd: 'epubcfi(/6/4!/4/2/1:50)',
          text: 'This is highlighted text',
          note: 'My note about this passage',
          color: AnnotationColor.pink,
          createdAt: testCreatedAt,
        );

        final map = original.toMap();
        final restored = AnnotationModel.fromMap(map);

        expect(restored.id, equals(original.id));
        expect(restored.bookId, equals(original.bookId));
        expect(restored.chapterId, equals(original.chapterId));
        expect(restored.cfiStart, equals(original.cfiStart));
        expect(restored.cfiEnd, equals(original.cfiEnd));
        expect(restored.text, equals(original.text));
        expect(restored.note, equals(original.note));
        expect(restored.color, equals(original.color));
        expect(
          restored.createdAt.millisecondsSinceEpoch,
          equals(original.createdAt.millisecondsSinceEpoch),
        );
      });

      test('fromEntity then toEntity preserves all data', () {
        final original = Annotation(
          id: 'annotation-123',
          bookId: 'book-456',
          chapterId: 'chapter-1',
          cfiStart: 'epubcfi(/6/4!/4/2/1:0)',
          cfiEnd: 'epubcfi(/6/4!/4/2/1:50)',
          text: 'This is highlighted text',
          note: 'My note',
          color: AnnotationColor.purple,
          createdAt: testCreatedAt,
        );

        final model = AnnotationModel.fromEntity(original);
        final restored = model.toEntity();

        expect(restored, equals(original));
      });

      test('round-trip with null optional fields', () {
        final original = AnnotationModel(
          id: 'annotation-123',
          bookId: 'book-456',
          cfiStart: 'epubcfi(/6/4!/4/2/1:0)',
          cfiEnd: 'epubcfi(/6/4!/4/2/1:50)',
          text: 'Highlighted',
          color: AnnotationColor.orange,
          createdAt: testCreatedAt,
        );

        final map = original.toMap();
        final restored = AnnotationModel.fromMap(map);

        expect(restored.chapterId, isNull);
        expect(restored.note, isNull);
      });

      test('round-trip preserves all color values', () {
        for (final color in AnnotationColor.values) {
          final original = AnnotationModel(
            id: 'annotation-123',
            bookId: 'book-456',
            cfiStart: '',
            cfiEnd: '',
            text: 'Text',
            color: color,
            createdAt: testCreatedAt,
          );

          final map = original.toMap();
          final restored = AnnotationModel.fromMap(map);

          expect(restored.color, equals(color));
        }
      });
    });
  });
}
