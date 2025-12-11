import 'package:equatable/equatable.dart';

import 'author.dart';
import 'chapter.dart';
import 'story_rating.dart';

/// Represents a story on fanfiction.de.
class Story extends Equatable {
  const Story({
    required this.id,
    required this.title,
    required this.author,
    required this.summary,
    required this.rating,
    required this.chapterCount,
    required this.wordCount,
    required this.isComplete,
    this.genres = const [],
    this.characters = const [],
    this.pairings = const [],
    this.fandomName,
    this.categoryName,
    this.publishedAt,
    this.updatedAt,
    this.url,
    this.chapters = const [],
  });

  /// Unique story ID (hex string, e.g., '692ad8140010153d10b9ea34').
  final String id;

  /// Story title.
  final String title;

  /// Author of the story.
  final Author author;

  /// Story summary/description.
  final String summary;

  /// Age rating of the story.
  final StoryRating rating;

  /// Total number of chapters.
  final int chapterCount;

  /// Total word count across all chapters.
  final int wordCount;

  /// Whether the story is marked as complete.
  final bool isComplete;

  /// Genre tags (e.g., 'Abenteuer', 'Romanze').
  final List<String> genres;

  /// Characters featured in the story.
  final List<String> characters;

  /// Character pairings (e.g., 'Harry/Ginny').
  final List<String> pairings;

  /// Name of the fandom this story belongs to.
  final String? fandomName;

  /// Name of the category this story belongs to.
  final String? categoryName;

  /// Date the story was first published.
  final DateTime? publishedAt;

  /// Date the story was last updated.
  final DateTime? updatedAt;

  /// Full URL to the story.
  final String? url;

  /// Chapter information (populated from story details page).
  final List<ChapterInfo> chapters;

  /// URL to read the first chapter.
  String get readUrl =>
      url ?? 'https://www.fanfiktion.de/s/$id/1/${_slugify(title)}';

  /// URL to a specific chapter.
  String chapterUrl(int chapterNumber) =>
      'https://www.fanfiktion.de/s/$id/$chapterNumber/${_slugify(title)}';

  /// Status text for display.
  String get statusText => isComplete ? 'Abgeschlossen' : 'In Arbeit';

  /// Create a simple URL slug from a title.
  static String _slugify(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[äÄ]'), 'ae')
        .replaceAll(RegExp(r'[öÖ]'), 'oe')
        .replaceAll(RegExp(r'[üÜ]'), 'ue')
        .replaceAll('ß', 'ss')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        summary,
        rating,
        chapterCount,
        wordCount,
        isComplete,
        genres,
        characters,
        pairings,
        fandomName,
        categoryName,
        publishedAt,
        updatedAt,
        url,
      ];

  @override
  String toString() =>
      'Story(id: $id, title: $title, author: ${author.username})';
}

/// Result of fetching a list of stories (e.g., from category or search).
class StoryListResult extends Equatable {
  const StoryListResult({
    required this.stories,
    this.totalCount,
    this.currentPage = 1,
    this.totalPages,
    this.hasNextPage = false,
  });

  /// The stories in this result page.
  final List<Story> stories;

  /// Total number of stories available (if known).
  final int? totalCount;

  /// Current page number (1-indexed).
  final int currentPage;

  /// Total number of pages (if known).
  final int? totalPages;

  /// Whether there are more pages after this one.
  final bool hasNextPage;

  /// Returns true if there are no stories.
  bool get isEmpty => stories.isEmpty;

  /// Returns true if there are stories.
  bool get isNotEmpty => stories.isNotEmpty;

  @override
  List<Object?> get props =>
      [stories, totalCount, currentPage, totalPages, hasNextPage];
}
