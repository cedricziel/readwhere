import 'package:equatable/equatable.dart';

/// An entry in the PDF document outline (bookmarks/table of contents).
class PdfOutlineEntry with EquatableMixin {
  /// The title of this outline entry.
  final String title;

  /// The page index this entry links to (zero-based), or null if not specified.
  final int? pageIndex;

  /// Child entries nested under this entry.
  final List<PdfOutlineEntry> children;

  /// The nesting depth of this entry (0 for top-level entries).
  final int depth;

  const PdfOutlineEntry({
    required this.title,
    this.pageIndex,
    this.children = const [],
    this.depth = 0,
  });

  /// Whether this entry has any children.
  bool get hasChildren => children.isNotEmpty;

  /// Returns a copy with the specified fields replaced.
  PdfOutlineEntry copyWith({
    String? title,
    int? pageIndex,
    List<PdfOutlineEntry>? children,
    int? depth,
  }) {
    return PdfOutlineEntry(
      title: title ?? this.title,
      pageIndex: pageIndex ?? this.pageIndex,
      children: children ?? this.children,
      depth: depth ?? this.depth,
    );
  }

  @override
  List<Object?> get props => [title, pageIndex, children, depth];

  @override
  String toString() {
    return 'PdfOutlineEntry(title: $title, pageIndex: $pageIndex, '
        'children: ${children.length}, depth: $depth)';
  }
}
