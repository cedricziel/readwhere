import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:readwhere_cbz/src/errors/cbz_exception.dart';
import 'package:readwhere_cbz/src/thumbnails/thumbnail_generator.dart';
import 'package:readwhere_cbz/src/thumbnails/thumbnail_options.dart';
import 'package:test/test.dart';

/// Creates a test image with the specified dimensions.
Uint8List createTestImage(int width, int height, {bool asPng = false}) {
  final image = img.Image(width: width, height: height);
  // Fill with a gradient for visual verification
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgba(
        x,
        y,
        (x * 255 ~/ width),
        (y * 255 ~/ height),
        128,
        255,
      );
    }
  }
  if (asPng) {
    return Uint8List.fromList(img.encodePng(image));
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}

void main() {
  group('ThumbnailGenerator', () {
    group('generate', () {
      test('creates thumbnail within specified dimensions', () {
        final sourceImage = createTestImage(800, 600);

        final thumbnail = ThumbnailGenerator.generate(
          sourceImage,
          const ThumbnailOptions(maxWidth: 200, maxHeight: 150),
        );

        // Verify thumbnail was created
        expect(thumbnail, isNotEmpty);

        // Decode and check dimensions
        final decoded = img.decodeImage(thumbnail);
        expect(decoded, isNotNull);
        expect(decoded!.width, lessThanOrEqualTo(200));
        expect(decoded.height, lessThanOrEqualTo(150));
      });

      test('maintains aspect ratio', () {
        // Create a 4:3 aspect ratio image
        final sourceImage = createTestImage(800, 600);

        final thumbnail = ThumbnailGenerator.generate(
          sourceImage,
          const ThumbnailOptions(maxWidth: 200, maxHeight: 200),
        );

        final decoded = img.decodeImage(thumbnail);
        expect(decoded, isNotNull);

        // Aspect ratio should be maintained (4:3)
        final aspectRatio = decoded!.width / decoded.height;
        expect(aspectRatio, closeTo(4 / 3, 0.05));
      });

      test('generates JPEG by default', () {
        final sourceImage = createTestImage(100, 100);

        final thumbnail = ThumbnailGenerator.generate(
          sourceImage,
          const ThumbnailOptions(),
        );

        // JPEG starts with FF D8 FF
        expect(thumbnail[0], equals(0xFF));
        expect(thumbnail[1], equals(0xD8));
        expect(thumbnail[2], equals(0xFF));
      });

      test('generates PNG when specified', () {
        final sourceImage = createTestImage(100, 100);

        final thumbnail = ThumbnailGenerator.generate(
          sourceImage,
          const ThumbnailOptions(format: ThumbnailFormat.png),
        );

        // PNG starts with 89 50 4E 47
        expect(thumbnail[0], equals(0x89));
        expect(thumbnail[1], equals(0x50));
        expect(thumbnail[2], equals(0x4E));
        expect(thumbnail[3], equals(0x47));
      });

      test('handles portrait images correctly', () {
        // Create a portrait image
        final sourceImage = createTestImage(600, 900);

        final thumbnail = ThumbnailGenerator.generate(
          sourceImage,
          const ThumbnailOptions(maxWidth: 200, maxHeight: 300),
        );

        final decoded = img.decodeImage(thumbnail);
        expect(decoded, isNotNull);
        expect(decoded!.width, lessThanOrEqualTo(200));
        expect(decoded.height, lessThanOrEqualTo(300));

        // Should maintain portrait aspect ratio
        expect(decoded.height, greaterThan(decoded.width));
      });

      test('does not upscale small images', () {
        // Create a small image
        final sourceImage = createTestImage(50, 50);

        final thumbnail = ThumbnailGenerator.generate(
          sourceImage,
          const ThumbnailOptions(maxWidth: 200, maxHeight: 200),
        );

        final decoded = img.decodeImage(thumbnail);
        expect(decoded, isNotNull);
        // Should not upscale
        expect(decoded!.width, equals(50));
        expect(decoded.height, equals(50));
      });

      test('throws CbzImageException for invalid image data', () {
        final invalidData = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);

        expect(
          () => ThumbnailGenerator.generate(
              invalidData, const ThumbnailOptions()),
          throwsA(isA<CbzImageException>()),
        );
      });
    });

    group('generateWithMaxDimension', () {
      test('creates square-constrained thumbnail', () {
        final sourceImage = createTestImage(800, 600);

        final thumbnail = ThumbnailGenerator.generateWithMaxDimension(
          sourceImage,
          100,
        );

        final decoded = img.decodeImage(thumbnail);
        expect(decoded, isNotNull);
        expect(decoded!.width, lessThanOrEqualTo(100));
        expect(decoded.height, lessThanOrEqualTo(100));
      });
    });

    group('preset methods', () {
      test('generateCover uses cover preset', () {
        final sourceImage = createTestImage(1200, 1800);

        final thumbnail = ThumbnailGenerator.generateCover(sourceImage);

        final decoded = img.decodeImage(thumbnail);
        expect(decoded, isNotNull);
        expect(decoded!.width, lessThanOrEqualTo(300));
        expect(decoded.height, lessThanOrEqualTo(450));
      });

      test('generateGrid uses grid preset', () {
        final sourceImage = createTestImage(800, 1200);

        final thumbnail = ThumbnailGenerator.generateGrid(sourceImage);

        final decoded = img.decodeImage(thumbnail);
        expect(decoded, isNotNull);
        expect(decoded!.width, lessThanOrEqualTo(150));
        expect(decoded.height, lessThanOrEqualTo(225));
      });

      test('generateSmall uses small preset', () {
        final sourceImage = createTestImage(400, 600);

        final thumbnail = ThumbnailGenerator.generateSmall(sourceImage);

        final decoded = img.decodeImage(thumbnail);
        expect(decoded, isNotNull);
        expect(decoded!.width, lessThanOrEqualTo(80));
        expect(decoded.height, lessThanOrEqualTo(120));
      });
    });

    group('calculateFitDimensions', () {
      test('returns original size when smaller than max', () {
        final (width, height) =
            ThumbnailGenerator.calculateFitDimensions(100, 100, 200, 200);
        expect(width, equals(100));
        expect(height, equals(100));
      });

      test('scales down width-constrained images', () {
        final (width, height) =
            ThumbnailGenerator.calculateFitDimensions(400, 200, 200, 200);
        expect(width, equals(200));
        expect(height, equals(100));
      });

      test('scales down height-constrained images', () {
        final (width, height) =
            ThumbnailGenerator.calculateFitDimensions(200, 400, 200, 200);
        expect(width, equals(100));
        expect(height, equals(200));
      });

      test('maintains aspect ratio', () {
        final (width, height) =
            ThumbnailGenerator.calculateFitDimensions(800, 600, 200, 200);
        final aspectRatio = width / height;
        expect(aspectRatio, closeTo(4 / 3, 0.01));
      });
    });

    group('canDecode', () {
      test('returns true for valid JPEG', () {
        final jpegImage = createTestImage(100, 100);
        expect(ThumbnailGenerator.canDecode(jpegImage), isTrue);
      });

      test('returns true for valid PNG', () {
        final pngImage = createTestImage(100, 100, asPng: true);
        expect(ThumbnailGenerator.canDecode(pngImage), isTrue);
      });

      test('returns false for invalid data', () {
        final invalidData = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
        expect(ThumbnailGenerator.canDecode(invalidData), isFalse);
      });
    });

    group('getImageDimensions', () {
      test('returns dimensions for valid image', () {
        final image = createTestImage(800, 600);
        final dims = ThumbnailGenerator.getImageDimensions(image);
        expect(dims, isNotNull);
        expect(dims!.$1, equals(800));
        expect(dims.$2, equals(600));
      });

      test('returns null for invalid data', () {
        final invalidData = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
        expect(ThumbnailGenerator.getImageDimensions(invalidData), isNull);
      });
    });
  });
}
