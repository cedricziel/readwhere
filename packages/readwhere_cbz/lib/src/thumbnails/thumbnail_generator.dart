import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../errors/cbz_exception.dart';
import 'thumbnail_options.dart';

/// Generates thumbnails from image data.
class ThumbnailGenerator {
  ThumbnailGenerator._();

  /// Generates a thumbnail from image bytes.
  ///
  /// The thumbnail maintains the original aspect ratio while fitting
  /// within the dimensions specified by [options].
  ///
  /// Throws [CbzImageException] if the image cannot be decoded or processed.
  static Uint8List generate(
    Uint8List imageBytes,
    ThumbnailOptions options,
  ) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw CbzImageException('Failed to decode image for thumbnail');
      }

      final thumbnail =
          _resizeToFit(image, options.maxWidth, options.maxHeight);
      return _encode(thumbnail, options);
    } catch (e, st) {
      if (e is CbzException) rethrow;
      throw CbzImageException(
        'Failed to generate thumbnail: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Generates a thumbnail maintaining aspect ratio with a single maximum dimension.
  ///
  /// The thumbnail will fit within a square of the specified size.
  static Uint8List generateWithMaxDimension(
    Uint8List imageBytes,
    int maxDimension, {
    ThumbnailFormat format = ThumbnailFormat.jpeg,
    int quality = 80,
  }) {
    return generate(
      imageBytes,
      ThumbnailOptions(
        maxWidth: maxDimension,
        maxHeight: maxDimension,
        quality: quality,
        format: format,
      ),
    );
  }

  /// Generates a cover thumbnail using preset options.
  static Uint8List generateCover(Uint8List imageBytes) {
    return generate(imageBytes, ThumbnailOptions.cover);
  }

  /// Generates a grid thumbnail using preset options.
  static Uint8List generateGrid(Uint8List imageBytes) {
    return generate(imageBytes, ThumbnailOptions.grid);
  }

  /// Generates a small thumbnail using preset options.
  static Uint8List generateSmall(Uint8List imageBytes) {
    return generate(imageBytes, ThumbnailOptions.small);
  }

  /// Calculates the dimensions for a thumbnail that fits within maxWidth x maxHeight
  /// while maintaining aspect ratio.
  static (int width, int height) calculateFitDimensions(
    int sourceWidth,
    int sourceHeight,
    int maxWidth,
    int maxHeight,
  ) {
    if (sourceWidth <= maxWidth && sourceHeight <= maxHeight) {
      return (sourceWidth, sourceHeight);
    }

    final widthRatio = maxWidth / sourceWidth;
    final heightRatio = maxHeight / sourceHeight;
    final ratio = widthRatio < heightRatio ? widthRatio : heightRatio;

    final newWidth = (sourceWidth * ratio).round();
    final newHeight = (sourceHeight * ratio).round();

    return (newWidth, newHeight);
  }

  /// Resizes an image to fit within the specified dimensions.
  static img.Image _resizeToFit(img.Image image, int maxWidth, int maxHeight) {
    final (newWidth, newHeight) = calculateFitDimensions(
      image.width,
      image.height,
      maxWidth,
      maxHeight,
    );

    // If no resize needed, return original
    if (newWidth == image.width && newHeight == image.height) {
      return image;
    }

    // Use Lanczos interpolation for high quality resize
    return img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );
  }

  /// Encodes an image to bytes in the specified format.
  static Uint8List _encode(img.Image image, ThumbnailOptions options) {
    switch (options.format) {
      case ThumbnailFormat.jpeg:
        return Uint8List.fromList(
          img.encodeJpg(image, quality: options.quality),
        );
      case ThumbnailFormat.png:
        return Uint8List.fromList(img.encodePng(image));
    }
  }

  /// Checks if the given bytes can be decoded as an image.
  static bool canDecode(Uint8List bytes) {
    try {
      return img.findDecoderForData(bytes) != null;
    } catch (_) {
      return false;
    }
  }

  /// Gets the dimensions of an image without generating a thumbnail.
  static (int width, int height)? getImageDimensions(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;
      return (image.width, image.height);
    } catch (_) {
      return null;
    }
  }
}
