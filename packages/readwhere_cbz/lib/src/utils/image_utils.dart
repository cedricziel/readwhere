import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../errors/cbz_exception.dart';

/// Supported image formats in CBZ archives.
enum ImageFormat {
  /// JPEG image.
  jpeg('image/jpeg', ['.jpg', '.jpeg']),

  /// PNG image.
  png('image/png', ['.png']),

  /// GIF image.
  gif('image/gif', ['.gif']),

  /// WebP image.
  webp('image/webp', ['.webp']),

  /// Unknown or unsupported format.
  unknown('application/octet-stream', []);

  /// MIME type for this format.
  final String mimeType;

  /// Common file extensions for this format.
  final List<String> extensions;

  const ImageFormat(this.mimeType, this.extensions);

  /// Whether this is a known/supported format.
  bool get isSupported => this != unknown;
}

/// Image dimensions.
class ImageDimensions {
  /// Width in pixels.
  final int width;

  /// Height in pixels.
  final int height;

  const ImageDimensions(this.width, this.height);

  /// Aspect ratio (width / height).
  double get aspectRatio => height > 0 ? width / height : 0;

  /// Whether this is a portrait (tall) image.
  bool get isPortrait => aspectRatio < 1.0;

  /// Whether this is a landscape (wide) image.
  bool get isLandscape => aspectRatio > 1.0;

  /// Whether this is approximately square.
  bool get isSquare {
    final ratio = aspectRatio;
    return ratio >= 0.9 && ratio <= 1.1;
  }

  @override
  String toString() => 'ImageDimensions($width x $height)';
}

/// Utilities for working with image data.
class ImageUtils {
  ImageUtils._();

  // Magic byte signatures for image formats
  static const _jpegMagic = [0xFF, 0xD8, 0xFF];
  static const _pngMagic = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  static const _gifMagic87 = [0x47, 0x49, 0x46, 0x38, 0x37, 0x61]; // GIF87a
  static const _gifMagic89 = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61]; // GIF89a
  static const _webpMagic = [0x52, 0x49, 0x46, 0x46]; // RIFF (WebP container)

  /// Detects the image format from raw bytes using magic byte signatures.
  ///
  /// This is more reliable than file extensions as it examines the actual
  /// file content.
  static ImageFormat detectFormat(Uint8List bytes) {
    if (bytes.length < 12) return ImageFormat.unknown;

    // Check JPEG (starts with FF D8 FF)
    if (_matchesMagic(bytes, _jpegMagic)) {
      return ImageFormat.jpeg;
    }

    // Check PNG (starts with 89 50 4E 47 0D 0A 1A 0A)
    if (_matchesMagic(bytes, _pngMagic)) {
      return ImageFormat.png;
    }

    // Check GIF (starts with GIF87a or GIF89a)
    if (_matchesMagic(bytes, _gifMagic87) ||
        _matchesMagic(bytes, _gifMagic89)) {
      return ImageFormat.gif;
    }

    // Check WebP (starts with RIFF, then has WEBP at offset 8)
    if (_matchesMagic(bytes, _webpMagic) && bytes.length >= 12) {
      // Check for "WEBP" at offset 8
      if (bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        return ImageFormat.webp;
      }
    }

    return ImageFormat.unknown;
  }

  /// Checks if bytes start with the given magic signature.
  static bool _matchesMagic(Uint8List bytes, List<int> magic) {
    if (bytes.length < magic.length) return false;
    for (var i = 0; i < magic.length; i++) {
      if (bytes[i] != magic[i]) return false;
    }
    return true;
  }

  /// Gets the MIME type for image bytes.
  static String getMimeType(Uint8List bytes) {
    return detectFormat(bytes).mimeType;
  }

  /// Gets the MIME type for a file extension.
  ///
  /// The extension should include the dot (e.g., '.jpg').
  static String getMimeTypeForExtension(String extension) {
    final lower = extension.toLowerCase();
    for (final format in ImageFormat.values) {
      if (format.extensions.contains(lower)) {
        return format.mimeType;
      }
    }
    return ImageFormat.unknown.mimeType;
  }

  /// Extracts image dimensions from raw bytes.
  ///
  /// Uses the `image` package to decode just enough of the image
  /// to determine its dimensions.
  ///
  /// Throws [CbzImageException] if dimensions cannot be extracted.
  static ImageDimensions getDimensions(Uint8List bytes) {
    try {
      final decoder = img.findDecoderForData(bytes);
      if (decoder == null) {
        throw CbzImageException('Unable to find decoder for image data');
      }

      final image = decoder.decode(bytes);
      if (image == null) {
        throw CbzImageException('Failed to decode image');
      }

      return ImageDimensions(image.width, image.height);
    } catch (e, st) {
      if (e is CbzException) rethrow;
      throw CbzImageException(
        'Failed to extract image dimensions: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Attempts to extract dimensions without full decode.
  ///
  /// This is a faster method that tries to read just the image header.
  /// Returns null if it cannot determine dimensions quickly.
  static ImageDimensions? getDimensionsFast(Uint8List bytes) {
    final format = detectFormat(bytes);

    switch (format) {
      case ImageFormat.png:
        return _getPngDimensions(bytes);
      case ImageFormat.jpeg:
        return _getJpegDimensions(bytes);
      case ImageFormat.gif:
        return _getGifDimensions(bytes);
      default:
        // Fall back to full decode for WebP and unknown formats
        return null;
    }
  }

  /// Extracts PNG dimensions from the IHDR chunk.
  static ImageDimensions? _getPngDimensions(Uint8List bytes) {
    // PNG header is 8 bytes, then IHDR chunk
    // IHDR starts at byte 8: 4 bytes length, 4 bytes "IHDR", then width/height
    if (bytes.length < 24) return null;

    // Check for IHDR chunk type at offset 12
    if (bytes[12] != 0x49 ||
        bytes[13] != 0x48 ||
        bytes[14] != 0x44 ||
        bytes[15] != 0x52) {
      return null;
    }

    // Width is at offset 16 (4 bytes, big-endian)
    final width =
        (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];

    // Height is at offset 20 (4 bytes, big-endian)
    final height =
        (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];

    return ImageDimensions(width, height);
  }

  /// Extracts JPEG dimensions from the SOF marker.
  static ImageDimensions? _getJpegDimensions(Uint8List bytes) {
    if (bytes.length < 4) return null;

    var offset = 2; // Skip SOI marker (FF D8)

    while (offset < bytes.length - 8) {
      if (bytes[offset] != 0xFF) {
        offset++;
        continue;
      }

      final marker = bytes[offset + 1];

      // SOF0-SOF2 contain dimensions
      if (marker >= 0xC0 && marker <= 0xC2) {
        // Skip marker (2 bytes) and length (2 bytes) and precision (1 byte)
        final height = (bytes[offset + 5] << 8) | bytes[offset + 6];
        final width = (bytes[offset + 7] << 8) | bytes[offset + 8];
        return ImageDimensions(width, height);
      }

      // Skip to next marker
      if (marker == 0xD8 || marker == 0xD9 || marker == 0x01) {
        offset += 2;
      } else {
        final length = (bytes[offset + 2] << 8) | bytes[offset + 3];
        offset += 2 + length;
      }
    }

    return null;
  }

  /// Extracts GIF dimensions from the header.
  static ImageDimensions? _getGifDimensions(Uint8List bytes) {
    // GIF header: 6 bytes signature, then 2 bytes width, 2 bytes height
    if (bytes.length < 10) return null;

    // Width and height are little-endian at offsets 6 and 8
    final width = bytes[6] | (bytes[7] << 8);
    final height = bytes[8] | (bytes[9] << 8);

    return ImageDimensions(width, height);
  }

  /// Checks if a filename has an image extension.
  static bool isImageFilename(String filename) {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex == -1) return false;

    final ext = filename.substring(dotIndex).toLowerCase();
    for (final format in ImageFormat.values) {
      if (format.extensions.contains(ext)) {
        return true;
      }
    }
    return false;
  }
}
