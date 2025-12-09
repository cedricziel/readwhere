import 'package:equatable/equatable.dart';

/// Represents a navigation link in a catalog.
///
/// Links are used for navigation within a catalog (e.g., pagination,
/// related entries, search endpoints) as opposed to [CatalogFile]
/// which represents downloadable content.
class CatalogLink extends Equatable {
  const CatalogLink({
    required this.href,
    this.title,
    this.rel,
    this.type,
    this.properties = const {},
  });

  /// The URL this link points to.
  final String href;

  /// Optional title/label for this link.
  final String? title;

  /// The relationship type (e.g., 'next', 'search', 'subsection').
  ///
  /// Common values include:
  /// - 'self': Link to the current resource
  /// - 'start': Link to the start/root of the catalog
  /// - 'next': Link to the next page of results
  /// - 'previous': Link to the previous page of results
  /// - 'search': Link to a search endpoint
  /// - 'subsection': Link to a subcategory/collection
  /// - 'http://opds-spec.org/acquisition': Acquisition link (OPDS)
  final String? rel;

  /// The MIME type of the linked resource.
  final String? type;

  /// Additional provider-specific properties.
  final Map<String, dynamic> properties;

  /// Whether this is a navigation link (as opposed to acquisition).
  bool get isNavigation {
    if (rel == null) return true;
    return !rel!.contains('acquisition');
  }

  /// Whether this is a search link.
  bool get isSearch => rel == 'search';

  /// Whether this is a pagination link.
  bool get isPagination => rel == 'next' || rel == 'previous';

  /// Whether this is a "next page" link.
  bool get isNext => rel == 'next';

  /// Whether this is a "previous page" link.
  bool get isPrevious => rel == 'previous';

  @override
  List<Object?> get props => [href, title, rel, type, properties];
}
