import 'package:equatable/equatable.dart';

import 'catalog_entry.dart';
import 'catalog_link.dart';

/// Result of browsing or searching a catalog.
///
/// Contains the entries found, pagination information, and any
/// additional navigation links.
class BrowseResult extends Equatable {
  const BrowseResult({
    required this.entries,
    this.title,
    this.page,
    this.totalPages,
    this.totalEntries,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.nextPageUrl,
    this.previousPageUrl,
    this.searchLinks = const [],
    this.navigationLinks = const [],
    this.properties = const {},
  });

  /// Creates an empty browse result.
  const BrowseResult.empty()
    : entries = const [],
      title = null,
      page = null,
      totalPages = null,
      totalEntries = null,
      hasNextPage = false,
      hasPreviousPage = false,
      nextPageUrl = null,
      previousPageUrl = null,
      searchLinks = const [],
      navigationLinks = const [],
      properties = const {};

  /// The entries returned by the browse/search operation.
  final List<CatalogEntry> entries;

  /// Optional title for this result set (e.g., category name).
  final String? title;

  /// The current page number (1-indexed), if paginated.
  final int? page;

  /// The total number of pages, if known.
  final int? totalPages;

  /// The total number of entries across all pages, if known.
  final int? totalEntries;

  /// Whether there are more entries on the next page.
  final bool hasNextPage;

  /// Whether there are entries on the previous page.
  final bool hasPreviousPage;

  /// URL to fetch the next page of results.
  final String? nextPageUrl;

  /// URL to fetch the previous page of results.
  final String? previousPageUrl;

  /// Links to search endpoints within this catalog/section.
  final List<CatalogLink> searchLinks;

  /// Additional navigation links (e.g., subcategories).
  final List<CatalogLink> navigationLinks;

  /// Additional provider-specific properties.
  final Map<String, dynamic> properties;

  /// Whether this result set is empty.
  bool get isEmpty => entries.isEmpty;

  /// Whether this result set has entries.
  bool get isNotEmpty => entries.isNotEmpty;

  /// The number of entries in this result set.
  int get length => entries.length;

  /// Whether this result is paginated.
  bool get isPaginated => hasNextPage || hasPreviousPage || page != null;

  /// Whether search is available for this catalog/section.
  bool get hasSearch => searchLinks.isNotEmpty;

  /// Creates a copy of this result with the given fields replaced.
  BrowseResult copyWith({
    List<CatalogEntry>? entries,
    String? title,
    int? page,
    int? totalPages,
    int? totalEntries,
    bool? hasNextPage,
    bool? hasPreviousPage,
    String? nextPageUrl,
    String? previousPageUrl,
    List<CatalogLink>? searchLinks,
    List<CatalogLink>? navigationLinks,
    Map<String, dynamic>? properties,
  }) {
    return BrowseResult(
      entries: entries ?? this.entries,
      title: title ?? this.title,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      totalEntries: totalEntries ?? this.totalEntries,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      nextPageUrl: nextPageUrl ?? this.nextPageUrl,
      previousPageUrl: previousPageUrl ?? this.previousPageUrl,
      searchLinks: searchLinks ?? this.searchLinks,
      navigationLinks: navigationLinks ?? this.navigationLinks,
      properties: properties ?? this.properties,
    );
  }

  @override
  List<Object?> get props => [
    entries,
    title,
    page,
    totalPages,
    totalEntries,
    hasNextPage,
    hasPreviousPage,
    nextPageUrl,
    previousPageUrl,
    searchLinks,
    navigationLinks,
    properties,
  ];
}
