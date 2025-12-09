import 'package:readwhere_plugin/readwhere_plugin.dart';

import '../entities/opds_entry.dart';
import '../entities/opds_feed.dart';
import '../entities/opds_link.dart';

/// Adapts OPDS entities to the plugin's catalog entity interfaces.
///
/// These adapters allow the existing OPDS entities to be used with
/// the new plugin-based provider system.

/// Converts an [OpdsEntry] to a [CatalogEntry].
class OpdsEntryAdapter implements CatalogEntry {
  /// Creates an adapter for the given OPDS entry.
  const OpdsEntryAdapter(this.entry);

  /// The underlying OPDS entry.
  final OpdsEntry entry;

  @override
  String get id => entry.id;

  @override
  String get title => entry.title;

  @override
  CatalogEntryType get type {
    if (entry.isBook) return CatalogEntryType.book;
    if (entry.isNavigation) return CatalogEntryType.navigation;
    return CatalogEntryType.collection;
  }

  @override
  String? get subtitle => entry.author;

  @override
  String? get summary => entry.summary;

  @override
  String? get thumbnailUrl => entry.thumbnailUrl;

  @override
  List<CatalogFile> get files {
    return entry.acquisitionLinks.map((link) => _linkToFile(link)).toList();
  }

  @override
  List<CatalogLink> get links {
    final result = <CatalogLink>[];

    // Add navigation link if present
    final navLink = entry.navigationLink;
    if (navLink != null) {
      result.add(_opdsLinkToCatalogLink(navLink));
    }

    // Add related links
    for (final link in entry.links) {
      if (link.rel == OpdsLinkRel.related ||
          link.rel == OpdsLinkRel.alternate) {
        result.add(_opdsLinkToCatalogLink(link));
      }
    }

    return result;
  }

  CatalogFile _linkToFile(OpdsLink link) {
    return CatalogFile(
      href: link.href,
      mimeType: link.type,
      size: link.length,
      title: link.title,
      isPrimary: link == entry.bestSupportedAcquisitionLink,
      properties: {
        'rel': link.rel,
        if (link.price != null) 'price': link.price,
        if (link.currency != null) 'currency': link.currency,
        if (link.fileExtension != null) 'extension': link.fileExtension,
      },
    );
  }

  CatalogLink _opdsLinkToCatalogLink(OpdsLink link) {
    return CatalogLink(
      href: link.href,
      rel: link.rel,
      type: link.type,
      title: link.title,
    );
  }
}

/// Converts an [OpdsFeed] to a [BrowseResult].
BrowseResult opdsFeedToBrowseResult(OpdsFeed feed) {
  final entries = feed.entries.map((e) => OpdsEntryAdapter(e)).toList();

  // Convert search links
  final searchLinks = <CatalogLink>[];
  if (feed.searchLink != null) {
    searchLinks.add(
      CatalogLink(
        href: feed.searchLink!.href,
        rel: feed.searchLink!.rel,
        type: feed.searchLink!.type,
        title: feed.searchLink!.title,
      ),
    );
  }

  // Convert navigation links (subsections, etc.)
  final navigationLinks = <CatalogLink>[];
  for (final link in feed.links) {
    if (link.rel == OpdsLinkRel.subsection || link.rel == OpdsLinkRel.related) {
      navigationLinks.add(
        CatalogLink(
          href: link.href,
          rel: link.rel,
          type: link.type,
          title: link.title,
        ),
      );
    }
  }

  return BrowseResult(
    entries: entries,
    title: feed.title,
    page: feed.currentPage,
    totalPages: feed.totalPages > 1 ? feed.totalPages : null,
    totalEntries: feed.totalResults,
    hasNextPage: feed.hasNextPage,
    hasPreviousPage: feed.hasPreviousPage,
    nextPageUrl: feed.nextPageLink?.href,
    previousPageUrl: feed.previousPageLink?.href,
    searchLinks: searchLinks,
    navigationLinks: navigationLinks,
    properties: {
      'feedId': feed.id,
      'feedKind': feed.kind.name,
      if (feed.subtitle != null) 'subtitle': feed.subtitle,
      if (feed.author != null) 'author': feed.author,
      if (feed.iconUrl != null) 'iconUrl': feed.iconUrl,
      if (feed.itemsPerPage != null) 'itemsPerPage': feed.itemsPerPage,
      if (feed.startIndex != null) 'startIndex': feed.startIndex,
    },
  );
}

/// Extension methods for easy conversion.
extension OpdsEntryToAdapter on OpdsEntry {
  /// Converts this entry to a [CatalogEntry] adapter.
  CatalogEntry toEntry() => OpdsEntryAdapter(this);
}

extension OpdsFeedToBrowseResult on OpdsFeed {
  /// Converts this feed to a [BrowseResult].
  BrowseResult toBrowseResult() => opdsFeedToBrowseResult(this);
}

extension OpdsEntryListToEntries on List<OpdsEntry> {
  /// Converts this list of entries to [CatalogEntry] adapters.
  List<CatalogEntry> toEntries() => map((e) => OpdsEntryAdapter(e)).toList();
}
