import 'package:equatable/equatable.dart';

/// Represents an OPDS facet - a filter option within a facet group.
///
/// Facets allow users to filter catalog results by categories like
/// genre, author, language, etc.
///
/// Example:
/// ```xml
/// <link rel="http://opds-spec.org/facet"
///       href="/sci-fi"
///       title="Science-Fiction"
///       opds:facetGroup="Genre"
///       opds:activeFacet="true"
///       thr:count="42" />
/// ```
class OpdsFacet extends Equatable {
  /// Human-readable name of this facet option
  final String title;

  /// URL to fetch the filtered feed
  final String href;

  /// Number of items matching this facet (optional)
  final int? count;

  /// Whether this facet is currently active/selected
  final bool isActive;

  const OpdsFacet({
    required this.title,
    required this.href,
    this.count,
    this.isActive = false,
  });

  @override
  List<Object?> get props => [title, href, count, isActive];
}

/// Represents a group of related OPDS facets.
///
/// Facets are organized into groups like "Genre", "Author", "Language", etc.
/// Each group contains multiple facet options, with at most one being active.
class OpdsFacetGroup extends Equatable {
  /// Name of this facet group (e.g., "Genre", "Author")
  final String name;

  /// Available facet options in this group
  final List<OpdsFacet> facets;

  const OpdsFacetGroup({required this.name, required this.facets});

  /// Get the currently active facet in this group, if any
  OpdsFacet? get activeFacet {
    return facets.where((f) => f.isActive).firstOrNull;
  }

  /// Whether any facet in this group is active
  bool get hasActiveFacet => activeFacet != null;

  @override
  List<Object?> get props => [name, facets];
}
