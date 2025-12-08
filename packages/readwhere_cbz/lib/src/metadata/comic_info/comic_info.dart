import 'package:equatable/equatable.dart';

import '../age_rating.dart';
import '../comic_page_info.dart';
import '../creators.dart';
import '../reading_direction.dart';

/// Metadata from ComicInfo.xml.
///
/// Based on the Anansi Project ComicInfo.xml schema v2.1.
/// See: https://anansi-project.github.io/docs/comicinfo/documentation
class ComicInfo extends Equatable {
  // ============================================
  // Bibliographic Information
  // ============================================

  /// Title of the book.
  final String? title;

  /// Name of the series.
  final String? series;

  /// Issue number within the series.
  final String? number;

  /// Total number of issues in the series.
  final int? count;

  /// Volume number (US Comics concept).
  final int? volume;

  /// Alternate series name (for crossovers).
  final String? alternateSeries;

  /// Alternate series issue number.
  final String? alternateNumber;

  /// Total issues in alternate series.
  final int? alternateCount;

  /// Summary/description of the book.
  final String? summary;

  /// Application-specific notes.
  final String? notes;

  // ============================================
  // Dates
  // ============================================

  /// Publication year.
  final int? year;

  /// Publication month (1-12).
  final int? month;

  /// Publication day (1-31).
  final int? day;

  // ============================================
  // Creators (parsed from comma-separated strings)
  // ============================================

  /// Writers/story creators.
  final List<String> writers;

  /// Pencil artists.
  final List<String> pencillers;

  /// Ink artists.
  final List<String> inkers;

  /// Colorists.
  final List<String> colorists;

  /// Letterers.
  final List<String> letterers;

  /// Cover artists.
  final List<String> coverArtists;

  /// Editors.
  final List<String> editors;

  /// Translators (includes scanlators).
  final List<String> translators;

  // ============================================
  // Publication Information
  // ============================================

  /// Publisher name.
  final String? publisher;

  /// Imprint (subdivision of publisher).
  final String? imprint;

  /// Genres (parsed from comma-separated string).
  final List<String> genres;

  /// Tags (parsed from comma-separated string).
  final List<String> tags;

  /// Reference URL(s).
  final String? web;

  /// Language code (IETF BCP 47 recommended).
  final String? languageISO;

  /// Binding format (e.g., "TBP", "HC", "Digital").
  final String? format;

  /// Global Trade Item Number (ISBN, ISSN, EAN, JAN).
  final String? gtin;

  // ============================================
  // Reading Information
  // ============================================

  /// Manga designation and reading direction.
  final MangaType manga;

  /// Whether the comic is black and white.
  final bool blackAndWhite;

  /// Age rating.
  final AgeRating? ageRating;

  /// Community rating (0.0 to 5.0).
  final double? communityRating;

  // ============================================
  // Story Information
  // ============================================

  /// Characters appearing in the comic.
  final List<String> characters;

  /// Teams appearing in the comic.
  final List<String> teams;

  /// Locations mentioned in the comic.
  final List<String> locations;

  /// Main character or team.
  final String? mainCharacterOrTeam;

  /// Story arc name.
  final String? storyArc;

  /// Position(s) in story arc reading order.
  final List<String> storyArcNumbers;

  /// Series group(s).
  final List<String> seriesGroups;

  // ============================================
  // Scanning Information
  // ============================================

  /// Information about the scan source.
  final String? scanInformation;

  /// Book review text.
  final String? review;

  // ============================================
  // Page Information
  // ============================================

  /// Page metadata list.
  final List<ComicPageInfo> pages;

  /// Explicit page count (may differ from pages.length).
  final int? pageCount;

  const ComicInfo({
    this.title,
    this.series,
    this.number,
    this.count,
    this.volume,
    this.alternateSeries,
    this.alternateNumber,
    this.alternateCount,
    this.summary,
    this.notes,
    this.year,
    this.month,
    this.day,
    this.writers = const [],
    this.pencillers = const [],
    this.inkers = const [],
    this.colorists = const [],
    this.letterers = const [],
    this.coverArtists = const [],
    this.editors = const [],
    this.translators = const [],
    this.publisher,
    this.imprint,
    this.genres = const [],
    this.tags = const [],
    this.web,
    this.languageISO,
    this.format,
    this.gtin,
    this.manga = MangaType.unknown,
    this.blackAndWhite = false,
    this.ageRating,
    this.communityRating,
    this.characters = const [],
    this.teams = const [],
    this.locations = const [],
    this.mainCharacterOrTeam,
    this.storyArc,
    this.storyArcNumbers = const [],
    this.seriesGroups = const [],
    this.scanInformation,
    this.review,
    this.pages = const [],
    this.pageCount,
  });

  // ============================================
  // Convenience Properties
  // ============================================

  /// Release date constructed from year, month, day.
  ///
  /// Returns null if year is not specified.
  DateTime? get releaseDate {
    if (year == null) return null;
    return DateTime(
      year!,
      month ?? 1,
      day ?? 1,
    );
  }

  /// Reading direction based on manga setting.
  ReadingDirection get readingDirection => manga.readingDirection;

  /// Whether this is manga (regardless of reading direction).
  bool get isManga =>
      manga == MangaType.yes || manga == MangaType.yesAndRightToLeft;

  /// All creators as [Creator] objects with their roles.
  List<Creator> get allCreators {
    return [
      ...writers.map((n) => Creator.writer(n)),
      ...pencillers.map((n) => Creator.penciller(n)),
      ...inkers.map((n) => Creator.inker(n)),
      ...colorists.map((n) => Creator.colorist(n)),
      ...letterers.map((n) => Creator.letterer(n)),
      ...coverArtists.map((n) => Creator.coverArtist(n)),
      ...editors.map((n) => Creator.editor(n)),
      ...translators.map((n) => Creator.translator(n)),
    ];
  }

  /// All artists (pencillers + inkers) as [Creator] objects.
  List<Creator> get artists {
    return [
      ...pencillers.map((n) => Creator.penciller(n)),
      ...inkers.map((n) => Creator.inker(n)),
    ];
  }

  /// Primary author (first writer, or first penciller if no writers).
  String? get author {
    if (writers.isNotEmpty) return writers.first;
    if (pencillers.isNotEmpty) return pencillers.first;
    return null;
  }

  /// Effective page count (from pageCount field or pages list).
  int get effectivePageCount => pageCount ?? pages.length;

  @override
  List<Object?> get props => [
        title,
        series,
        number,
        count,
        volume,
        alternateSeries,
        alternateNumber,
        alternateCount,
        summary,
        notes,
        year,
        month,
        day,
        writers,
        pencillers,
        inkers,
        colorists,
        letterers,
        coverArtists,
        editors,
        translators,
        publisher,
        imprint,
        genres,
        tags,
        web,
        languageISO,
        format,
        gtin,
        manga,
        blackAndWhite,
        ageRating,
        communityRating,
        characters,
        teams,
        locations,
        mainCharacterOrTeam,
        storyArc,
        storyArcNumbers,
        seriesGroups,
        scanInformation,
        review,
        pages,
        pageCount,
      ];

  @override
  String toString() {
    final parts = <String>[];
    if (title != null) parts.add('title: $title');
    if (series != null) parts.add('series: $series');
    if (number != null) parts.add('number: $number');
    return 'ComicInfo(${parts.join(', ')})';
  }
}
