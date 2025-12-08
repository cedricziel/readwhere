import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/plugins/reader_content.dart';

void main() {
  group('ReaderContent', () {
    group('constructor', () {
      test('creates reader content with all fields', () {
        final images = {
          'image1.png': Uint8List.fromList([1, 2, 3]),
          'image2.jpg': Uint8List.fromList([4, 5, 6]),
        };

        final content = ReaderContent(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          htmlContent: '<p>Hello World</p>',
          cssContent: 'p { color: black; }',
          images: images,
        );

        expect(content.chapterId, equals('chapter-1'));
        expect(content.chapterTitle, equals('Introduction'));
        expect(content.htmlContent, equals('<p>Hello World</p>'));
        expect(content.cssContent, equals('p { color: black; }'));
        expect(content.images, equals(images));
      });

      test('creates reader content with default cssContent', () {
        final content = ReaderContent(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          htmlContent: '<p>Hello</p>',
        );

        expect(content.cssContent, equals(''));
      });

      test('creates reader content with default empty images', () {
        final content = ReaderContent(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          htmlContent: '<p>Hello</p>',
        );

        expect(content.images, isEmpty);
      });

      test('creates reader content with empty strings', () {
        final content = ReaderContent(
          chapterId: '',
          chapterTitle: '',
          htmlContent: '',
          cssContent: '',
          images: const {},
        );

        expect(content.chapterId, equals(''));
        expect(content.chapterTitle, equals(''));
        expect(content.htmlContent, equals(''));
        expect(content.cssContent, equals(''));
        expect(content.images, isEmpty);
      });
    });

    group('copyWith', () {
      test('copies with all new values', () {
        final originalImages = {
          'img1.png': Uint8List.fromList([1, 2, 3]),
        };
        final original = ReaderContent(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          htmlContent: '<p>Original</p>',
          cssContent: 'p { color: red; }',
          images: originalImages,
        );

        final newImages = {
          'img2.jpg': Uint8List.fromList([4, 5, 6]),
        };
        final copied = original.copyWith(
          chapterId: 'chapter-2',
          chapterTitle: 'Conclusion',
          htmlContent: '<p>New</p>',
          cssContent: 'p { color: blue; }',
          images: newImages,
        );

        expect(copied.chapterId, equals('chapter-2'));
        expect(copied.chapterTitle, equals('Conclusion'));
        expect(copied.htmlContent, equals('<p>New</p>'));
        expect(copied.cssContent, equals('p { color: blue; }'));
        expect(copied.images, equals(newImages));
      });

      test('preserves original values when not specified', () {
        final images = {
          'img.png': Uint8List.fromList([1, 2, 3]),
        };
        final original = ReaderContent(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          htmlContent: '<p>Original</p>',
          cssContent: 'p { color: red; }',
          images: images,
        );

        final copied = original.copyWith();

        expect(copied.chapterId, equals(original.chapterId));
        expect(copied.chapterTitle, equals(original.chapterTitle));
        expect(copied.htmlContent, equals(original.htmlContent));
        expect(copied.cssContent, equals(original.cssContent));
        expect(copied.images, equals(original.images));
      });

      test('copies with partial new values', () {
        final original = ReaderContent(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          htmlContent: '<p>Original</p>',
          cssContent: 'p { color: red; }',
        );

        final copied = original.copyWith(htmlContent: '<p>Updated</p>');

        expect(copied.chapterId, equals(original.chapterId));
        expect(copied.chapterTitle, equals(original.chapterTitle));
        expect(copied.htmlContent, equals('<p>Updated</p>'));
        expect(copied.cssContent, equals(original.cssContent));
      });
    });

    group('equatable', () {
      test('two contents with same values are equal', () {
        final images = {
          'img.png': Uint8List.fromList([1, 2, 3]),
        };

        final content1 = ReaderContent(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          htmlContent: '<p>Hello</p>',
          cssContent: 'p { }',
          images: images,
        );

        final content2 = ReaderContent(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          htmlContent: '<p>Hello</p>',
          cssContent: 'p { }',
          images: images,
        );

        expect(content1, equals(content2));
      });

      test('two contents with different values are not equal', () {
        final content1 = ReaderContent(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          htmlContent: '<p>Hello</p>',
        );

        final content2 = ReaderContent(
          chapterId: 'chapter-2',
          chapterTitle: 'Introduction',
          htmlContent: '<p>Hello</p>',
        );

        expect(content1, isNot(equals(content2)));
      });

      test('props includes all fields', () {
        final images = {
          'img.png': Uint8List.fromList([1, 2, 3]),
        };
        final content = ReaderContent(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          htmlContent: '<p>Hello</p>',
          cssContent: 'p { }',
          images: images,
        );

        expect(content.props, contains('chapter-1'));
        expect(content.props, contains('Introduction'));
        expect(content.props, contains('<p>Hello</p>'));
        expect(content.props, contains('p { }'));
        expect(content.props, contains(images));
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        final images = {
          'img1.png': Uint8List.fromList([1, 2, 3]),
          'img2.jpg': Uint8List.fromList([4, 5, 6]),
        };
        final content = ReaderContent(
          chapterId: 'chapter-1',
          chapterTitle: 'Introduction',
          htmlContent: '<p>Hello World</p>',
          cssContent: 'p { color: black; }',
          images: images,
        );

        final str = content.toString();

        expect(str, contains('ReaderContent'));
        expect(str, contains('chapterId: chapter-1'));
        expect(str, contains('chapterTitle: Introduction'));
        expect(str, contains('htmlLength: 18')); // '<p>Hello World</p>'.length
        expect(str, contains('cssLength: 19')); // 'p { color: black; }'.length
        expect(str, contains('imageCount: 2'));
      });

      test('shows correct lengths for empty content', () {
        final content = ReaderContent(
          chapterId: 'chapter-1',
          chapterTitle: 'Test',
          htmlContent: '',
          cssContent: '',
        );

        final str = content.toString();
        expect(str, contains('htmlLength: 0'));
        expect(str, contains('cssLength: 0'));
        expect(str, contains('imageCount: 0'));
      });
    });
  });
}
