import 'dart:math';

/// A detected panel in a comic page.
///
/// Represents a rectangular region of the page that contains
/// a single panel of content.
class Panel {
  /// Left edge of the panel (x coordinate).
  final int x;

  /// Top edge of the panel (y coordinate).
  final int y;

  /// Width of the panel in pixels.
  final int width;

  /// Height of the panel in pixels.
  final int height;

  /// Reading order index (0-based).
  ///
  /// Panels are sorted by reading order based on their position
  /// and the configured reading direction.
  final int order;

  /// Creates a panel with the given bounds and order.
  const Panel({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.order = 0,
  });

  /// Right edge of the panel.
  int get right => x + width;

  /// Bottom edge of the panel.
  int get bottom => y + height;

  /// Center X coordinate.
  int get centerX => x + width ~/ 2;

  /// Center Y coordinate.
  int get centerY => y + height ~/ 2;

  /// Area of the panel in pixels.
  int get area => width * height;

  /// Aspect ratio (width / height).
  double get aspectRatio => width / height;

  /// Creates a copy with a new order.
  Panel withOrder(int newOrder) {
    return Panel(x: x, y: y, width: width, height: height, order: newOrder);
  }

  /// Returns true if this panel contains the given point.
  bool containsPoint(int px, int py) {
    return px >= x && px < right && py >= y && py < bottom;
  }

  /// Returns true if this panel overlaps with another.
  bool overlaps(Panel other) {
    return x < other.right &&
        right > other.x &&
        y < other.bottom &&
        bottom > other.y;
  }

  /// Returns the intersection of this panel with another, or null if none.
  Panel? intersection(Panel other) {
    final ix = max(x, other.x);
    final iy = max(y, other.y);
    final ir = min(right, other.right);
    final ib = min(bottom, other.bottom);

    if (ix < ir && iy < ib) {
      return Panel(x: ix, y: iy, width: ir - ix, height: ib - iy);
    }
    return null;
  }

  /// Expands the panel by the given margin on all sides.
  Panel expand(int margin) {
    return Panel(
      x: x - margin,
      y: y - margin,
      width: width + margin * 2,
      height: height + margin * 2,
      order: order,
    );
  }

  /// Clamps the panel to fit within the given bounds.
  Panel clamp(int maxWidth, int maxHeight) {
    final nx = x.clamp(0, maxWidth - 1);
    final ny = y.clamp(0, maxHeight - 1);
    final nr = right.clamp(0, maxWidth);
    final nb = bottom.clamp(0, maxHeight);

    return Panel(
      x: nx,
      y: ny,
      width: max(0, nr - nx),
      height: max(0, nb - ny),
      order: order,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Panel &&
        other.x == x &&
        other.y == y &&
        other.width == width &&
        other.height == height &&
        other.order == order;
  }

  @override
  int get hashCode => Object.hash(x, y, width, height, order);

  @override
  String toString() {
    return 'Panel(x: $x, y: $y, width: $width, height: $height, order: $order)';
  }
}
