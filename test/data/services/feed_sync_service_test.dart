import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere/data/services/feed_sync_service.dart';
import 'package:readwhere/domain/entities/catalog.dart';
import 'package:readwhere/domain/entities/feed_item.dart';
import 'package:readwhere/domain/sync/feed_sync_protocol.dart';
import 'package:readwhere/domain/sync/progress_sync_protocol.dart';
import 'package:readwhere_rss/readwhere_rss.dart';

import '../../mocks/mock_repositories.mocks.dart';

void main() {
  group('FeedSyncService', () {
    late MockFeedItemRepository mockFeedItemRepository;
    late MockCatalogRepository mockCatalogRepository;
    late MockRssClient mockRssClient;
    late FeedSyncService service;

    final now = DateTime(2024, 6, 15, 10, 30);

    final rssCatalog = Catalog(
      id: 'feed-1',
      name: 'Test RSS Feed',
      url: 'https://example.com/feed.xml',
      type: CatalogType.rss,
      addedAt: now,
    );

    final opdsCatalog = Catalog(
      id: 'opds-1',
      name: 'Test OPDS',
      url: 'https://opds.example.com',
      type: CatalogType.opds,
      addedAt: now,
    );

    final testFeedItem1 = FeedItem(
      id: 'item-1',
      feedId: 'feed-1',
      title: 'Test Item 1',
      link: 'https://example.com/item1',
      pubDate: now,
      fetchedAt: now,
      isRead: false,
      isStarred: false,
    );

    final testFeedItem2 = FeedItem(
      id: 'item-2',
      feedId: 'feed-1',
      title: 'Test Item 2',
      link: 'https://example.com/item2',
      pubDate: now,
      fetchedAt: now,
      isRead: true,
      isStarred: true,
    );

    setUp(() {
      mockFeedItemRepository = MockFeedItemRepository();
      mockCatalogRepository = MockCatalogRepository();
      mockRssClient = MockRssClient();

      service = FeedSyncService(
        feedItemRepository: mockFeedItemRepository,
        catalogRepository: mockCatalogRepository,
        rssClient: mockRssClient,
      );
    });

    group('syncAllFeeds', () {
      test('syncs only RSS catalogs', () async {
        when(
          mockCatalogRepository.getAll(),
        ).thenAnswer((_) async => [rssCatalog, opdsCatalog]);
        when(
          mockFeedItemRepository.getByFeedId(any),
        ).thenAnswer((_) async => []);
        when(mockRssClient.fetchFeed(any)).thenAnswer(
          (_) async => RssFeed(
            id: 'feed-1',
            title: 'Test Feed',
            format: RssFeedFormat.rss2,
            items: [],
            feedUrl: 'https://example.com/feed.xml',
            link: 'https://example.com',
          ),
        );
        when(
          mockFeedItemRepository.upsertItems(any, any),
        ).thenAnswer((_) async {});
        when(
          mockFeedItemRepository.deleteOldItems(
            any,
            keepCount: anyNamed('keepCount'),
          ),
        ).thenAnswer((_) async => 0);

        final results = await service.syncAllFeeds();

        // Should only sync RSS catalog, not OPDS
        expect(results.length, equals(1));
        expect(results.first.feedId, equals('feed-1'));
        verify(
          mockRssClient.fetchFeed('https://example.com/feed.xml'),
        ).called(1);
      });

      test('returns empty list when no RSS feeds', () async {
        when(
          mockCatalogRepository.getAll(),
        ).thenAnswer((_) async => [opdsCatalog]);

        final results = await service.syncAllFeeds();

        expect(results, isEmpty);
        verifyNever(mockRssClient.fetchFeed(any));
      });
    });

    group('syncFeed', () {
      test('adds new items', () async {
        when(
          mockFeedItemRepository.getByFeedId('feed-1'),
        ).thenAnswer((_) async => []);

        final rssItem = RssItem(
          id: 'new-item-1',
          title: 'New Item',
          link: 'https://example.com/new',
          pubDate: now,
        );

        when(
          mockRssClient.fetchFeed('https://example.com/feed.xml'),
        ).thenAnswer(
          (_) async => RssFeed(
            id: 'feed-1',
            title: 'Test Feed',
            format: RssFeedFormat.rss2,
            items: [rssItem],
            feedUrl: 'https://example.com/feed.xml',
            link: 'https://example.com',
          ),
        );
        when(
          mockFeedItemRepository.upsertItems(any, any),
        ).thenAnswer((_) async {});
        when(
          mockFeedItemRepository.deleteOldItems(
            any,
            keepCount: anyNamed('keepCount'),
          ),
        ).thenAnswer((_) async => 0);

        final result = await service.syncFeed(
          feedId: 'feed-1',
          feedUrl: 'https://example.com/feed.xml',
        );

        expect(result.itemsAdded, equals(1));
        expect(result.itemsUpdated, equals(0));
        expect(result.hasErrors, isFalse);
        verify(mockFeedItemRepository.upsertItems('feed-1', any)).called(1);
      });

      test('updates existing items', () async {
        when(
          mockFeedItemRepository.getByFeedId('feed-1'),
        ).thenAnswer((_) async => [testFeedItem1]);

        final rssItem = RssItem(
          id: 'item-1', // Same ID as testFeedItem1
          title: 'Updated Title',
          link: 'https://example.com/item1',
          pubDate: now,
        );

        when(
          mockRssClient.fetchFeed('https://example.com/feed.xml'),
        ).thenAnswer(
          (_) async => RssFeed(
            id: 'feed-1',
            title: 'Test Feed',
            format: RssFeedFormat.rss2,
            items: [rssItem],
            feedUrl: 'https://example.com/feed.xml',
            link: 'https://example.com',
          ),
        );
        when(
          mockFeedItemRepository.upsertItems(any, any),
        ).thenAnswer((_) async {});
        when(
          mockFeedItemRepository.deleteOldItems(
            any,
            keepCount: anyNamed('keepCount'),
          ),
        ).thenAnswer((_) async => 0);

        final result = await service.syncFeed(
          feedId: 'feed-1',
          feedUrl: 'https://example.com/feed.xml',
        );

        expect(result.itemsAdded, equals(0));
        expect(result.itemsUpdated, equals(1));
        expect(result.hasErrors, isFalse);
      });

      test('cleans up old items', () async {
        when(
          mockFeedItemRepository.getByFeedId('feed-1'),
        ).thenAnswer((_) async => []);
        when(
          mockRssClient.fetchFeed('https://example.com/feed.xml'),
        ).thenAnswer(
          (_) async => RssFeed(
            id: 'feed-1',
            title: 'Test Feed',
            format: RssFeedFormat.rss2,
            items: [],
            feedUrl: 'https://example.com/feed.xml',
            link: 'https://example.com',
          ),
        );
        when(
          mockFeedItemRepository.upsertItems(any, any),
        ).thenAnswer((_) async {});
        when(
          mockFeedItemRepository.deleteOldItems(
            any,
            keepCount: anyNamed('keepCount'),
          ),
        ).thenAnswer((_) async => 5);

        await service.syncFeed(
          feedId: 'feed-1',
          feedUrl: 'https://example.com/feed.xml',
        );

        verify(
          mockFeedItemRepository.deleteOldItems(
            'feed-1',
            keepCount: FeedSyncService.maxItemsPerFeed,
          ),
        ).called(1);
      });

      test('returns error result on fetch failure', () async {
        when(
          mockFeedItemRepository.getByFeedId('feed-1'),
        ).thenAnswer((_) async => []);
        when(
          mockRssClient.fetchFeed('https://example.com/feed.xml'),
        ).thenThrow(Exception('Network error'));

        final result = await service.syncFeed(
          feedId: 'feed-1',
          feedUrl: 'https://example.com/feed.xml',
        );

        expect(result.hasErrors, isTrue);
        expect(result.errors.first.message, contains('Network error'));
        expect(result.itemsAdded, equals(0));
      });
    });

    group('mergeStarredState', () {
      test('stars items that are starred remotely but not locally', () async {
        final unstarredItem = FeedItem(
          id: 'item-1',
          feedId: 'feed-1',
          title: 'Test Item',
          link: 'https://example.com/item1',
          pubDate: now,
          fetchedAt: now,
          isRead: false,
          isStarred: false, // Not starred locally
        );

        when(
          mockFeedItemRepository.getByFeedId('feed-1'),
        ).thenAnswer((_) async => [unstarredItem]);
        when(
          mockFeedItemRepository.toggleStarred('item-1'),
        ).thenAnswer((_) async => unstarredItem.copyWith(isStarred: true));

        await service.mergeStarredState(
          feedId: 'feed-1',
          remoteStarredIds: ['item-1'], // Starred remotely
        );

        verify(mockFeedItemRepository.toggleStarred('item-1')).called(1);
      });

      test('keeps locally starred items starred', () async {
        final starredItem = FeedItem(
          id: 'item-1',
          feedId: 'feed-1',
          title: 'Test Item',
          link: 'https://example.com/item1',
          pubDate: now,
          fetchedAt: now,
          isRead: false,
          isStarred: true, // Already starred locally
        );

        when(
          mockFeedItemRepository.getByFeedId('feed-1'),
        ).thenAnswer((_) async => [starredItem]);

        await service.mergeStarredState(
          feedId: 'feed-1',
          remoteStarredIds: ['item-1'], // Also starred remotely
        );

        // Should not toggle since already starred
        verifyNever(mockFeedItemRepository.toggleStarred(any));
      });

      test('does not unstar locally starred items not in remote', () async {
        final starredItem = FeedItem(
          id: 'item-1',
          feedId: 'feed-1',
          title: 'Test Item',
          link: 'https://example.com/item1',
          pubDate: now,
          fetchedAt: now,
          isRead: false,
          isStarred: true, // Starred locally
        );

        when(
          mockFeedItemRepository.getByFeedId('feed-1'),
        ).thenAnswer((_) async => [starredItem]);

        await service.mergeStarredState(
          feedId: 'feed-1',
          remoteStarredIds: [], // Not starred remotely
        );

        // Should not toggle - union merge keeps local starred
        verifyNever(mockFeedItemRepository.toggleStarred(any));
      });
    });

    group('mergeReadState', () {
      test(
        'marks items as read that are read remotely but not locally',
        () async {
          final unreadItem = FeedItem(
            id: 'item-1',
            feedId: 'feed-1',
            title: 'Test Item',
            link: 'https://example.com/item1',
            pubDate: now,
            fetchedAt: now,
            isRead: false, // Not read locally
            isStarred: false,
          );

          when(
            mockFeedItemRepository.getByFeedId('feed-1'),
          ).thenAnswer((_) async => [unreadItem]);
          when(
            mockFeedItemRepository.markAsRead('item-1'),
          ).thenAnswer((_) async {});

          final count = await service.mergeReadState(
            feedId: 'feed-1',
            remoteReadIds: ['item-1'], // Read remotely
          );

          expect(count, equals(1));
          verify(mockFeedItemRepository.markAsRead('item-1')).called(1);
        },
      );

      test('does not mark already-read items', () async {
        final readItem = FeedItem(
          id: 'item-1',
          feedId: 'feed-1',
          title: 'Test Item',
          link: 'https://example.com/item1',
          pubDate: now,
          fetchedAt: now,
          isRead: true, // Already read locally
          isStarred: false,
        );

        when(
          mockFeedItemRepository.getByFeedId('feed-1'),
        ).thenAnswer((_) async => [readItem]);

        final count = await service.mergeReadState(
          feedId: 'feed-1',
          remoteReadIds: ['item-1'],
        );

        expect(count, equals(0));
        verifyNever(mockFeedItemRepository.markAsRead(any));
      });
    });

    group('getLocalStarredIds', () {
      test('returns only starred items from specified feed', () async {
        final starredItem1 = testFeedItem2; // isStarred: true, feedId: 'feed-1'
        final starredItem2 = FeedItem(
          id: 'other-item',
          feedId: 'feed-2', // Different feed
          title: 'Other Item',
          link: 'https://example.com/other',
          pubDate: now,
          fetchedAt: now,
          isRead: false,
          isStarred: true,
        );

        when(
          mockFeedItemRepository.getStarredItems(),
        ).thenAnswer((_) async => [starredItem1, starredItem2]);

        final ids = await service.getLocalStarredIds('feed-1');

        expect(ids, equals(['item-2']));
        expect(ids.length, equals(1));
      });
    });

    group('getLocalReadIds', () {
      test('returns only read items from specified feed', () async {
        when(
          mockFeedItemRepository.getByFeedId('feed-1'),
        ).thenAnswer((_) async => [testFeedItem1, testFeedItem2]);

        final ids = await service.getLocalReadIds('feed-1');

        // testFeedItem1 is unread, testFeedItem2 is read
        expect(ids, equals(['item-2']));
      });
    });

    group('needsSync', () {
      test('returns true when no items exist', () async {
        when(
          mockFeedItemRepository.getByFeedId('feed-1'),
        ).thenAnswer((_) async => []);

        final needsSync = await service.needsSync('feed-1');

        expect(needsSync, isTrue);
      });

      test('returns true when last fetch is older than threshold', () async {
        final oldItem = FeedItem(
          id: 'old-item',
          feedId: 'feed-1',
          title: 'Old Item',
          link: 'https://example.com/old',
          pubDate: now.subtract(const Duration(days: 1)),
          fetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: false,
          isStarred: false,
        );

        when(
          mockFeedItemRepository.getByFeedId('feed-1'),
        ).thenAnswer((_) async => [oldItem]);

        final needsSync = await service.needsSync(
          'feed-1',
          threshold: const Duration(hours: 1),
        );

        expect(needsSync, isTrue);
      });

      test('returns false when last fetch is within threshold', () async {
        final recentItem = FeedItem(
          id: 'recent-item',
          feedId: 'feed-1',
          title: 'Recent Item',
          link: 'https://example.com/recent',
          pubDate: now,
          fetchedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          isRead: false,
          isStarred: false,
        );

        when(
          mockFeedItemRepository.getByFeedId('feed-1'),
        ).thenAnswer((_) async => [recentItem]);

        final needsSync = await service.needsSync(
          'feed-1',
          threshold: const Duration(hours: 1),
        );

        expect(needsSync, isFalse);
      });
    });
  });

  group('FeedSyncResult', () {
    test('hasErrors returns true when errors exist', () {
      final result = FeedSyncResult(
        feedId: 'feed-1',
        itemsAdded: 0,
        itemsUpdated: 0,
        starredMerged: 0,
        readStateMerged: 0,
        errors: const [
          SyncError(recordId: 'feed-1', operation: 'sync', message: 'Error'),
        ],
        syncedAt: DateTime.now(),
      );

      expect(result.hasErrors, isTrue);
      expect(result.isSuccessful, isFalse);
    });

    test('isSuccessful returns true when no errors', () {
      final result = FeedSyncResult(
        feedId: 'feed-1',
        itemsAdded: 5,
        itemsUpdated: 3,
        starredMerged: 2,
        readStateMerged: 1,
        errors: const [],
        syncedAt: DateTime.now(),
      );

      expect(result.isSuccessful, isTrue);
      expect(result.hasErrors, isFalse);
    });

    test('toString returns formatted string', () {
      final result = FeedSyncResult(
        feedId: 'feed-1',
        itemsAdded: 5,
        itemsUpdated: 3,
        starredMerged: 2,
        readStateMerged: 1,
        errors: const [],
        syncedAt: DateTime.now(),
      );

      final str = result.toString();
      expect(str, contains('feed-1'));
      expect(str, contains('+5'));
      expect(str, contains('~3'));
    });
  });
}
