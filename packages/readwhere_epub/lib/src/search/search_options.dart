import 'package:equatable/equatable.dart';

/// Configuration options for EPUB search.
class SearchOptions extends Equatable {
  /// Whether the search is case-sensitive.
  ///
  /// Default: false (case-insensitive)
  final bool caseSensitive;

  /// Whether to match whole words only.
  ///
  /// When true, "book" won't match "bookmark" or "ebook".
  /// Default: false
  final bool wholeWord;

  /// Number of characters to include before and after the match.
  ///
  /// Default: 50
  final int contextChars;

  /// Maximum number of results to return.
  ///
  /// Set to 0 for unlimited results.
  /// Default: 0 (unlimited)
  final int maxResults;

  /// Optional regex pattern to use instead of plain text search.
  ///
  /// When provided, this pattern is used directly and [caseSensitive]
  /// determines whether the pattern is case-sensitive.
  final RegExp? pattern;

  /// Chapters to include in the search (0-based indices).
  ///
  /// When null or empty, all chapters are searched.
  final Set<int>? chaptersToSearch;

  const SearchOptions({
    this.caseSensitive = false,
    this.wholeWord = false,
    this.contextChars = 50,
    this.maxResults = 0,
    this.pattern,
    this.chaptersToSearch,
  });

  /// Default search options.
  static const SearchOptions defaultOptions = SearchOptions();

  /// Creates options for case-sensitive search.
  factory SearchOptions.caseSensitive({
    bool wholeWord = false,
    int contextChars = 50,
    int maxResults = 0,
  }) {
    return SearchOptions(
      caseSensitive: true,
      wholeWord: wholeWord,
      contextChars: contextChars,
      maxResults: maxResults,
    );
  }

  /// Creates options for whole-word search.
  factory SearchOptions.wholeWord({
    bool caseSensitive = false,
    int contextChars = 50,
    int maxResults = 0,
  }) {
    return SearchOptions(
      caseSensitive: caseSensitive,
      wholeWord: true,
      contextChars: contextChars,
      maxResults: maxResults,
    );
  }

  /// Creates options with a custom regex pattern.
  factory SearchOptions.regex(
    String pattern, {
    bool caseSensitive = false,
    int contextChars = 50,
    int maxResults = 0,
  }) {
    return SearchOptions(
      caseSensitive: caseSensitive,
      contextChars: contextChars,
      maxResults: maxResults,
      pattern: RegExp(pattern, caseSensitive: caseSensitive),
    );
  }

  /// Creates a copy with modified fields.
  SearchOptions copyWith({
    bool? caseSensitive,
    bool? wholeWord,
    int? contextChars,
    int? maxResults,
    RegExp? pattern,
    Set<int>? chaptersToSearch,
  }) {
    return SearchOptions(
      caseSensitive: caseSensitive ?? this.caseSensitive,
      wholeWord: wholeWord ?? this.wholeWord,
      contextChars: contextChars ?? this.contextChars,
      maxResults: maxResults ?? this.maxResults,
      pattern: pattern ?? this.pattern,
      chaptersToSearch: chaptersToSearch ?? this.chaptersToSearch,
    );
  }

  /// Whether this search has a result limit.
  bool get hasLimit => maxResults > 0;

  /// Whether to search all chapters.
  bool get searchAllChapters =>
      chaptersToSearch == null || chaptersToSearch!.isEmpty;

  @override
  List<Object?> get props => [
        caseSensitive,
        wholeWord,
        contextChars,
        maxResults,
        pattern?.pattern,
        chaptersToSearch,
      ];
}
