import 'package:readwhere_plugin/readwhere_plugin.dart';
import 'package:readwhere_rss/readwhere_rss.dart';

/// Adapts RSS entities to the plugin's catalog entity interfaces.
///
/// These adapters allow RSS feed items to be used with
/// the plugin-based provider system.

/// Converts an [RssItem] to a [CatalogEntry].
class RssItemAdapter extends CatalogEntry {
  /// Creates an adapter for the given RSS item.
  const RssItemAdapter(this.item);

  /// The underlying RSS item.
  final RssItem item;

  @override
  String? get author => item.author;

  @override
  String get id => item.id;

  @override
  String get title => item.title;

  @override
  CatalogEntryType get type {
    if (item.hasSupportedEnclosures) {
      return CatalogEntryType.book;
    }
    // Items without supported enclosures are navigation (links to external content)
    return CatalogEntryType.navigation;
  }

  @override
  String? get subtitle => item.author;

  @override
  String? get summary => item.description;

  @override
  String? get thumbnailUrl => item.thumbnailUrl;

  @override
  List<CatalogFile> get files {
    return item.supportedEnclosures.map(_enclosureToFile).toList();
  }

  @override
  List<CatalogLink> get links {
    final result = <CatalogLink>[];

    // Add link to the original article/page
    if (item.link != null) {
      result.add(
        CatalogLink(href: item.link!, rel: 'alternate', title: 'View online'),
      );
    }

    // Add comments link if available
    if (item.commentsUrl != null) {
      result.add(
        CatalogLink(href: item.commentsUrl!, rel: 'replies', title: 'Comments'),
      );
    }

    return result;
  }

  CatalogFile _enclosureToFile(RssEnclosure enclosure) {
    return CatalogFile(
      href: enclosure.url,
      mimeType: enclosure.type ?? 'application/octet-stream',
      size: enclosure.length,
      title: enclosure.title ?? enclosure.filename,
      isPrimary: enclosure == item.supportedEnclosures.firstOrNull,
      properties: {
        if (enclosure.filename != null) 'filename': enclosure.filename,
      },
    );
  }
}

/// Converts an [RssFeed] to a [BrowseResult].
BrowseResult rssFeedToBrowseResult(RssFeed feed) {
  // Convert all items that have supported enclosures
  final entries = feed.items
      .where((item) => item.hasSupportedEnclosures)
      .map((item) => RssItemAdapter(item))
      .toList();

  return BrowseResult(
    entries: entries,
    title: feed.title,
    page: 1,
    totalPages: null, // RSS feeds are not paginated
    totalEntries: entries.length,
    hasNextPage: false,
    hasPreviousPage: false,
    nextPageUrl: null,
    previousPageUrl: null,
    searchLinks: const [], // RSS doesn't support search
    navigationLinks: const [],
    properties: {
      'feedId': feed.id,
      'feedFormat': feed.format.name,
      if (feed.description != null) 'description': feed.description,
      if (feed.author != null) 'author': feed.author,
      if (feed.imageUrl != null) 'imageUrl': feed.imageUrl,
      if (feed.language != null) 'language': feed.language,
      'totalItems': feed.items.length,
      'supportedItems': entries.length,
    },
  );
}

/// Extension methods for easy conversion.
extension RssItemToAdapter on RssItem {
  /// Converts this item to a [CatalogEntry] adapter.
  CatalogEntry toEntry() => RssItemAdapter(this);
}

extension RssFeedToBrowseResultExt on RssFeed {
  /// Converts this feed to a [BrowseResult].
  BrowseResult toBrowseResult() => rssFeedToBrowseResult(this);
}

extension RssItemListToEntries on List<RssItem> {
  /// Converts this list of items to [CatalogEntry] adapters.
  List<CatalogEntry> toEntries() => map((i) => RssItemAdapter(i)).toList();
}
