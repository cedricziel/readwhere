import 'package:equatable/equatable.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

/// Represents a filterable facet for library books.
///
/// Similar to [CatalogFacet] but for local filtering rather than
/// server-side OPDS navigation.
class LibraryFacet extends Equatable {
  /// Unique identifier for this facet (e.g., "format:epub")
  final String id;

  /// Human-readable name (e.g., "EPUB")
  final String title;

  /// Number of books matching this facet
  final int count;

  /// Whether this facet is currently selected
  final bool isActive;

  const LibraryFacet({
    required this.id,
    required this.title,
    required this.count,
    this.isActive = false,
  });

  /// Create a copy with updated active state.
  LibraryFacet copyWith({bool? isActive}) {
    return LibraryFacet(
      id: id,
      title: title,
      count: count,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convert to [CatalogFacet] for use with facet filter widgets.
  CatalogFacet toCatalogFacet() {
    return CatalogFacet(
      title: title,
      href: id, // Use id as href for identification
      count: count,
      isActive: isActive,
    );
  }

  @override
  List<Object?> get props => [id, title, count, isActive];
}

/// Represents a group of related library facets.
class LibraryFacetGroup extends Equatable {
  /// Group name (e.g., "Format", "Language")
  final String name;

  /// Field key for filtering (e.g., "format", "language")
  final String fieldKey;

  /// Available facets in this group
  final List<LibraryFacet> facets;

  const LibraryFacetGroup({
    required this.name,
    required this.fieldKey,
    required this.facets,
  });

  /// Get currently active facets in this group.
  List<LibraryFacet> get activeFacets =>
      facets.where((f) => f.isActive).toList();

  /// Whether any facet in this group is active.
  bool get hasActiveFacet => facets.any((f) => f.isActive);

  /// Convert to [CatalogFacetGroup] for use with facet filter widgets.
  CatalogFacetGroup toCatalogFacetGroup() {
    return CatalogFacetGroup(
      name: name,
      facets: facets.map((f) => f.toCatalogFacet()).toList(),
    );
  }

  @override
  List<Object?> get props => [name, fieldKey, facets];
}

/// Standard library facet field keys.
abstract class LibraryFacetFields {
  static const String format = 'format';
  static const String language = 'language';
  static const String subject = 'subject';
  static const String source = 'source';
  static const String status = 'status';
}

/// Standard library status facet values.
abstract class LibraryStatusFacets {
  static const String favorites = 'favorites';
  static const String unread = 'unread';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
}
