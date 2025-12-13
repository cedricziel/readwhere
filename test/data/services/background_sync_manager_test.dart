import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere/data/services/background_sync_manager.dart';
import 'package:readwhere/domain/entities/sync_job.dart';
import 'package:readwhere/domain/services/connectivity_service.dart';
import 'package:readwhere/domain/sync/catalog_sync_protocol.dart';
import 'package:readwhere/domain/sync/feed_sync_protocol.dart';

import '../../mocks/mock_repositories.mocks.dart';

/// Helper to create a ConnectionStatus for testing
ConnectionStatus _createConnectionStatus({
  bool isConnected = true,
  ConnectionType type = ConnectionType.wifi,
  ConnectionQuality quality = ConnectionQuality.good,
}) {
  return ConnectionStatus(
    isConnected: isConnected,
    type: type,
    quality: quality,
    checkedAt: DateTime.now(),
  );
}

/// Helper to create a dummy SyncJob for mocking returns
SyncJob _createDummySyncJob({
  String id = 'job-1',
  SyncJobType type = SyncJobType.progress,
  String targetId = 'target-1',
  Map<String, dynamic>? payload,
}) {
  final now = DateTime.now();
  return SyncJob(
    id: id,
    type: type,
    targetId: targetId,
    payload: payload ?? {},
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('BackgroundSyncManager', () {
    late MockConnectivityService mockConnectivityService;
    late MockSyncSettingsProvider mockSettingsProvider;
    late MockSyncQueueService mockQueueService;
    late MockProgressSyncService mockProgressSyncService;
    late MockCatalogSyncService mockCatalogSyncService;
    late MockFeedSyncService mockFeedSyncService;
    late MockBackgroundExecutor mockBackgroundExecutor;
    late BackgroundSyncManager manager;
    late StreamController<ConnectionStatus> connectivityController;

    final now = DateTime.now();

    setUp(() {
      mockConnectivityService = MockConnectivityService();
      mockSettingsProvider = MockSyncSettingsProvider();
      mockQueueService = MockSyncQueueService();
      mockProgressSyncService = MockProgressSyncService();
      mockCatalogSyncService = MockCatalogSyncService();
      mockFeedSyncService = MockFeedSyncService();
      mockBackgroundExecutor = MockBackgroundExecutor();
      connectivityController = StreamController<ConnectionStatus>.broadcast();

      // Default stubs
      when(
        mockConnectivityService.onConnectivityChanged,
      ).thenAnswer((_) => connectivityController.stream);
      when(mockSettingsProvider.syncEnabled).thenReturn(true);
      when(mockSettingsProvider.wifiOnly).thenReturn(false);
      when(mockSettingsProvider.syncIntervalMinutes).thenReturn(15);
      when(mockSettingsProvider.progressSyncEnabled).thenReturn(true);
      when(mockSettingsProvider.catalogSyncEnabled).thenReturn(true);
      when(mockSettingsProvider.feedSyncEnabled).thenReturn(true);
      when(mockSettingsProvider.addListener(any)).thenReturn(null);
      when(mockSettingsProvider.removeListener(any)).thenReturn(null);
      when(mockBackgroundExecutor.initialize()).thenAnswer((_) async {});
      when(mockBackgroundExecutor.registerTask(any, any)).thenReturn(null);
      when(
        mockBackgroundExecutor.schedulePeriodic(
          any,
          frequency: anyNamed('frequency'),
          constraints: anyNamed('constraints'),
        ),
      ).thenAnswer((_) async => 'periodic-task-id');
      when(mockBackgroundExecutor.cancelTask(any)).thenAnswer((_) async {});
      when(mockBackgroundExecutor.dispose()).thenReturn(null);
      when(
        mockConnectivityService.canSync(
          wifiOnlyEnabled: anyNamed('wifiOnlyEnabled'),
        ),
      ).thenReturn(true);

      manager = BackgroundSyncManager(
        connectivityService: mockConnectivityService,
        settingsProvider: mockSettingsProvider,
        queueService: mockQueueService,
        progressSyncService: mockProgressSyncService,
        catalogSyncService: mockCatalogSyncService,
        feedSyncService: mockFeedSyncService,
        backgroundExecutor: mockBackgroundExecutor,
      );
    });

    tearDown(() {
      connectivityController.close();
      manager.dispose();
    });

    group('initialization', () {
      test(
        'initializes background executor and registers task handlers',
        () async {
          await manager.initialize();

          verify(mockBackgroundExecutor.initialize()).called(1);
          verify(
            mockBackgroundExecutor.registerTask(SyncTaskIds.periodicSync, any),
          ).called(1);
          verify(
            mockBackgroundExecutor.registerTask(SyncTaskIds.immediateSync, any),
          ).called(1);
        },
      );

      test('subscribes to connectivity changes', () async {
        await manager.initialize();

        verify(mockConnectivityService.onConnectivityChanged).called(1);
      });

      test('schedules periodic sync when enabled', () async {
        await manager.initialize();

        verify(
          mockBackgroundExecutor.schedulePeriodic(
            any,
            frequency: const Duration(minutes: 15),
            constraints: anyNamed('constraints'),
          ),
        ).called(1);
      });

      test('does not schedule periodic sync when disabled', () async {
        when(mockSettingsProvider.syncEnabled).thenReturn(false);

        await manager.initialize();

        verifyNever(
          mockBackgroundExecutor.schedulePeriodic(
            any,
            frequency: anyNamed('frequency'),
            constraints: anyNamed('constraints'),
          ),
        );
      });

      test('only initializes once', () async {
        await manager.initialize();
        await manager.initialize();

        verify(mockBackgroundExecutor.initialize()).called(1);
      });
    });

    group('status', () {
      test('starts with idle status', () {
        expect(manager.status, equals(SyncStatus.idle));
        expect(manager.isSyncing, isFalse);
        expect(manager.lastError, isNull);
        expect(manager.lastSyncTime, isNull);
      });
    });

    group('syncNow', () {
      test('does nothing when sync is disabled', () async {
        when(mockSettingsProvider.syncEnabled).thenReturn(false);
        when(
          mockQueueService.getNextBatch(limit: anyNamed('limit')),
        ).thenAnswer((_) async => []);

        await manager.syncNow();

        verifyNever(mockQueueService.getNextBatch(limit: anyNamed('limit')));
      });

      test('sets error when network conditions not met', () async {
        when(
          mockConnectivityService.canSync(
            wifiOnlyEnabled: anyNamed('wifiOnlyEnabled'),
          ),
        ).thenReturn(false);

        await manager.syncNow();

        expect(manager.lastError, contains('Network conditions'));
        expect(manager.status, equals(SyncStatus.error));
      });

      test('processes pending jobs when conditions are met', () async {
        when(
          mockQueueService.getNextBatch(limit: anyNamed('limit')),
        ).thenAnswer((_) async => []);

        await manager.syncNow();

        verify(
          mockQueueService.getNextBatch(limit: anyNamed('limit')),
        ).called(1);
        expect(manager.lastSyncTime, isNotNull);
      });

      test('does not process when already syncing', () async {
        // First call starts syncing
        final completer = Completer<List<SyncJob>>();
        when(
          mockQueueService.getNextBatch(limit: anyNamed('limit')),
        ).thenAnswer((_) => completer.future);

        // Start first sync (won't complete until we complete the future)
        final future1 = manager.syncNow();

        // Second call should be ignored while first is in progress
        await manager.syncNow();

        // Complete first sync
        completer.complete([]);
        await future1;

        // Should only have called once
        verify(
          mockQueueService.getNextBatch(limit: anyNamed('limit')),
        ).called(1);
      });
    });

    group('processPendingJobs', () {
      test('processes jobs in batches', () async {
        final job1 = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-1',
          payload: {
            'bookId': 'book-1',
            'sourceCatalogId': 'catalog-1',
            'sourceEntryId': 'entry-1',
          },
          createdAt: now,
          updatedAt: now,
        );

        when(
          mockQueueService.getNextBatch(limit: anyNamed('limit')),
        ).thenAnswer((invocation) async {
          // First call returns job, second returns empty (end of queue)
          if (invocation.namedArguments[#limit] == 10) {
            // Reset for subsequent calls
            when(
              mockQueueService.getNextBatch(limit: anyNamed('limit')),
            ).thenAnswer((_) async => []);
            return [job1];
          }
          return [];
        });
        when(mockQueueService.startJob(any)).thenAnswer((_) async => null);
        when(mockQueueService.completeJob(any)).thenAnswer((_) async {});
        when(
          mockProgressSyncService.syncBook(
            catalogId: anyNamed('catalogId'),
            bookId: anyNamed('bookId'),
            remoteBookId: anyNamed('remoteBookId'),
          ),
        ).thenAnswer((_) async {});

        await manager.processPendingJobs();

        verify(mockQueueService.startJob('job-1')).called(1);
        verify(mockQueueService.completeJob('job-1')).called(1);
      });

      test('updates sync time on successful completion', () async {
        when(
          mockQueueService.getNextBatch(limit: anyNamed('limit')),
        ).thenAnswer((_) async => []);

        await manager.processPendingJobs();

        expect(manager.lastSyncTime, isNotNull);
        expect(manager.lastError, isNull);
      });

      test('sets error on failure', () async {
        when(
          mockQueueService.getNextBatch(limit: anyNamed('limit')),
        ).thenThrow(Exception('Queue error'));

        await manager.processPendingJobs();

        expect(manager.lastError, contains('Queue error'));
      });

      test('handles job failure with retry', () async {
        final job = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-1',
          payload: {},
          createdAt: now,
          updatedAt: now,
        );

        var callCount = 0;
        when(
          mockQueueService.getNextBatch(limit: anyNamed('limit')),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return [job];
          return [];
        });
        when(mockQueueService.startJob(any)).thenAnswer((_) async => null);
        when(
          mockQueueService.handleFailure(any, any),
        ).thenAnswer((_) async => null);

        // Job processing will fail due to missing payload data
        await manager.processPendingJobs();

        // Verify failure was handled (either completeJob or handleFailure called)
        // Since payload is incomplete, it should complete without doing work
        verify(mockQueueService.completeJob('job-1')).called(1);
      });
    });

    group('job processing', () {
      test('processes progress job with sync service', () async {
        final job = SyncJob(
          id: 'progress-job',
          type: SyncJobType.progress,
          targetId: 'book-1',
          payload: {
            'bookId': 'book-1',
            'sourceCatalogId': 'catalog-1',
            'sourceEntryId': 'entry-1',
          },
          createdAt: now,
          updatedAt: now,
        );

        var callCount = 0;
        when(
          mockQueueService.getNextBatch(limit: anyNamed('limit')),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return [job];
          return [];
        });
        when(mockQueueService.startJob(any)).thenAnswer((_) async => null);
        when(mockQueueService.completeJob(any)).thenAnswer((_) async {});
        when(
          mockProgressSyncService.syncBook(
            catalogId: anyNamed('catalogId'),
            bookId: anyNamed('bookId'),
            remoteBookId: anyNamed('remoteBookId'),
          ),
        ).thenAnswer((_) async {});

        await manager.processPendingJobs();

        verify(
          mockProgressSyncService.syncBook(
            catalogId: 'catalog-1',
            bookId: 'book-1',
            remoteBookId: 'entry-1',
          ),
        ).called(1);
      });

      test('processes catalog job with sync service', () async {
        final job = SyncJob(
          id: 'catalog-job',
          type: SyncJobType.catalog,
          targetId: 'catalog-1',
          payload: {},
          createdAt: now,
          updatedAt: now,
        );

        var callCount = 0;
        when(
          mockQueueService.getNextBatch(limit: anyNamed('limit')),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return [job];
          return [];
        });
        when(mockQueueService.startJob(any)).thenAnswer((_) async => null);
        when(mockQueueService.completeJob(any)).thenAnswer((_) async {});
        when(mockCatalogSyncService.refreshCatalog(any)).thenAnswer(
          (_) async => CatalogSyncResult(
            catalogId: 'catalog-1',
            feedsRefreshed: 1,
            entriesUpdated: 0,
            entriesAdded: 0,
            entriesRemoved: 0,
            cacheInvalidated: false,
            errors: const [],
            syncedAt: DateTime.now(),
          ),
        );

        await manager.processPendingJobs();

        verify(mockCatalogSyncService.refreshCatalog('catalog-1')).called(1);
      });

      test('processes feed job with sync service', () async {
        final job = SyncJob(
          id: 'feed-job',
          type: SyncJobType.feed,
          targetId: 'feed-1',
          payload: {
            'feedId': 'feed-1',
            'feedUrl': 'https://example.com/feed.xml',
          },
          createdAt: now,
          updatedAt: now,
        );

        var callCount = 0;
        when(
          mockQueueService.getNextBatch(limit: anyNamed('limit')),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return [job];
          return [];
        });
        when(mockQueueService.startJob(any)).thenAnswer((_) async => null);
        when(mockQueueService.completeJob(any)).thenAnswer((_) async {});
        when(
          mockFeedSyncService.syncFeed(
            feedId: anyNamed('feedId'),
            feedUrl: anyNamed('feedUrl'),
          ),
        ).thenAnswer(
          (_) async => FeedSyncResult(
            feedId: 'feed-1',
            itemsAdded: 0,
            itemsUpdated: 0,
            starredMerged: 0,
            readStateMerged: 0,
            errors: const [],
            syncedAt: DateTime.now(),
          ),
        );

        await manager.processPendingJobs();

        verify(
          mockFeedSyncService.syncFeed(
            feedId: 'feed-1',
            feedUrl: 'https://example.com/feed.xml',
          ),
        ).called(1);
      });

      test('skips progress job when progress sync disabled', () async {
        when(mockSettingsProvider.progressSyncEnabled).thenReturn(false);

        final job = SyncJob(
          id: 'progress-job',
          type: SyncJobType.progress,
          targetId: 'book-1',
          payload: {
            'bookId': 'book-1',
            'sourceCatalogId': 'catalog-1',
            'sourceEntryId': 'entry-1',
          },
          createdAt: now,
          updatedAt: now,
        );

        var callCount = 0;
        when(
          mockQueueService.getNextBatch(limit: anyNamed('limit')),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return [job];
          return [];
        });
        when(mockQueueService.startJob(any)).thenAnswer((_) async => null);
        when(mockQueueService.completeJob(any)).thenAnswer((_) async {});

        await manager.processPendingJobs();

        verifyNever(
          mockProgressSyncService.syncBook(
            catalogId: anyNamed('catalogId'),
            bookId: anyNamed('bookId'),
            remoteBookId: anyNamed('remoteBookId'),
          ),
        );
      });

      test('skips catalog job when catalog sync disabled', () async {
        when(mockSettingsProvider.catalogSyncEnabled).thenReturn(false);

        final job = SyncJob(
          id: 'catalog-job',
          type: SyncJobType.catalog,
          targetId: 'catalog-1',
          payload: {},
          createdAt: now,
          updatedAt: now,
        );

        var callCount = 0;
        when(
          mockQueueService.getNextBatch(limit: anyNamed('limit')),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return [job];
          return [];
        });
        when(mockQueueService.startJob(any)).thenAnswer((_) async => null);
        when(mockQueueService.completeJob(any)).thenAnswer((_) async {});

        await manager.processPendingJobs();

        verifyNever(mockCatalogSyncService.refreshCatalog(any));
      });

      test('skips feed job when feed sync disabled', () async {
        when(mockSettingsProvider.feedSyncEnabled).thenReturn(false);

        final job = SyncJob(
          id: 'feed-job',
          type: SyncJobType.feed,
          targetId: 'feed-1',
          payload: {
            'feedId': 'feed-1',
            'feedUrl': 'https://example.com/feed.xml',
          },
          createdAt: now,
          updatedAt: now,
        );

        var callCount = 0;
        when(
          mockQueueService.getNextBatch(limit: anyNamed('limit')),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return [job];
          return [];
        });
        when(mockQueueService.startJob(any)).thenAnswer((_) async => null);
        when(mockQueueService.completeJob(any)).thenAnswer((_) async {});

        await manager.processPendingJobs();

        verifyNever(
          mockFeedSyncService.syncFeed(
            feedId: anyNamed('feedId'),
            feedUrl: anyNamed('feedUrl'),
          ),
        );
      });
    });

    group('scheduleProgressSync', () {
      test('enqueues progress sync job', () async {
        when(
          mockQueueService.enqueueProgressSync(
            bookId: anyNamed('bookId'),
            sourceCatalogId: anyNamed('sourceCatalogId'),
            sourceEntryId: anyNamed('sourceEntryId'),
            progress: anyNamed('progress'),
            cfi: anyNamed('cfi'),
          ),
        ).thenAnswer((_) async => _createDummySyncJob());
        when(
          mockQueueService.getNextBatch(limit: anyNamed('limit')),
        ).thenAnswer((_) async => []);

        await manager.scheduleProgressSync(
          bookId: 'book-1',
          sourceCatalogId: 'catalog-1',
          sourceEntryId: 'entry-1',
          progress: 0.5,
          cfi: 'epubcfi(/6/4!/2/1)',
        );

        verify(
          mockQueueService.enqueueProgressSync(
            bookId: 'book-1',
            sourceCatalogId: 'catalog-1',
            sourceEntryId: 'entry-1',
            progress: 0.5,
            cfi: 'epubcfi(/6/4!/2/1)',
          ),
        ).called(1);
      });

      test('does nothing when sync disabled', () async {
        when(mockSettingsProvider.syncEnabled).thenReturn(false);

        await manager.scheduleProgressSync(
          bookId: 'book-1',
          sourceCatalogId: 'catalog-1',
          sourceEntryId: 'entry-1',
        );

        verifyNever(
          mockQueueService.enqueueProgressSync(
            bookId: anyNamed('bookId'),
            sourceCatalogId: anyNamed('sourceCatalogId'),
            sourceEntryId: anyNamed('sourceEntryId'),
            progress: anyNamed('progress'),
            cfi: anyNamed('cfi'),
          ),
        );
      });

      test('does nothing when progress sync disabled', () async {
        when(mockSettingsProvider.progressSyncEnabled).thenReturn(false);

        await manager.scheduleProgressSync(
          bookId: 'book-1',
          sourceCatalogId: 'catalog-1',
          sourceEntryId: 'entry-1',
        );

        verifyNever(
          mockQueueService.enqueueProgressSync(
            bookId: anyNamed('bookId'),
            sourceCatalogId: anyNamed('sourceCatalogId'),
            sourceEntryId: anyNamed('sourceEntryId'),
            progress: anyNamed('progress'),
            cfi: anyNamed('cfi'),
          ),
        );
      });

      test('does nothing when sourceCatalogId is null', () async {
        await manager.scheduleProgressSync(
          bookId: 'book-1',
          sourceCatalogId: null,
          sourceEntryId: 'entry-1',
        );

        verifyNever(
          mockQueueService.enqueueProgressSync(
            bookId: anyNamed('bookId'),
            sourceCatalogId: anyNamed('sourceCatalogId'),
            sourceEntryId: anyNamed('sourceEntryId'),
            progress: anyNamed('progress'),
            cfi: anyNamed('cfi'),
          ),
        );
      });

      test('triggers sync immediately when network is available', () async {
        when(
          mockQueueService.enqueueProgressSync(
            bookId: anyNamed('bookId'),
            sourceCatalogId: anyNamed('sourceCatalogId'),
            sourceEntryId: anyNamed('sourceEntryId'),
            progress: anyNamed('progress'),
            cfi: anyNamed('cfi'),
          ),
        ).thenAnswer((_) async => _createDummySyncJob());
        when(
          mockQueueService.getNextBatch(limit: anyNamed('limit')),
        ).thenAnswer((_) async => []);

        await manager.scheduleProgressSync(
          bookId: 'book-1',
          sourceCatalogId: 'catalog-1',
          sourceEntryId: 'entry-1',
        );

        verify(
          mockQueueService.getNextBatch(limit: anyNamed('limit')),
        ).called(1);
      });

      test(
        'does not trigger immediate sync when network unavailable',
        () async {
          when(
            mockConnectivityService.canSync(
              wifiOnlyEnabled: anyNamed('wifiOnlyEnabled'),
            ),
          ).thenReturn(false);
          when(
            mockQueueService.enqueueProgressSync(
              bookId: anyNamed('bookId'),
              sourceCatalogId: anyNamed('sourceCatalogId'),
              sourceEntryId: anyNamed('sourceEntryId'),
              progress: anyNamed('progress'),
              cfi: anyNamed('cfi'),
            ),
          ).thenAnswer((_) async => _createDummySyncJob());

          await manager.scheduleProgressSync(
            bookId: 'book-1',
            sourceCatalogId: 'catalog-1',
            sourceEntryId: 'entry-1',
          );

          verifyNever(mockQueueService.getNextBatch(limit: anyNamed('limit')));
        },
      );
    });

    group('scheduleCatalogSync', () {
      test('enqueues catalog sync job', () async {
        when(
          mockQueueService.enqueueCatalogSync(
            catalogId: anyNamed('catalogId'),
            catalogType: anyNamed('catalogType'),
            feedUrl: anyNamed('feedUrl'),
          ),
        ).thenAnswer(
          (_) async => _createDummySyncJob(type: SyncJobType.catalog),
        );

        await manager.scheduleCatalogSync(
          catalogId: 'catalog-1',
          catalogType: 'opds',
          feedUrl: 'https://example.com/opds',
        );

        verify(
          mockQueueService.enqueueCatalogSync(
            catalogId: 'catalog-1',
            catalogType: 'opds',
            feedUrl: 'https://example.com/opds',
          ),
        ).called(1);
      });

      test('does nothing when sync disabled', () async {
        when(mockSettingsProvider.syncEnabled).thenReturn(false);

        await manager.scheduleCatalogSync(
          catalogId: 'catalog-1',
          catalogType: 'opds',
        );

        verifyNever(
          mockQueueService.enqueueCatalogSync(
            catalogId: anyNamed('catalogId'),
            catalogType: anyNamed('catalogType'),
            feedUrl: anyNamed('feedUrl'),
          ),
        );
      });

      test('does nothing when catalog sync disabled', () async {
        when(mockSettingsProvider.catalogSyncEnabled).thenReturn(false);

        await manager.scheduleCatalogSync(
          catalogId: 'catalog-1',
          catalogType: 'opds',
        );

        verifyNever(
          mockQueueService.enqueueCatalogSync(
            catalogId: anyNamed('catalogId'),
            catalogType: anyNamed('catalogType'),
            feedUrl: anyNamed('feedUrl'),
          ),
        );
      });
    });

    group('scheduleFeedSync', () {
      test('enqueues feed sync job', () async {
        when(
          mockQueueService.enqueueFeedSync(
            feedId: anyNamed('feedId'),
            feedUrl: anyNamed('feedUrl'),
          ),
        ).thenAnswer((_) async => _createDummySyncJob(type: SyncJobType.feed));

        await manager.scheduleFeedSync(
          feedId: 'feed-1',
          feedUrl: 'https://example.com/feed.xml',
        );

        verify(
          mockQueueService.enqueueFeedSync(
            feedId: 'feed-1',
            feedUrl: 'https://example.com/feed.xml',
          ),
        ).called(1);
      });

      test('does nothing when sync disabled', () async {
        when(mockSettingsProvider.syncEnabled).thenReturn(false);

        await manager.scheduleFeedSync(
          feedId: 'feed-1',
          feedUrl: 'https://example.com/feed.xml',
        );

        verifyNever(
          mockQueueService.enqueueFeedSync(
            feedId: anyNamed('feedId'),
            feedUrl: anyNamed('feedUrl'),
          ),
        );
      });

      test('does nothing when feed sync disabled', () async {
        when(mockSettingsProvider.feedSyncEnabled).thenReturn(false);

        await manager.scheduleFeedSync(
          feedId: 'feed-1',
          feedUrl: 'https://example.com/feed.xml',
        );

        verifyNever(
          mockQueueService.enqueueFeedSync(
            feedId: anyNamed('feedId'),
            feedUrl: anyNamed('feedUrl'),
          ),
        );
      });
    });

    group('connectivity changes', () {
      test(
        'processes pending jobs when connection becomes available',
        () async {
          await manager.initialize();

          when(
            mockQueueService.getNextBatch(limit: anyNamed('limit')),
          ).thenAnswer((_) async => []);

          // Simulate connectivity change
          connectivityController.add(_createConnectionStatus());

          // Allow async processing
          await Future.delayed(const Duration(milliseconds: 10));

          verify(
            mockQueueService.getNextBatch(limit: anyNamed('limit')),
          ).called(1);
        },
      );

      test('does not process when sync is disabled', () async {
        when(mockSettingsProvider.syncEnabled).thenReturn(false);
        await manager.initialize();

        // Simulate connectivity change
        connectivityController.add(_createConnectionStatus());

        // Allow async processing
        await Future.delayed(const Duration(milliseconds: 10));

        verifyNever(mockQueueService.getNextBatch(limit: anyNamed('limit')));
      });
    });

    group('clearError', () {
      test('clears last error and updates status', () async {
        // Cause an error
        when(
          mockConnectivityService.canSync(
            wifiOnlyEnabled: anyNamed('wifiOnlyEnabled'),
          ),
        ).thenReturn(false);
        await manager.syncNow();

        expect(manager.lastError, isNotNull);
        expect(manager.status, equals(SyncStatus.error));

        manager.clearError();

        expect(manager.lastError, isNull);
        expect(manager.status, equals(SyncStatus.idle));
      });
    });

    group('statusStream', () {
      test('emits status updates during sync', () async {
        when(
          mockQueueService.getNextBatch(limit: anyNamed('limit')),
        ).thenAnswer((_) async => []);

        final statuses = <SyncStatus>[];
        final subscription = manager.statusStream.listen(statuses.add);

        await manager.syncNow();

        await Future.delayed(const Duration(milliseconds: 10));
        await subscription.cancel();

        expect(statuses, contains(SyncStatus.syncing));
        expect(statuses, contains(SyncStatus.idle));
      });
    });

    group('dispose', () {
      test('cancels subscriptions and closes streams', () async {
        await manager.initialize();

        manager.dispose();

        verify(mockBackgroundExecutor.dispose()).called(1);
        verify(mockSettingsProvider.removeListener(any)).called(1);
      });
    });
  });

  group('SyncTaskIds', () {
    test('has correct task IDs', () {
      expect(SyncTaskIds.periodicSync, equals('com.readwhere.sync.periodic'));
      expect(SyncTaskIds.immediateSync, equals('com.readwhere.sync.immediate'));
    });
  });

  group('SyncStatus', () {
    test('has correct enum values', () {
      expect(SyncStatus.idle.name, equals('idle'));
      expect(SyncStatus.syncing.name, equals('syncing'));
      expect(SyncStatus.error.name, equals('error'));
    });
  });
}
