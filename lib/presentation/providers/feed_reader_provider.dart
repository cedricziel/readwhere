import 'package:flutter/foundation.dart';
import 'package:readwhere_rss/readwhere_rss.dart';

import '../../data/models/feed_item_model.dart';
import '../../domain/entities/feed_item.dart';
import '../../domain/repositories/feed_item_repository.dart';

/// Provider for RSS feed reader functionality.
///
/// This provider handles:
/// - Loading and refreshing feed items
/// - Tracking read/unread state
/// - Starring items
/// - Unread counts for badges
class FeedReaderProvider extends ChangeNotifier {
  final FeedItemRepository _feedItemRepository;
  final RssClient _rssClient;

  FeedReaderProvider({
    required FeedItemRepository feedItemRepository,
    required RssClient rssClient,
  }) : _feedItemRepository = feedItemRepository,
       _rssClient = rssClient;

  // State
  final Map<String, List<FeedItem>> _itemsByFeed = {};
  final Map<String, int> _unreadCounts = {};
  final Set<String> _loadingFeeds = {};
  String? _error;

  // Getters
  bool get hasError => _error != null;
  String? get error => _error;

  /// Whether any feed is currently loading
  bool get isLoading => _loadingFeeds.isNotEmpty;

  /// Check if a specific feed is loading
  bool isFeedLoading(String feedId) => _loadingFeeds.contains(feedId);

  /// Get items for a specific feed
  List<FeedItem> getItems(String feedId) {
    return List.unmodifiable(_itemsByFeed[feedId] ?? []);
  }

  /// Get unread count for a specific feed
  int getUnreadCount(String feedId) {
    return _unreadCounts[feedId] ?? 0;
  }

  /// Get all unread counts (for badges)
  Map<String, int> get allUnreadCounts => Map.unmodifiable(_unreadCounts);

  /// Total unread count across all feeds
  int get totalUnreadCount =>
      _unreadCounts.values.fold(0, (sum, count) => sum + count);

  // ===== Feed Item Loading =====

  /// Load feed items from the database
  Future<void> loadFeedItems(String feedId, {bool unreadOnly = false}) async {
    _loadingFeeds.add(feedId);
    _error = null;
    notifyListeners();

    try {
      final items = await _feedItemRepository.getByFeedId(
        feedId,
        unreadOnly: unreadOnly,
      );
      _itemsByFeed[feedId] = items;

      // Update unread count
      _unreadCounts[feedId] = await _feedItemRepository.getUnreadCount(feedId);
    } catch (e) {
      _error = 'Failed to load feed items: $e';
      debugPrint('FeedReaderProvider.loadFeedItems error: $e');
    } finally {
      _loadingFeeds.remove(feedId);
      notifyListeners();
    }
  }

  /// Refresh feed from network and update database
  Future<void> refreshFeed(String feedId, String feedUrl) async {
    _loadingFeeds.add(feedId);
    _error = null;
    notifyListeners();

    try {
      // Fetch fresh data from network
      final rssFeed = await _rssClient.fetchFeed(feedUrl);
      final fetchedAt = DateTime.now();

      // Convert RssItems to FeedItems
      final items = rssFeed.items.map((rssItem) {
        return FeedItemModel.fromRssItem(
          feedId: feedId,
          rssItem: rssItem,
          fetchedAt: fetchedAt,
        );
      }).toList();

      // Upsert to database (preserves read/starred state)
      await _feedItemRepository.upsertItems(feedId, items);

      // Clean up old items (keep last 100)
      await _feedItemRepository.deleteOldItems(feedId, keepCount: 100);

      // Reload from database to get updated state
      final updatedItems = await _feedItemRepository.getByFeedId(feedId);
      _itemsByFeed[feedId] = updatedItems;

      // Update unread count
      _unreadCounts[feedId] = await _feedItemRepository.getUnreadCount(feedId);
    } catch (e) {
      _error = 'Failed to refresh feed: $e';
      debugPrint('FeedReaderProvider.refreshFeed error: $e');
    } finally {
      _loadingFeeds.remove(feedId);
      notifyListeners();
    }
  }

  /// Load all unread counts (for initializing badges)
  Future<void> loadAllUnreadCounts() async {
    try {
      final counts = await _feedItemRepository.getAllUnreadCounts();
      _unreadCounts
        ..clear()
        ..addAll(counts);
      notifyListeners();
    } catch (e) {
      debugPrint('FeedReaderProvider.loadAllUnreadCounts error: $e');
    }
  }

  // ===== Read State Management =====

  /// Mark an item as read
  Future<void> markAsRead(String itemId) async {
    try {
      await _feedItemRepository.markAsRead(itemId);

      // Update local state
      for (final feedId in _itemsByFeed.keys) {
        final items = _itemsByFeed[feedId]!;
        final index = items.indexWhere((item) => item.id == itemId);
        if (index != -1) {
          final item = items[index];
          if (!item.isRead) {
            _itemsByFeed[feedId] = List.from(items)
              ..[index] = item.copyWith(isRead: true);

            // Update unread count
            final currentCount = _unreadCounts[feedId] ?? 0;
            if (currentCount > 0) {
              _unreadCounts[feedId] = currentCount - 1;
            }
          }
          break;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('FeedReaderProvider.markAsRead error: $e');
    }
  }

  /// Mark an item as unread
  Future<void> markAsUnread(String itemId) async {
    try {
      await _feedItemRepository.markAsUnread(itemId);

      // Update local state
      for (final feedId in _itemsByFeed.keys) {
        final items = _itemsByFeed[feedId]!;
        final index = items.indexWhere((item) => item.id == itemId);
        if (index != -1) {
          final item = items[index];
          if (item.isRead) {
            _itemsByFeed[feedId] = List.from(items)
              ..[index] = item.copyWith(isRead: false);

            // Update unread count
            _unreadCounts[feedId] = (_unreadCounts[feedId] ?? 0) + 1;
          }
          break;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('FeedReaderProvider.markAsUnread error: $e');
    }
  }

  /// Mark all items in a feed as read
  Future<void> markAllAsRead(String feedId) async {
    try {
      await _feedItemRepository.markAllAsRead(feedId);

      // Update local state
      if (_itemsByFeed.containsKey(feedId)) {
        _itemsByFeed[feedId] = _itemsByFeed[feedId]!
            .map((item) => item.copyWith(isRead: true))
            .toList();
      }
      _unreadCounts[feedId] = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('FeedReaderProvider.markAllAsRead error: $e');
    }
  }

  // ===== Starred Items =====

  /// Toggle starred state for an item
  Future<void> toggleStarred(String itemId) async {
    try {
      await _feedItemRepository.toggleStarred(itemId);

      // Update local state
      for (final feedId in _itemsByFeed.keys) {
        final items = _itemsByFeed[feedId]!;
        final index = items.indexWhere((item) => item.id == itemId);
        if (index != -1) {
          final item = items[index];
          _itemsByFeed[feedId] = List.from(items)
            ..[index] = item.copyWith(isStarred: !item.isStarred);
          break;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('FeedReaderProvider.toggleStarred error: $e');
    }
  }

  // ===== Item Retrieval =====

  /// Get a specific item by ID
  Future<FeedItem?> getItem(String itemId) async {
    // First check local cache
    for (final items in _itemsByFeed.values) {
      final item = items.where((i) => i.id == itemId).firstOrNull;
      if (item != null) return item;
    }

    // Fall back to database
    return await _feedItemRepository.getById(itemId);
  }

  /// Get starred items across all feeds
  Future<List<FeedItem>> getStarredItems() async {
    return await _feedItemRepository.getStarredItems();
  }

  // ===== Cleanup =====

  /// Delete all items for a feed (called when unsubscribing)
  Future<void> deleteItemsForFeed(String feedId) async {
    try {
      await _feedItemRepository.deleteByFeedId(feedId);
      _itemsByFeed.remove(feedId);
      _unreadCounts.remove(feedId);
      notifyListeners();
    } catch (e) {
      debugPrint('FeedReaderProvider.deleteItemsForFeed error: $e');
    }
  }

  /// Clear any error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
