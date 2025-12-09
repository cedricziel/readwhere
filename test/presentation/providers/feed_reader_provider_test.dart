import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere/domain/entities/feed_item.dart';
import 'package:readwhere/presentation/providers/feed_reader_provider.dart';
import 'package:readwhere_rss/readwhere_rss.dart';

import '../../mocks/mock_repositories.mocks.dart';

void main() {
  group('FeedReaderProvider', () {
    late MockFeedItemRepository mockRepository;
    late MockRssClient mockRssClient;
    late MockArticleScraperService mockScraperService;
    late FeedReaderProvider provider;

    final testFetchedAt = DateTime(2024, 1, 15, 10, 30);

    final testItem1 = FeedItem(
      id: 'item-1',
      feedId: 'feed-1',
      title: 'Article One',
      content: '<p>Content of article one</p>',
      description: 'Summary of article one',
      link: 'https://example.com/article-1',
      author: 'Author A',
      pubDate: DateTime(2024, 1, 14, 12, 0),
      thumbnailUrl: 'https://example.com/thumb1.jpg',
      isRead: false,
      isStarred: false,
      fetchedAt: testFetchedAt,
    );

    final testItem2 = FeedItem(
      id: 'item-2',
      feedId: 'feed-1',
      title: 'Article Two',
      content: '<p>Content of article two</p>',
      description: 'Summary of article two',
      link: 'https://example.com/article-2',
      author: 'Author B',
      pubDate: DateTime(2024, 1, 13, 12, 0),
      isRead: true,
      isStarred: true,
      fetchedAt: testFetchedAt,
    );

    final testItems = [testItem1, testItem2];

    setUp(() {
      mockRepository = MockFeedItemRepository();
      mockRssClient = MockRssClient();
      mockScraperService = MockArticleScraperService();
      provider = FeedReaderProvider(
        feedItemRepository: mockRepository,
        rssClient: mockRssClient,
        articleScraperService: mockScraperService,
      );
    });

    group('initial state', () {
      test('has no error', () {
        expect(provider.error, isNull);
        expect(provider.hasError, isFalse);
      });

      test('is not loading', () {
        expect(provider.isLoading, isFalse);
      });

      test('returns empty items for unknown feed', () {
        expect(provider.getItems('unknown-feed'), isEmpty);
      });

      test('returns zero unread count for unknown feed', () {
        expect(provider.getUnreadCount('unknown-feed'), equals(0));
      });

      test('has zero total unread count', () {
        expect(provider.totalUnreadCount, equals(0));
      });

      test('returns empty unread counts map', () {
        expect(provider.allUnreadCounts, isEmpty);
      });
    });

    group('loadFeedItems', () {
      test('loads items from repository successfully', () async {
        when(
          mockRepository.getByFeedId('feed-1', unreadOnly: false),
        ).thenAnswer((_) async => testItems);
        when(
          mockRepository.getUnreadCount('feed-1'),
        ).thenAnswer((_) async => 1);

        await provider.loadFeedItems('feed-1');

        expect(provider.getItems('feed-1'), equals(testItems));
        expect(provider.getUnreadCount('feed-1'), equals(1));
        expect(provider.hasError, isFalse);
        verify(
          mockRepository.getByFeedId('feed-1', unreadOnly: false),
        ).called(1);
      });

      test('can filter to unread only', () async {
        final unreadItems = [testItem1];
        when(
          mockRepository.getByFeedId('feed-1', unreadOnly: true),
        ).thenAnswer((_) async => unreadItems);
        when(
          mockRepository.getUnreadCount('feed-1'),
        ).thenAnswer((_) async => 1);

        await provider.loadFeedItems('feed-1', unreadOnly: true);

        expect(provider.getItems('feed-1'), equals(unreadItems));
        verify(
          mockRepository.getByFeedId('feed-1', unreadOnly: true),
        ).called(1);
      });

      test('sets error state on failure', () async {
        when(
          mockRepository.getByFeedId('feed-1', unreadOnly: false),
        ).thenThrow(Exception('Database error'));

        await provider.loadFeedItems('feed-1');

        expect(provider.hasError, isTrue);
        expect(provider.error, contains('Failed to load feed items'));
      });

      test('indicates loading state during operation', () async {
        when(
          mockRepository.getByFeedId('feed-1', unreadOnly: false),
        ).thenAnswer((_) async {
          // Verify loading state during execution
          expect(provider.isFeedLoading('feed-1'), isTrue);
          return testItems;
        });
        when(
          mockRepository.getUnreadCount('feed-1'),
        ).thenAnswer((_) async => 1);

        expect(provider.isFeedLoading('feed-1'), isFalse);
        await provider.loadFeedItems('feed-1');
        expect(provider.isFeedLoading('feed-1'), isFalse);
      });
    });

    group('refreshFeed', () {
      test('fetches from network and updates database', () async {
        final rssFeed = RssFeed(
          id: 'feed-1',
          title: 'Test Feed',
          link: 'https://example.com/feed',
          format: RssFeedFormat.rss2,
          feedUrl: 'https://example.com/feed',
          items: [
            RssItem(
              id: 'new-item',
              title: 'New Article',
              content: 'New content',
              link: 'https://example.com/new',
            ),
          ],
        );

        when(
          mockRssClient.fetchFeed('https://example.com/feed'),
        ).thenAnswer((_) async => rssFeed);
        when(mockRepository.upsertItems(any, any)).thenAnswer((_) async {});
        when(
          mockRepository.deleteOldItems('feed-1', keepCount: 100),
        ).thenAnswer((_) async {});
        when(
          mockRepository.getByFeedId('feed-1'),
        ).thenAnswer((_) async => testItems);
        when(
          mockRepository.getUnreadCount('feed-1'),
        ).thenAnswer((_) async => 2);

        await provider.refreshFeed('feed-1', 'https://example.com/feed');

        verify(mockRssClient.fetchFeed('https://example.com/feed')).called(1);
        verify(mockRepository.upsertItems('feed-1', any)).called(1);
        verify(
          mockRepository.deleteOldItems('feed-1', keepCount: 100),
        ).called(1);
        expect(provider.getItems('feed-1'), equals(testItems));
        expect(provider.getUnreadCount('feed-1'), equals(2));
      });

      test('sets error state on network failure', () async {
        when(
          mockRssClient.fetchFeed(any),
        ).thenThrow(Exception('Network error'));

        await provider.refreshFeed('feed-1', 'https://example.com/feed');

        expect(provider.hasError, isTrue);
        expect(provider.error, contains('Failed to refresh feed'));
      });
    });

    group('loadAllUnreadCounts', () {
      test('loads unread counts for all feeds', () async {
        final counts = {'feed-1': 5, 'feed-2': 3, 'feed-3': 0};
        when(
          mockRepository.getAllUnreadCounts(),
        ).thenAnswer((_) async => counts);

        await provider.loadAllUnreadCounts();

        expect(provider.getUnreadCount('feed-1'), equals(5));
        expect(provider.getUnreadCount('feed-2'), equals(3));
        expect(provider.getUnreadCount('feed-3'), equals(0));
        expect(provider.totalUnreadCount, equals(8));
      });
    });

    group('markAsRead', () {
      test(
        'marks item as read in repository and updates local state',
        () async {
          when(
            mockRepository.getByFeedId('feed-1', unreadOnly: false),
          ).thenAnswer((_) async => [testItem1]);
          when(
            mockRepository.getUnreadCount('feed-1'),
          ).thenAnswer((_) async => 1);
          when(mockRepository.markAsRead('item-1')).thenAnswer((_) async {});

          await provider.loadFeedItems('feed-1');
          await provider.markAsRead('item-1');

          verify(mockRepository.markAsRead('item-1')).called(1);
          expect(provider.getItems('feed-1').first.isRead, isTrue);
          expect(provider.getUnreadCount('feed-1'), equals(0));
        },
      );

      test('does not decrement count if item was already read', () async {
        when(
          mockRepository.getByFeedId('feed-1', unreadOnly: false),
        ).thenAnswer((_) async => [testItem2]); // testItem2 is already read
        when(
          mockRepository.getUnreadCount('feed-1'),
        ).thenAnswer((_) async => 0);
        when(mockRepository.markAsRead('item-2')).thenAnswer((_) async {});

        await provider.loadFeedItems('feed-1');
        await provider.markAsRead('item-2');

        expect(provider.getUnreadCount('feed-1'), equals(0));
      });
    });

    group('markAsUnread', () {
      test(
        'marks item as unread in repository and updates local state',
        () async {
          when(
            mockRepository.getByFeedId('feed-1', unreadOnly: false),
          ).thenAnswer((_) async => [testItem2]); // testItem2 is read
          when(
            mockRepository.getUnreadCount('feed-1'),
          ).thenAnswer((_) async => 0);
          when(mockRepository.markAsUnread('item-2')).thenAnswer((_) async {});

          await provider.loadFeedItems('feed-1');
          await provider.markAsUnread('item-2');

          verify(mockRepository.markAsUnread('item-2')).called(1);
          expect(provider.getItems('feed-1').first.isRead, isFalse);
          expect(provider.getUnreadCount('feed-1'), equals(1));
        },
      );
    });

    group('markAllAsRead', () {
      test('marks all items in feed as read', () async {
        when(
          mockRepository.getByFeedId('feed-1', unreadOnly: false),
        ).thenAnswer((_) async => testItems);
        when(
          mockRepository.getUnreadCount('feed-1'),
        ).thenAnswer((_) async => 1);
        when(mockRepository.markAllAsRead('feed-1')).thenAnswer((_) async {});

        await provider.loadFeedItems('feed-1');
        await provider.markAllAsRead('feed-1');

        verify(mockRepository.markAllAsRead('feed-1')).called(1);
        expect(
          provider.getItems('feed-1').every((item) => item.isRead),
          isTrue,
        );
        expect(provider.getUnreadCount('feed-1'), equals(0));
      });
    });

    group('toggleStarred', () {
      test(
        'toggles starred state in repository and updates local state',
        () async {
          when(
            mockRepository.getByFeedId('feed-1', unreadOnly: false),
          ).thenAnswer((_) async => [testItem1]); // testItem1 is not starred
          when(
            mockRepository.getUnreadCount('feed-1'),
          ).thenAnswer((_) async => 1);
          when(mockRepository.toggleStarred('item-1')).thenAnswer((_) async {});

          await provider.loadFeedItems('feed-1');
          expect(provider.getItems('feed-1').first.isStarred, isFalse);

          await provider.toggleStarred('item-1');

          verify(mockRepository.toggleStarred('item-1')).called(1);
          expect(provider.getItems('feed-1').first.isStarred, isTrue);

          // Toggle back
          await provider.toggleStarred('item-1');
          expect(provider.getItems('feed-1').first.isStarred, isFalse);
        },
      );
    });

    group('getItem', () {
      test('returns item from local cache if available', () async {
        when(
          mockRepository.getByFeedId('feed-1', unreadOnly: false),
        ).thenAnswer((_) async => testItems);
        when(
          mockRepository.getUnreadCount('feed-1'),
        ).thenAnswer((_) async => 1);

        await provider.loadFeedItems('feed-1');

        final item = await provider.getItem('item-1');

        expect(item, equals(testItem1));
        verifyNever(mockRepository.getById(any));
      });

      test('falls back to repository if not in cache', () async {
        when(
          mockRepository.getById('item-1'),
        ).thenAnswer((_) async => testItem1);

        final item = await provider.getItem('item-1');

        expect(item, equals(testItem1));
        verify(mockRepository.getById('item-1')).called(1);
      });

      test('returns null if item does not exist', () async {
        when(
          mockRepository.getById('nonexistent'),
        ).thenAnswer((_) async => null);

        final item = await provider.getItem('nonexistent');

        expect(item, isNull);
      });
    });

    group('getStarredItems', () {
      test('returns starred items from repository', () async {
        final starredItems = [testItem2];
        when(
          mockRepository.getStarredItems(),
        ).thenAnswer((_) async => starredItems);

        final items = await provider.getStarredItems();

        expect(items, equals(starredItems));
        verify(mockRepository.getStarredItems()).called(1);
      });
    });

    group('deleteItemsForFeed', () {
      test('deletes items and clears local state', () async {
        when(
          mockRepository.getByFeedId('feed-1', unreadOnly: false),
        ).thenAnswer((_) async => testItems);
        when(
          mockRepository.getUnreadCount('feed-1'),
        ).thenAnswer((_) async => 1);
        when(mockRepository.deleteByFeedId('feed-1')).thenAnswer((_) async {});

        await provider.loadFeedItems('feed-1');
        expect(provider.getItems('feed-1'), isNotEmpty);

        await provider.deleteItemsForFeed('feed-1');

        verify(mockRepository.deleteByFeedId('feed-1')).called(1);
        expect(provider.getItems('feed-1'), isEmpty);
        expect(provider.getUnreadCount('feed-1'), equals(0));
      });
    });

    group('clearError', () {
      test('clears error state', () async {
        when(
          mockRepository.getByFeedId('feed-1', unreadOnly: false),
        ).thenThrow(Exception('Error'));

        await provider.loadFeedItems('feed-1');
        expect(provider.hasError, isTrue);

        provider.clearError();

        expect(provider.hasError, isFalse);
        expect(provider.error, isNull);
      });
    });

    group('notifyListeners', () {
      test('notifies listeners on state changes', () async {
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);

        when(
          mockRepository.getByFeedId('feed-1', unreadOnly: false),
        ).thenAnswer((_) async => testItems);
        when(
          mockRepository.getUnreadCount('feed-1'),
        ).thenAnswer((_) async => 1);

        await provider.loadFeedItems('feed-1');

        // Should notify at least twice: when loading starts and when it ends
        expect(notificationCount, greaterThanOrEqualTo(2));
      });
    });
  });
}
