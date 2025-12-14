import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/catalog.dart';
import '../../domain/entities/feed_item.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/repositories/feed_item_repository.dart';
import '../../domain/repositories/nextcloud_news_mapping_repository.dart';

/// Result of a Nextcloud News sync operation
class NextcloudNewsSyncResult {
  /// Whether the sync completed successfully
  final bool success;

  /// Error message if sync failed
  final String? error;

  /// Number of new feeds imported
  final int feedsImported;

  /// Number of feeds linked (already existed locally)
  final int feedsLinked;

  /// Number of items synced
  final int itemsSynced;

  /// Number of items with state updated (read/starred)
  final int itemsStateUpdated;

  const NextcloudNewsSyncResult({
    required this.success,
    this.error,
    this.feedsImported = 0,
    this.feedsLinked = 0,
    this.itemsSynced = 0,
    this.itemsStateUpdated = 0,
  });

  factory NextcloudNewsSyncResult.failure(String error) {
    return NextcloudNewsSyncResult(success: false, error: error);
  }

  factory NextcloudNewsSyncResult.successEmpty() {
    return const NextcloudNewsSyncResult(success: true);
  }

  @override
  String toString() {
    if (!success) {
      return 'NextcloudNewsSyncResult(failed: $error)';
    }
    return 'NextcloudNewsSyncResult(success: $feedsImported imported, '
        '$feedsLinked linked, $itemsSynced items, $itemsStateUpdated updated)';
  }
}

/// Service for syncing RSS feeds from Nextcloud News
///
/// This service handles:
/// - Checking if the Nextcloud News app is available
/// - Importing feed subscriptions from Nextcloud News
/// - Deduplicating feeds by URL (linking existing local feeds)
/// - Syncing article read/starred state from Nextcloud
class NextcloudNewsSyncService {
  final NextcloudNewsService _newsService;
  final NextcloudCredentialStorage _credentialStorage;
  final CatalogRepository _catalogRepository;
  final FeedItemRepository _feedItemRepository;
  final NextcloudNewsMappingRepository _mappingRepository;
  final Uuid _uuid = const Uuid();

  NextcloudNewsSyncService({
    required NextcloudNewsService newsService,
    required NextcloudCredentialStorage credentialStorage,
    required CatalogRepository catalogRepository,
    required FeedItemRepository feedItemRepository,
    required NextcloudNewsMappingRepository mappingRepository,
  }) : _newsService = newsService,
       _credentialStorage = credentialStorage,
       _catalogRepository = catalogRepository,
       _feedItemRepository = feedItemRepository,
       _mappingRepository = mappingRepository;

  /// Check if the Nextcloud News app is available on the server
  ///
  /// [catalog] The Nextcloud catalog to check
  /// Returns true if the News app is available, false otherwise
  Future<bool> isNewsAvailable(Catalog catalog) async {
    if (!catalog.isNextcloud) {
      return false;
    }

    final appPassword = await _credentialStorage.getAppPassword(catalog.id);
    if (appPassword == null || catalog.username == null) {
      return false;
    }

    final auth = NextcloudNewsService.createAuth(
      catalog.username!,
      appPassword,
    );

    final status = await _newsService.checkAvailability(catalog.url, auth);
    return status.isAvailable;
  }

  /// Perform a full sync from Nextcloud News for a catalog
  ///
  /// This imports all feed subscriptions and syncs article state.
  /// [catalogId] The Nextcloud catalog ID to sync from
  Future<NextcloudNewsSyncResult> syncFromCatalog(String catalogId) async {
    try {
      // Get the catalog
      final catalog = await _catalogRepository.getById(catalogId);
      if (catalog == null) {
        return NextcloudNewsSyncResult.failure('Catalog not found');
      }

      if (!catalog.isNextcloud) {
        return NextcloudNewsSyncResult.failure('Not a Nextcloud catalog');
      }

      if (!catalog.newsSyncEnabled) {
        return NextcloudNewsSyncResult.failure('News sync not enabled');
      }

      // Get credentials
      final appPassword = await _credentialStorage.getAppPassword(catalogId);
      if (appPassword == null || catalog.username == null) {
        return NextcloudNewsSyncResult.failure('Missing credentials');
      }

      final auth = NextcloudNewsService.createAuth(
        catalog.username!,
        appPassword,
      );

      // Check if News app is available
      final status = await _newsService.checkAvailability(catalog.url, auth);
      if (!status.isAvailable) {
        return NextcloudNewsSyncResult.failure(
          'Nextcloud News app not available: '
          '${status.errorMessage ?? "not installed"}',
        );
      }

      // Fetch feeds from Nextcloud News
      final feedsResponse = await _newsService.getFeeds(catalog.url, auth);

      // Import feeds
      final feedResult = await _importFeeds(catalog, feedsResponse.feeds);

      // Fetch and sync items
      final itemResult = await _syncItems(catalog, auth, feedsResponse.feeds);

      return NextcloudNewsSyncResult(
        success: true,
        feedsImported: feedResult.imported,
        feedsLinked: feedResult.linked,
        itemsSynced: itemResult.synced,
        itemsStateUpdated: itemResult.stateUpdated,
      );
    } catch (e) {
      return NextcloudNewsSyncResult.failure('Sync failed: $e');
    }
  }

  /// Import feeds from Nextcloud News, deduplicating by URL
  Future<_FeedImportResult> _importFeeds(
    Catalog ncCatalog,
    List<NextcloudNewsFeed> ncFeeds,
  ) async {
    int imported = 0;
    int linked = 0;

    for (final ncFeed in ncFeeds) {
      // Check if we already have a mapping for this NC feed
      final existingMapping = await _mappingRepository.getLocalFeedId(
        ncCatalog.id,
        ncFeed.id,
      );

      if (existingMapping != null) {
        // Already mapped, skip
        continue;
      }

      // Check if there's an existing local feed with this URL
      final existingFeed = await _catalogRepository.findByUrl(ncFeed.url);

      if (existingFeed != null && existingFeed.isRss) {
        // Link to existing local feed
        await _mappingRepository.saveFeedMapping(
          catalogId: ncCatalog.id,
          ncFeedId: ncFeed.id,
          localFeedId: existingFeed.id,
          feedUrl: ncFeed.url,
        );
        linked++;
      } else {
        // Create new local RSS feed
        final newFeedId = _uuid.v4();
        final newFeed = Catalog(
          id: newFeedId,
          name: ncFeed.title,
          url: ncFeed.url,
          iconUrl: ncFeed.faviconLink,
          addedAt: DateTime.now(),
          type: CatalogType.rss,
        );

        await _catalogRepository.insert(newFeed);

        // Save the mapping
        await _mappingRepository.saveFeedMapping(
          catalogId: ncCatalog.id,
          ncFeedId: ncFeed.id,
          localFeedId: newFeedId,
          feedUrl: ncFeed.url,
        );
        imported++;
      }
    }

    return _FeedImportResult(imported: imported, linked: linked);
  }

  /// Sync items from Nextcloud News, updating read/starred state
  Future<_ItemSyncResult> _syncItems(
    Catalog ncCatalog,
    String auth,
    List<NextcloudNewsFeed> ncFeeds,
  ) async {
    int synced = 0;
    int stateUpdated = 0;

    for (final ncFeed in ncFeeds) {
      // Get the local feed ID for this NC feed
      final localFeedId = await _mappingRepository.getLocalFeedId(
        ncCatalog.id,
        ncFeed.id,
      );

      if (localFeedId == null) {
        // Feed not mapped (shouldn't happen after importFeeds)
        continue;
      }

      // Fetch items from Nextcloud News
      // Include read items to sync state
      // type=0 means filter by feed, id is the feed ID
      final ncItems = await _newsService.getItems(
        ncCatalog.url,
        auth,
        type: 0,
        id: ncFeed.id,
        getRead: true,
        batchSize: 200,
      );

      for (final ncItem in ncItems) {
        synced++;

        // Check if we have a mapping for this item
        final localItemId = await _mappingRepository.getLocalItemId(
          ncCatalog.id,
          ncItem.id,
        );

        if (localItemId != null) {
          // Item exists, sync state
          final localItem = await _feedItemRepository.getById(localItemId);
          if (localItem != null) {
            bool stateChanged = false;

            // Sync read state (Nextcloud wins)
            if (localItem.isRead != ncItem.isRead) {
              if (ncItem.isRead) {
                await _feedItemRepository.markAsRead(localItemId);
              } else {
                await _feedItemRepository.markAsUnread(localItemId);
              }
              stateChanged = true;
            }

            // Sync starred state (Nextcloud wins)
            if (localItem.isStarred != ncItem.isStarred) {
              await _feedItemRepository.toggleStarred(localItemId);
              stateChanged = true;
            }

            if (stateChanged) {
              stateUpdated++;
            }
          }
        } else {
          // Create new local item
          final newItemId = _uuid.v4();
          final newItem = FeedItem(
            id: newItemId,
            feedId: localFeedId,
            title: ncItem.title,
            content: ncItem.body,
            description: ncItem.body,
            link: ncItem.url,
            author: ncItem.author,
            pubDate: ncItem.pubDateTime,
            thumbnailUrl: ncItem.enclosureLink,
            isRead: ncItem.isRead,
            isStarred: ncItem.isStarred,
            fetchedAt: DateTime.now(),
          );

          await _feedItemRepository.upsertItems(localFeedId, [newItem]);

          // Save the mapping
          await _mappingRepository.saveItemMapping(
            catalogId: ncCatalog.id,
            ncItemId: ncItem.id,
            localItemId: newItemId,
            ncFeedId: ncFeed.id,
            localFeedId: localFeedId,
          );
        }
      }
    }

    return _ItemSyncResult(synced: synced, stateUpdated: stateUpdated);
  }

  /// Update the News app availability status for a catalog
  ///
  /// This checks the Nextcloud News API and updates the catalog's
  /// newsAppAvailable field.
  Future<Catalog> updateNewsAvailability(Catalog catalog) async {
    if (!catalog.isNextcloud) {
      return catalog;
    }

    final appPassword = await _credentialStorage.getAppPassword(catalog.id);
    if (appPassword == null || catalog.username == null) {
      return catalog.copyWith(newsAppAvailable: false);
    }

    final auth = NextcloudNewsService.createAuth(
      catalog.username!,
      appPassword,
    );

    final status = await _newsService.checkAvailability(catalog.url, auth);

    final updatedCatalog = catalog.copyWith(
      newsAppAvailable: status.isAvailable,
    );

    await _catalogRepository.update(updatedCatalog);

    return updatedCatalog;
  }

  /// Cleanup mappings when News sync is disabled for a catalog
  Future<void> cleanupMappings(String catalogId) async {
    await _mappingRepository.deleteMappingsForCatalog(catalogId);
  }

  /// Get sync statistics for a catalog
  Future<({int feedCount, int itemCount})> getSyncStats(
    String catalogId,
  ) async {
    final feedCount = await _mappingRepository.getFeedMappingCount(catalogId);
    final itemCount = await _mappingRepository.getItemMappingCount(catalogId);
    return (feedCount: feedCount, itemCount: itemCount);
  }
}

/// Internal result type for feed import
class _FeedImportResult {
  final int imported;
  final int linked;

  const _FeedImportResult({required this.imported, required this.linked});
}

/// Internal result type for item sync
class _ItemSyncResult {
  final int synced;
  final int stateUpdated;

  const _ItemSyncResult({required this.synced, required this.stateUpdated});
}
