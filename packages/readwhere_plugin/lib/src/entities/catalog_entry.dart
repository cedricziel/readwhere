import 'catalog_file.dart';
import 'catalog_link.dart';

/// The type of catalog entry.
enum CatalogEntryType {
  /// A downloadable book/publication.
  book,

  /// A collection/group of entries (e.g., a series, category).
  collection,

  /// A navigation entry that leads to more content.
  navigation,
}

/// Interface for catalog entries (books, collections, navigation items).
///
/// Entries represent browsable/downloadable items in a catalog.
/// They can be books with downloadable files, collections that
/// contain more entries, or navigation items that link to other
/// parts of the catalog.
abstract class CatalogEntry {
  /// Unique identifier for this entry within its catalog.
  String get id;

  /// The title of the entry.
  String get title;

  /// The type of entry.
  CatalogEntryType get type;

  /// Optional subtitle (e.g., author name, series info).
  String? get subtitle;

  /// Optional summary/description of the entry.
  String? get summary;

  /// Optional URL for a thumbnail/cover image.
  String? get thumbnailUrl;

  /// Downloadable files for this entry.
  ///
  /// Only populated for [CatalogEntryType.book] entries.
  List<CatalogFile> get files;

  /// Navigation/related links for this entry.
  List<CatalogLink> get links;
}

/// Default implementation of [CatalogEntry].
///
/// Providers can use this directly or create their own implementations
/// that extend [CatalogEntry] with additional provider-specific data.
class DefaultCatalogEntry implements CatalogEntry {
  const DefaultCatalogEntry({
    required this.id,
    required this.title,
    required this.type,
    this.subtitle,
    this.summary,
    this.thumbnailUrl,
    this.files = const [],
    this.links = const [],
    this.properties = const {},
  });

  @override
  final String id;

  @override
  final String title;

  @override
  final CatalogEntryType type;

  @override
  final String? subtitle;

  @override
  final String? summary;

  @override
  final String? thumbnailUrl;

  @override
  final List<CatalogFile> files;

  @override
  final List<CatalogLink> links;

  /// Additional provider-specific properties.
  final Map<String, dynamic> properties;

  /// Returns the primary downloadable file, if any.
  CatalogFile? get primaryFile {
    if (files.isEmpty) return null;
    return files.firstWhere((f) => f.isPrimary, orElse: () => files.first);
  }

  /// Whether this entry has downloadable files.
  bool get hasFiles => files.isNotEmpty;

  /// Whether this entry can be browsed (collection or navigation).
  bool get isBrowsable =>
      type == CatalogEntryType.collection ||
      type == CatalogEntryType.navigation;
}
