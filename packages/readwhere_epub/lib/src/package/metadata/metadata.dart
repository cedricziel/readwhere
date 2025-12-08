import 'package:equatable/equatable.dart';

import '../../errors/epub_exception.dart';

/// A creator or contributor to the publication.
class EpubCreator extends Equatable {
  /// The name of the creator/contributor.
  final String name;

  /// Name for sorting (e.g., "Doe, John").
  final String? fileAs;

  /// Role code (MARC relator, e.g., "aut" for author).
  final String? role;

  /// ID attribute for refinements.
  final String? id;

  const EpubCreator({
    required this.name,
    this.fileAs,
    this.role,
    this.id,
  });

  /// Parsed role as enum, if recognized.
  CreatorRole? get roleEnum => CreatorRole.fromCode(role);

  @override
  List<Object?> get props => [name, fileAs, role, id];

  @override
  String toString() => name;
}

/// Common MARC relator roles.
enum CreatorRole {
  author('aut'),
  editor('edt'),
  illustrator('ill'),
  translator('trl'),
  narrator('nrt'),
  publisher('pbl'),
  contributor('ctb'),
  adapter('adp'),
  artist('art'),
  composer('cmp'),
  compiler('com'),
  designer('dsr'),
  photographer('pht'),
  other('oth');

  final String code;
  const CreatorRole(this.code);

  /// Gets a role from its MARC code.
  static CreatorRole? fromCode(String? code) {
    if (code == null) return null;
    final lower = code.toLowerCase();
    return CreatorRole.values.where((r) => r.code == lower).firstOrNull;
  }
}

/// An identifier for the publication.
class EpubIdentifier extends Equatable {
  /// The identifier value.
  final String value;

  /// The identifier scheme (e.g., "ISBN", "UUID", "DOI").
  final String? scheme;

  /// Whether this is the unique identifier for the publication.
  final bool isPrimary;

  /// ID attribute for refinements.
  final String? id;

  const EpubIdentifier({
    required this.value,
    this.scheme,
    this.isPrimary = false,
    this.id,
  });

  @override
  List<Object?> get props => [value, scheme, isPrimary, id];

  @override
  String toString() {
    if (scheme != null) {
      return '$scheme: $value';
    }
    return value;
  }
}

/// A title with optional type and refinements.
class EpubTitle extends Equatable {
  /// The title text.
  final String value;

  /// Title type (main, subtitle, short, collection, etc.).
  final TitleType? type;

  /// Language of the title.
  final String? language;

  /// Display sequence for multiple titles.
  final int? displaySeq;

  /// ID attribute for refinements.
  final String? id;

  const EpubTitle({
    required this.value,
    this.type,
    this.language,
    this.displaySeq,
    this.id,
  });

  @override
  List<Object?> get props => [value, type, language, displaySeq, id];

  @override
  String toString() => value;
}

/// Title types per EPUB specification.
enum TitleType {
  main,
  subtitle,
  short,
  collection,
  edition,
  expanded;

  /// Parses a title type from a string.
  static TitleType? fromString(String? value) {
    if (value == null) return null;
    final lower = value.toLowerCase();
    return TitleType.values.where((t) => t.name == lower).firstOrNull;
  }
}

/// Complete metadata for an EPUB publication.
class EpubMetadata extends Equatable {
  // Required elements

  /// The unique identifier for this publication.
  final String identifier;

  /// The title of the publication.
  final String title;

  /// The primary language (BCP 47 code).
  final String language;

  // Optional Dublin Core elements

  /// All creators (authors, etc.).
  final List<EpubCreator> creators;

  /// All contributors.
  final List<EpubCreator> contributors;

  /// Publisher name.
  final String? publisher;

  /// Description/summary.
  final String? description;

  /// Subject keywords/categories.
  final List<String> subjects;

  /// Publication date.
  final DateTime? date;

  /// Rights/copyright statement.
  final String? rights;

  /// Source publication (for derived works).
  final String? source;

  /// Content type.
  final String? type;

  /// Format identifier.
  final String? format;

  /// Related resources.
  final List<String> relations;

  /// Coverage (geographic/temporal).
  final String? coverage;

  // EPUB-specific metadata

  /// Last modified timestamp (required for EPUB 3).
  final DateTime? modified;

  /// Cover image manifest ID.
  final String? coverImageId;

  /// All identifiers (may have multiple).
  final List<EpubIdentifier> identifiers;

  /// All titles (may have subtitles, etc.).
  final List<EpubTitle> titles;

  /// Additional metadata from <meta> elements.
  final Map<String, String> meta;

  /// The EPUB version.
  final EpubVersion version;

  const EpubMetadata({
    required this.identifier,
    required this.title,
    required this.language,
    this.creators = const [],
    this.contributors = const [],
    this.publisher,
    this.description,
    this.subjects = const [],
    this.date,
    this.rights,
    this.source,
    this.type,
    this.format,
    this.relations = const [],
    this.coverage,
    this.modified,
    this.coverImageId,
    this.identifiers = const [],
    this.titles = const [],
    this.meta = const {},
    this.version = EpubVersion.epub33,
  });

  /// The primary author name.
  String? get author {
    final authors = creators.where((c) =>
        c.role == null || c.role == 'aut' || c.roleEnum == CreatorRole.author);
    return authors.firstOrNull?.name;
  }

  /// All author names.
  List<String> get authors {
    return creators
        .where((c) =>
            c.role == null ||
            c.role == 'aut' ||
            c.roleEnum == CreatorRole.author)
        .map((c) => c.name)
        .toList();
  }

  /// All creator names (regardless of role).
  List<String> get creatorNames => creators.map((c) => c.name).toList();

  /// All contributor names.
  List<String> get contributorNames => contributors.map((c) => c.name).toList();

  /// The main title (first title or type=main).
  EpubTitle? get mainTitle {
    final main = titles.where((t) => t.type == TitleType.main).firstOrNull;
    return main ?? titles.firstOrNull;
  }

  /// The subtitle if present.
  EpubTitle? get subtitle {
    return titles.where((t) => t.type == TitleType.subtitle).firstOrNull;
  }

  /// Gets a meta property value.
  String? getMeta(String property) => meta[property];

  /// Whether this is an EPUB 3.x publication.
  bool get isEpub3 => version.isEpub3;

  /// Whether this is an EPUB 2.x publication.
  bool get isEpub2 => version.isEpub2;

  @override
  List<Object?> get props => [
        identifier,
        title,
        language,
        creators,
        contributors,
        publisher,
        description,
        subjects,
        date,
        rights,
        source,
        type,
        format,
        relations,
        coverage,
        modified,
        coverImageId,
        identifiers,
        titles,
        meta,
        version,
      ];

  /// Creates a copy with modified fields.
  EpubMetadata copyWith({
    String? identifier,
    String? title,
    String? language,
    List<EpubCreator>? creators,
    List<EpubCreator>? contributors,
    String? publisher,
    String? description,
    List<String>? subjects,
    DateTime? date,
    String? rights,
    String? source,
    String? type,
    String? format,
    List<String>? relations,
    String? coverage,
    DateTime? modified,
    String? coverImageId,
    List<EpubIdentifier>? identifiers,
    List<EpubTitle>? titles,
    Map<String, String>? meta,
    EpubVersion? version,
  }) {
    return EpubMetadata(
      identifier: identifier ?? this.identifier,
      title: title ?? this.title,
      language: language ?? this.language,
      creators: creators ?? this.creators,
      contributors: contributors ?? this.contributors,
      publisher: publisher ?? this.publisher,
      description: description ?? this.description,
      subjects: subjects ?? this.subjects,
      date: date ?? this.date,
      rights: rights ?? this.rights,
      source: source ?? this.source,
      type: type ?? this.type,
      format: format ?? this.format,
      relations: relations ?? this.relations,
      coverage: coverage ?? this.coverage,
      modified: modified ?? this.modified,
      coverImageId: coverImageId ?? this.coverImageId,
      identifiers: identifiers ?? this.identifiers,
      titles: titles ?? this.titles,
      meta: meta ?? this.meta,
      version: version ?? this.version,
    );
  }
}
