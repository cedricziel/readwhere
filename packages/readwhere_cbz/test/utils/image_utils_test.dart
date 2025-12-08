import 'dart:typed_data';

import 'package:readwhere_cbz/src/utils/image_utils.dart';
import 'package:test/test.dart';

void main() {
  group('ImageFormat', () {
    test('has correct MIME types', () {
      expect(ImageFormat.jpeg.mimeType, equals('image/jpeg'));
      expect(ImageFormat.png.mimeType, equals('image/png'));
      expect(ImageFormat.gif.mimeType, equals('image/gif'));
      expect(ImageFormat.webp.mimeType, equals('image/webp'));
      expect(ImageFormat.unknown.mimeType, equals('application/octet-stream'));
    });

    test('has correct extensions', () {
      expect(ImageFormat.jpeg.extensions, contains('.jpg'));
      expect(ImageFormat.jpeg.extensions, contains('.jpeg'));
      expect(ImageFormat.png.extensions, contains('.png'));
      expect(ImageFormat.gif.extensions, contains('.gif'));
      expect(ImageFormat.webp.extensions, contains('.webp'));
    });

    test('isSupported returns false for unknown', () {
      expect(ImageFormat.jpeg.isSupported, isTrue);
      expect(ImageFormat.png.isSupported, isTrue);
      expect(ImageFormat.unknown.isSupported, isFalse);
    });
  });

  group('ImageDimensions', () {
    test('calculates aspect ratio correctly', () {
      const dims = ImageDimensions(1600, 900);
      expect(dims.aspectRatio, closeTo(1.778, 0.001));
    });

    test('identifies portrait images', () {
      const dims = ImageDimensions(600, 900);
      expect(dims.isPortrait, isTrue);
      expect(dims.isLandscape, isFalse);
      expect(dims.isSquare, isFalse);
    });

    test('identifies landscape images', () {
      const dims = ImageDimensions(1600, 900);
      expect(dims.isPortrait, isFalse);
      expect(dims.isLandscape, isTrue);
      expect(dims.isSquare, isFalse);
    });

    test('identifies square images', () {
      const dims = ImageDimensions(100, 100);
      expect(dims.isPortrait, isFalse);
      expect(dims.isLandscape, isFalse);
      expect(dims.isSquare, isTrue);
    });

    test('tolerates near-square images', () {
      // 95x100 is within 10% tolerance
      const dims = ImageDimensions(95, 100);
      expect(dims.isSquare, isTrue);
    });

    test('toString shows dimensions', () {
      const dims = ImageDimensions(800, 600);
      expect(dims.toString(), equals('ImageDimensions(800 x 600)'));
    });
  });

  group('ImageUtils.detectFormat', () {
    test('detects JPEG from magic bytes', () {
      // JPEG starts with FF D8 FF
      final bytes = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, // SOI + APP0 marker
        0x00, 0x10, // Length
        0x4A, 0x46, 0x49, 0x46, 0x00, // "JFIF\0"
        ...List.filled(100, 0), // Padding
      ]);

      expect(ImageUtils.detectFormat(bytes), equals(ImageFormat.jpeg));
    });

    test('detects PNG from magic bytes', () {
      // PNG starts with 89 50 4E 47 0D 0A 1A 0A
      final bytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        ...List.filled(100, 0), // Padding
      ]);

      expect(ImageUtils.detectFormat(bytes), equals(ImageFormat.png));
    });

    test('detects GIF87a from magic bytes', () {
      // GIF87a
      final bytes = Uint8List.fromList([
        0x47, 0x49, 0x46, 0x38, 0x37, 0x61, // "GIF87a"
        ...List.filled(100, 0), // Padding
      ]);

      expect(ImageUtils.detectFormat(bytes), equals(ImageFormat.gif));
    });

    test('detects GIF89a from magic bytes', () {
      // GIF89a
      final bytes = Uint8List.fromList([
        0x47, 0x49, 0x46, 0x38, 0x39, 0x61, // "GIF89a"
        ...List.filled(100, 0), // Padding
      ]);

      expect(ImageUtils.detectFormat(bytes), equals(ImageFormat.gif));
    });

    test('detects WebP from magic bytes', () {
      // WebP: RIFF....WEBP
      final bytes = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, // "RIFF"
        0x00, 0x00, 0x00, 0x00, // Size (dummy)
        0x57, 0x45, 0x42, 0x50, // "WEBP"
        ...List.filled(100, 0), // Padding
      ]);

      expect(ImageUtils.detectFormat(bytes), equals(ImageFormat.webp));
    });

    test('returns unknown for unrecognized data', () {
      final bytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03, 0x04]);
      expect(ImageUtils.detectFormat(bytes), equals(ImageFormat.unknown));
    });

    test('returns unknown for too-short data', () {
      final bytes = Uint8List.fromList([0xFF, 0xD8]);
      expect(ImageUtils.detectFormat(bytes), equals(ImageFormat.unknown));
    });
  });

  group('ImageUtils.getMimeType', () {
    test('returns correct MIME type for detected format', () {
      final jpegBytes = Uint8List.fromList([
        0xFF,
        0xD8,
        0xFF,
        0xE0,
        ...List.filled(100, 0),
      ]);

      expect(ImageUtils.getMimeType(jpegBytes), equals('image/jpeg'));
    });
  });

  group('ImageUtils.getMimeTypeForExtension', () {
    test('returns correct MIME type for known extensions', () {
      expect(ImageUtils.getMimeTypeForExtension('.jpg'), equals('image/jpeg'));
      expect(ImageUtils.getMimeTypeForExtension('.jpeg'), equals('image/jpeg'));
      expect(ImageUtils.getMimeTypeForExtension('.png'), equals('image/png'));
      expect(ImageUtils.getMimeTypeForExtension('.gif'), equals('image/gif'));
      expect(ImageUtils.getMimeTypeForExtension('.webp'), equals('image/webp'));
    });

    test('is case-insensitive', () {
      expect(ImageUtils.getMimeTypeForExtension('.JPG'), equals('image/jpeg'));
      expect(ImageUtils.getMimeTypeForExtension('.PNG'), equals('image/png'));
    });

    test('returns octet-stream for unknown extensions', () {
      expect(
        ImageUtils.getMimeTypeForExtension('.xyz'),
        equals('application/octet-stream'),
      );
    });
  });

  group('ImageUtils.isImageFilename', () {
    test('returns true for image extensions', () {
      expect(ImageUtils.isImageFilename('photo.jpg'), isTrue);
      expect(ImageUtils.isImageFilename('image.jpeg'), isTrue);
      expect(ImageUtils.isImageFilename('graphic.png'), isTrue);
      expect(ImageUtils.isImageFilename('animation.gif'), isTrue);
      expect(ImageUtils.isImageFilename('modern.webp'), isTrue);
    });

    test('is case-insensitive', () {
      expect(ImageUtils.isImageFilename('PHOTO.JPG'), isTrue);
      expect(ImageUtils.isImageFilename('Image.PNG'), isTrue);
    });

    test('returns false for non-image extensions', () {
      expect(ImageUtils.isImageFilename('document.pdf'), isFalse);
      expect(ImageUtils.isImageFilename('data.xml'), isFalse);
      expect(ImageUtils.isImageFilename('script.js'), isFalse);
    });

    test('returns false for no extension', () {
      expect(ImageUtils.isImageFilename('noextension'), isFalse);
    });
  });

  group('ImageUtils dimension extraction', () {
    test('_getPngDimensions extracts dimensions from PNG header', () {
      // Minimal PNG header with IHDR chunk
      // PNG signature + IHDR chunk (13 bytes data)
      final bytes = Uint8List.fromList([
        // PNG signature (8 bytes)
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        // IHDR chunk length (4 bytes, big-endian) = 13
        0x00, 0x00, 0x00, 0x0D,
        // Chunk type "IHDR" (4 bytes)
        0x49, 0x48, 0x44, 0x52,
        // Width (4 bytes, big-endian) = 800
        0x00, 0x00, 0x03, 0x20,
        // Height (4 bytes, big-endian) = 600
        0x00, 0x00, 0x02, 0x58,
        // Rest of IHDR (5 bytes: bit depth, color type, etc.)
        0x08, 0x06, 0x00, 0x00, 0x00,
        // CRC (4 bytes)
        0x00, 0x00, 0x00, 0x00,
      ]);

      final dims = ImageUtils.getDimensionsFast(bytes);
      expect(dims, isNotNull);
      expect(dims!.width, equals(800));
      expect(dims.height, equals(600));
    });

    test('_getGifDimensions extracts dimensions from GIF header', () {
      // GIF header: signature (6) + width (2, LE) + height (2, LE)
      final bytes = Uint8List.fromList([
        // GIF89a signature
        0x47, 0x49, 0x46, 0x38, 0x39, 0x61,
        // Width (2 bytes, little-endian) = 320
        0x40, 0x01,
        // Height (2 bytes, little-endian) = 240
        0xF0, 0x00,
        // Rest of header
        ...List.filled(100, 0),
      ]);

      final dims = ImageUtils.getDimensionsFast(bytes);
      expect(dims, isNotNull);
      expect(dims!.width, equals(320));
      expect(dims.height, equals(240));
    });
  });
}
