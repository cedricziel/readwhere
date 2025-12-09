import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'panel.dart';
import 'reading_order.dart';

/// Options for panel detection.
class PanelDetectionOptions {
  /// Threshold for converting grayscale to binary (0-255).
  ///
  /// Pixels brighter than this are considered background (gutters).
  /// Lower values detect more content as panels.
  final int threshold;

  /// Minimum panel area as a fraction of the total image area.
  ///
  /// Panels smaller than this fraction are filtered out as noise.
  final double minPanelAreaFraction;

  /// Maximum panel area as a fraction of the total image area.
  ///
  /// Panels larger than this are likely the full page (no panels detected).
  final double maxPanelAreaFraction;

  /// Minimum aspect ratio for panels (width / height).
  final double minAspectRatio;

  /// Maximum aspect ratio for panels (width / height).
  final double maxAspectRatio;

  /// Whether to invert the image before detection.
  ///
  /// Set to true if panels are dark on light background.
  final bool invert;

  /// Margin to add around detected panels (in pixels).
  final int panelMargin;

  /// Reading direction for sorting panels.
  final ReadingDirection readingDirection;

  /// Creates detection options with the given parameters.
  const PanelDetectionOptions({
    this.threshold = 240,
    this.minPanelAreaFraction = 0.01,
    this.maxPanelAreaFraction = 0.95,
    this.minAspectRatio = 0.1,
    this.maxAspectRatio = 10.0,
    this.invert = false,
    this.panelMargin = 5,
    this.readingDirection = ReadingDirection.leftToRight,
  });

  /// Default options for Western comics (LTR).
  static const western = PanelDetectionOptions(
    readingDirection: ReadingDirection.leftToRight,
  );

  /// Default options for Manga (RTL).
  static const manga = PanelDetectionOptions(
    readingDirection: ReadingDirection.rightToLeft,
  );
}

/// Result of panel detection.
class PanelDetectionResult {
  /// Detected panels sorted by reading order.
  final List<Panel> panels;

  /// Width of the source image.
  final int imageWidth;

  /// Height of the source image.
  final int imageHeight;

  /// Whether detection was successful.
  final bool success;

  /// Error message if detection failed.
  final String? error;

  /// Creates a successful result.
  const PanelDetectionResult({
    required this.panels,
    required this.imageWidth,
    required this.imageHeight,
  }) : success = true,
       error = null;

  /// Creates a failed result.
  const PanelDetectionResult.failed(this.error)
    : panels = const [],
      imageWidth = 0,
      imageHeight = 0,
      success = false;

  /// Number of detected panels.
  int get panelCount => panels.length;

  /// Whether no panels were detected (full page mode).
  bool get isFullPage => panels.isEmpty;
}

/// Detects panels in comic book pages using connected component labeling.
///
/// The algorithm works as follows:
/// 1. Decode the image from bytes
/// 2. Convert to grayscale
/// 3. Apply threshold to create binary image (content vs background)
/// 4. Find connected components (flood fill)
/// 5. Extract bounding boxes for each component
/// 6. Filter by size and aspect ratio
/// 7. Sort by reading order
class PanelDetector {
  /// Detection options.
  final PanelDetectionOptions options;

  /// Creates a detector with the given options.
  const PanelDetector({this.options = const PanelDetectionOptions()});

  /// Detects panels in the given image bytes.
  ///
  /// Supports common image formats (PNG, JPEG, WebP, etc.).
  PanelDetectionResult detect(Uint8List imageBytes) {
    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return const PanelDetectionResult.failed('Failed to decode image');
      }

      return detectFromImage(image);
    } catch (e) {
      return PanelDetectionResult.failed('Detection error: $e');
    }
  }

  /// Detects panels in an already-decoded image.
  PanelDetectionResult detectFromImage(img.Image image) {
    try {
      final width = image.width;
      final height = image.height;
      final totalArea = width * height;

      // Convert to grayscale
      final grayscale = img.grayscale(image);

      // Create binary image (true = content, false = background)
      final binary = _createBinaryImage(grayscale);

      // Find connected components
      final components = _findConnectedComponents(binary, width, height);

      // Convert to panels and filter
      var panels = <Panel>[];
      for (final bounds in components) {
        final area = bounds.area;
        final areaFraction = area / totalArea;

        // Filter by area
        if (areaFraction < options.minPanelAreaFraction) continue;
        if (areaFraction > options.maxPanelAreaFraction) continue;

        // Filter by aspect ratio
        final aspectRatio = bounds.aspectRatio;
        if (aspectRatio < options.minAspectRatio) continue;
        if (aspectRatio > options.maxAspectRatio) continue;

        // Add margin and clamp to image bounds
        var panel = bounds.expand(options.panelMargin);
        panel = panel.clamp(width, height);

        panels.add(panel);
      }

      // Sort by reading order
      final sorter = ReadingOrderSorter(direction: options.readingDirection);
      panels = sorter.sort(panels);

      return PanelDetectionResult(
        panels: panels,
        imageWidth: width,
        imageHeight: height,
      );
    } catch (e) {
      return PanelDetectionResult.failed('Detection error: $e');
    }
  }

  /// Creates a binary image from grayscale.
  ///
  /// Returns a 2D list where true = content, false = background.
  List<List<bool>> _createBinaryImage(img.Image grayscale) {
    final width = grayscale.width;
    final height = grayscale.height;
    final binary = List.generate(height, (_) => List.filled(width, false));

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = grayscale.getPixel(x, y);
        // Get luminance (grayscale value)
        final lum = img.getLuminance(pixel);

        // Content is darker than threshold
        var isContent = lum < options.threshold;
        if (options.invert) isContent = !isContent;

        binary[y][x] = isContent;
      }
    }

    return binary;
  }

  /// Finds connected components using flood fill.
  ///
  /// Returns bounding boxes for each connected component.
  List<Panel> _findConnectedComponents(
    List<List<bool>> binary,
    int width,
    int height,
  ) {
    final visited = List.generate(height, (_) => List.filled(width, false));

    final components = <Panel>[];

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (binary[y][x] && !visited[y][x]) {
          final bounds = _floodFill(binary, visited, x, y, width, height);
          if (bounds != null) {
            components.add(bounds);
          }
        }
      }
    }

    return components;
  }

  /// Flood fill from a starting point to find component bounds.
  Panel? _floodFill(
    List<List<bool>> binary,
    List<List<bool>> visited,
    int startX,
    int startY,
    int width,
    int height,
  ) {
    var minX = startX;
    var minY = startY;
    var maxX = startX;
    var maxY = startY;

    // Use iterative flood fill with a stack to avoid stack overflow
    final stack = <_Point>[_Point(startX, startY)];

    while (stack.isNotEmpty) {
      final point = stack.removeLast();
      final x = point.x;
      final y = point.y;

      if (x < 0 || x >= width || y < 0 || y >= height) continue;
      if (visited[y][x] || !binary[y][x]) continue;

      visited[y][x] = true;

      // Update bounds
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;

      // Add neighbors (4-connectivity)
      stack.add(_Point(x + 1, y));
      stack.add(_Point(x - 1, y));
      stack.add(_Point(x, y + 1));
      stack.add(_Point(x, y - 1));
    }

    return Panel(
      x: minX,
      y: minY,
      width: maxX - minX + 1,
      height: maxY - minY + 1,
    );
  }
}

/// Simple point class for flood fill.
class _Point {
  final int x;
  final int y;
  const _Point(this.x, this.y);
}
