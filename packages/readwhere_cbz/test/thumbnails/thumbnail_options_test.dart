import 'package:readwhere_cbz/src/thumbnails/thumbnail_options.dart';
import 'package:test/test.dart';

void main() {
  group('ThumbnailFormat', () {
    test('has jpeg and png values', () {
      expect(ThumbnailFormat.values, contains(ThumbnailFormat.jpeg));
      expect(ThumbnailFormat.values, contains(ThumbnailFormat.png));
    });
  });

  group('ThumbnailOptions', () {
    test('creates with default values', () {
      const options = ThumbnailOptions();
      expect(options.maxWidth, equals(200));
      expect(options.maxHeight, equals(300));
      expect(options.quality, equals(80));
      expect(options.format, equals(ThumbnailFormat.jpeg));
    });

    test('creates with custom values', () {
      const options = ThumbnailOptions(
        maxWidth: 400,
        maxHeight: 600,
        quality: 90,
        format: ThumbnailFormat.png,
      );
      expect(options.maxWidth, equals(400));
      expect(options.maxHeight, equals(600));
      expect(options.quality, equals(90));
      expect(options.format, equals(ThumbnailFormat.png));
    });

    group('presets', () {
      test('cover has correct dimensions', () {
        expect(ThumbnailOptions.cover.maxWidth, equals(300));
        expect(ThumbnailOptions.cover.maxHeight, equals(450));
        expect(ThumbnailOptions.cover.quality, equals(85));
      });

      test('grid has correct dimensions', () {
        expect(ThumbnailOptions.grid.maxWidth, equals(150));
        expect(ThumbnailOptions.grid.maxHeight, equals(225));
        expect(ThumbnailOptions.grid.quality, equals(80));
      });

      test('small has correct dimensions', () {
        expect(ThumbnailOptions.small.maxWidth, equals(80));
        expect(ThumbnailOptions.small.maxHeight, equals(120));
        expect(ThumbnailOptions.small.quality, equals(75));
      });

      test('large has correct dimensions', () {
        expect(ThumbnailOptions.large.maxWidth, equals(600));
        expect(ThumbnailOptions.large.maxHeight, equals(900));
        expect(ThumbnailOptions.large.quality, equals(90));
      });
    });

    test('toPng creates PNG options', () {
      const original = ThumbnailOptions(
        maxWidth: 200,
        maxHeight: 300,
        quality: 80,
        format: ThumbnailFormat.jpeg,
      );
      final pngOptions = original.toPng();
      expect(pngOptions.format, equals(ThumbnailFormat.png));
      expect(pngOptions.maxWidth, equals(original.maxWidth));
      expect(pngOptions.maxHeight, equals(original.maxHeight));
    });

    test('toJpeg creates JPEG options', () {
      const original = ThumbnailOptions(
        maxWidth: 200,
        maxHeight: 300,
        format: ThumbnailFormat.png,
      );
      final jpegOptions = original.toJpeg(quality: 95);
      expect(jpegOptions.format, equals(ThumbnailFormat.jpeg));
      expect(jpegOptions.quality, equals(95));
    });

    test('withMaxDimension creates square constraint', () {
      const original = ThumbnailOptions.cover;
      final square = original.withMaxDimension(256);
      expect(square.maxWidth, equals(256));
      expect(square.maxHeight, equals(256));
      expect(square.quality, equals(original.quality));
    });

    test('scaled creates proportionally scaled options', () {
      const original = ThumbnailOptions(maxWidth: 100, maxHeight: 200);
      final scaled = original.scaled(2.0);
      expect(scaled.maxWidth, equals(200));
      expect(scaled.maxHeight, equals(400));
    });

    test('extension returns correct file extension', () {
      expect(ThumbnailOptions.cover.extension, equals('.jpg'));
      expect(ThumbnailOptions.cover.toPng().extension, equals('.png'));
    });

    test('mimeType returns correct MIME type', () {
      expect(ThumbnailOptions.cover.mimeType, equals('image/jpeg'));
      expect(ThumbnailOptions.cover.toPng().mimeType, equals('image/png'));
    });

    test('equals compares all fields', () {
      const a = ThumbnailOptions(
        maxWidth: 100,
        maxHeight: 200,
        quality: 80,
        format: ThumbnailFormat.jpeg,
      );
      const b = ThumbnailOptions(
        maxWidth: 100,
        maxHeight: 200,
        quality: 80,
        format: ThumbnailFormat.jpeg,
      );
      const c = ThumbnailOptions(
        maxWidth: 100,
        maxHeight: 200,
        quality: 90,
        format: ThumbnailFormat.jpeg,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('toString shows all fields', () {
      const options = ThumbnailOptions(
        maxWidth: 100,
        maxHeight: 200,
        quality: 80,
        format: ThumbnailFormat.jpeg,
      );
      expect(options.toString(), contains('100'));
      expect(options.toString(), contains('200'));
      expect(options.toString(), contains('80'));
      expect(options.toString(), contains('jpeg'));
    });
  });
}
