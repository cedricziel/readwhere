import 'package:equatable/equatable.dart';

/// Represents a facet (filter option) in a catalog.
///
/// Facets allow filtering catalog results by categories like
/// genre, author, language, etc.
class CatalogFacet extends Equatable {
  /// Human-readable name of this facet option
  final String title;

  /// URL to fetch the filtered results
  final String href;

  /// Number of items matching this facet (optional)
  final int? count;

  /// Whether this facet is currently active/selected
  final bool isActive;

  const CatalogFacet({
    required this.title,
    required this.href,
    this.count,
    this.isActive = false,
  });

  @override
  List<Object?> get props => [title, href, count, isActive];
}

/// Represents a group of related facets.
///
/// Facets are organized into groups like "Genre", "Author", "Language", etc.
class CatalogFacetGroup extends Equatable {
  /// Name of this facet group (e.g., "Genre", "Author")
  final String name;

  /// Available facet options in this group
  final List<CatalogFacet> facets;

  const CatalogFacetGroup({required this.name, required this.facets});

  /// Get the currently active facet in this group, if any
  CatalogFacet? get activeFacet {
    return facets.where((f) => f.isActive).firstOrNull;
  }

  /// Whether any facet in this group is active
  bool get hasActiveFacet => activeFacet != null;

  @override
  List<Object?> get props => [name, facets];
}
