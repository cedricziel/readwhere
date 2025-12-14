import 'package:equatable/equatable.dart';

/// Represents the state of a text selection in the reader.
///
/// This entity captures the essential information about selected text
/// before it's converted to an annotation. It tracks what was selected,
/// where it was selected, and provides the basis for CFI resolution.
class TextSelectionState extends Equatable {
  /// The plain text content that was selected
  final String selectedText;

  /// The index of the chapter where the selection occurred (0-based)
  final int chapterIndex;

  /// The href/path of the chapter document (optional, for EPUB)
  final String? chapterHref;

  /// When the selection was made
  final DateTime selectionTime;

  /// Resolved CFI for the start of the selection (set after resolution)
  final String? cfiStart;

  /// Resolved CFI for the end of the selection (set after resolution)
  final String? cfiEnd;

  const TextSelectionState({
    required this.selectedText,
    required this.chapterIndex,
    this.chapterHref,
    required this.selectionTime,
    this.cfiStart,
    this.cfiEnd,
  });

  /// Whether the CFI positions have been resolved
  bool get hasResolvedPosition => cfiStart != null && cfiEnd != null;

  /// Creates a copy with resolved CFI positions
  TextSelectionState withResolvedCfi({
    required String cfiStart,
    required String cfiEnd,
  }) {
    return TextSelectionState(
      selectedText: selectedText,
      chapterIndex: chapterIndex,
      chapterHref: chapterHref,
      selectionTime: selectionTime,
      cfiStart: cfiStart,
      cfiEnd: cfiEnd,
    );
  }

  /// Creates a copy with the given fields replaced
  TextSelectionState copyWith({
    String? selectedText,
    int? chapterIndex,
    String? chapterHref,
    DateTime? selectionTime,
    String? cfiStart,
    String? cfiEnd,
  }) {
    return TextSelectionState(
      selectedText: selectedText ?? this.selectedText,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      chapterHref: chapterHref ?? this.chapterHref,
      selectionTime: selectionTime ?? this.selectionTime,
      cfiStart: cfiStart ?? this.cfiStart,
      cfiEnd: cfiEnd ?? this.cfiEnd,
    );
  }

  @override
  List<Object?> get props => [
    selectedText,
    chapterIndex,
    chapterHref,
    selectionTime,
    cfiStart,
    cfiEnd,
  ];

  @override
  String toString() {
    final truncatedText = selectedText.length > 30
        ? '${selectedText.substring(0, 30)}...'
        : selectedText;
    return 'TextSelectionState(text: "$truncatedText", chapter: $chapterIndex, '
        'resolved: $hasResolvedPosition)';
  }
}
