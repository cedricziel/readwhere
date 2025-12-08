import 'package:equatable/equatable.dart';

import '../errors/epub_exception.dart';
import '../navigation/toc.dart';
import '../package/manifest/manifest.dart';
import '../package/metadata/metadata.dart';
import '../package/spine/spine.dart';

/// Represents a complete parsed EPUB book.
///
/// This is the main data model containing all parsed EPUB information.
class EpubBook extends Equatable {
  /// EPUB version (2.0, 3.0, 3.2, 3.3).
  final EpubVersion version;

  /// Unique identifier for this EPUB.
  final String uniqueIdentifier;

  /// Book metadata (title, authors, etc.).
  final EpubMetadata metadata;

  /// All resources in the book.
  final EpubManifest manifest;

  /// Reading order of content documents.
  final EpubSpine spine;

  /// Navigation structure (TOC, page list, landmarks).
  final EpubNavigation navigation;

  const EpubBook({
    required this.version,
    required this.uniqueIdentifier,
    required this.metadata,
    required this.manifest,
    required this.spine,
    required this.navigation,
  });

  /// The book title.
  String get title => metadata.title;

  /// The primary author.
  String? get author => metadata.author;

  /// All authors.
  List<String> get authors => metadata.authors;

  /// Book language.
  String get language => metadata.language;

  /// Publisher name.
  String? get publisher => metadata.publisher;

  /// Book description.
  String? get description => metadata.description;

  /// Publication date.
  DateTime? get publicationDate => metadata.date;

  /// Last modified date.
  DateTime? get modifiedDate => metadata.modified;

  /// Whether this is a fixed-layout EPUB.
  bool get isFixedLayout {
    // Check rendition:layout in metadata
    final layout = metadata.meta['rendition:layout'];
    return layout == 'pre-paginated';
  }

  /// Total number of chapters in spine.
  int get chapterCount => spine.length;

  /// Whether the book has a table of contents.
  bool get hasTableOfContents => navigation.isNotEmpty;

  /// Table of contents entries.
  List<TocEntry> get tableOfContents => navigation.tableOfContents;

  /// Whether the book has a page list.
  bool get hasPageList => navigation.hasPageList;

  /// Cover image manifest ID, if available.
  String? get coverImageId => metadata.coverImageId ?? manifest.coverImage?.id;

  @override
  List<Object?> get props => [
        version,
        uniqueIdentifier,
        metadata,
        manifest,
        spine,
        navigation,
      ];
}
