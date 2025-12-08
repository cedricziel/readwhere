import 'package:equatable/equatable.dart';

/// Role of a creator in a comic book.
enum CreatorRole {
  /// Story writer.
  writer,

  /// Pencil artist.
  penciller,

  /// Ink artist.
  inker,

  /// Colorist.
  colorist,

  /// Letterer (text/speech bubbles).
  letterer,

  /// Cover artist.
  coverArtist,

  /// Editor.
  editor,

  /// Translator.
  translator,

  /// Generic artist (combined penciller/inker).
  artist,

  /// Other/unknown role.
  other,
}

/// A creator (person) involved in making a comic book.
class Creator extends Equatable {
  /// The creator's name.
  final String name;

  /// The creator's role in the work.
  final CreatorRole role;

  /// Optional ID from a metadata source (e.g., Metron database).
  final String? id;

  const Creator({
    required this.name,
    required this.role,
    this.id,
  });

  /// Creates a writer.
  const Creator.writer(this.name, {this.id}) : role = CreatorRole.writer;

  /// Creates a penciller.
  const Creator.penciller(this.name, {this.id}) : role = CreatorRole.penciller;

  /// Creates an inker.
  const Creator.inker(this.name, {this.id}) : role = CreatorRole.inker;

  /// Creates a colorist.
  const Creator.colorist(this.name, {this.id}) : role = CreatorRole.colorist;

  /// Creates a letterer.
  const Creator.letterer(this.name, {this.id}) : role = CreatorRole.letterer;

  /// Creates a cover artist.
  const Creator.coverArtist(this.name, {this.id})
      : role = CreatorRole.coverArtist;

  /// Creates an editor.
  const Creator.editor(this.name, {this.id}) : role = CreatorRole.editor;

  /// Creates a translator.
  const Creator.translator(this.name, {this.id})
      : role = CreatorRole.translator;

  /// Creates a generic artist.
  const Creator.artist(this.name, {this.id}) : role = CreatorRole.artist;

  @override
  List<Object?> get props => [name, role, id];

  @override
  String toString() => 'Creator($name, ${role.name})';
}

/// Utility for parsing comma-separated creator lists from ComicInfo.xml.
class CreatorParser {
  CreatorParser._();

  /// Parses a comma-separated list of names into [Creator] objects.
  static List<Creator> parseList(String? value, CreatorRole role) {
    if (value == null || value.trim().isEmpty) return const [];

    return value
        .split(',')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .map((name) => Creator(name: name, role: role))
        .toList();
  }

  /// Parses writers from a comma-separated string.
  static List<Creator> parseWriters(String? value) =>
      parseList(value, CreatorRole.writer);

  /// Parses pencillers from a comma-separated string.
  static List<Creator> parsePencillers(String? value) =>
      parseList(value, CreatorRole.penciller);

  /// Parses inkers from a comma-separated string.
  static List<Creator> parseInkers(String? value) =>
      parseList(value, CreatorRole.inker);

  /// Parses colorists from a comma-separated string.
  static List<Creator> parseColorists(String? value) =>
      parseList(value, CreatorRole.colorist);

  /// Parses letterers from a comma-separated string.
  static List<Creator> parseLetterers(String? value) =>
      parseList(value, CreatorRole.letterer);

  /// Parses cover artists from a comma-separated string.
  static List<Creator> parseCoverArtists(String? value) =>
      parseList(value, CreatorRole.coverArtist);

  /// Parses editors from a comma-separated string.
  static List<Creator> parseEditors(String? value) =>
      parseList(value, CreatorRole.editor);

  /// Parses translators from a comma-separated string.
  static List<Creator> parseTranslators(String? value) =>
      parseList(value, CreatorRole.translator);
}
