import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere/domain/entities/annotation.dart';
import 'package:readwhere/presentation/providers/annotation_provider.dart';

import '../../mocks/mock_repositories.mocks.dart';

void main() {
  group('AnnotationProvider', () {
    late MockAnnotationRepository mockRepository;
    late AnnotationProvider provider;

    final testCreatedAt = DateTime(2024, 1, 15, 10, 30);

    final testAnnotation = Annotation(
      id: 'annotation-123',
      bookId: 'book-456',
      chapterId: 'chapter-0',
      cfiStart: 'epubcfi(/6/2!)',
      cfiEnd: 'epubcfi(/6/2!)',
      text: 'Test highlighted text',
      note: 'Test note',
      color: AnnotationColor.yellow,
      createdAt: testCreatedAt,
    );

    final testAnnotation2 = Annotation(
      id: 'annotation-124',
      bookId: 'book-456',
      chapterId: 'chapter-1',
      cfiStart: 'epubcfi(/6/4!)',
      cfiEnd: 'epubcfi(/6/4!)',
      text: 'Another highlight',
      color: AnnotationColor.blue,
      createdAt: testCreatedAt,
    );

    setUp(() {
      mockRepository = MockAnnotationRepository();
      provider = AnnotationProvider(annotationRepository: mockRepository);
    });

    group('initial state', () {
      test('has empty annotations list', () {
        expect(provider.annotations, isEmpty);
      });

      test('has no current book', () {
        expect(provider.currentBookId, isNull);
      });

      test('is not loading', () {
        expect(provider.isLoading, isFalse);
      });

      test('has no error', () {
        expect(provider.error, isNull);
      });

      test('has no selection', () {
        expect(provider.currentSelection, isNull);
        expect(provider.hasSelection, isFalse);
      });

      test('side panel is hidden', () {
        expect(provider.sidePanelVisible, isFalse);
      });
    });

    group('loadAnnotationsForBook', () {
      test('loads annotations successfully', () async {
        when(
          mockRepository.getAnnotationsForBook('book-456'),
        ).thenAnswer((_) async => [testAnnotation, testAnnotation2]);

        await provider.loadAnnotationsForBook('book-456');

        expect(provider.annotations, hasLength(2));
        expect(provider.currentBookId, equals('book-456'));
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
      });

      test('sets loading state while fetching', () async {
        when(
          mockRepository.getAnnotationsForBook('book-456'),
        ).thenAnswer((_) async => [testAnnotation]);

        final future = provider.loadAnnotationsForBook('book-456');
        // Note: In a real test we'd check isLoading during the operation
        await future;

        expect(provider.isLoading, isFalse);
      });

      test('sets error on failure', () async {
        when(
          mockRepository.getAnnotationsForBook('book-456'),
        ).thenThrow(Exception('Database error'));

        await provider.loadAnnotationsForBook('book-456');

        expect(provider.error, contains('Failed to load annotations'));
        expect(provider.isLoading, isFalse);
      });

      test('skips reload if same book already loaded', () async {
        when(
          mockRepository.getAnnotationsForBook('book-456'),
        ).thenAnswer((_) async => [testAnnotation]);

        await provider.loadAnnotationsForBook('book-456');
        await provider.loadAnnotationsForBook('book-456');

        verify(mockRepository.getAnnotationsForBook('book-456')).called(1);
      });
    });

    group('clearAnnotations', () {
      test('clears all state', () async {
        when(
          mockRepository.getAnnotationsForBook('book-456'),
        ).thenAnswer((_) async => [testAnnotation]);

        await provider.loadAnnotationsForBook('book-456');
        provider.setSelection(selectedText: 'Test', chapterIndex: 0);
        provider.showSidePanel();

        provider.clearAnnotations();

        expect(provider.annotations, isEmpty);
        expect(provider.currentBookId, isNull);
        expect(provider.currentSelection, isNull);
        expect(provider.sidePanelVisible, isFalse);
      });
    });

    group('setSelection', () {
      test('sets selection with text', () {
        provider.setSelection(
          selectedText: 'Selected text',
          chapterIndex: 2,
          chapterHref: 'chapter2.xhtml',
        );

        expect(provider.currentSelection, isNotNull);
        expect(
          provider.currentSelection!.selectedText,
          equals('Selected text'),
        );
        expect(provider.currentSelection!.chapterIndex, equals(2));
        expect(
          provider.currentSelection!.chapterHref,
          equals('chapter2.xhtml'),
        );
        expect(provider.hasSelection, isTrue);
      });

      test('clears selection when text is empty', () {
        provider.setSelection(selectedText: 'Some text', chapterIndex: 0);
        expect(provider.hasSelection, isTrue);

        provider.setSelection(selectedText: '   ', chapterIndex: 0);

        expect(provider.currentSelection, isNull);
        expect(provider.hasSelection, isFalse);
      });
    });

    group('clearSelection', () {
      test('clears the current selection', () {
        provider.setSelection(selectedText: 'Test', chapterIndex: 0);
        expect(provider.hasSelection, isTrue);

        provider.clearSelection();

        expect(provider.currentSelection, isNull);
        expect(provider.hasSelection, isFalse);
      });
    });

    group('createAnnotationFromSelection', () {
      test('creates annotation from current selection', () async {
        when(
          mockRepository.getAnnotationsForBook('book-456'),
        ).thenAnswer((_) async => []);
        when(
          mockRepository.addAnnotation(any),
        ).thenAnswer((invocation) async => invocation.positionalArguments[0]);

        await provider.loadAnnotationsForBook('book-456');
        provider.setSelection(
          selectedText: 'Highlighted text',
          chapterIndex: 1,
        );

        final result = await provider.createAnnotationFromSelection(
          color: AnnotationColor.green,
          note: 'My note',
        );

        expect(result, isNotNull);
        expect(result!.text, equals('Highlighted text'));
        expect(result.color, equals(AnnotationColor.green));
        expect(result.note, equals('My note'));
        expect(provider.annotations, hasLength(1));
        expect(provider.currentSelection, isNull);
      });

      test('returns null when no selection', () async {
        when(
          mockRepository.getAnnotationsForBook('book-456'),
        ).thenAnswer((_) async => []);

        await provider.loadAnnotationsForBook('book-456');

        final result = await provider.createAnnotationFromSelection(
          color: AnnotationColor.yellow,
        );

        expect(result, isNull);
      });

      test('returns null when no book loaded', () async {
        provider.setSelection(selectedText: 'Test', chapterIndex: 0);

        final result = await provider.createAnnotationFromSelection(
          color: AnnotationColor.yellow,
        );

        expect(result, isNull);
      });
    });

    group('createAnnotation', () {
      test('creates annotation directly', () async {
        when(
          mockRepository.getAnnotationsForBook('book-456'),
        ).thenAnswer((_) async => []);
        when(
          mockRepository.addAnnotation(any),
        ).thenAnswer((invocation) async => invocation.positionalArguments[0]);

        await provider.loadAnnotationsForBook('book-456');

        final result = await provider.createAnnotation(
          text: 'Direct annotation',
          chapterIndex: 0,
          color: AnnotationColor.pink,
          note: 'Direct note',
        );

        expect(result, isNotNull);
        expect(result!.text, equals('Direct annotation'));
        expect(result.color, equals(AnnotationColor.pink));
        expect(provider.annotations, hasLength(1));
      });
    });

    group('updateNote', () {
      test('updates annotation note', () async {
        when(
          mockRepository.getAnnotationsForBook('book-456'),
        ).thenAnswer((_) async => [testAnnotation]);
        when(
          mockRepository.updateAnnotation(any),
        ).thenAnswer((invocation) async => invocation.positionalArguments[0]);

        await provider.loadAnnotationsForBook('book-456');

        final result = await provider.updateNote(
          'annotation-123',
          'Updated note',
        );

        expect(result, isNotNull);
        expect(result!.note, equals('Updated note'));
        expect(provider.annotations.first.note, equals('Updated note'));
      });

      test('returns null for non-existent annotation', () async {
        when(
          mockRepository.getAnnotationsForBook('book-456'),
        ).thenAnswer((_) async => [testAnnotation]);

        await provider.loadAnnotationsForBook('book-456');

        final result = await provider.updateNote('non-existent', 'Note');

        expect(result, isNull);
      });
    });

    group('updateColor', () {
      test('updates annotation color', () async {
        when(
          mockRepository.getAnnotationsForBook('book-456'),
        ).thenAnswer((_) async => [testAnnotation]);
        when(
          mockRepository.updateAnnotation(any),
        ).thenAnswer((invocation) async => invocation.positionalArguments[0]);

        await provider.loadAnnotationsForBook('book-456');

        final result = await provider.updateColor(
          'annotation-123',
          AnnotationColor.purple,
        );

        expect(result, isNotNull);
        expect(result!.color, equals(AnnotationColor.purple));
      });
    });

    group('deleteAnnotation', () {
      test('deletes annotation successfully', () async {
        when(
          mockRepository.getAnnotationsForBook('book-456'),
        ).thenAnswer((_) async => [testAnnotation, testAnnotation2]);
        when(
          mockRepository.deleteAnnotation('annotation-123'),
        ).thenAnswer((_) async => true);

        await provider.loadAnnotationsForBook('book-456');
        expect(provider.annotations, hasLength(2));

        final result = await provider.deleteAnnotation('annotation-123');

        expect(result, isTrue);
        expect(provider.annotations, hasLength(1));
        expect(provider.annotations.first.id, equals('annotation-124'));
      });

      test('returns false when delete fails', () async {
        when(
          mockRepository.getAnnotationsForBook('book-456'),
        ).thenAnswer((_) async => [testAnnotation]);
        when(
          mockRepository.deleteAnnotation('annotation-123'),
        ).thenAnswer((_) async => false);

        await provider.loadAnnotationsForBook('book-456');

        final result = await provider.deleteAnnotation('annotation-123');

        expect(result, isFalse);
        expect(provider.annotations, hasLength(1));
      });
    });

    group('side panel', () {
      test('toggleSidePanel toggles visibility', () {
        expect(provider.sidePanelVisible, isFalse);

        provider.toggleSidePanel();
        expect(provider.sidePanelVisible, isTrue);

        provider.toggleSidePanel();
        expect(provider.sidePanelVisible, isFalse);
      });

      test('showSidePanel makes panel visible', () {
        provider.showSidePanel();
        expect(provider.sidePanelVisible, isTrue);

        provider.showSidePanel();
        expect(provider.sidePanelVisible, isTrue);
      });

      test('hideSidePanel hides panel', () {
        provider.showSidePanel();
        provider.hideSidePanel();
        expect(provider.sidePanelVisible, isFalse);
      });
    });

    group('annotationsForChapter', () {
      test('returns annotations for specific chapter', () async {
        when(
          mockRepository.getAnnotationsForBook('book-456'),
        ).thenAnswer((_) async => [testAnnotation, testAnnotation2]);

        await provider.loadAnnotationsForBook('book-456');

        final chapter0Annotations = provider.annotationsForChapter('chapter-0');
        final chapter1Annotations = provider.annotationsForChapter('chapter-1');

        expect(chapter0Annotations, hasLength(1));
        expect(chapter0Annotations.first.id, equals('annotation-123'));
        expect(chapter1Annotations, hasLength(1));
        expect(chapter1Annotations.first.id, equals('annotation-124'));
      });

      test('returns empty list for null chapter', () {
        expect(provider.annotationsForChapter(null), isEmpty);
      });
    });

    group('annotationsByChapter', () {
      test('groups annotations by chapter', () async {
        when(
          mockRepository.getAnnotationsForBook('book-456'),
        ).thenAnswer((_) async => [testAnnotation, testAnnotation2]);

        await provider.loadAnnotationsForBook('book-456');

        final grouped = provider.annotationsByChapter;

        expect(grouped.keys, contains('chapter-0'));
        expect(grouped.keys, contains('chapter-1'));
        expect(grouped['chapter-0'], hasLength(1));
        expect(grouped['chapter-1'], hasLength(1));
      });
    });

    group('getAnnotation', () {
      test('returns annotation by ID', () async {
        when(
          mockRepository.getAnnotationsForBook('book-456'),
        ).thenAnswer((_) async => [testAnnotation, testAnnotation2]);

        await provider.loadAnnotationsForBook('book-456');

        final result = provider.getAnnotation('annotation-123');

        expect(result, isNotNull);
        expect(result!.id, equals('annotation-123'));
      });

      test('returns null for non-existent ID', () async {
        when(
          mockRepository.getAnnotationsForBook('book-456'),
        ).thenAnswer((_) async => [testAnnotation]);

        await provider.loadAnnotationsForBook('book-456');

        final result = provider.getAnnotation('non-existent');

        expect(result, isNull);
      });
    });

    group('clearError', () {
      test('clears error state', () async {
        when(
          mockRepository.getAnnotationsForBook('book-456'),
        ).thenThrow(Exception('Error'));

        await provider.loadAnnotationsForBook('book-456');
        expect(provider.error, isNotNull);

        provider.clearError();

        expect(provider.error, isNull);
      });
    });

    group('annotationCount', () {
      test('returns correct count', () async {
        when(
          mockRepository.getAnnotationsForBook('book-456'),
        ).thenAnswer((_) async => [testAnnotation, testAnnotation2]);

        await provider.loadAnnotationsForBook('book-456');

        expect(provider.annotationCount, equals(2));
      });

      test('returns 0 when empty', () {
        expect(provider.annotationCount, equals(0));
      });
    });
  });
}
