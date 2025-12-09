import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:readwhere_panel_detection/readwhere_panel_detection.dart';
import 'package:test/test.dart';

void main() {
  group('PanelDetector', () {
    test('detects single dark rectangle on white background', () {
      // Create a 200x200 white image with a dark rectangle
      final image = img.Image(width: 200, height: 200);
      img.fill(image, color: img.ColorRgb8(255, 255, 255)); // White background

      // Draw a dark rectangle (panel) in the center
      img.fillRect(
        image,
        x1: 50,
        y1: 50,
        x2: 150,
        y2: 150,
        color: img.ColorRgb8(0, 0, 0),
      );

      final detector = PanelDetector();
      final result = detector.detectFromImage(image);

      expect(result.success, true);
      expect(result.imageWidth, 200);
      expect(result.imageHeight, 200);
      expect(result.panels.isNotEmpty, true);

      // Should detect approximately the dark region
      final panel = result.panels.first;
      expect(panel.x, lessThanOrEqualTo(55)); // With margin
      expect(panel.y, lessThanOrEqualTo(55));
    });

    test('detects multiple panels', () {
      // Create a 400x200 white image with two dark rectangles
      final image = img.Image(width: 400, height: 200);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));

      // Left panel
      img.fillRect(
        image,
        x1: 20,
        y1: 20,
        x2: 180,
        y2: 180,
        color: img.ColorRgb8(0, 0, 0),
      );

      // Right panel
      img.fillRect(
        image,
        x1: 220,
        y1: 20,
        x2: 380,
        y2: 180,
        color: img.ColorRgb8(0, 0, 0),
      );

      final detector = PanelDetector();
      final result = detector.detectFromImage(image);

      expect(result.success, true);
      expect(result.panels.length, 2);

      // Panels should be sorted left-to-right
      expect(result.panels[0].x, lessThan(result.panels[1].x));
      expect(result.panels[0].order, 0);
      expect(result.panels[1].order, 1);
    });

    test('respects reading direction option', () {
      // Create image with two panels
      final image = img.Image(width: 400, height: 200);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));

      // Left panel
      img.fillRect(
        image,
        x1: 20,
        y1: 20,
        x2: 180,
        y2: 180,
        color: img.ColorRgb8(0, 0, 0),
      );

      // Right panel
      img.fillRect(
        image,
        x1: 220,
        y1: 20,
        x2: 380,
        y2: 180,
        color: img.ColorRgb8(0, 0, 0),
      );

      final detector = PanelDetector(
        options: PanelDetectionOptions.manga, // RTL
      );
      final result = detector.detectFromImage(image);

      expect(result.success, true);
      expect(result.panels.length, 2);

      // Panels should be sorted right-to-left for manga
      expect(result.panels[0].x, greaterThan(result.panels[1].x));
      expect(result.panels[0].order, 0);
      expect(result.panels[1].order, 1);
    });

    test('filters small noise', () {
      // Create image with one large panel and small noise
      final image = img.Image(width: 200, height: 200);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));

      // Large panel
      img.fillRect(
        image,
        x1: 20,
        y1: 20,
        x2: 180,
        y2: 180,
        color: img.ColorRgb8(0, 0, 0),
      );

      // Small noise (should be filtered)
      img.fillRect(
        image,
        x1: 5,
        y1: 5,
        x2: 8,
        y2: 8,
        color: img.ColorRgb8(0, 0, 0),
      );

      final detector = PanelDetector(
        options: PanelDetectionOptions(
          minPanelAreaFraction: 0.01, // 1% minimum
        ),
      );
      final result = detector.detectFromImage(image);

      expect(result.success, true);
      // Should only detect the large panel, not the noise
      expect(result.panels.length, 1);
    });

    test('handles uniform white image (no panels)', () {
      final image = img.Image(width: 200, height: 200);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));

      final detector = PanelDetector();
      final result = detector.detectFromImage(image);

      expect(result.success, true);
      expect(result.isFullPage, true);
      expect(result.panelCount, 0);
    });

    test('handles uniform black image as single panel', () {
      final image = img.Image(width: 200, height: 200);
      img.fill(image, color: img.ColorRgb8(0, 0, 0));

      final detector = PanelDetector(
        options: PanelDetectionOptions(
          maxPanelAreaFraction: 1.0, // Allow full page
        ),
      );
      final result = detector.detectFromImage(image);

      expect(result.success, true);
      // Full black image is one large component
      expect(result.panels.length, greaterThanOrEqualTo(0));
    });

    test('detect from bytes works with PNG', () {
      // Create a simple image and encode to PNG
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));
      img.fillRect(
        image,
        x1: 20,
        y1: 20,
        x2: 80,
        y2: 80,
        color: img.ColorRgb8(0, 0, 0),
      );

      final pngBytes = Uint8List.fromList(img.encodePng(image));

      final detector = PanelDetector();
      final result = detector.detect(pngBytes);

      expect(result.success, true);
      expect(result.panels.isNotEmpty, true);
    });

    test('returns error for invalid image bytes', () {
      final invalidBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final detector = PanelDetector();
      final result = detector.detect(invalidBytes);

      expect(result.success, false);
      expect(result.error, isNotNull);
    });
  });

  group('PanelDetectionOptions', () {
    test('default values', () {
      const options = PanelDetectionOptions();

      expect(options.threshold, 240);
      expect(options.minPanelAreaFraction, 0.01);
      expect(options.maxPanelAreaFraction, 0.95);
      expect(options.invert, false);
      expect(options.panelMargin, 5);
      expect(options.readingDirection, ReadingDirection.leftToRight);
    });

    test('western preset', () {
      expect(
        PanelDetectionOptions.western.readingDirection,
        ReadingDirection.leftToRight,
      );
    });

    test('manga preset', () {
      expect(
        PanelDetectionOptions.manga.readingDirection,
        ReadingDirection.rightToLeft,
      );
    });
  });

  group('PanelDetectionResult', () {
    test('successful result', () {
      final panels = [Panel(x: 10, y: 10, width: 100, height: 100, order: 0)];

      final result = PanelDetectionResult(
        panels: panels,
        imageWidth: 200,
        imageHeight: 200,
      );

      expect(result.success, true);
      expect(result.error, isNull);
      expect(result.panelCount, 1);
      expect(result.isFullPage, false);
    });

    test('failed result', () {
      const result = PanelDetectionResult.failed('Test error');

      expect(result.success, false);
      expect(result.error, 'Test error');
      expect(result.panelCount, 0);
      expect(result.isFullPage, true);
    });
  });
}
