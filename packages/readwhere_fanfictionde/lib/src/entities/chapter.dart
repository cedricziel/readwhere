import 'package:equatable/equatable.dart';

/// Represents a chapter of a story on fanfiction.de.
class Chapter extends Equatable {
  const Chapter({
    required this.number,
    required this.title,
    this.htmlContent,
    this.wordCount,
    this.publishedAt,
  });

  /// Chapter number (1-indexed).
  final int number;

  /// Chapter title.
  final String title;

  /// Raw HTML content of the chapter.
  /// Only populated when the chapter content has been fetched.
  final String? htmlContent;

  /// Word count of this chapter (if available).
  final int? wordCount;

  /// Date this chapter was published.
  final DateTime? publishedAt;

  /// Returns true if the chapter content has been fetched.
  bool get hasContent => htmlContent != null && htmlContent!.isNotEmpty;

  /// Creates a copy with the given content.
  Chapter withContent(String content) => Chapter(
        number: number,
        title: title,
        htmlContent: content,
        wordCount: wordCount,
        publishedAt: publishedAt,
      );

  @override
  List<Object?> get props =>
      [number, title, htmlContent, wordCount, publishedAt];

  @override
  String toString() => 'Chapter(number: $number, title: $title)';
}

/// Metadata about a chapter from the story details page.
///
/// Used before full chapter content is fetched.
class ChapterInfo extends Equatable {
  const ChapterInfo({
    required this.number,
    required this.title,
    this.wordCount,
    this.publishedAt,
  });

  /// Chapter number (1-indexed).
  final int number;

  /// Chapter title.
  final String title;

  /// Word count of this chapter (if available).
  final int? wordCount;

  /// Date this chapter was published.
  final DateTime? publishedAt;

  /// Convert to a Chapter without content.
  Chapter toChapter() => Chapter(
        number: number,
        title: title,
        wordCount: wordCount,
        publishedAt: publishedAt,
      );

  @override
  List<Object?> get props => [number, title, wordCount, publishedAt];
}
