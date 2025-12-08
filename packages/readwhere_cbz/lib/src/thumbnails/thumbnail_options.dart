import 'package:equatable/equatable.dart';

/// Output format for generated thumbnails.
enum ThumbnailFormat {
  /// JPEG format (smaller file size, lossy compression).
  jpeg,

  /// PNG format (larger file size, lossless compression).
  png,
}

/// Configuration options for thumbnail generation.
class ThumbnailOptions extends Equatable {
  /// Maximum width of the thumbnail in pixels.
  final int maxWidth;

  /// Maximum height of the thumbnail in pixels.
  final int maxHeight;

  /// JPEG quality (0-100). Only applies when format is JPEG.
  final int quality;

  /// Output format for the thumbnail.
  final ThumbnailFormat format;

  /// Creates thumbnail options with specified dimensions and quality.
  const ThumbnailOptions({
    this.maxWidth = 200,
    this.maxHeight = 300,
    this.quality = 80,
    this.format = ThumbnailFormat.jpeg,
  });

  /// Preset for cover thumbnails (larger, suitable for library display).
  static const cover = ThumbnailOptions(
    maxWidth: 300,
    maxHeight: 450,
    quality: 85,
  );

  /// Preset for grid thumbnails (medium, suitable for grid views).
  static const grid = ThumbnailOptions(
    maxWidth: 150,
    maxHeight: 225,
    quality: 80,
  );

  /// Preset for small thumbnails (compact, suitable for lists).
  static const small = ThumbnailOptions(
    maxWidth: 80,
    maxHeight: 120,
    quality: 75,
  );

  /// Preset for large thumbnails (high quality preview).
  static const large = ThumbnailOptions(
    maxWidth: 600,
    maxHeight: 900,
    quality: 90,
  );

  /// Creates options with PNG output format.
  ThumbnailOptions toPng() => ThumbnailOptions(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
        format: ThumbnailFormat.png,
      );

  /// Creates options with JPEG output format.
  ThumbnailOptions toJpeg({int? quality}) => ThumbnailOptions(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality ?? this.quality,
        format: ThumbnailFormat.jpeg,
      );

  /// Creates options with a specific maximum dimension (applies to both width and height).
  ThumbnailOptions withMaxDimension(int maxDimension) => ThumbnailOptions(
        maxWidth: maxDimension,
        maxHeight: maxDimension,
        quality: quality,
        format: format,
      );

  /// Creates options scaled by a factor.
  ThumbnailOptions scaled(double factor) => ThumbnailOptions(
        maxWidth: (maxWidth * factor).round(),
        maxHeight: (maxHeight * factor).round(),
        quality: quality,
        format: format,
      );

  /// The file extension for this format.
  String get extension => format == ThumbnailFormat.jpeg ? '.jpg' : '.png';

  /// The MIME type for this format.
  String get mimeType =>
      format == ThumbnailFormat.jpeg ? 'image/jpeg' : 'image/png';

  @override
  List<Object?> get props => [maxWidth, maxHeight, quality, format];

  @override
  String toString() =>
      'ThumbnailOptions(${maxWidth}x$maxHeight, quality: $quality, format: ${format.name})';
}
