import 'package:readwhere_rss/readwhere_rss.dart';

import '../../domain/entities/feed_item.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/repositories/feed_item_repository.dart';
import '../../domain/sync/feed_sync_protocol.dart';
import '../../domain/sync/progress_sync_protocol.dart';
import '../models/feed_item_model.dart';

/// Implementation of [FeedSyncProtocol] for RSS/Atom feeds.
///
/// This service handles refreshing feed content and syncing
/// read/starred state across devices.
class FeedSyncService implements FeedSyncProtocol {
  final FeedItemRepository _feedItemRepository;
  final CatalogRepository _catalogRepository;
  final RssClient _rssClient;

  /// Maximum number of items to keep per feed
  static const int maxItemsPerFeed = 100;

  FeedSyncService({
    required FeedItemRepository feedItemRepository,
    required CatalogRepository catalogRepository,
    required RssClient rssClient,
  }) : _feedItemRepository = feedItemRepository,
       _catalogRepository = catalogRepository,
       _rssClient = rssClient;

  @override
  Future<List<FeedSyncResult>> syncAllFeeds() async {
    final catalogs = await _catalogRepository.getAll();
    final results = <FeedSyncResult>[];

    for (final catalog in catalogs) {
      if (catalog.isRss) {
        final result = await syncFeed(feedId: catalog.id, feedUrl: catalog.url);
        results.add(result);
      }
    }

    return results;
  }

  @override
  Future<FeedSyncResult> syncFeed({
    required String feedId,
    required String feedUrl,
  }) async {
    final errors = <SyncError>[];
    var itemsAdded = 0;
    var itemsUpdated = 0;

    try {
      // Get existing item IDs (which are GUIDs) to identify new vs updated items
      final existingItems = await _feedItemRepository.getByFeedId(feedId);
      final existingIds = existingItems.map((i) => i.id).toSet();

      // Fetch fresh data from network
      final rssFeed = await _rssClient.fetchFeed(feedUrl);
      final fetchedAt = DateTime.now();

      // Convert and categorize items
      final newItems = <FeedItem>[];
      final updatedItems = <FeedItem>[];

      for (final rssItem in rssFeed.items) {
        final item = FeedItemModel.fromRssItem(
          feedId: feedId,
          rssItem: rssItem,
          fetchedAt: fetchedAt,
        );

        if (existingIds.contains(item.id)) {
          // Item exists - will be updated (preserving read/starred state)
          updatedItems.add(item);
          itemsUpdated++;
        } else {
          // New item
          newItems.add(item);
          itemsAdded++;
        }
      }

      // Upsert all items (preserves read/starred state)
      await _feedItemRepository.upsertItems(feedId, [
        ...newItems,
        ...updatedItems,
      ]);

      // Cleanup old items (keep most recent)
      await _feedItemRepository.deleteOldItems(
        feedId,
        keepCount: maxItemsPerFeed,
      );

      return FeedSyncResult(
        feedId: feedId,
        itemsAdded: itemsAdded,
        itemsUpdated: itemsUpdated,
        starredMerged: 0, // Will be updated when sync is implemented
        readStateMerged: 0,
        errors: errors,
        syncedAt: DateTime.now(),
      );
    } catch (e) {
      errors.add(
        SyncError(
          recordId: feedId,
          operation: 'syncFeed',
          message: e.toString(),
        ),
      );

      return FeedSyncResult(
        feedId: feedId,
        itemsAdded: 0,
        itemsUpdated: 0,
        starredMerged: 0,
        readStateMerged: 0,
        errors: errors,
        syncedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> mergeStarredState({
    required String feedId,
    required List<String> remoteStarredIds,
  }) async {
    // Get local items
    final localItems = await _feedItemRepository.getByFeedId(feedId);

    // Union merge: items starred on any device stay starred
    for (final item in localItems) {
      if (remoteStarredIds.contains(item.id) && !item.isStarred) {
        // Remote is starred, local is not - star locally
        await _feedItemRepository.toggleStarred(item.id);
      }
      // If local is starred and remote is not, keep local starred
      // (will be synced to remote on next push)
    }
  }

  @override
  Future<List<String>> getLocalStarredIds(String feedId) async {
    // Get all starred items and filter by feedId
    final allStarredItems = await _feedItemRepository.getStarredItems();
    return allStarredItems
        .where((item) => item.feedId == feedId)
        .map((item) => item.id)
        .toList();
  }

  /// Sync read state from remote
  ///
  /// [feedId] The feed to sync
  /// [remoteReadIds] IDs of items marked as read on other devices
  Future<int> mergeReadState({
    required String feedId,
    required List<String> remoteReadIds,
  }) async {
    var mergedCount = 0;
    final localItems = await _feedItemRepository.getByFeedId(feedId);

    for (final item in localItems) {
      if (remoteReadIds.contains(item.id) && !item.isRead) {
        await _feedItemRepository.markAsRead(item.id);
        mergedCount++;
      }
    }

    return mergedCount;
  }

  /// Get items that need their read state synced
  ///
  /// [feedId] The feed to check
  Future<List<String>> getLocalReadIds(String feedId) async {
    final items = await _feedItemRepository.getByFeedId(feedId);
    return items.where((item) => item.isRead).map((item) => item.id).toList();
  }

  /// Check if a feed needs sync based on time elapsed
  Future<bool> needsSync(
    String feedId, {
    Duration threshold = const Duration(hours: 1),
  }) async {
    final items = await _feedItemRepository.getByFeedId(feedId);
    if (items.isEmpty) return true;

    // Get the most recent fetch time
    final mostRecentFetch = items
        .map((i) => i.fetchedAt)
        .whereType<DateTime>()
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return DateTime.now().difference(mostRecentFetch) > threshold;
  }
}
