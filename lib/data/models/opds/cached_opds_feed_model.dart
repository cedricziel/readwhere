import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/opds_entry.dart';
import '../../../domain/entities/opds_feed.dart';
import '../../../domain/entities/opds_link.dart';
import '../../database/tables/cached_opds_feeds_table.dart';

/// Result containing feed data and its cache status
class CachedFeedResult {
  /// The feed data
  final OpdsFeed feed;

  /// Whether this data came from cache
  final bool isFromCache;

  /// When the data was cached (null if not from cache)
  final DateTime? cachedAt;

  /// When the cache expires (null if not from cache)
  final DateTime? expiresAt;

  const CachedFeedResult({
    required this.feed,
    required this.isFromCache,
    this.cachedAt,
    this.expiresAt,
  });

  /// Whether the cached data is still fresh (not expired)
  bool get isFresh =>
      !isFromCache ||
      (expiresAt != null && DateTime.now().isBefore(expiresAt!));

  /// Whether the cached data is stale (expired)
  bool get isStale => isFromCache && !isFresh;

  /// Age of the cached data
  Duration? get age =>
      cachedAt != null ? DateTime.now().difference(cachedAt!) : null;
}

/// Model for cached OPDS feeds with SQLite serialization
class CachedOpdsFeedModel {
  final String id;
  final String catalogId;
  final String url;
  final String title;
  final String? subtitle;
  final String? author;
  final String? iconUrl;
  final OpdsFeedKind kind;
  final int? totalResults;
  final int? itemsPerPage;
  final int? startIndex;
  final DateTime? feedUpdatedAt;
  final DateTime cachedAt;
  final DateTime expiresAt;

  const CachedOpdsFeedModel({
    required this.id,
    required this.catalogId,
    required this.url,
    required this.title,
    this.subtitle,
    this.author,
    this.iconUrl,
    required this.kind,
    this.totalResults,
    this.itemsPerPage,
    this.startIndex,
    this.feedUpdatedAt,
    required this.cachedAt,
    required this.expiresAt,
  });

  /// Whether the cache has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether the cache is still fresh
  bool get isFresh => !isExpired;

  /// Age of the cached data
  Duration get age => DateTime.now().difference(cachedAt);

  /// Create from SQLite map
  factory CachedOpdsFeedModel.fromMap(Map<String, dynamic> map) {
    return CachedOpdsFeedModel(
      id: map[CachedOpdsFeedsTable.columnId] as String,
      catalogId: map[CachedOpdsFeedsTable.columnCatalogId] as String,
      url: map[CachedOpdsFeedsTable.columnUrl] as String,
      title: map[CachedOpdsFeedsTable.columnTitle] as String,
      subtitle: map[CachedOpdsFeedsTable.columnSubtitle] as String?,
      author: map[CachedOpdsFeedsTable.columnAuthor] as String?,
      iconUrl: map[CachedOpdsFeedsTable.columnIconUrl] as String?,
      kind: _kindFromString(map[CachedOpdsFeedsTable.columnKind] as String),
      totalResults: map[CachedOpdsFeedsTable.columnTotalResults] as int?,
      itemsPerPage: map[CachedOpdsFeedsTable.columnItemsPerPage] as int?,
      startIndex: map[CachedOpdsFeedsTable.columnStartIndex] as int?,
      feedUpdatedAt: map[CachedOpdsFeedsTable.columnFeedUpdatedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[CachedOpdsFeedsTable.columnFeedUpdatedAt] as int,
            )
          : null,
      cachedAt: DateTime.fromMillisecondsSinceEpoch(
        map[CachedOpdsFeedsTable.columnCachedAt] as int,
      ),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        map[CachedOpdsFeedsTable.columnExpiresAt] as int,
      ),
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      CachedOpdsFeedsTable.columnId: id,
      CachedOpdsFeedsTable.columnCatalogId: catalogId,
      CachedOpdsFeedsTable.columnUrl: url,
      CachedOpdsFeedsTable.columnTitle: title,
      CachedOpdsFeedsTable.columnSubtitle: subtitle,
      CachedOpdsFeedsTable.columnAuthor: author,
      CachedOpdsFeedsTable.columnIconUrl: iconUrl,
      CachedOpdsFeedsTable.columnKind: _kindToString(kind),
      CachedOpdsFeedsTable.columnTotalResults: totalResults,
      CachedOpdsFeedsTable.columnItemsPerPage: itemsPerPage,
      CachedOpdsFeedsTable.columnStartIndex: startIndex,
      CachedOpdsFeedsTable.columnFeedUpdatedAt:
          feedUpdatedAt?.millisecondsSinceEpoch,
      CachedOpdsFeedsTable.columnCachedAt: cachedAt.millisecondsSinceEpoch,
      CachedOpdsFeedsTable.columnExpiresAt: expiresAt.millisecondsSinceEpoch,
    };
  }

  /// Create from domain entity and URL
  factory CachedOpdsFeedModel.fromFeed({
    required String catalogId,
    required String url,
    required OpdsFeed feed,
    int? expirationDays,
  }) {
    final now = DateTime.now();
    final expiration = Duration(
      days: expirationDays ?? AppConstants.cacheExpirationDays,
    );

    return CachedOpdsFeedModel(
      id: feed.id,
      catalogId: catalogId,
      url: url,
      title: feed.title,
      subtitle: feed.subtitle,
      author: feed.author,
      iconUrl: feed.iconUrl,
      kind: feed.kind,
      totalResults: feed.totalResults,
      itemsPerPage: feed.itemsPerPage,
      startIndex: feed.startIndex,
      feedUpdatedAt: feed.updated,
      cachedAt: now,
      expiresAt: now.add(expiration),
    );
  }

  /// Convert to domain entity (requires entries and links to be provided)
  OpdsFeed toFeed({
    required List<OpdsEntry> entries,
    required List<OpdsLink> links,
  }) {
    return OpdsFeed(
      id: id,
      title: title,
      subtitle: subtitle,
      updated: feedUpdatedAt ?? cachedAt,
      author: author,
      iconUrl: iconUrl,
      links: links,
      entries: entries,
      kind: kind,
      totalResults: totalResults,
      itemsPerPage: itemsPerPage,
      startIndex: startIndex,
    );
  }

  /// Convert to CachedFeedResult
  CachedFeedResult toCachedResult({
    required List<OpdsEntry> entries,
    required List<OpdsLink> links,
  }) {
    return CachedFeedResult(
      feed: toFeed(entries: entries, links: links),
      isFromCache: true,
      cachedAt: cachedAt,
      expiresAt: expiresAt,
    );
  }

  static OpdsFeedKind _kindFromString(String value) {
    switch (value) {
      case 'navigation':
        return OpdsFeedKind.navigation;
      case 'acquisition':
        return OpdsFeedKind.acquisition;
      default:
        return OpdsFeedKind.unknown;
    }
  }

  static String _kindToString(OpdsFeedKind kind) {
    switch (kind) {
      case OpdsFeedKind.navigation:
        return 'navigation';
      case OpdsFeedKind.acquisition:
        return 'acquisition';
      case OpdsFeedKind.unknown:
        return 'unknown';
    }
  }
}
