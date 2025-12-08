import 'package:equatable/equatable.dart';

import '../cfi/epub_cfi.dart';

/// A search result with match text and context.
///
/// Contains the matched text, surrounding context, and location information
/// for navigation back to the search result in the EPUB.
class EpubSearchResult extends Equatable {
  /// Index of the chapter containing the match (0-based).
  final int chapterIndex;

  /// Manifest ID of the chapter.
  final String chapterId;

  /// Title of the chapter (from TOC or extracted).
  final String? chapterTitle;

  /// The text that matched the search query.
  final String matchText;

  /// Text context before the match.
  final String contextBefore;

  /// Text context after the match.
  final String contextAfter;

  /// Character offset of the match start within the chapter's plain text.
  final int matchStart;

  /// Length of the matched text.
  final int matchLength;

  /// CFI pointing to the match location (if available).
  final EpubCfi? cfi;

  const EpubSearchResult({
    required this.chapterIndex,
    required this.chapterId,
    this.chapterTitle,
    required this.matchText,
    required this.contextBefore,
    required this.contextAfter,
    required this.matchStart,
    required this.matchLength,
    this.cfi,
  });

  /// Character offset of the match end within the chapter's plain text.
  int get matchEnd => matchStart + matchLength;

  /// Full context string including before, match, and after.
  String get fullContext => '$contextBefore$matchText$contextAfter';

  /// Creates a copy with modified fields.
  EpubSearchResult copyWith({
    int? chapterIndex,
    String? chapterId,
    String? chapterTitle,
    String? matchText,
    String? contextBefore,
    String? contextAfter,
    int? matchStart,
    int? matchLength,
    EpubCfi? cfi,
  }) {
    return EpubSearchResult(
      chapterIndex: chapterIndex ?? this.chapterIndex,
      chapterId: chapterId ?? this.chapterId,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      matchText: matchText ?? this.matchText,
      contextBefore: contextBefore ?? this.contextBefore,
      contextAfter: contextAfter ?? this.contextAfter,
      matchStart: matchStart ?? this.matchStart,
      matchLength: matchLength ?? this.matchLength,
      cfi: cfi ?? this.cfi,
    );
  }

  @override
  List<Object?> get props => [
        chapterIndex,
        chapterId,
        chapterTitle,
        matchText,
        contextBefore,
        contextAfter,
        matchStart,
        matchLength,
        cfi,
      ];

  @override
  String toString() {
    return 'EpubSearchResult(chapter: $chapterIndex, match: "$matchText" at $matchStart)';
  }
}
