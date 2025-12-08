import 'package:equatable/equatable.dart';

/// Layout mode for EPUB rendition.
enum RenditionLayout {
  /// Content reflows to fit the viewport (default).
  reflowable,

  /// Content has fixed dimensions (pre-paginated).
  prePaginated,
}

/// Orientation preference for EPUB rendition.
enum RenditionOrientation {
  /// Automatically determine based on viewport.
  auto,

  /// Portrait orientation preferred.
  portrait,

  /// Landscape orientation preferred.
  landscape,
}

/// Spread behavior for EPUB rendition.
enum RenditionSpread {
  /// Automatically determine spread behavior.
  auto,

  /// Never display as a spread (single page).
  none,

  /// Display as spread only in landscape.
  landscape,

  /// Always display as spread if viewport allows.
  both,
}

/// Viewport dimensions for fixed-layout content.
class ViewportDimensions extends Equatable {
  /// Width in pixels.
  final int width;

  /// Height in pixels.
  final int height;

  const ViewportDimensions({
    required this.width,
    required this.height,
  });

  /// Parses viewport from string format "width=1024, height=768".
  ///
  /// Returns null if the format is invalid.
  static ViewportDimensions? tryParse(String value) {
    final normalized = value.replaceAll(' ', '').toLowerCase();

    int? width;
    int? height;

    // Parse width=N and height=N patterns
    final widthMatch = RegExp(r'width=(\d+)').firstMatch(normalized);
    final heightMatch = RegExp(r'height=(\d+)').firstMatch(normalized);

    if (widthMatch != null) {
      width = int.tryParse(widthMatch.group(1)!);
    }
    if (heightMatch != null) {
      height = int.tryParse(heightMatch.group(1)!);
    }

    if (width != null && height != null && width > 0 && height > 0) {
      return ViewportDimensions(width: width, height: height);
    }
    return null;
  }

  /// Aspect ratio (width / height).
  double get aspectRatio => width / height;

  /// Whether this is a landscape viewport.
  bool get isLandscape => width > height;

  /// Whether this is a portrait viewport.
  bool get isPortrait => height > width;

  /// Whether this is a square viewport.
  bool get isSquare => width == height;

  @override
  List<Object?> get props => [width, height];

  @override
  String toString() => 'ViewportDimensions(width=$width, height=$height)';
}

/// Rendition properties for an EPUB publication.
///
/// These properties control how the content should be rendered,
/// particularly for fixed-layout EPUBs.
class RenditionProperties extends Equatable {
  /// Layout mode (reflowable or pre-paginated).
  final RenditionLayout layout;

  /// Orientation preference.
  final RenditionOrientation orientation;

  /// Spread behavior.
  final RenditionSpread spread;

  /// Viewport dimensions for fixed-layout content.
  final ViewportDimensions? viewport;

  const RenditionProperties({
    this.layout = RenditionLayout.reflowable,
    this.orientation = RenditionOrientation.auto,
    this.spread = RenditionSpread.auto,
    this.viewport,
  });

  /// Default rendition properties (reflowable layout).
  static const RenditionProperties defaultProperties = RenditionProperties();

  /// Whether this is a fixed-layout publication.
  bool get isFixedLayout => layout == RenditionLayout.prePaginated;

  /// Whether this is a reflowable publication.
  bool get isReflowable => layout == RenditionLayout.reflowable;

  /// Whether viewport dimensions are specified.
  bool get hasViewport => viewport != null;

  /// Creates a copy with modified properties.
  RenditionProperties copyWith({
    RenditionLayout? layout,
    RenditionOrientation? orientation,
    RenditionSpread? spread,
    ViewportDimensions? viewport,
  }) {
    return RenditionProperties(
      layout: layout ?? this.layout,
      orientation: orientation ?? this.orientation,
      spread: spread ?? this.spread,
      viewport: viewport ?? this.viewport,
    );
  }

  @override
  List<Object?> get props => [layout, orientation, spread, viewport];

  @override
  String toString() => 'RenditionProperties('
      'layout: $layout, '
      'orientation: $orientation, '
      'spread: $spread, '
      'viewport: $viewport)';
}

/// Per-item rendition overrides for spine items.
///
/// These can override the publication-level rendition properties
/// for individual spine items.
class SpineItemRendition extends Equatable {
  /// Item-level layout override.
  final RenditionLayout? layout;

  /// Item-level orientation override.
  final RenditionOrientation? orientation;

  /// Item-level spread override.
  final RenditionSpread? spread;

  const SpineItemRendition({
    this.layout,
    this.orientation,
    this.spread,
  });

  /// No overrides.
  static const SpineItemRendition none = SpineItemRendition();

  /// Whether any overrides are specified.
  bool get hasOverrides =>
      layout != null || orientation != null || spread != null;

  @override
  List<Object?> get props => [layout, orientation, spread];
}
