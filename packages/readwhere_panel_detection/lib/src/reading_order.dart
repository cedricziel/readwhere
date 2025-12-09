import 'panel.dart';

/// Reading direction for comic panels.
enum ReadingDirection {
  /// Left-to-right, top-to-bottom (Western comics).
  leftToRight,

  /// Right-to-left, top-to-bottom (Manga).
  rightToLeft,
}

/// Sorts panels by reading order.
///
/// Panels are grouped into rows based on vertical overlap, then sorted
/// within each row by horizontal position according to the reading direction.
class ReadingOrderSorter {
  /// The reading direction to use for sorting.
  final ReadingDirection direction;

  /// Vertical overlap threshold for grouping panels into rows.
  ///
  /// Two panels are considered on the same row if their vertical centers
  /// are within this fraction of the smaller panel's height.
  final double rowThreshold;

  /// Creates a sorter with the given direction and threshold.
  const ReadingOrderSorter({
    this.direction = ReadingDirection.leftToRight,
    this.rowThreshold = 0.5,
  });

  /// Sorts the given panels by reading order.
  ///
  /// Returns a new list with panels sorted and their order property updated.
  List<Panel> sort(List<Panel> panels) {
    if (panels.isEmpty) return [];
    if (panels.length == 1) return [panels[0].withOrder(0)];

    // Group panels into rows based on vertical position
    final rows = _groupIntoRows(panels);

    // Sort rows by their top position
    rows.sort((a, b) => _rowTop(a).compareTo(_rowTop(b)));

    // Sort panels within each row by horizontal position
    for (final row in rows) {
      if (direction == ReadingDirection.leftToRight) {
        row.sort((a, b) => a.x.compareTo(b.x));
      } else {
        row.sort((a, b) => b.x.compareTo(a.x));
      }
    }

    // Flatten rows and assign order
    final sorted = <Panel>[];
    var order = 0;
    for (final row in rows) {
      for (final panel in row) {
        sorted.add(panel.withOrder(order));
        order++;
      }
    }

    return sorted;
  }

  /// Groups panels into rows based on vertical overlap.
  List<List<Panel>> _groupIntoRows(List<Panel> panels) {
    final rows = <List<Panel>>[];
    final used = <int>{};

    // Sort by vertical position first
    final sorted = List<Panel>.from(panels);
    sorted.sort((a, b) => a.y.compareTo(b.y));

    for (var i = 0; i < sorted.length; i++) {
      if (used.contains(i)) continue;

      final row = <Panel>[sorted[i]];
      used.add(i);

      // Find all panels that overlap vertically with this one
      for (var j = i + 1; j < sorted.length; j++) {
        if (used.contains(j)) continue;

        if (_areOnSameRow(sorted[i], sorted[j])) {
          row.add(sorted[j]);
          used.add(j);
        }
      }

      rows.add(row);
    }

    return rows;
  }

  /// Returns true if two panels should be on the same row.
  bool _areOnSameRow(Panel a, Panel b) {
    // Calculate vertical overlap
    final overlapTop = a.y > b.y ? a.y : b.y;
    final overlapBottom = a.bottom < b.bottom ? a.bottom : b.bottom;
    final overlap = overlapBottom - overlapTop;

    if (overlap <= 0) return false;

    // Check if overlap is significant relative to smaller panel
    final smallerHeight = a.height < b.height ? a.height : b.height;
    return overlap >= smallerHeight * rowThreshold;
  }

  /// Returns the top position of a row (minimum y of all panels).
  int _rowTop(List<Panel> row) {
    var minY = row[0].y;
    for (final panel in row) {
      if (panel.y < minY) minY = panel.y;
    }
    return minY;
  }
}
