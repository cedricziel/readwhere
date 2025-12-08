import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/plugins/search_result.dart';

void main() {
  group('SearchResult', () {
    group('constructor', () {
      test('creates search result with all fields', () {
        final result = SearchResult(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          text: 'This is the matched text with surrounding context',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
        );

        expect(result.chapterId, equals('chapter-1'));
        expect(result.chapterTitle, equals('Introduction'));
        expect(
          result.text,
          equals('This is the matched text with surrounding context'),
        );
        expect(result.cfi, equals('epubcfi(/6/4!/4/2/1:0)'));
      });

      test('creates search result with empty strings', () {
        final result = SearchResult(
          chapterId: '',
          chapterTitle: '',
          text: '',
          cfi: '',
        );

        expect(result.chapterId, equals(''));
        expect(result.chapterTitle, equals(''));
        expect(result.text, equals(''));
        expect(result.cfi, equals(''));
      });
    });

    group('copyWith', () {
      test('copies with all new values', () {
        final original = SearchResult(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          text: 'Original text',
          cfi: 'original-cfi',
        );

        final copied = original.copyWith(
          chapterId: 'chapter-2',
          chapterTitle: 'Conclusion',
          text: 'New text',
          cfi: 'new-cfi',
        );

        expect(copied.chapterId, equals('chapter-2'));
        expect(copied.chapterTitle, equals('Conclusion'));
        expect(copied.text, equals('New text'));
        expect(copied.cfi, equals('new-cfi'));
      });

      test('preserves original values when not specified', () {
        final original = SearchResult(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          text: 'Original text',
          cfi: 'original-cfi',
        );

        final copied = original.copyWith();

        expect(copied.chapterId, equals(original.chapterId));
        expect(copied.chapterTitle, equals(original.chapterTitle));
        expect(copied.text, equals(original.text));
        expect(copied.cfi, equals(original.cfi));
      });

      test('copies with partial new values', () {
        final original = SearchResult(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          text: 'Original text',
          cfi: 'original-cfi',
        );

        final copied = original.copyWith(text: 'Updated text');

        expect(copied.chapterId, equals(original.chapterId));
        expect(copied.chapterTitle, equals(original.chapterTitle));
        expect(copied.text, equals('Updated text'));
        expect(copied.cfi, equals(original.cfi));
      });
    });

    group('equatable', () {
      test('two results with same values are equal', () {
        final result1 = SearchResult(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          text: 'Matched text',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
        );

        final result2 = SearchResult(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          text: 'Matched text',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
        );

        expect(result1, equals(result2));
      });

      test('two results with different values are not equal', () {
        final result1 = SearchResult(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          text: 'Matched text',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
        );

        final result2 = SearchResult(
          chapterId: 'chapter-2',
          chapterTitle: 'Introduction',
          text: 'Matched text',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
        );

        expect(result1, isNot(equals(result2)));
      });

      test('props includes all fields', () {
        final result = SearchResult(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          text: 'Matched text',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
        );

        expect(result.props, contains('chapter-1'));
        expect(result.props, contains('Introduction'));
        expect(result.props, contains('Matched text'));
        expect(result.props, contains('epubcfi(/6/4!/4/2/1:0)'));
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        final result = SearchResult(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          text: 'This is a short matched text',
          cfi: 'epubcfi(/6/4!/4/2/1:0)',
        );

        final str = result.toString();

        expect(str, contains('SearchResult'));
        expect(str, contains('chapterId: chapter-1'));
        expect(str, contains('chapterTitle: Introduction'));
        expect(str, contains('cfi: epubcfi(/6/4!/4/2/1:0)'));
      });

      test('truncates long text to 50 characters', () {
        final longText = 'A' * 100; // 100 character string
        final result = SearchResult(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          text: longText,
          cfi: 'cfi',
        );

        final str = result.toString();

        // Text should be truncated at 50 characters
        expect(str, contains('A' * 50));
        expect(str, contains('...'));
      });

      test('handles text shorter than 50 characters', () {
        final result = SearchResult(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          text: 'Short',
          cfi: 'cfi',
        );

        final str = result.toString();
        expect(str, contains('text: Short'));
      });
    });
  });
}
