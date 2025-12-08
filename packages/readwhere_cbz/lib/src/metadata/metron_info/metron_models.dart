import 'package:equatable/equatable.dart';

/// ID source for MetronInfo resources.
enum MetronIdSource {
  /// AniList database.
  aniList('AniList'),

  /// Comic Vine database.
  comicVine('Comic Vine'),

  /// Grand Comics Database.
  grandComicsDatabase('Grand Comics Database'),

  /// Kitsu database.
  kitsu('Kitsu'),

  /// MangaDex database.
  mangaDex('MangaDex'),

  /// MangaUpdates database.
  mangaUpdates('MangaUpdates'),

  /// Metron database.
  metron('Metron'),

  /// MyAnimeList database.
  myAnimeList('MyAnimeList'),

  /// League of Comic Geeks database.
  leagueOfComicGeeks('League of Comic Geeks');

  final String displayName;
  const MetronIdSource(this.displayName);

  /// Parses a source string to [MetronIdSource].
  static MetronIdSource? parse(String? value) {
    if (value == null || value.isEmpty) return null;
    final lower = value.toLowerCase();
    for (final source in values) {
      if (source.displayName.toLowerCase() == lower ||
          source.name.toLowerCase() == lower) {
        return source;
      }
    }
    return null;
  }
}

/// A resource identifier from an external database.
class MetronId extends Equatable {
  /// The source database.
  final MetronIdSource source;

  /// The ID value.
  final String value;

  /// Whether this is the primary ID.
  final bool isPrimary;

  const MetronId({
    required this.source,
    required this.value,
    this.isPrimary = false,
  });

  @override
  List<Object?> get props => [source, value, isPrimary];

  @override
  String toString() => 'MetronId(${source.displayName}: $value)';
}

/// Series format type.
enum SeriesFormat {
  /// Annual publication.
  annual('Annual'),

  /// Digital chapter release.
  digitalChapter('Digital Chapter'),

  /// Graphic novel.
  graphicNovel('Graphic Novel'),

  /// Hardcover edition.
  hardcover('Hardcover'),

  /// Limited series.
  limitedSeries('Limited Series'),

  /// Omnibus collection.
  omnibus('Omnibus'),

  /// One-shot issue.
  oneShot('One-Shot'),

  /// Single issue.
  singleIssue('Single Issue'),

  /// Trade paperback.
  tradePaperback('Trade Paperback');

  final String displayName;
  const SeriesFormat(this.displayName);

  /// Parses a format string to [SeriesFormat].
  static SeriesFormat? parse(String? value) {
    if (value == null || value.isEmpty) return null;
    final lower = value.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
    for (final format in values) {
      final formatLower = format.displayName
          .toLowerCase()
          .replaceAll(' ', '')
          .replaceAll('-', '');
      if (formatLower == lower || format.name.toLowerCase() == lower) {
        return format;
      }
    }
    return null;
  }
}

/// Creator role in a comic (MetronInfo-specific with more detailed roles).
enum MetronCreatorRole {
  /// Writer.
  writer('Writer'),

  /// Script writer.
  script('Script'),

  /// Story creator.
  story('Story'),

  /// Plot developer.
  plot('Plot'),

  /// Artist (general).
  artist('Artist'),

  /// Penciller.
  penciller('Penciller'),

  /// Inker.
  inker('Inker'),

  /// Colorist.
  colorist('Colorist'),

  /// Letterer.
  letterer('Letterer'),

  /// Cover artist.
  cover('Cover'),

  /// Variant cover artist.
  variantCover('Variant Cover'),

  /// Editor.
  editor('Editor'),

  /// Assistant editor.
  assistantEditor('Assistant Editor'),

  /// Editor in chief.
  editorInChief('Editor In Chief'),

  /// Translator.
  translator('Translator'),

  /// Designer.
  designer('Designer'),

  /// Production.
  production('Production'),

  /// Other role.
  other('Other');

  final String displayName;
  const MetronCreatorRole(this.displayName);

  /// Parses a role string to [MetronCreatorRole].
  static MetronCreatorRole? parse(String? value) {
    if (value == null || value.isEmpty) return null;
    final lower = value.toLowerCase().replaceAll(' ', '');
    for (final role in values) {
      final roleLower = role.displayName.toLowerCase().replaceAll(' ', '');
      if (roleLower == lower || role.name.toLowerCase() == lower) {
        return role;
      }
    }
    return null;
  }
}

/// A creator with role and optional database ID.
class MetronCreator extends Equatable {
  /// Creator name.
  final String name;

  /// Creator roles.
  final List<MetronCreatorRole> roles;

  /// Optional database ID.
  final int? id;

  const MetronCreator({
    required this.name,
    required this.roles,
    this.id,
  });

  /// Primary role (first in list).
  MetronCreatorRole? get primaryRole => roles.isNotEmpty ? roles.first : null;

  @override
  List<Object?> get props => [name, roles, id];

  @override
  String toString() =>
      'MetronCreator($name, roles: ${roles.map((r) => r.displayName).join(', ')})';
}

/// A named resource with optional ID (character, team, location, etc.).
class MetronResource extends Equatable {
  /// Resource name.
  final String name;

  /// Optional database ID.
  final int? id;

  const MetronResource({
    required this.name,
    this.id,
  });

  @override
  List<Object?> get props => [name, id];

  @override
  String toString() => 'MetronResource($name)';
}

/// A story arc reference.
class MetronArc extends Equatable {
  /// Arc name.
  final String name;

  /// Issue number within the arc.
  final int? number;

  /// Optional database ID.
  final int? id;

  const MetronArc({
    required this.name,
    this.number,
    this.id,
  });

  @override
  List<Object?> get props => [name, number, id];

  @override
  String toString() => 'MetronArc($name${number != null ? ' #$number' : ''})';
}

/// A universe/multiverse reference.
class MetronUniverse extends Equatable {
  /// Universe name.
  final String name;

  /// Universe designation (e.g., "Earth-616").
  final String? designation;

  /// Optional database ID.
  final int? id;

  const MetronUniverse({
    required this.name,
    this.designation,
    this.id,
  });

  @override
  List<Object?> get props => [name, designation, id];

  @override
  String toString() =>
      'MetronUniverse($name${designation != null ? ' ($designation)' : ''})';
}

/// Publisher information.
class MetronPublisher extends Equatable {
  /// Publisher name.
  final String name;

  /// Optional database ID.
  final int? id;

  /// Imprint name (if any).
  final String? imprint;

  /// Imprint database ID (if any).
  final int? imprintId;

  const MetronPublisher({
    required this.name,
    this.id,
    this.imprint,
    this.imprintId,
  });

  @override
  List<Object?> get props => [name, id, imprint, imprintId];

  @override
  String toString() =>
      'MetronPublisher($name${imprint != null ? ' / $imprint' : ''})';
}

/// Series information.
class MetronSeries extends Equatable {
  /// Series name.
  final String name;

  /// Sort name (for alphabetical ordering).
  final String? sortName;

  /// Volume number (US comics specific).
  final int? volume;

  /// Total issue count.
  final int? issueCount;

  /// Total volume count.
  final int? volumeCount;

  /// Series format.
  final SeriesFormat? format;

  /// Year series started.
  final int? startYear;

  /// Language code (ISO 639-3).
  final String? language;

  /// Optional database ID.
  final int? id;

  /// Alternative names for the series.
  final List<String> alternativeNames;

  const MetronSeries({
    required this.name,
    this.sortName,
    this.volume,
    this.issueCount,
    this.volumeCount,
    this.format,
    this.startYear,
    this.language,
    this.id,
    this.alternativeNames = const [],
  });

  /// Effective sort name (falls back to name).
  String get effectiveSortName => sortName ?? name;

  @override
  List<Object?> get props => [
        name,
        sortName,
        volume,
        issueCount,
        volumeCount,
        format,
        startYear,
        language,
        id,
        alternativeNames,
      ];

  @override
  String toString() => 'MetronSeries($name)';
}

/// Price with country code.
class MetronPrice extends Equatable {
  /// Price value.
  final double value;

  /// ISO 3166-1 alpha-2 country code.
  final String country;

  const MetronPrice({
    required this.value,
    required this.country,
  });

  @override
  List<Object?> get props => [value, country];

  @override
  String toString() => 'MetronPrice($value $country)';
}

/// GTIN (Global Trade Item Number) identifiers.
class MetronGtin extends Equatable {
  /// ISBN (10 or 13 digits).
  final String? isbn;

  /// UPC (typically 12 digits).
  final String? upc;

  const MetronGtin({
    this.isbn,
    this.upc,
  });

  /// Whether any GTIN is present.
  bool get hasValue => isbn != null || upc != null;

  @override
  List<Object?> get props => [isbn, upc];

  @override
  String toString() {
    final parts = <String>[];
    if (isbn != null) parts.add('ISBN: $isbn');
    if (upc != null) parts.add('UPC: $upc');
    return 'MetronGtin(${parts.join(', ')})';
  }
}

/// URL reference.
class MetronUrl extends Equatable {
  /// URL value.
  final String url;

  /// Whether this is the primary URL.
  final bool isPrimary;

  const MetronUrl({
    required this.url,
    this.isPrimary = false,
  });

  @override
  List<Object?> get props => [url, isPrimary];

  @override
  String toString() => 'MetronUrl($url)';
}

/// Page metadata from MetronInfo.xml.
class MetronPageInfo extends Equatable {
  /// Page index (0-based).
  final int index;

  /// Page filename.
  final String? filename;

  /// Page type.
  final String? type;

  /// Whether this is a double page spread.
  final bool? doublePage;

  /// Image width.
  final int? imageWidth;

  /// Image height.
  final int? imageHeight;

  /// Image file size in bytes.
  final int? imageSize;

  const MetronPageInfo({
    required this.index,
    this.filename,
    this.type,
    this.doublePage,
    this.imageWidth,
    this.imageHeight,
    this.imageSize,
  });

  @override
  List<Object?> get props => [
        index,
        filename,
        type,
        doublePage,
        imageWidth,
        imageHeight,
        imageSize,
      ];

  @override
  String toString() => 'MetronPageInfo($index)';
}

/// A named story within an issue.
class MetronStory extends Equatable {
  /// Story title.
  final String title;

  const MetronStory({required this.title});

  @override
  List<Object?> get props => [title];

  @override
  String toString() => 'MetronStory($title)';
}

/// Reprint reference.
class MetronReprint extends Equatable {
  /// Reprint ID.
  final int? id;

  /// Reprint name/description.
  final String? name;

  const MetronReprint({this.id, this.name});

  @override
  List<Object?> get props => [id, name];

  @override
  String toString() => 'MetronReprint(${name ?? id})';
}
