import 'package:equatable/equatable.dart';

/// Options for rendering a PDF page to an image.
class PdfRenderOptions with EquatableMixin {
  /// The scale factor for rendering (1.0 = 72 DPI, 2.0 = 144 DPI, etc.).
  final double scale;

  /// The background color to use (ARGB format). Null for transparent.
  final int? backgroundColor;

  /// Whether to include annotations in the rendered output.
  final bool includeAnnotations;

  /// Maximum width constraint in pixels. If specified, the page will be scaled
  /// to fit within this width while maintaining aspect ratio.
  final int? maxWidth;

  /// Maximum height constraint in pixels. If specified, the page will be scaled
  /// to fit within this height while maintaining aspect ratio.
  final int? maxHeight;

  const PdfRenderOptions({
    this.scale = 2.0,
    this.backgroundColor,
    this.includeAnnotations = true,
    this.maxWidth,
    this.maxHeight,
  });

  /// Default rendering options (2x scale for good quality).
  static const PdfRenderOptions standard = PdfRenderOptions();

  /// Low quality rendering options for thumbnails.
  static const PdfRenderOptions thumbnail = PdfRenderOptions(
    scale: 0.5,
    maxWidth: 200,
  );

  /// High quality rendering options.
  static const PdfRenderOptions highQuality = PdfRenderOptions(scale: 4.0);

  /// Returns a copy with the specified fields replaced.
  PdfRenderOptions copyWith({
    double? scale,
    int? backgroundColor,
    bool? includeAnnotations,
    int? maxWidth,
    int? maxHeight,
  }) {
    return PdfRenderOptions(
      scale: scale ?? this.scale,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      includeAnnotations: includeAnnotations ?? this.includeAnnotations,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
    );
  }

  @override
  List<Object?> get props => [
    scale,
    backgroundColor,
    includeAnnotations,
    maxWidth,
    maxHeight,
  ];

  @override
  String toString() {
    return 'PdfRenderOptions(scale: $scale, backgroundColor: $backgroundColor, '
        'includeAnnotations: $includeAnnotations, maxWidth: $maxWidth, '
        'maxHeight: $maxHeight)';
  }
}
