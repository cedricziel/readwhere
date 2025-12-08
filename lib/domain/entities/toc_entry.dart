import 'package:equatable/equatable.dart';

/// Represents an entry in the table of contents
class TocEntry extends Equatable {
  final String id;
  final String title;
  final String href; // Link to the chapter/section
  final int level; // Nesting level (0 for top-level, 1 for nested, etc.)
  final List<TocEntry> children;

  const TocEntry({
    required this.id,
    required this.title,
    required this.href,
    required this.level,
    this.children = const [],
  });

  /// Creates a copy of this TocEntry with the given fields replaced
  TocEntry copyWith({
    String? id,
    String? title,
    String? href,
    int? level,
    List<TocEntry>? children,
  }) {
    return TocEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      href: href ?? this.href,
      level: level ?? this.level,
      children: children ?? this.children,
    );
  }

  @override
  List<Object?> get props => [id, title, href, level, children];

  @override
  String toString() {
    final indent = '  ' * level;
    final childrenStr = children.isEmpty
        ? ''
        : ', children: ${children.length}';
    return '$indent TocEntry(title: $title, level: $level$childrenStr)';
  }
}
