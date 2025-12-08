import 'package:equatable/equatable.dart';

import 'opds_entry.dart';
import 'opds_link.dart';

/// The kind of OPDS feed
enum OpdsFeedKind {
  /// Navigation feed - contains links to other feeds
  navigation,

  /// Acquisition feed - contains book entries
  acquisition,

  /// Unknown or mixed feed
  unknown,
}

/// Represents an OPDS catalog feed
class OpdsFeed extends Equatable {
  /// Feed identifier
  final String id;

  /// Feed title
  final String title;

  /// Optional subtitle
  final String? subtitle;

  /// Last update timestamp
  final DateTime updated;

  /// Author/provider of the feed
  final String? author;

  /// Icon URL for the feed
  final String? iconUrl;

  /// Links in the feed (self, search, pagination, etc.)
  final List<OpdsLink> links;

  /// Entries in the feed (books or navigation items)
  final List<OpdsEntry> entries;

  /// The kind of feed (navigation or acquisition)
  final OpdsFeedKind kind;

  /// Total number of results (for paginated feeds)
  final int? totalResults;

  /// Items per page (for paginated feeds)
  final int? itemsPerPage;

  /// Start index (for paginated feeds)
  final int? startIndex;

  const OpdsFeed({
    required this.id,
    required this.title,
    this.subtitle,
    required this.updated,
    this.author,
    this.iconUrl,
    required this.links,
    required this.entries,
    this.kind = OpdsFeedKind.unknown,
    this.totalResults,
    this.itemsPerPage,
    this.startIndex,
  });

  /// Whether this is a navigation feed
  bool get isNavigation => kind == OpdsFeedKind.navigation;

  /// Whether this is an acquisition feed
  bool get isAcquisition => kind == OpdsFeedKind.acquisition;

  /// Whether this feed has pagination
  bool get hasPagination =>
      totalResults != null || hasNextPage || hasPreviousPage;

  /// Whether there is a next page
  bool get hasNextPage => nextPageLink != null;

  /// Whether there is a previous page
  bool get hasPreviousPage => previousPageLink != null;

  /// Get the self link
  OpdsLink? get selfLink {
    return links.where((l) => l.rel == OpdsLinkRel.self).firstOrNull;
  }

  /// Get the search link
  OpdsLink? get searchLink {
    return links.where((l) => l.isSearch).firstOrNull;
  }

  /// Whether this feed has search capability
  bool get hasSearch => searchLink != null;

  /// Get the start/home link
  OpdsLink? get startLink {
    return links.where((l) => l.rel == OpdsLinkRel.start).firstOrNull;
  }

  /// Get the next page link
  OpdsLink? get nextPageLink {
    return links.where((l) => l.rel == OpdsLinkRel.next).firstOrNull;
  }

  /// Get the previous page link
  OpdsLink? get previousPageLink {
    return links.where((l) => l.rel == OpdsLinkRel.previous).firstOrNull;
  }

  /// Get the first page link
  OpdsLink? get firstPageLink {
    return links.where((l) => l.rel == OpdsLinkRel.first).firstOrNull;
  }

  /// Get the last page link
  OpdsLink? get lastPageLink {
    return links.where((l) => l.rel == OpdsLinkRel.last).firstOrNull;
  }

  /// Get all navigation entries
  List<OpdsEntry> get navigationEntries {
    return entries.where((e) => e.isNavigation).toList();
  }

  /// Get all book entries
  List<OpdsEntry> get bookEntries {
    return entries.where((e) => e.isBook).toList();
  }

  /// Current page number (1-based)
  int get currentPage {
    if (startIndex == null || itemsPerPage == null || itemsPerPage == 0) {
      return 1;
    }
    return (startIndex! ~/ itemsPerPage!) + 1;
  }

  /// Total number of pages
  int get totalPages {
    if (totalResults == null || itemsPerPage == null || itemsPerPage == 0) {
      return 1;
    }
    return (totalResults! / itemsPerPage!).ceil();
  }

  OpdsFeed copyWith({
    String? id,
    String? title,
    String? subtitle,
    DateTime? updated,
    String? author,
    String? iconUrl,
    List<OpdsLink>? links,
    List<OpdsEntry>? entries,
    OpdsFeedKind? kind,
    int? totalResults,
    int? itemsPerPage,
    int? startIndex,
  }) {
    return OpdsFeed(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      updated: updated ?? this.updated,
      author: author ?? this.author,
      iconUrl: iconUrl ?? this.iconUrl,
      links: links ?? this.links,
      entries: entries ?? this.entries,
      kind: kind ?? this.kind,
      totalResults: totalResults ?? this.totalResults,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      startIndex: startIndex ?? this.startIndex,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    updated,
    author,
    iconUrl,
    links,
    entries,
    kind,
    totalResults,
    itemsPerPage,
    startIndex,
  ];

  @override
  String toString() =>
      'OpdsFeed(id: $id, title: $title, kind: $kind, entries: ${entries.length})';
}
