import 'dart:io';

import 'package:readwhere_cbr/readwhere_cbr.dart';
import 'package:test/test.dart';

void main() {
  group('CbrReader', () {
    group('open', () {
      test('throws CbrReadException for non-existent file', () async {
        expect(
          () => CbrReader.open('/non/existent/file.cbr'),
          throwsA(isA<CbrReadException>()),
        );
      });

      test('throws CbrReadException with correct file path', () async {
        try {
          await CbrReader.open('/non/existent/file.cbr');
          fail('Expected CbrReadException');
        } on CbrReadException catch (e) {
          expect(e.filePath, '/non/existent/file.cbr');
          expect(e.message, contains('not found'));
        }
      });
    });

    group('openFile', () {
      test('throws CbrReadException for non-existent file', () async {
        final file = File('/non/existent/file.cbr');
        expect(
          () => CbrReader.openFile(file),
          throwsA(isA<CbrReadException>()),
        );
      });
    });
  });

  group('CbrBook (type alias for CbzBook)', () {
    test('CbrBook is same as CbzBook', () {
      // CbrBook is typedef to CbzBook, so we can test basic construction
      // through the CbzBook.pagesOnly factory
      final book = CbrBook.pagesOnly([]);
      expect(book.pages, isEmpty);
      expect(book.pageCount, 0);
      expect(book.title, isNull);
      expect(book.metadataSource, MetadataSource.none);
    });

    test('CbrBook with pages', () {
      final pages = [
        ComicPage(
          index: 0,
          filename: 'page001.jpg',
          mediaType: 'image/jpeg',
        ),
        ComicPage(
          index: 1,
          filename: 'page002.jpg',
          mediaType: 'image/jpeg',
        ),
      ];

      final book = CbrBook.pagesOnly(pages);
      expect(book.pageCount, 2);
      expect(book.pages, pages);
      expect(book.coverPage, pages[0]);
    });
  });

  group('Re-exported types from CBZ', () {
    test('ComicPage is accessible', () {
      final page = ComicPage(
        index: 0,
        filename: 'test.jpg',
        mediaType: 'image/jpeg',
      );
      expect(page.index, 0);
      expect(page.filename, 'test.jpg');
    });

    test('PageType enum is accessible', () {
      expect(PageType.frontCover, isNotNull);
      expect(PageType.story, isNotNull);
      expect(PageType.backCover, isNotNull);
    });

    test('MetadataSource enum is accessible', () {
      expect(MetadataSource.none, isNotNull);
      expect(MetadataSource.comicInfo, isNotNull);
      expect(MetadataSource.metronInfo, isNotNull);
    });

    test('ReadingDirection enum is accessible', () {
      expect(ReadingDirection.leftToRight, isNotNull);
      expect(ReadingDirection.rightToLeft, isNotNull);
    });

    test('AgeRating class is accessible', () {
      expect(AgeRating.unknown, isNotNull);
      expect(AgeRating.everyone, isNotNull);
      expect(AgeRating.mature17, isNotNull);
    });

    test('Creator class is accessible', () {
      final creator = Creator(
        name: 'Test Author',
        role: CreatorRole.writer,
      );
      expect(creator.name, 'Test Author');
      expect(creator.role, CreatorRole.writer);
    });

    test('ThumbnailOptions presets are accessible', () {
      expect(ThumbnailOptions.cover, isNotNull);
      expect(ThumbnailOptions.grid, isNotNull);
      expect(ThumbnailOptions.small, isNotNull);
    });

    test('ThumbnailFormat enum is accessible', () {
      expect(ThumbnailFormat.jpeg, isNotNull);
      expect(ThumbnailFormat.png, isNotNull);
    });

    test('ImageFormat enum is accessible', () {
      expect(ImageFormat.jpeg, isNotNull);
      expect(ImageFormat.png, isNotNull);
      expect(ImageFormat.gif, isNotNull);
      expect(ImageFormat.webp, isNotNull);
    });

    test('ImageDimensions class is accessible', () {
      final dims = ImageDimensions(800, 600);
      expect(dims.width, 800);
      expect(dims.height, 600);
      expect(dims.isLandscape, isTrue);
    });

    test('ImageUtils is accessible', () {
      // ImageUtils has static methods
      expect(ImageUtils.isImageFilename('test.jpg'), isTrue);
      expect(ImageUtils.isImageFilename('test.txt'), isFalse);
    });
  });
}
