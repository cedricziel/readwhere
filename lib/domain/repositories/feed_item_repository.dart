import '../entities/feed_item.dart';

/// Repository interface for feed item persistence and retrieval
abstract class FeedItemRepository {
  /// Get all items for a specific feed
  ///
  /// [feedId] - The catalog ID of the feed
  /// [unreadOnly] - If true, only return unread items
  /// [limit] - Maximum number of items to return (null = no limit)
  Future<List<FeedItem>> getByFeedId(
    String feedId, {
    bool unreadOnly = false,
    int? limit,
  });

  /// Get a specific feed item by ID
  Future<FeedItem?> getById(String id);

  /// Insert or update feed items for a feed
  ///
  /// Items are matched by ID. Existing items are updated,
  /// new items are inserted. Read/starred state is preserved
  /// for existing items.
  Future<void> upsertItems(String feedId, List<FeedItem> items);

  /// Mark a specific item as read
  Future<void> markAsRead(String itemId);

  /// Mark a specific item as unread
  Future<void> markAsUnread(String itemId);

  /// Mark all items in a feed as read
  Future<void> markAllAsRead(String feedId);

  /// Toggle the starred state of an item
  Future<void> toggleStarred(String itemId);

  /// Get the count of unread items for a specific feed
  Future<int> getUnreadCount(String feedId);

  /// Get unread counts for all feeds
  ///
  /// Returns a map of feedId -> unreadCount
  Future<Map<String, int>> getAllUnreadCounts();

  /// Delete old items from a feed, keeping only the most recent
  ///
  /// [feedId] - The feed to clean up
  /// [keepCount] - Number of items to keep (default 100)
  Future<void> deleteOldItems(String feedId, {int keepCount = 100});

  /// Delete all items for a specific feed
  Future<void> deleteByFeedId(String feedId);

  /// Get starred items across all feeds
  Future<List<FeedItem>> getStarredItems();
}
