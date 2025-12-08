import 'dart:async';

import '../cfi/epub_cfi.dart';
import '../content/content_document.dart';
import 'search_options.dart';
import 'search_result.dart';

export 'search_options.dart';
export 'search_result.dart';

/// Search engine for EPUB content.
///
/// Provides full-text search across all chapters with configurable options
/// including case sensitivity, whole-word matching, and context extraction.
///
/// ## Example
/// ```dart
/// final engine = EpubSearchEngine(chapters);
/// await for (final result in engine.search('adventure')) {
///   print('Found "${result.matchText}" in ${result.chapterTitle}');
/// }
/// ```
class EpubSearchEngine {
  /// The chapters to search.
  final List<EpubChapter> _chapters;

  /// Creates a search engine for the given chapters.
  EpubSearchEngine(this._chapters);

  /// Searches all chapters for the given query.
  ///
  /// Returns a stream of search results as they are found.
  /// Results are yielded in chapter order, then by position within each chapter.
  ///
  /// ## Example
  /// ```dart
  /// await for (final result in engine.search('love', options: SearchOptions(
  ///   caseSensitive: false,
  ///   contextChars: 30,
  /// ))) {
  ///   print(result.fullContext);
  /// }
  /// ```
  Stream<EpubSearchResult> search(
    String query, {
    SearchOptions options = SearchOptions.defaultOptions,
  }) async* {
    if (query.isEmpty && options.pattern == null) return;

    final pattern = _buildPattern(query, options);
    var resultCount = 0;

    for (var i = 0; i < _chapters.length; i++) {
      // Check if we should search this chapter
      if (!options.searchAllChapters &&
          !options.chaptersToSearch!.contains(i)) {
        continue;
      }

      final results =
          searchChapter(i, query, pattern: pattern, options: options);

      for (final result in results) {
        yield result;
        resultCount++;

        // Check result limit
        if (options.hasLimit && resultCount >= options.maxResults) {
          return;
        }
      }
    }
  }

  /// Searches a specific chapter for the given query.
  ///
  /// Returns a list of all matches in the chapter.
  List<EpubSearchResult> searchChapter(
    int chapterIndex,
    String query, {
    RegExp? pattern,
    SearchOptions options = SearchOptions.defaultOptions,
  }) {
    if (chapterIndex < 0 || chapterIndex >= _chapters.length) {
      return [];
    }

    final chapter = _chapters[chapterIndex];
    final text = chapter.plainText;
    final searchPattern = pattern ?? _buildPattern(query, options);

    final results = <EpubSearchResult>[];

    for (final match in searchPattern.allMatches(text)) {
      final matchText = match.group(0)!;
      final matchStart = match.start;

      // Extract context
      final contextStart =
          (matchStart - options.contextChars).clamp(0, text.length);
      final contextEnd = (matchStart + matchText.length + options.contextChars)
          .clamp(0, text.length);

      String contextBefore = text.substring(contextStart, matchStart);
      String contextAfter =
          text.substring(matchStart + matchText.length, contextEnd);

      // Clean up context (don't start/end mid-word)
      if (contextStart > 0) {
        final spaceIndex = contextBefore.indexOf(' ');
        if (spaceIndex >= 0) {
          contextBefore = '...${contextBefore.substring(spaceIndex + 1)}';
        }
      }
      if (contextEnd < text.length) {
        final spaceIndex = contextAfter.lastIndexOf(' ');
        if (spaceIndex >= 0) {
          contextAfter = '${contextAfter.substring(0, spaceIndex)}...';
        }
      }

      // Generate CFI for this result
      final cfi = EpubCfi.fromSpineIndex(chapterIndex);

      results.add(EpubSearchResult(
        chapterIndex: chapterIndex,
        chapterId: chapter.id,
        chapterTitle: chapter.title ?? chapter.documentTitle,
        matchText: matchText,
        contextBefore: contextBefore,
        contextAfter: contextAfter,
        matchStart: matchStart,
        matchLength: matchText.length,
        cfi: cfi,
      ));

      // Check result limit for single chapter search
      if (options.hasLimit && results.length >= options.maxResults) {
        break;
      }
    }

    return results;
  }

  /// Counts total matches across all chapters.
  ///
  /// Faster than collecting all results when you only need the count.
  int countMatches(
    String query, {
    SearchOptions options = SearchOptions.defaultOptions,
  }) {
    if (query.isEmpty && options.pattern == null) return 0;

    final pattern = _buildPattern(query, options);
    var count = 0;

    for (var i = 0; i < _chapters.length; i++) {
      if (!options.searchAllChapters &&
          !options.chaptersToSearch!.contains(i)) {
        continue;
      }

      final text = _chapters[i].plainText;
      count += pattern.allMatches(text).length;
    }

    return count;
  }

  /// Builds a regex pattern from the search query and options.
  RegExp _buildPattern(String query, SearchOptions options) {
    // Use custom pattern if provided
    if (options.pattern != null) {
      return options.pattern!;
    }

    // Escape special regex characters
    var pattern = RegExp.escape(query);

    // Apply whole-word matching
    if (options.wholeWord) {
      pattern = '\\b$pattern\\b';
    }

    return RegExp(pattern, caseSensitive: options.caseSensitive);
  }
}

/// Extension to add search capability to a list of chapters.
extension SearchableChapters on List<EpubChapter> {
  /// Creates a search engine for these chapters.
  EpubSearchEngine get searchEngine => EpubSearchEngine(this);

  /// Searches all chapters for the given query.
  Stream<EpubSearchResult> search(
    String query, {
    SearchOptions options = SearchOptions.defaultOptions,
  }) {
    return searchEngine.search(query, options: options);
  }
}
