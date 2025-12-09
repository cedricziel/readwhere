import 'package:equatable/equatable.dart';

/// Represents a search result within a book
class SearchResult extends Equatable {
  /// Unique identifier for the chapter containing this result
  final String chapterId;

  /// Title of the chapter containing this result
  final String chapterTitle;

  /// The matched text with surrounding context
  final String text;

  /// CFI (Canonical Fragment Identifier) location of the match
  final String cfi;

  const SearchResult({
    required this.chapterId,
    required this.chapterTitle,
    required this.text,
    required this.cfi,
  });

  /// Creates a copy of this SearchResult with the given fields replaced
  SearchResult copyWith({
    String? chapterId,
    String? chapterTitle,
    String? text,
    String? cfi,
  }) {
    return SearchResult(
      chapterId: chapterId ?? this.chapterId,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      text: text ?? this.text,
      cfi: cfi ?? this.cfi,
    );
  }

  @override
  List<Object?> get props => [chapterId, chapterTitle, text, cfi];

  @override
  String toString() {
    return 'SearchResult(chapterId: $chapterId, chapterTitle: $chapterTitle, '
        'text: ${text.substring(0, text.length > 50 ? 50 : text.length)}..., cfi: $cfi)';
  }
}
