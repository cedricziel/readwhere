import 'package:equatable/equatable.dart';

import '../metadata/comic_info/comic_info.dart';
import '../metadata/metron_info/metron_info.dart';
import '../metadata/reading_direction.dart';
import '../pages/comic_page.dart';

/// Source of metadata in a CBZ file.
enum MetadataSource {
  /// No metadata file found.
  none,

  /// Metadata from ComicInfo.xml.
  comicInfo,

  /// Metadata from MetronInfo.xml.
  metronInfo,
}

/// A complete CBZ comic book with all parsed data.
class CbzBook extends Equatable {
  /// Title of the comic.
  final String? title;

  /// Series name.
  final String? series;

  /// Issue number (can be alphanumeric).
  final String? number;

  /// Total number of issues in series.
  final int? count;

  /// Volume number.
  final int? volume;

  /// Summary/description.
  final String? summary;

  /// Publisher name.
  final String? publisher;

  /// Primary author (writer or artist).
  final String? author;

  /// Release/publication date.
  final DateTime? releaseDate;

  /// Reading direction for this comic.
  final ReadingDirection readingDirection;

  /// Whether this is a manga (reads right-to-left).
  final bool isManga;

  /// Whether the comic is in black and white.
  final bool isBlackAndWhite;

  /// Parsed ComicInfo.xml metadata (if available).
  final ComicInfo? comicInfo;

  /// Parsed MetronInfo.xml metadata (if available).
  final MetronInfo? metronInfo;

  /// Source of the primary metadata.
  final MetadataSource metadataSource;

  /// List of comic pages in reading order.
  final List<ComicPage> pages;

  /// Creates a CbzBook with all fields.
  const CbzBook({
    this.title,
    this.series,
    this.number,
    this.count,
    this.volume,
    this.summary,
    this.publisher,
    this.author,
    this.releaseDate,
    this.readingDirection = ReadingDirection.leftToRight,
    this.isManga = false,
    this.isBlackAndWhite = false,
    this.comicInfo,
    this.metronInfo,
    this.metadataSource = MetadataSource.none,
    this.pages = const [],
  });

  /// Creates a CbzBook from ComicInfo metadata.
  factory CbzBook.fromComicInfo(ComicInfo info, List<ComicPage> pages) {
    return CbzBook(
      title: info.title ?? info.series,
      series: info.series,
      number: info.number,
      count: info.count,
      volume: info.volume,
      summary: info.summary,
      publisher: info.publisher,
      author: info.author,
      releaseDate: info.releaseDate,
      readingDirection: info.readingDirection,
      isManga: info.isManga,
      isBlackAndWhite: info.blackAndWhite,
      comicInfo: info,
      metadataSource: MetadataSource.comicInfo,
      pages: pages,
    );
  }

  /// Creates a CbzBook from MetronInfo metadata.
  factory CbzBook.fromMetronInfo(MetronInfo info, List<ComicPage> pages) {
    return CbzBook(
      title: info.title,
      series: info.seriesName,
      number: info.number,
      count: info.count,
      volume: info.volume,
      summary: info.summary,
      publisher: info.publisherName,
      author: info.author,
      releaseDate: info.releaseDate,
      readingDirection: info.readingDirection,
      isManga: info.isManga,
      isBlackAndWhite: info.blackAndWhite,
      metronInfo: info,
      metadataSource: MetadataSource.metronInfo,
      pages: pages,
    );
  }

  /// Creates a CbzBook with no metadata, only pages.
  factory CbzBook.pagesOnly(List<ComicPage> pages) {
    return CbzBook(
      pages: pages,
      metadataSource: MetadataSource.none,
    );
  }

  // ============================================================
  // Convenience getters
  // ============================================================

  /// Number of pages in the book.
  int get pageCount => pages.length;

  /// Whether the book has any metadata.
  bool get hasMetadata => metadataSource != MetadataSource.none;

  /// The cover page (first FrontCover page, or first page).
  ComicPage? get coverPage {
    // Try to find a page marked as front cover
    for (final page in pages) {
      if (page.type == PageType.frontCover) {
        return page;
      }
    }
    // Fall back to first page
    return pages.isNotEmpty ? pages.first : null;
  }

  /// Display title (title or series with number).
  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    if (series != null && series!.isNotEmpty) {
      if (number != null && number!.isNotEmpty) {
        return '$series #$number';
      }
      return series!;
    }
    return 'Unknown Comic';
  }

  /// All genres from metadata.
  List<String> get genres {
    if (comicInfo != null) return comicInfo!.genres;
    if (metronInfo != null) return metronInfo!.genres;
    return const [];
  }

  /// All tags from metadata.
  List<String> get tags {
    if (comicInfo != null) return comicInfo!.tags;
    if (metronInfo != null) return metronInfo!.tags;
    return const [];
  }

  /// All character names from metadata.
  List<String> get characters {
    if (comicInfo != null) return comicInfo!.characters;
    if (metronInfo != null) return metronInfo!.characterNames;
    return const [];
  }

  /// Language ISO code from metadata.
  String? get languageISO {
    if (comicInfo != null) return comicInfo!.languageISO;
    if (metronInfo != null) return metronInfo!.languageISO;
    return null;
  }

  /// Creates a copy with modified fields.
  CbzBook copyWith({
    String? title,
    String? series,
    String? number,
    int? count,
    int? volume,
    String? summary,
    String? publisher,
    String? author,
    DateTime? releaseDate,
    ReadingDirection? readingDirection,
    bool? isManga,
    bool? isBlackAndWhite,
    ComicInfo? comicInfo,
    MetronInfo? metronInfo,
    MetadataSource? metadataSource,
    List<ComicPage>? pages,
  }) {
    return CbzBook(
      title: title ?? this.title,
      series: series ?? this.series,
      number: number ?? this.number,
      count: count ?? this.count,
      volume: volume ?? this.volume,
      summary: summary ?? this.summary,
      publisher: publisher ?? this.publisher,
      author: author ?? this.author,
      releaseDate: releaseDate ?? this.releaseDate,
      readingDirection: readingDirection ?? this.readingDirection,
      isManga: isManga ?? this.isManga,
      isBlackAndWhite: isBlackAndWhite ?? this.isBlackAndWhite,
      comicInfo: comicInfo ?? this.comicInfo,
      metronInfo: metronInfo ?? this.metronInfo,
      metadataSource: metadataSource ?? this.metadataSource,
      pages: pages ?? this.pages,
    );
  }

  @override
  List<Object?> get props => [
        title,
        series,
        number,
        count,
        volume,
        summary,
        publisher,
        author,
        releaseDate,
        readingDirection,
        isManga,
        isBlackAndWhite,
        comicInfo,
        metronInfo,
        metadataSource,
        pages,
      ];

  @override
  String toString() =>
      'CbzBook(title: $displayTitle, pages: $pageCount, source: ${metadataSource.name})';
}
