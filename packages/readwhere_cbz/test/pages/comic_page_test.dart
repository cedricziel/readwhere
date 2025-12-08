import 'package:readwhere_cbz/src/pages/comic_page.dart';
import 'package:test/test.dart';

void main() {
  group('PageType', () {
    test('has correct XML values', () {
      expect(PageType.frontCover.xmlValue, equals('FrontCover'));
      expect(PageType.story.xmlValue, equals('Story'));
      expect(PageType.backCover.xmlValue, equals('BackCover'));
    });

    test('parse returns correct type for valid values', () {
      expect(PageType.parse('FrontCover'), equals(PageType.frontCover));
      expect(PageType.parse('Story'), equals(PageType.story));
      expect(PageType.parse('BackCover'), equals(PageType.backCover));
      expect(PageType.parse('Advertisement'), equals(PageType.advertisement));
    });

    test('parse is case-insensitive', () {
      expect(PageType.parse('frontcover'), equals(PageType.frontCover));
      expect(PageType.parse('FRONTCOVER'), equals(PageType.frontCover));
      expect(PageType.parse('FrontCOVER'), equals(PageType.frontCover));
    });

    test('parse returns story for unknown values', () {
      expect(PageType.parse('Unknown'), equals(PageType.story));
      expect(PageType.parse('InvalidType'), equals(PageType.story));
      expect(PageType.parse(''), equals(PageType.story));
    });

    test('parse returns story for null', () {
      expect(PageType.parse(null), equals(PageType.story));
    });
  });

  group('ComicPage', () {
    test('creates with required fields', () {
      const page = ComicPage(
        index: 0,
        filename: 'page001.jpg',
        mediaType: 'image/jpeg',
      );

      expect(page.index, equals(0));
      expect(page.filename, equals('page001.jpg'));
      expect(page.mediaType, equals('image/jpeg'));
      expect(page.type, equals(PageType.story)); // default
      expect(page.width, isNull);
      expect(page.height, isNull);
      expect(page.fileSize, isNull);
      expect(page.isDoublePage, isFalse); // default
      expect(page.bookmark, isNull);
    });

    test('creates with all fields', () {
      const page = ComicPage(
        index: 5,
        filename: 'cover.png',
        mediaType: 'image/png',
        type: PageType.frontCover,
        width: 1200,
        height: 1800,
        fileSize: 500000,
        isDoublePage: true,
        bookmark: 'Chapter 1',
      );

      expect(page.index, equals(5));
      expect(page.filename, equals('cover.png'));
      expect(page.mediaType, equals('image/png'));
      expect(page.type, equals(PageType.frontCover));
      expect(page.width, equals(1200));
      expect(page.height, equals(1800));
      expect(page.fileSize, equals(500000));
      expect(page.isDoublePage, isTrue);
      expect(page.bookmark, equals('Chapter 1'));
    });

    group('isCover', () {
      test('returns true for front cover', () {
        const page = ComicPage(
          index: 0,
          filename: 'cover.jpg',
          mediaType: 'image/jpeg',
          type: PageType.frontCover,
        );
        expect(page.isCover, isTrue);
        expect(page.isFrontCover, isTrue);
        expect(page.isBackCover, isFalse);
      });

      test('returns true for back cover', () {
        const page = ComicPage(
          index: 10,
          filename: 'back.jpg',
          mediaType: 'image/jpeg',
          type: PageType.backCover,
        );
        expect(page.isCover, isTrue);
        expect(page.isFrontCover, isFalse);
        expect(page.isBackCover, isTrue);
      });

      test('returns false for story pages', () {
        const page = ComicPage(
          index: 5,
          filename: 'page005.jpg',
          mediaType: 'image/jpeg',
          type: PageType.story,
        );
        expect(page.isCover, isFalse);
      });
    });

    group('aspectRatio', () {
      test('returns null when dimensions unknown', () {
        const page = ComicPage(
          index: 0,
          filename: 'page.jpg',
          mediaType: 'image/jpeg',
        );
        expect(page.aspectRatio, isNull);
      });

      test('returns correct ratio for portrait page', () {
        const page = ComicPage(
          index: 0,
          filename: 'page.jpg',
          mediaType: 'image/jpeg',
          width: 600,
          height: 900,
        );
        expect(page.aspectRatio, closeTo(0.667, 0.001));
      });

      test('returns correct ratio for landscape page', () {
        const page = ComicPage(
          index: 0,
          filename: 'spread.jpg',
          mediaType: 'image/jpeg',
          width: 1800,
          height: 900,
        );
        expect(page.aspectRatio, equals(2.0));
      });
    });

    group('isPortrait/isLandscape', () {
      test('returns null when dimensions unknown', () {
        const page = ComicPage(
          index: 0,
          filename: 'page.jpg',
          mediaType: 'image/jpeg',
        );
        expect(page.isPortrait, isNull);
        expect(page.isLandscape, isNull);
      });

      test('identifies portrait pages', () {
        const page = ComicPage(
          index: 0,
          filename: 'page.jpg',
          mediaType: 'image/jpeg',
          width: 600,
          height: 900,
        );
        expect(page.isPortrait, isTrue);
        expect(page.isLandscape, isFalse);
      });

      test('identifies landscape pages', () {
        const page = ComicPage(
          index: 0,
          filename: 'spread.jpg',
          mediaType: 'image/jpeg',
          width: 1800,
          height: 900,
        );
        expect(page.isPortrait, isFalse);
        expect(page.isLandscape, isTrue);
      });
    });

    group('extension', () {
      test('extracts extension from filename', () {
        const page1 = ComicPage(
          index: 0,
          filename: 'page.jpg',
          mediaType: 'image/jpeg',
        );
        expect(page1.extension, equals('jpg'));

        const page2 = ComicPage(
          index: 0,
          filename: 'image.PNG',
          mediaType: 'image/png',
        );
        expect(page2.extension, equals('png'));
      });

      test('returns empty for no extension', () {
        const page = ComicPage(
          index: 0,
          filename: 'image',
          mediaType: 'image/jpeg',
        );
        expect(page.extension, equals(''));
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        const original = ComicPage(
          index: 0,
          filename: 'page.jpg',
          mediaType: 'image/jpeg',
          type: PageType.story,
        );

        final copy = original.copyWith(
          type: PageType.frontCover,
          width: 800,
          height: 1200,
        );

        expect(copy.index, equals(0)); // unchanged
        expect(copy.filename, equals('page.jpg')); // unchanged
        expect(copy.type, equals(PageType.frontCover)); // changed
        expect(copy.width, equals(800)); // changed
        expect(copy.height, equals(1200)); // changed
      });

      test('preserves original values when not specified', () {
        const original = ComicPage(
          index: 5,
          filename: 'page.jpg',
          mediaType: 'image/jpeg',
          type: PageType.frontCover,
          width: 800,
          height: 1200,
          bookmark: 'Test',
        );

        final copy = original.copyWith(index: 10);

        expect(copy.index, equals(10));
        expect(copy.filename, equals('page.jpg'));
        expect(copy.type, equals(PageType.frontCover));
        expect(copy.width, equals(800));
        expect(copy.height, equals(1200));
        expect(copy.bookmark, equals('Test'));
      });
    });

    group('Equatable', () {
      test('equal pages are equal', () {
        const page1 = ComicPage(
          index: 0,
          filename: 'page.jpg',
          mediaType: 'image/jpeg',
          type: PageType.story,
          width: 800,
          height: 1200,
        );

        const page2 = ComicPage(
          index: 0,
          filename: 'page.jpg',
          mediaType: 'image/jpeg',
          type: PageType.story,
          width: 800,
          height: 1200,
        );

        expect(page1, equals(page2));
        expect(page1.hashCode, equals(page2.hashCode));
      });

      test('different pages are not equal', () {
        const page1 = ComicPage(
          index: 0,
          filename: 'page.jpg',
          mediaType: 'image/jpeg',
        );

        const page2 = ComicPage(
          index: 1,
          filename: 'page.jpg',
          mediaType: 'image/jpeg',
        );

        expect(page1, isNot(equals(page2)));
      });
    });

    test('toString includes key info', () {
      const page = ComicPage(
        index: 5,
        filename: 'page005.jpg',
        mediaType: 'image/jpeg',
        type: PageType.story,
      );

      final str = page.toString();
      expect(str, contains('5'));
      expect(str, contains('page005.jpg'));
      expect(str, contains('story'));
    });
  });
}
