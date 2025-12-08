import 'dart:convert';
import 'dart:typed_data';

import 'resource.dart';

/// An EPUB image resource.
class EpubImage extends EpubResource {
  /// Raw bytes of the image.
  final Uint8List bytes;

  const EpubImage({
    required super.id,
    required super.href,
    required super.mediaType,
    required this.bytes,
    super.properties,
  });

  @override
  int get size => bytes.length;

  /// Whether this is the cover image (based on properties).
  bool get isCoverImage => properties.contains('cover-image');

  /// Whether this is a vector image (SVG).
  bool get isVector => mediaType == 'image/svg+xml';

  /// Whether this is a raster image.
  bool get isRaster => !isVector;

  /// Image format based on media type.
  ImageFormat get format {
    return switch (mediaType) {
      'image/jpeg' => ImageFormat.jpeg,
      'image/png' => ImageFormat.png,
      'image/gif' => ImageFormat.gif,
      'image/webp' => ImageFormat.webp,
      'image/svg+xml' => ImageFormat.svg,
      'image/avif' => ImageFormat.avif,
      'image/jxl' => ImageFormat.jxl,
      _ => ImageFormat.unknown,
    };
  }

  /// Returns a data URI for the image.
  String get dataUri {
    final base64Data = base64Encode(bytes);
    return 'data:$mediaType;base64,$base64Data';
  }

  @override
  List<Object?> get props => [id, href, mediaType, bytes, properties];

  /// Creates an image from media type string.
  static EpubImage? fromMediaType({
    required String id,
    required String href,
    required String mediaType,
    required Uint8List bytes,
    Set<String> properties = const {},
  }) {
    // Only create if it's a recognized image type
    if (!_isImageMediaType(mediaType)) {
      return null;
    }

    return EpubImage(
      id: id,
      href: href,
      mediaType: mediaType,
      bytes: bytes,
      properties: properties,
    );
  }

  static bool _isImageMediaType(String mediaType) {
    return mediaType.startsWith('image/') ||
        mediaType == 'application/svg+xml';
  }
}

/// Supported image formats.
enum ImageFormat {
  jpeg,
  png,
  gif,
  webp,
  svg,
  avif,
  jxl,
  unknown;

  /// File extension for this format.
  String get extension {
    return switch (this) {
      ImageFormat.jpeg => '.jpg',
      ImageFormat.png => '.png',
      ImageFormat.gif => '.gif',
      ImageFormat.webp => '.webp',
      ImageFormat.svg => '.svg',
      ImageFormat.avif => '.avif',
      ImageFormat.jxl => '.jxl',
      ImageFormat.unknown => '',
    };
  }

  /// MIME type for this format.
  String get mimeType {
    return switch (this) {
      ImageFormat.jpeg => 'image/jpeg',
      ImageFormat.png => 'image/png',
      ImageFormat.gif => 'image/gif',
      ImageFormat.webp => 'image/webp',
      ImageFormat.svg => 'image/svg+xml',
      ImageFormat.avif => 'image/avif',
      ImageFormat.jxl => 'image/jxl',
      ImageFormat.unknown => 'application/octet-stream',
    };
  }

  /// Whether this format supports transparency.
  bool get supportsTransparency {
    return switch (this) {
      ImageFormat.jpeg => false,
      ImageFormat.png => true,
      ImageFormat.gif => true,
      ImageFormat.webp => true,
      ImageFormat.svg => true,
      ImageFormat.avif => true,
      ImageFormat.jxl => true,
      ImageFormat.unknown => false,
    };
  }
}

/// Represents cover image information.
class CoverImage {
  /// The image resource.
  final EpubImage image;

  /// How the cover was discovered.
  final CoverDiscoveryMethod method;

  const CoverImage({
    required this.image,
    required this.method,
  });

  /// Raw image bytes.
  Uint8List get bytes => image.bytes;

  /// Image media type.
  String get mediaType => image.mediaType;

  /// Image format.
  ImageFormat get format => image.format;

  /// Data URI for the cover.
  String get dataUri => image.dataUri;
}

/// How the cover image was discovered.
enum CoverDiscoveryMethod {
  /// From manifest item with cover-image property (EPUB 3).
  manifestProperty,

  /// From metadata cover meta element (EPUB 2).
  metadataCoverMeta,

  /// From guide reference with type="cover".
  guideReference,

  /// First image in the first spine item.
  firstSpineImage,

  /// Image named "cover" in the manifest.
  coverNameHeuristic,
}
