import 'package:equatable/equatable.dart';

import '../age_rating.dart';
import '../creators.dart' show Creator, CreatorRole;
import '../reading_direction.dart';
import 'metron_models.dart';

/// MetronInfo.xml metadata for a comic.
///
/// MetronInfo is a more structured alternative to ComicInfo.xml,
/// using proper arrays instead of comma-separated strings and
/// supporting database IDs for cross-referencing.
///
/// See: https://github.com/Metron-Project/metroninfo
class MetronInfo extends Equatable {
  // IDs
  /// External database identifiers.
  final List<MetronId> ids;

  // Publisher
  /// Publisher information.
  final MetronPublisher? publisher;

  // Series
  /// Series information.
  final MetronSeries? series;

  // Issue details
  /// Manga volume number.
  final int? mangaVolume;

  /// Collection title (for collected editions).
  final String? collectionTitle;

  /// Issue number (can be alphanumeric like "1A").
  final String? number;

  /// Stories contained in this issue.
  final List<MetronStory> stories;

  /// Summary/description.
  final String? summary;

  /// Page count.
  final int? pageCount;

  /// Additional notes.
  final String? notes;

  // Prices
  /// Prices by country.
  final List<MetronPrice> prices;

  // Dates
  /// Cover date.
  final DateTime? coverDate;

  /// Store/release date.
  final DateTime? storeDate;

  // Classification
  /// Genres.
  final List<String> genres;

  /// Tags.
  final List<String> tags;

  /// Age rating.
  final AgeRating? ageRating;

  // Story elements
  /// Story arcs.
  final List<MetronArc> arcs;

  /// Characters.
  final List<MetronResource> characters;

  /// Teams.
  final List<MetronResource> teams;

  /// Locations.
  final List<MetronResource> locations;

  /// Universes.
  final List<MetronUniverse> universes;

  /// Reprints.
  final List<MetronReprint> reprints;

  // Identifiers
  /// GTIN identifiers (ISBN, UPC).
  final MetronGtin? gtin;

  // URLs
  /// Web URLs.
  final List<MetronUrl> urls;

  // Credits
  /// Creator credits.
  final List<MetronCreator> credits;

  // Pages
  /// Page metadata.
  final List<MetronPageInfo> pages;

  // Administrative
  /// Last modification timestamp.
  final DateTime? lastModified;

  // Display flags
  /// Whether the comic is black and white.
  final bool blackAndWhite;

  const MetronInfo({
    this.ids = const [],
    this.publisher,
    this.series,
    this.mangaVolume,
    this.collectionTitle,
    this.number,
    this.stories = const [],
    this.summary,
    this.pageCount,
    this.notes,
    this.prices = const [],
    this.coverDate,
    this.storeDate,
    this.genres = const [],
    this.tags = const [],
    this.ageRating,
    this.arcs = const [],
    this.characters = const [],
    this.teams = const [],
    this.locations = const [],
    this.universes = const [],
    this.reprints = const [],
    this.gtin,
    this.urls = const [],
    this.credits = const [],
    this.pages = const [],
    this.lastModified,
    this.blackAndWhite = false,
  });

  // ============================================================
  // Convenience getters
  // ============================================================

  /// Title from collection title or series name.
  String? get title => collectionTitle ?? series?.name;

  /// Series name.
  String? get seriesName => series?.name;

  /// Volume number.
  int? get volume => series?.volume;

  /// Total issue count from series.
  int? get count => series?.issueCount;

  /// Publisher name.
  String? get publisherName => publisher?.name;

  /// Release date (prefers store date, falls back to cover date).
  DateTime? get releaseDate => storeDate ?? coverDate;

  /// Primary URL.
  String? get primaryUrl {
    final primary = urls.where((u) => u.isPrimary).firstOrNull;
    return primary?.url ?? urls.firstOrNull?.url;
  }

  /// Primary external ID.
  MetronId? get primaryId {
    final primary = ids.where((id) => id.isPrimary).firstOrNull;
    return primary ?? ids.firstOrNull;
  }

  /// ISBN from GTIN.
  String? get isbn => gtin?.isbn;

  /// UPC from GTIN.
  String? get upc => gtin?.upc;

  /// Primary story arc.
  MetronArc? get primaryArc => arcs.firstOrNull;

  /// Story arc name.
  String? get storyArc => primaryArc?.name;

  // ============================================================
  // Creator convenience getters
  // ============================================================

  /// All writers.
  List<MetronCreator> get writers =>
      credits.where((c) => c.roles.contains(MetronCreatorRole.writer)).toList();

  /// All artists (pencillers, inkers, general artists).
  List<MetronCreator> get artists => credits
      .where((c) =>
          c.roles.contains(MetronCreatorRole.artist) ||
          c.roles.contains(MetronCreatorRole.penciller) ||
          c.roles.contains(MetronCreatorRole.inker))
      .toList();

  /// All pencillers.
  List<MetronCreator> get pencillers => credits
      .where((c) => c.roles.contains(MetronCreatorRole.penciller))
      .toList();

  /// All inkers.
  List<MetronCreator> get inkers =>
      credits.where((c) => c.roles.contains(MetronCreatorRole.inker)).toList();

  /// All colorists.
  List<MetronCreator> get colorists => credits
      .where((c) => c.roles.contains(MetronCreatorRole.colorist))
      .toList();

  /// All letterers.
  List<MetronCreator> get letterers => credits
      .where((c) => c.roles.contains(MetronCreatorRole.letterer))
      .toList();

  /// All cover artists.
  List<MetronCreator> get coverArtists =>
      credits.where((c) => c.roles.contains(MetronCreatorRole.cover)).toList();

  /// All editors.
  List<MetronCreator> get editors =>
      credits.where((c) => c.roles.contains(MetronCreatorRole.editor)).toList();

  /// All translators.
  List<MetronCreator> get translators => credits
      .where((c) => c.roles.contains(MetronCreatorRole.translator))
      .toList();

  /// Primary author (first writer, or first penciller, or first artist).
  String? get author {
    final writer = writers.firstOrNull;
    if (writer != null) return writer.name;

    final penciller = pencillers.firstOrNull;
    if (penciller != null) return penciller.name;

    final artist = artists.firstOrNull;
    return artist?.name;
  }

  /// All creators as unified [Creator] objects.
  List<Creator> get allCreators {
    final result = <Creator>[];
    for (final credit in credits) {
      for (final role in credit.roles) {
        result.add(Creator(
          name: credit.name,
          role: _mapRoleToCreatorRole(role),
        ));
      }
    }
    return result;
  }

  static CreatorRole _mapRoleToCreatorRole(MetronCreatorRole role) {
    switch (role) {
      case MetronCreatorRole.writer:
      case MetronCreatorRole.script:
      case MetronCreatorRole.story:
      case MetronCreatorRole.plot:
        return CreatorRole.writer;
      case MetronCreatorRole.penciller:
        return CreatorRole.penciller;
      case MetronCreatorRole.inker:
        return CreatorRole.inker;
      case MetronCreatorRole.colorist:
        return CreatorRole.colorist;
      case MetronCreatorRole.letterer:
        return CreatorRole.letterer;
      case MetronCreatorRole.cover:
      case MetronCreatorRole.variantCover:
        return CreatorRole.coverArtist;
      case MetronCreatorRole.editor:
      case MetronCreatorRole.assistantEditor:
      case MetronCreatorRole.editorInChief:
        return CreatorRole.editor;
      case MetronCreatorRole.translator:
        return CreatorRole.translator;
      case MetronCreatorRole.artist:
      case MetronCreatorRole.designer:
      case MetronCreatorRole.production:
      case MetronCreatorRole.other:
        return CreatorRole.other;
    }
  }

  // ============================================================
  // Character/team convenience
  // ============================================================

  /// Character names.
  List<String> get characterNames => characters.map((c) => c.name).toList();

  /// Team names.
  List<String> get teamNames => teams.map((t) => t.name).toList();

  /// Location names.
  List<String> get locationNames => locations.map((l) => l.name).toList();

  // ============================================================
  // Reading direction
  // ============================================================

  /// Whether this is a manga.
  bool get isManga =>
      mangaVolume != null || series?.format == SeriesFormat.digitalChapter;

  /// Effective reading direction.
  ReadingDirection get readingDirection =>
      isManga ? ReadingDirection.rightToLeft : ReadingDirection.leftToRight;

  /// Language ISO code.
  String? get languageISO => series?.language;

  // ============================================================
  // Equatable
  // ============================================================

  @override
  List<Object?> get props => [
        ids,
        publisher,
        series,
        mangaVolume,
        collectionTitle,
        number,
        stories,
        summary,
        pageCount,
        notes,
        prices,
        coverDate,
        storeDate,
        genres,
        tags,
        ageRating,
        arcs,
        characters,
        teams,
        locations,
        universes,
        reprints,
        gtin,
        urls,
        credits,
        pages,
        lastModified,
        blackAndWhite,
      ];

  @override
  String toString() => 'MetronInfo(title: $title, number: $number)';
}
