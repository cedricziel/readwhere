import 'package:equatable/equatable.dart';

/// Represents a page in a PDF document.
class PdfPage with EquatableMixin {
  /// Zero-based page index.
  final int index;

  /// Page width in points (72 points = 1 inch).
  final double width;

  /// Page height in points (72 points = 1 inch).
  final double height;

  /// Page rotation in degrees (0, 90, 180, or 270).
  final int rotation;

  const PdfPage({
    required this.index,
    required this.width,
    required this.height,
    this.rotation = 0,
  });

  /// The aspect ratio (width / height) of this page.
  double get aspectRatio => width / height;

  /// Whether this page is in portrait orientation.
  bool get isPortrait => height > width;

  /// Whether this page is in landscape orientation.
  bool get isLandscape => width > height;

  /// Whether this page is square.
  bool get isSquare => width == height;

  /// The effective width after applying rotation.
  double get effectiveWidth =>
      (rotation == 90 || rotation == 270) ? height : width;

  /// The effective height after applying rotation.
  double get effectiveHeight =>
      (rotation == 90 || rotation == 270) ? width : height;

  /// Returns a copy with the specified fields replaced.
  PdfPage copyWith({int? index, double? width, double? height, int? rotation}) {
    return PdfPage(
      index: index ?? this.index,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
    );
  }

  @override
  List<Object?> get props => [index, width, height, rotation];

  @override
  String toString() {
    return 'PdfPage(index: $index, width: $width, height: $height, '
        'rotation: $rotation)';
  }
}

/// Dimensions of a page (width and height in pixels at a given scale).
class PageDimensions with EquatableMixin {
  /// Width in pixels.
  final int width;

  /// Height in pixels.
  final int height;

  const PageDimensions({required this.width, required this.height});

  /// The aspect ratio (width / height).
  double get aspectRatio => width / height;

  @override
  List<Object?> get props => [width, height];

  @override
  String toString() => 'PageDimensions($width x $height)';
}
