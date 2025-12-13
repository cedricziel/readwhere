import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_pdf/readwhere_pdf.dart';

void main() {
  group('PdfPage', () {
    test('creates page with required fields', () {
      const page = PdfPage(index: 0, width: 612.0, height: 792.0);

      expect(page.index, 0);
      expect(page.width, 612.0);
      expect(page.height, 792.0);
      expect(page.rotation, 0); // Default
    });

    test('creates page with all fields', () {
      const page = PdfPage(index: 5, width: 595.0, height: 842.0, rotation: 90);

      expect(page.index, 5);
      expect(page.width, 595.0);
      expect(page.height, 842.0);
      expect(page.rotation, 90);
    });

    group('aspectRatio', () {
      test('calculates aspect ratio correctly', () {
        const page = PdfPage(index: 0, width: 612.0, height: 792.0);

        expect(page.aspectRatio, closeTo(0.7727, 0.001));
      });

      test('handles square page', () {
        const page = PdfPage(index: 0, width: 500.0, height: 500.0);

        expect(page.aspectRatio, 1.0);
      });
    });

    group('orientation', () {
      test('isPortrait returns true for tall pages', () {
        const page = PdfPage(index: 0, width: 612.0, height: 792.0);

        expect(page.isPortrait, isTrue);
        expect(page.isLandscape, isFalse);
        expect(page.isSquare, isFalse);
      });

      test('isLandscape returns true for wide pages', () {
        const page = PdfPage(index: 0, width: 842.0, height: 595.0);

        expect(page.isPortrait, isFalse);
        expect(page.isLandscape, isTrue);
        expect(page.isSquare, isFalse);
      });

      test('isSquare returns true for square pages', () {
        const page = PdfPage(index: 0, width: 500.0, height: 500.0);

        expect(page.isPortrait, isFalse);
        expect(page.isLandscape, isFalse);
        expect(page.isSquare, isTrue);
      });
    });

    group('effectiveWidth and effectiveHeight', () {
      test('returns original dimensions for 0 rotation', () {
        const page = PdfPage(
          index: 0,
          width: 612.0,
          height: 792.0,
          rotation: 0,
        );

        expect(page.effectiveWidth, 612.0);
        expect(page.effectiveHeight, 792.0);
      });

      test('swaps dimensions for 90 degree rotation', () {
        const page = PdfPage(
          index: 0,
          width: 612.0,
          height: 792.0,
          rotation: 90,
        );

        expect(page.effectiveWidth, 792.0);
        expect(page.effectiveHeight, 612.0);
      });

      test('returns original dimensions for 180 rotation', () {
        const page = PdfPage(
          index: 0,
          width: 612.0,
          height: 792.0,
          rotation: 180,
        );

        expect(page.effectiveWidth, 612.0);
        expect(page.effectiveHeight, 792.0);
      });

      test('swaps dimensions for 270 degree rotation', () {
        const page = PdfPage(
          index: 0,
          width: 612.0,
          height: 792.0,
          rotation: 270,
        );

        expect(page.effectiveWidth, 792.0);
        expect(page.effectiveHeight, 612.0);
      });
    });

    group('copyWith', () {
      test('creates copy with modified index', () {
        const original = PdfPage(index: 0, width: 612.0, height: 792.0);

        final copy = original.copyWith(index: 5);

        expect(copy.index, 5);
        expect(copy.width, 612.0);
        expect(copy.height, 792.0);
        expect(copy.rotation, 0);
      });

      test('creates copy with modified dimensions', () {
        const original = PdfPage(index: 0, width: 612.0, height: 792.0);

        final copy = original.copyWith(width: 100.0, height: 200.0);

        expect(copy.index, 0);
        expect(copy.width, 100.0);
        expect(copy.height, 200.0);
      });

      test('creates copy with modified rotation', () {
        const original = PdfPage(
          index: 0,
          width: 612.0,
          height: 792.0,
          rotation: 0,
        );

        final copy = original.copyWith(rotation: 90);

        expect(copy.rotation, 90);
      });
    });

    group('equality', () {
      test('equal pages are equal', () {
        const page1 = PdfPage(
          index: 0,
          width: 612.0,
          height: 792.0,
          rotation: 90,
        );
        const page2 = PdfPage(
          index: 0,
          width: 612.0,
          height: 792.0,
          rotation: 90,
        );

        expect(page1, equals(page2));
        expect(page1.hashCode, equals(page2.hashCode));
      });

      test('different pages are not equal', () {
        const page1 = PdfPage(index: 0, width: 612.0, height: 792.0);
        const page2 = PdfPage(index: 1, width: 612.0, height: 792.0);

        expect(page1, isNot(equals(page2)));
      });
    });

    test('toString returns meaningful representation', () {
      const page = PdfPage(index: 0, width: 612.0, height: 792.0, rotation: 90);

      final str = page.toString();
      expect(str, contains('PdfPage'));
      expect(str, contains('index: 0'));
      expect(str, contains('width: 612'));
      expect(str, contains('height: 792'));
      expect(str, contains('rotation: 90'));
    });
  });

  group('PageDimensions', () {
    test('creates dimensions with required fields', () {
      const dims = PageDimensions(width: 1024, height: 768);

      expect(dims.width, 1024);
      expect(dims.height, 768);
    });

    test('calculates aspect ratio correctly', () {
      const dims = PageDimensions(width: 1920, height: 1080);

      expect(dims.aspectRatio, closeTo(1.778, 0.001));
    });

    group('equality', () {
      test('equal dimensions are equal', () {
        const dims1 = PageDimensions(width: 1024, height: 768);
        const dims2 = PageDimensions(width: 1024, height: 768);

        expect(dims1, equals(dims2));
        expect(dims1.hashCode, equals(dims2.hashCode));
      });

      test('different dimensions are not equal', () {
        const dims1 = PageDimensions(width: 1024, height: 768);
        const dims2 = PageDimensions(width: 800, height: 600);

        expect(dims1, isNot(equals(dims2)));
      });
    });

    test('toString returns meaningful representation', () {
      const dims = PageDimensions(width: 1024, height: 768);

      final str = dims.toString();
      expect(str, contains('1024'));
      expect(str, contains('768'));
    });
  });
}
