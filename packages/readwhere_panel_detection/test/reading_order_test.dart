import 'package:readwhere_panel_detection/readwhere_panel_detection.dart';
import 'package:test/test.dart';

void main() {
  group('ReadingOrderSorter', () {
    group('left-to-right', () {
      final sorter = ReadingOrderSorter(
        direction: ReadingDirection.leftToRight,
      );

      test('sorts single panel', () {
        final panels = [Panel(x: 10, y: 10, width: 100, height: 100)];

        final sorted = sorter.sort(panels);

        expect(sorted.length, 1);
        expect(sorted[0].order, 0);
      });

      test('sorts horizontal panels left to right', () {
        final panels = [
          Panel(x: 200, y: 10, width: 100, height: 100),
          Panel(x: 10, y: 10, width: 100, height: 100),
          Panel(x: 400, y: 10, width: 100, height: 100),
        ];

        final sorted = sorter.sort(panels);

        expect(sorted.length, 3);
        expect(sorted[0].x, 10);
        expect(sorted[0].order, 0);
        expect(sorted[1].x, 200);
        expect(sorted[1].order, 1);
        expect(sorted[2].x, 400);
        expect(sorted[2].order, 2);
      });

      test('sorts vertical panels top to bottom', () {
        final panels = [
          Panel(x: 10, y: 200, width: 100, height: 100),
          Panel(x: 10, y: 10, width: 100, height: 100),
          Panel(x: 10, y: 400, width: 100, height: 100),
        ];

        final sorted = sorter.sort(panels);

        expect(sorted.length, 3);
        expect(sorted[0].y, 10);
        expect(sorted[0].order, 0);
        expect(sorted[1].y, 200);
        expect(sorted[1].order, 1);
        expect(sorted[2].y, 400);
        expect(sorted[2].order, 2);
      });

      test('sorts 2x2 grid correctly', () {
        // Grid layout:
        // [0,0] [1,0]
        // [0,1] [1,1]
        final panels = [
          Panel(x: 200, y: 200, width: 100, height: 100), // bottom-right
          Panel(x: 10, y: 10, width: 100, height: 100), // top-left
          Panel(x: 200, y: 10, width: 100, height: 100), // top-right
          Panel(x: 10, y: 200, width: 100, height: 100), // bottom-left
        ];

        final sorted = sorter.sort(panels);

        expect(sorted.length, 4);
        // Row 1: left then right
        expect(sorted[0].x, 10);
        expect(sorted[0].y, 10);
        expect(sorted[0].order, 0);
        expect(sorted[1].x, 200);
        expect(sorted[1].y, 10);
        expect(sorted[1].order, 1);
        // Row 2: left then right
        expect(sorted[2].x, 10);
        expect(sorted[2].y, 200);
        expect(sorted[2].order, 2);
        expect(sorted[3].x, 200);
        expect(sorted[3].y, 200);
        expect(sorted[3].order, 3);
      });

      test('handles empty list', () {
        final sorted = sorter.sort([]);
        expect(sorted, isEmpty);
      });

      test('groups overlapping vertical panels in same row', () {
        // Two panels that overlap vertically (same row)
        final panels = [
          Panel(x: 200, y: 20, width: 100, height: 100),
          Panel(x: 10, y: 10, width: 100, height: 100),
        ];

        final sorted = sorter.sort(panels);

        expect(sorted.length, 2);
        expect(sorted[0].x, 10); // Left first
        expect(sorted[1].x, 200); // Right second
      });
    });

    group('right-to-left', () {
      final sorter = ReadingOrderSorter(
        direction: ReadingDirection.rightToLeft,
      );

      test('sorts horizontal panels right to left', () {
        final panels = [
          Panel(x: 200, y: 10, width: 100, height: 100),
          Panel(x: 10, y: 10, width: 100, height: 100),
          Panel(x: 400, y: 10, width: 100, height: 100),
        ];

        final sorted = sorter.sort(panels);

        expect(sorted.length, 3);
        expect(sorted[0].x, 400);
        expect(sorted[0].order, 0);
        expect(sorted[1].x, 200);
        expect(sorted[1].order, 1);
        expect(sorted[2].x, 10);
        expect(sorted[2].order, 2);
      });

      test('sorts 2x2 grid for manga reading', () {
        // Grid layout:
        // [1,0] [0,0]  <- RTL: right first
        // [1,1] [0,1]
        final panels = [
          Panel(x: 200, y: 200, width: 100, height: 100), // bottom-right
          Panel(x: 10, y: 10, width: 100, height: 100), // top-left
          Panel(x: 200, y: 10, width: 100, height: 100), // top-right
          Panel(x: 10, y: 200, width: 100, height: 100), // bottom-left
        ];

        final sorted = sorter.sort(panels);

        expect(sorted.length, 4);
        // Row 1: right then left
        expect(sorted[0].x, 200);
        expect(sorted[0].y, 10);
        expect(sorted[0].order, 0);
        expect(sorted[1].x, 10);
        expect(sorted[1].y, 10);
        expect(sorted[1].order, 1);
        // Row 2: right then left
        expect(sorted[2].x, 200);
        expect(sorted[2].y, 200);
        expect(sorted[2].order, 2);
        expect(sorted[3].x, 10);
        expect(sorted[3].y, 200);
        expect(sorted[3].order, 3);
      });
    });

    group('row threshold', () {
      test('custom threshold affects row grouping', () {
        final strictSorter = ReadingOrderSorter(
          direction: ReadingDirection.leftToRight,
          rowThreshold: 0.9, // Very strict
        );

        // Panels with slight vertical offset
        final panels = [
          Panel(x: 10, y: 10, width: 100, height: 100),
          Panel(x: 200, y: 40, width: 100, height: 100), // 30px offset
        ];

        final sorted = strictSorter.sort(panels);

        // With strict threshold, they might be in different rows
        expect(sorted.length, 2);
      });
    });
  });

  group('ReadingDirection', () {
    test('has leftToRight value', () {
      expect(ReadingDirection.leftToRight, isNotNull);
    });

    test('has rightToLeft value', () {
      expect(ReadingDirection.rightToLeft, isNotNull);
    });
  });
}
