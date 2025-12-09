import 'package:readwhere_rss/readwhere_rss.dart';

import '../../domain/entities/feed_item.dart';
import '../database/tables/feed_items_table.dart';

/// Data model for FeedItem entity with database serialization support
class FeedItemModel extends FeedItem {
  const FeedItemModel({
    required super.id,
    required super.feedId,
    required super.title,
    super.content,
    super.description,
    super.link,
    super.author,
    super.pubDate,
    super.thumbnailUrl,
    super.isRead,
    super.isStarred,
    required super.fetchedAt,
    super.enclosures,
    super.fullContent,
    super.contentScrapedAt,
  });

  /// Create a FeedItemModel from a Map (SQLite row)
  factory FeedItemModel.fromMap(Map<String, dynamic> map) {
    return FeedItemModel(
      id: map[FeedItemsTable.columnId] as String,
      feedId: map[FeedItemsTable.columnFeedId] as String,
      title: map[FeedItemsTable.columnTitle] as String,
      content: map[FeedItemsTable.columnContent] as String?,
      description: map[FeedItemsTable.columnDescription] as String?,
      link: map[FeedItemsTable.columnLink] as String?,
      author: map[FeedItemsTable.columnAuthor] as String?,
      pubDate: map[FeedItemsTable.columnPubDate] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[FeedItemsTable.columnPubDate] as int,
            )
          : null,
      thumbnailUrl: map[FeedItemsTable.columnThumbnailUrl] as String?,
      isRead: (map[FeedItemsTable.columnIsRead] as int) == 1,
      isStarred: (map[FeedItemsTable.columnIsStarred] as int) == 1,
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(
        map[FeedItemsTable.columnFetchedAt] as int,
      ),
      // Enclosures are not stored in the database - they come from the RSS feed
      enclosures: const [],
      fullContent: map[FeedItemsTable.columnFullContent] as String?,
      contentScrapedAt: map[FeedItemsTable.columnContentScrapedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[FeedItemsTable.columnContentScrapedAt] as int,
            )
          : null,
    );
  }

  /// Create a FeedItemModel from a domain entity
  factory FeedItemModel.fromEntity(FeedItem item) {
    if (item is FeedItemModel) {
      return item;
    }
    return FeedItemModel(
      id: item.id,
      feedId: item.feedId,
      title: item.title,
      content: item.content,
      description: item.description,
      link: item.link,
      author: item.author,
      pubDate: item.pubDate,
      thumbnailUrl: item.thumbnailUrl,
      isRead: item.isRead,
      isStarred: item.isStarred,
      fetchedAt: item.fetchedAt,
      enclosures: item.enclosures,
      fullContent: item.fullContent,
      contentScrapedAt: item.contentScrapedAt,
    );
  }

  /// Create a FeedItemModel from an RssItem
  ///
  /// [feedId] - The catalog ID of the feed this item belongs to
  /// [rssItem] - The RSS item to convert
  /// [fetchedAt] - When this item was fetched (defaults to now)
  factory FeedItemModel.fromRssItem({
    required String feedId,
    required RssItem rssItem,
    DateTime? fetchedAt,
  }) {
    return FeedItemModel(
      id: rssItem.id,
      feedId: feedId,
      title: rssItem.title,
      content: rssItem.content,
      description: rssItem.description,
      link: rssItem.link,
      author: rssItem.author,
      pubDate: rssItem.pubDate,
      thumbnailUrl: rssItem.thumbnailUrl,
      isRead: false,
      isStarred: false,
      fetchedAt: fetchedAt ?? DateTime.now(),
      enclosures: rssItem.enclosures,
    );
  }

  /// Convert to a Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      FeedItemsTable.columnId: id,
      FeedItemsTable.columnFeedId: feedId,
      FeedItemsTable.columnTitle: title,
      FeedItemsTable.columnContent: content,
      FeedItemsTable.columnDescription: description,
      FeedItemsTable.columnLink: link,
      FeedItemsTable.columnAuthor: author,
      FeedItemsTable.columnPubDate: pubDate?.millisecondsSinceEpoch,
      FeedItemsTable.columnThumbnailUrl: thumbnailUrl,
      FeedItemsTable.columnIsRead: isRead ? 1 : 0,
      FeedItemsTable.columnIsStarred: isStarred ? 1 : 0,
      FeedItemsTable.columnFetchedAt: fetchedAt.millisecondsSinceEpoch,
      FeedItemsTable.columnFullContent: fullContent,
      FeedItemsTable.columnContentScrapedAt:
          contentScrapedAt?.millisecondsSinceEpoch,
    };
  }

  /// Convert to domain entity (FeedItem)
  FeedItem toEntity() {
    return FeedItem(
      id: id,
      feedId: feedId,
      title: title,
      content: content,
      description: description,
      link: link,
      author: author,
      pubDate: pubDate,
      thumbnailUrl: thumbnailUrl,
      isRead: isRead,
      isStarred: isStarred,
      fetchedAt: fetchedAt,
      enclosures: enclosures,
      fullContent: fullContent,
      contentScrapedAt: contentScrapedAt,
    );
  }
}
