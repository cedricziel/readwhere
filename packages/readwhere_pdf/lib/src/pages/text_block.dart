import 'dart:ui';

import 'package:equatable/equatable.dart';

/// A block of text extracted from a PDF page, with position information.
class TextBlock with EquatableMixin {
  /// The text content of this block.
  final String text;

  /// The bounding rectangle of this text block on the page (in points).
  final Rect bounds;

  /// The page index this text block belongs to.
  final int pageIndex;

  /// The character offset where this block starts in the full page text.
  final int startOffset;

  /// The character offset where this block ends in the full page text.
  final int endOffset;

  const TextBlock({
    required this.text,
    required this.bounds,
    required this.pageIndex,
    required this.startOffset,
    required this.endOffset,
  });

  /// The width of the text block.
  double get width => bounds.width;

  /// The height of the text block.
  double get height => bounds.height;

  /// The length of the text in characters.
  int get length => text.length;

  /// Whether this text block is empty.
  bool get isEmpty => text.isEmpty;

  /// Whether this text block contains non-empty text.
  bool get isNotEmpty => text.isNotEmpty;

  @override
  List<Object?> get props => [text, bounds, pageIndex, startOffset, endOffset];

  @override
  String toString() {
    return 'TextBlock(text: "${text.length > 50 ? '${text.substring(0, 50)}...' : text}", '
        'bounds: $bounds, pageIndex: $pageIndex)';
  }
}

/// A line of text extracted from a PDF page.
class TextLine with EquatableMixin {
  /// The text content of this line.
  final String text;

  /// The bounding rectangle of this line on the page (in points).
  final Rect bounds;

  /// The individual text fragments/spans that make up this line.
  final List<TextFragment> fragments;

  const TextLine({
    required this.text,
    required this.bounds,
    this.fragments = const [],
  });

  @override
  List<Object?> get props => [text, bounds, fragments];
}

/// A fragment of text with specific styling or position.
class TextFragment with EquatableMixin {
  /// The text content of this fragment.
  final String text;

  /// The bounding rectangle of this fragment on the page (in points).
  final Rect bounds;

  /// The font size in points, if available.
  final double? fontSize;

  const TextFragment({required this.text, required this.bounds, this.fontSize});

  @override
  List<Object?> get props => [text, bounds, fontSize];
}
