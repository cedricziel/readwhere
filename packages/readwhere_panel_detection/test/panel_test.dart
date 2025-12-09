import 'package:readwhere_panel_detection/readwhere_panel_detection.dart';
import 'package:test/test.dart';

void main() {
  group('Panel', () {
    test('creates panel with correct bounds', () {
      final panel = Panel(x: 10, y: 20, width: 100, height: 50);

      expect(panel.x, 10);
      expect(panel.y, 20);
      expect(panel.width, 100);
      expect(panel.height, 50);
      expect(panel.order, 0);
    });

    test('calculates right and bottom edges', () {
      final panel = Panel(x: 10, y: 20, width: 100, height: 50);

      expect(panel.right, 110);
      expect(panel.bottom, 70);
    });

    test('calculates center coordinates', () {
      final panel = Panel(x: 10, y: 20, width: 100, height: 50);

      expect(panel.centerX, 60);
      expect(panel.centerY, 45);
    });

    test('calculates area', () {
      final panel = Panel(x: 10, y: 20, width: 100, height: 50);

      expect(panel.area, 5000);
    });

    test('calculates aspect ratio', () {
      final panel = Panel(x: 0, y: 0, width: 200, height: 100);

      expect(panel.aspectRatio, 2.0);
    });

    test('withOrder creates copy with new order', () {
      final panel = Panel(x: 10, y: 20, width: 100, height: 50, order: 0);
      final reordered = panel.withOrder(5);

      expect(reordered.x, 10);
      expect(reordered.y, 20);
      expect(reordered.width, 100);
      expect(reordered.height, 50);
      expect(reordered.order, 5);

      // Original unchanged
      expect(panel.order, 0);
    });

    test('containsPoint returns true for point inside', () {
      final panel = Panel(x: 10, y: 20, width: 100, height: 50);

      expect(panel.containsPoint(50, 40), true);
      expect(panel.containsPoint(10, 20), true);
      expect(panel.containsPoint(109, 69), true);
    });

    test('containsPoint returns false for point outside', () {
      final panel = Panel(x: 10, y: 20, width: 100, height: 50);

      expect(panel.containsPoint(5, 40), false);
      expect(panel.containsPoint(50, 15), false);
      expect(panel.containsPoint(110, 40), false);
      expect(panel.containsPoint(50, 70), false);
    });

    test('overlaps returns true for overlapping panels', () {
      final panel1 = Panel(x: 0, y: 0, width: 100, height: 100);
      final panel2 = Panel(x: 50, y: 50, width: 100, height: 100);

      expect(panel1.overlaps(panel2), true);
      expect(panel2.overlaps(panel1), true);
    });

    test('overlaps returns false for non-overlapping panels', () {
      final panel1 = Panel(x: 0, y: 0, width: 100, height: 100);
      final panel2 = Panel(x: 200, y: 200, width: 100, height: 100);

      expect(panel1.overlaps(panel2), false);
      expect(panel2.overlaps(panel1), false);
    });

    test('overlaps returns false for adjacent panels', () {
      final panel1 = Panel(x: 0, y: 0, width: 100, height: 100);
      final panel2 = Panel(x: 100, y: 0, width: 100, height: 100);

      expect(panel1.overlaps(panel2), false);
      expect(panel2.overlaps(panel1), false);
    });

    test('intersection returns overlapping region', () {
      final panel1 = Panel(x: 0, y: 0, width: 100, height: 100);
      final panel2 = Panel(x: 50, y: 50, width: 100, height: 100);

      final intersection = panel1.intersection(panel2);

      expect(intersection, isNotNull);
      expect(intersection!.x, 50);
      expect(intersection.y, 50);
      expect(intersection.width, 50);
      expect(intersection.height, 50);
    });

    test('intersection returns null for non-overlapping panels', () {
      final panel1 = Panel(x: 0, y: 0, width: 100, height: 100);
      final panel2 = Panel(x: 200, y: 200, width: 100, height: 100);

      expect(panel1.intersection(panel2), isNull);
    });

    test('expand increases size by margin', () {
      final panel = Panel(x: 50, y: 50, width: 100, height: 100, order: 1);
      final expanded = panel.expand(10);

      expect(expanded.x, 40);
      expect(expanded.y, 40);
      expect(expanded.width, 120);
      expect(expanded.height, 120);
      expect(expanded.order, 1);
    });

    test('clamp constrains to bounds', () {
      final panel = Panel(x: -10, y: -10, width: 200, height: 200);
      final clamped = panel.clamp(100, 100);

      expect(clamped.x, 0);
      expect(clamped.y, 0);
      expect(clamped.width, 100);
      expect(clamped.height, 100);
    });

    test('equality compares all fields', () {
      final panel1 = Panel(x: 10, y: 20, width: 100, height: 50, order: 1);
      final panel2 = Panel(x: 10, y: 20, width: 100, height: 50, order: 1);
      final panel3 = Panel(x: 10, y: 20, width: 100, height: 50, order: 2);

      expect(panel1, equals(panel2));
      expect(panel1, isNot(equals(panel3)));
    });

    test('toString returns readable format', () {
      final panel = Panel(x: 10, y: 20, width: 100, height: 50, order: 1);

      expect(
        panel.toString(),
        'Panel(x: 10, y: 20, width: 100, height: 50, order: 1)',
      );
    });
  });
}
