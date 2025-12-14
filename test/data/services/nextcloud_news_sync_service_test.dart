import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere/data/services/nextcloud_news_sync_service.dart';
import 'package:readwhere/domain/entities/catalog.dart';
import 'package:readwhere/domain/entities/feed_item.dart';
import 'package:readwhere/domain/repositories/catalog_repository.dart';
import 'package:readwhere/domain/repositories/feed_item_repository.dart';
import 'package:readwhere/domain/repositories/nextcloud_news_mapping_repository.dart';
import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';

import 'nextcloud_news_sync_service_test.mocks.dart';

@GenerateMocks([
  NextcloudNewsService,
  NextcloudCredentialStorage,
  CatalogRepository,
  FeedItemRepository,
  NextcloudNewsMappingRepository,
])
void main() {
  late MockNextcloudNewsService mockNewsService;
  late MockNextcloudCredentialStorage mockCredentialStorage;
  late MockCatalogRepository mockCatalogRepository;
  late MockFeedItemRepository mockFeedItemRepository;
  late MockNextcloudNewsMappingRepository mockMappingRepository;
  late NextcloudNewsSyncService syncService;

  setUp(() {
    mockNewsService = MockNextcloudNewsService();
    mockCredentialStorage = MockNextcloudCredentialStorage();
    mockCatalogRepository = MockCatalogRepository();
    mockFeedItemRepository = MockFeedItemRepository();
    mockMappingRepository = MockNextcloudNewsMappingRepository();

    syncService = NextcloudNewsSyncService(
      newsService: mockNewsService,
      credentialStorage: mockCredentialStorage,
      catalogRepository: mockCatalogRepository,
      feedItemRepository: mockFeedItemRepository,
      mappingRepository: mockMappingRepository,
    );
  });

  Catalog createNextcloudCatalog({
    String id = 'nc-catalog-1',
    bool newsSyncEnabled = true,
    String username = 'testuser',
  }) {
    return Catalog(
      id: id,
      name: 'My Nextcloud',
      url: 'https://cloud.example.com',
      type: CatalogType.nextcloud,
      addedAt: DateTime.now(),
      username: username,
      newsSyncEnabled: newsSyncEnabled,
    );
  }

  group('NextcloudNewsSyncResult', () {
    test('failure factory creates failed result', () {
      final result = NextcloudNewsSyncResult.failure('Some error');

      expect(result.success, false);
      expect(result.error, 'Some error');
    });

    test('successEmpty factory creates successful empty result', () {
      final result = NextcloudNewsSyncResult.successEmpty();

      expect(result.success, true);
      expect(result.feedsImported, 0);
      expect(result.itemsSynced, 0);
    });

    test('toString formats failure correctly', () {
      final result = NextcloudNewsSyncResult.failure('Error message');

      expect(result.toString(), contains('failed'));
      expect(result.toString(), contains('Error message'));
    });

    test('toString formats success correctly', () {
      const result = NextcloudNewsSyncResult(
        success: true,
        feedsImported: 5,
        feedsLinked: 2,
        itemsSynced: 100,
        itemsStateUpdated: 10,
      );

      expect(result.toString(), contains('success'));
      expect(result.toString(), contains('5 imported'));
      expect(result.toString(), contains('2 linked'));
    });
  });

  group('isNewsAvailable', () {
    test('returns false for non-Nextcloud catalog', () async {
      final catalog = Catalog(
        id: 'opds-1',
        name: 'OPDS Catalog',
        url: 'https://example.com/opds',
        type: CatalogType.opds,
        addedAt: DateTime.now(),
      );

      final result = await syncService.isNewsAvailable(catalog);

      expect(result, false);
      verifyNever(mockCredentialStorage.getAppPassword(any));
    });

    test('returns false when credentials are missing', () async {
      final catalog = createNextcloudCatalog();

      when(mockCredentialStorage.getAppPassword(catalog.id))
          .thenAnswer((_) async => null);

      final result = await syncService.isNewsAvailable(catalog);

      expect(result, false);
    });

    test('returns false when username is missing', () async {
      final catalog = Catalog(
        id: 'nc-1',
        name: 'NC',
        url: 'https://cloud.example.com',
        type: CatalogType.nextcloud,
        addedAt: DateTime.now(),
        username: null,
      );

      when(mockCredentialStorage.getAppPassword(catalog.id))
          .thenAnswer((_) async => 'app-password');

      final result = await syncService.isNewsAvailable(catalog);

      expect(result, false);
    });

    test('returns true when News app is available', () async {
      final catalog = createNextcloudCatalog();

      when(mockCredentialStorage.getAppPassword(catalog.id))
          .thenAnswer((_) async => 'app-password');

      when(mockNewsService.checkAvailability(any, any)).thenAnswer(
        (_) async => const NewsAppAvailabilityResult(
          status: NewsAppStatus.available,
          version: '24.0.0',
        ),
      );

      final result = await syncService.isNewsAvailable(catalog);

      expect(result, true);
    });

    test('returns false when News app is not installed', () async {
      final catalog = createNextcloudCatalog();

      when(mockCredentialStorage.getAppPassword(catalog.id))
          .thenAnswer((_) async => 'app-password');

      when(mockNewsService.checkAvailability(any, any)).thenAnswer(
        (_) async => const NewsAppAvailabilityResult(
          status: NewsAppStatus.notInstalled,
        ),
      );

      final result = await syncService.isNewsAvailable(catalog);

      expect(result, false);
    });
  });

  group('syncFromCatalog', () {
    test('returns failure when catalog not found', () async {
      when(mockCatalogRepository.getById('non-existent'))
          .thenAnswer((_) async => null);

      final result = await syncService.syncFromCatalog('non-existent');

      expect(result.success, false);
      expect(result.error, contains('not found'));
    });

    test('returns failure for non-Nextcloud catalog', () async {
      final catalog = Catalog(
        id: 'opds-1',
        name: 'OPDS',
        url: 'https://example.com/opds',
        type: CatalogType.opds,
        addedAt: DateTime.now(),
      );

      when(mockCatalogRepository.getById(catalog.id))
          .thenAnswer((_) async => catalog);

      final result = await syncService.syncFromCatalog(catalog.id);

      expect(result.success, false);
      expect(result.error, contains('Not a Nextcloud'));
    });

    test('returns failure when News sync is not enabled', () async {
      final catalog = createNextcloudCatalog(newsSyncEnabled: false);

      when(mockCatalogRepository.getById(catalog.id))
          .thenAnswer((_) async => catalog);

      final result = await syncService.syncFromCatalog(catalog.id);

      expect(result.success, false);
      expect(result.error, contains('not enabled'));
    });

    test('returns failure when credentials are missing', () async {
      final catalog = createNextcloudCatalog();

      when(mockCatalogRepository.getById(catalog.id))
          .thenAnswer((_) async => catalog);
      when(mockCredentialStorage.getAppPassword(catalog.id))
          .thenAnswer((_) async => null);

      final result = await syncService.syncFromCatalog(catalog.id);

      expect(result.success, false);
      expect(result.error, contains('credentials'));
    });

    test('returns failure when News app not available', () async {
      final catalog = createNextcloudCatalog();

      when(mockCatalogRepository.getById(catalog.id))
          .thenAnswer((_) async => catalog);
      when(mockCredentialStorage.getAppPassword(catalog.id))
          .thenAnswer((_) async => 'app-password');
      when(mockNewsService.checkAvailability(any, any)).thenAnswer(
        (_) async => const NewsAppAvailabilityResult(
          status: NewsAppStatus.notInstalled,
        ),
      );

      final result = await syncService.syncFromCatalog(catalog.id);

      expect(result.success, false);
      expect(result.error, contains('not available'));
    });

    test('successfully syncs feeds and items', () async {
      final catalog = createNextcloudCatalog();
      const ncFeed = NextcloudNewsFeed(
        id: 1,
        url: 'https://blog.example.com/feed',
        title: 'Example Blog',
        unreadCount: 5,
      );
      const ncItem = NextcloudNewsItem(
        id: 100,
        guid: 'guid-100',
        guidHash: 'hash-100',
        title: 'Test Article',
        feedId: 1,
        lastModified: 1700000000,
        unread: true,
        starred: false,
      );

      when(mockCatalogRepository.getById(catalog.id))
          .thenAnswer((_) async => catalog);
      when(mockCredentialStorage.getAppPassword(catalog.id))
          .thenAnswer((_) async => 'app-password');
      when(mockNewsService.checkAvailability(any, any)).thenAnswer(
        (_) async => const NewsAppAvailabilityResult(
          status: NewsAppStatus.available,
        ),
      );
      when(mockNewsService.getFeeds(any, any)).thenAnswer(
        (_) async => const NewsFedsResult(feeds: [ncFeed]),
      );
      // Track call count for getLocalFeedId to return different values
      var getLocalFeedIdCallCount = 0;
      when(mockMappingRepository.getLocalFeedId(catalog.id, ncFeed.id))
          .thenAnswer((_) async {
        getLocalFeedIdCallCount++;
        // First call (during import): no mapping
        // Second call (during sync): mapping exists
        return getLocalFeedIdCallCount == 1 ? null : 'local-feed-1';
      });
      when(mockCatalogRepository.findByUrl(ncFeed.url))
          .thenAnswer((_) async => null); // No existing local feed
      when(mockCatalogRepository.insert(any)).thenAnswer((invocation) async {
        final catalog = invocation.positionalArguments[0] as Catalog;
        return catalog;
      });
      when(mockMappingRepository.saveFeedMapping(
        catalogId: anyNamed('catalogId'),
        ncFeedId: anyNamed('ncFeedId'),
        localFeedId: anyNamed('localFeedId'),
        feedUrl: anyNamed('feedUrl'),
      )).thenAnswer((_) async => NewsFeedMapping(
            id: 'mapping-1',
            catalogId: catalog.id,
            ncFeedId: ncFeed.id,
            localFeedId: 'local-feed-1',
            feedUrl: ncFeed.url,
            createdAt: DateTime.now(),
          ));
      when(mockNewsService.getItems(
        any,
        any,
        type: anyNamed('type'),
        id: anyNamed('id'),
        getRead: anyNamed('getRead'),
        batchSize: anyNamed('batchSize'),
      )).thenAnswer((_) async => [ncItem]);
      when(mockMappingRepository.getLocalItemId(catalog.id, ncItem.id))
          .thenAnswer((_) async => null); // No mapping, will create item
      when(mockFeedItemRepository.upsertItems(any, any))
          .thenAnswer((_) async => {});
      when(mockMappingRepository.saveItemMapping(
        catalogId: anyNamed('catalogId'),
        ncItemId: anyNamed('ncItemId'),
        localItemId: anyNamed('localItemId'),
        ncFeedId: anyNamed('ncFeedId'),
        localFeedId: anyNamed('localFeedId'),
      )).thenAnswer((_) async => NewsItemMapping(
            id: 'item-mapping-1',
            catalogId: catalog.id,
            ncItemId: ncItem.id,
            localItemId: 'local-item-1',
            ncFeedId: ncFeed.id,
            localFeedId: 'local-feed-1',
            createdAt: DateTime.now(),
          ));

      final result = await syncService.syncFromCatalog(catalog.id);

      expect(result.success, true);
      expect(result.feedsImported, 1);
      expect(result.itemsSynced, 1);
      verify(mockCatalogRepository.insert(any)).called(1);
    });

    test('links existing feed by URL instead of importing', () async {
      final catalog = createNextcloudCatalog();
      const ncFeed = NextcloudNewsFeed(
        id: 1,
        url: 'https://blog.example.com/feed',
        title: 'Example Blog',
      );
      final existingLocalFeed = Catalog(
        id: 'existing-feed',
        name: 'Existing Feed',
        url: ncFeed.url,
        type: CatalogType.rss,
        addedAt: DateTime.now(),
      );

      when(mockCatalogRepository.getById(catalog.id))
          .thenAnswer((_) async => catalog);
      when(mockCredentialStorage.getAppPassword(catalog.id))
          .thenAnswer((_) async => 'app-password');
      when(mockNewsService.checkAvailability(any, any)).thenAnswer(
        (_) async => const NewsAppAvailabilityResult(
          status: NewsAppStatus.available,
        ),
      );
      when(mockNewsService.getFeeds(any, any)).thenAnswer(
        (_) async => const NewsFedsResult(feeds: [ncFeed]),
      );
      // Track call count for getLocalFeedId to return different values
      var getLocalFeedIdCallCount = 0;
      when(mockMappingRepository.getLocalFeedId(catalog.id, ncFeed.id))
          .thenAnswer((_) async {
        getLocalFeedIdCallCount++;
        // First call (during import): no mapping
        // Second call (during sync): mapping exists
        return getLocalFeedIdCallCount == 1 ? null : existingLocalFeed.id;
      });
      when(mockCatalogRepository.findByUrl(ncFeed.url))
          .thenAnswer((_) async => existingLocalFeed);
      when(mockMappingRepository.saveFeedMapping(
        catalogId: anyNamed('catalogId'),
        ncFeedId: anyNamed('ncFeedId'),
        localFeedId: anyNamed('localFeedId'),
        feedUrl: anyNamed('feedUrl'),
      )).thenAnswer((_) async => NewsFeedMapping(
            id: 'mapping-1',
            catalogId: catalog.id,
            ncFeedId: ncFeed.id,
            localFeedId: existingLocalFeed.id,
            feedUrl: ncFeed.url,
            createdAt: DateTime.now(),
          ));
      when(mockNewsService.getItems(
        any,
        any,
        type: anyNamed('type'),
        id: anyNamed('id'),
        getRead: anyNamed('getRead'),
        batchSize: anyNamed('batchSize'),
      )).thenAnswer((_) async => []);

      final result = await syncService.syncFromCatalog(catalog.id);

      expect(result.success, true);
      expect(result.feedsLinked, 1);
      expect(result.feedsImported, 0);
      verifyNever(mockCatalogRepository.insert(any));
    });

    test('syncs read state from Nextcloud to local item', () async {
      final catalog = createNextcloudCatalog();
      const ncFeed = NextcloudNewsFeed(id: 1, url: 'https://f.com', title: 'F');
      const ncItem = NextcloudNewsItem(
        id: 100,
        guid: 'g',
        guidHash: 'h',
        title: 'T',
        feedId: 1,
        lastModified: 0,
        unread: false, // Read on Nextcloud
        starred: false,
      );
      final localItem = FeedItem(
        id: 'local-100',
        feedId: 'local-feed-1',
        title: 'T',
        isRead: false, // Unread locally
        isStarred: false,
        fetchedAt: DateTime.now(),
      );

      when(mockCatalogRepository.getById(catalog.id))
          .thenAnswer((_) async => catalog);
      when(mockCredentialStorage.getAppPassword(catalog.id))
          .thenAnswer((_) async => 'app-password');
      when(mockNewsService.checkAvailability(any, any)).thenAnswer(
        (_) async => const NewsAppAvailabilityResult(
          status: NewsAppStatus.available,
        ),
      );
      when(mockNewsService.getFeeds(any, any)).thenAnswer(
        (_) async => const NewsFedsResult(feeds: [ncFeed]),
      );
      when(mockMappingRepository.getLocalFeedId(catalog.id, ncFeed.id))
          .thenAnswer((_) async => 'local-feed-1');
      when(mockNewsService.getItems(
        any,
        any,
        type: anyNamed('type'),
        id: anyNamed('id'),
        getRead: anyNamed('getRead'),
        batchSize: anyNamed('batchSize'),
      )).thenAnswer((_) async => [ncItem]);
      when(mockMappingRepository.getLocalItemId(catalog.id, ncItem.id))
          .thenAnswer((_) async => localItem.id);
      when(mockFeedItemRepository.getById(localItem.id))
          .thenAnswer((_) async => localItem);
      when(mockFeedItemRepository.markAsRead(localItem.id))
          .thenAnswer((_) async => {});

      final result = await syncService.syncFromCatalog(catalog.id);

      expect(result.success, true);
      expect(result.itemsStateUpdated, 1);
      verify(mockFeedItemRepository.markAsRead(localItem.id)).called(1);
    });
  });

  group('updateNewsAvailability', () {
    test('returns unchanged catalog for non-Nextcloud', () async {
      final catalog = Catalog(
        id: 'opds-1',
        name: 'OPDS',
        url: 'https://example.com',
        type: CatalogType.opds,
        addedAt: DateTime.now(),
      );

      final result = await syncService.updateNewsAvailability(catalog);

      expect(result.id, catalog.id);
      verifyNever(mockNewsService.checkAvailability(any, any));
    });

    test('sets newsAppAvailable to false when credentials missing', () async {
      final catalog = createNextcloudCatalog();

      when(mockCredentialStorage.getAppPassword(catalog.id))
          .thenAnswer((_) async => null);

      final result = await syncService.updateNewsAvailability(catalog);

      expect(result.newsAppAvailable, false);
    });

    test('updates catalog with availability status', () async {
      final catalog = createNextcloudCatalog();

      when(mockCredentialStorage.getAppPassword(catalog.id))
          .thenAnswer((_) async => 'app-password');
      when(mockNewsService.checkAvailability(any, any)).thenAnswer(
        (_) async => const NewsAppAvailabilityResult(
          status: NewsAppStatus.available,
        ),
      );
      when(mockCatalogRepository.update(any)).thenAnswer((invocation) async {
        final catalog = invocation.positionalArguments[0] as Catalog;
        return catalog;
      });

      final result = await syncService.updateNewsAvailability(catalog);

      expect(result.newsAppAvailable, true);
      verify(mockCatalogRepository.update(any)).called(1);
    });
  });

  group('cleanupMappings', () {
    test('delegates to mapping repository', () async {
      when(mockMappingRepository.deleteMappingsForCatalog('catalog-1'))
          .thenAnswer((_) async => {});

      await syncService.cleanupMappings('catalog-1');

      verify(mockMappingRepository.deleteMappingsForCatalog('catalog-1'))
          .called(1);
    });
  });

  group('getSyncStats', () {
    test('returns counts from mapping repository', () async {
      when(mockMappingRepository.getFeedMappingCount('catalog-1'))
          .thenAnswer((_) async => 5);
      when(mockMappingRepository.getItemMappingCount('catalog-1'))
          .thenAnswer((_) async => 100);

      final stats = await syncService.getSyncStats('catalog-1');

      expect(stats.feedCount, 5);
      expect(stats.itemCount, 100);
    });
  });
}
