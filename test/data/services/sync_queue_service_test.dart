import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readwhere/data/services/sync_queue_service.dart';
import 'package:readwhere/domain/entities/sync_job.dart';
import 'package:readwhere/domain/repositories/sync_job_repository.dart';

import '../../mocks/mock_repositories.mocks.dart';

void main() {
  group('SyncQueueService', () {
    late MockSyncJobRepository mockRepository;
    late SyncQueueService service;

    final now = DateTime.now();

    setUp(() {
      mockRepository = MockSyncJobRepository();
      service = SyncQueueService(repository: mockRepository);
    });

    group('enqueue', () {
      test('creates job with correct id format', () async {
        final expectedJob = SyncJob(
          id: 'progress_book-123',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {'progress': 0.5},
          priority: SyncJobPriority.high,
          createdAt: now,
          updatedAt: now,
        );

        when(mockRepository.enqueue(any)).thenAnswer((_) async => expectedJob);

        final result = await service.enqueue(
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {'progress': 0.5},
          priority: SyncJobPriority.high,
        );

        expect(result.type, SyncJobType.progress);
        expect(result.targetId, 'book-123');

        final captured = verify(mockRepository.enqueue(captureAny)).captured;
        final capturedJob = captured.single as SyncJob;
        expect(capturedJob.id, 'progress_book-123');
        expect(capturedJob.type, SyncJobType.progress);
        expect(capturedJob.status, SyncJobStatus.pending);
        expect(capturedJob.attempts, 0);
      });

      test('uses default normal priority when not specified', () async {
        final expectedJob = SyncJob(
          id: 'catalog_cat-456',
          type: SyncJobType.catalog,
          targetId: 'cat-456',
          payload: {},
          priority: SyncJobPriority.normal,
          createdAt: now,
          updatedAt: now,
        );

        when(mockRepository.enqueue(any)).thenAnswer((_) async => expectedJob);

        await service.enqueue(
          type: SyncJobType.catalog,
          targetId: 'cat-456',
          payload: {},
        );

        final captured = verify(mockRepository.enqueue(captureAny)).captured;
        final capturedJob = captured.single as SyncJob;
        expect(capturedJob.priority, SyncJobPriority.normal);
      });
    });

    group('getNextBatch', () {
      test('returns pending jobs from repository', () async {
        final jobs = [
          SyncJob(
            id: 'job-1',
            type: SyncJobType.progress,
            targetId: 'book-1',
            payload: {},
            createdAt: now,
            updatedAt: now,
          ),
          SyncJob(
            id: 'job-2',
            type: SyncJobType.catalog,
            targetId: 'cat-1',
            payload: {},
            createdAt: now,
            updatedAt: now,
          ),
        ];

        when(
          mockRepository.getPendingJobs(limit: anyNamed('limit')),
        ).thenAnswer((_) async => jobs);

        final result = await service.getNextBatch(limit: 5);

        expect(result, jobs);
        verify(mockRepository.getPendingJobs(limit: 5)).called(1);
      });

      test('uses default limit of 10', () async {
        when(
          mockRepository.getPendingJobs(limit: anyNamed('limit')),
        ).thenAnswer((_) async => []);

        await service.getNextBatch();

        verify(mockRepository.getPendingJobs(limit: 10)).called(1);
      });
    });

    group('startJob', () {
      test('updates job status to in progress', () async {
        final job = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-1',
          payload: {},
          status: SyncJobStatus.inProgress,
          createdAt: now,
          updatedAt: now,
        );

        when(
          mockRepository.updateStatus(any, any, error: anyNamed('error')),
        ).thenAnswer((_) async => job);

        final result = await service.startJob('job-1');

        expect(result?.status, SyncJobStatus.inProgress);
        verify(
          mockRepository.updateStatus('job-1', SyncJobStatus.inProgress),
        ).called(1);
      });

      test('returns null for non-existent job', () async {
        when(
          mockRepository.updateStatus(any, any, error: anyNamed('error')),
        ).thenAnswer((_) async => null);

        final result = await service.startJob('non-existent');

        expect(result, isNull);
      });
    });

    group('handleFailure', () {
      test('schedules retry when under max retries', () async {
        final job = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-1',
          payload: {},
          attempts: 2,
          createdAt: now,
          updatedAt: now,
        );

        final failedJob = job.copyWith(
          status: SyncJobStatus.failed,
          attempts: 3,
          lastError: 'Network error',
        );

        when(mockRepository.getById('job-1')).thenAnswer((_) async => job);
        when(
          mockRepository.markFailed('job-1', 'Network error'),
        ).thenAnswer((_) async => failedJob);

        final result = await service.handleFailure('job-1', 'Network error');

        expect(result?.status, SyncJobStatus.failed);
        verify(mockRepository.markFailed('job-1', 'Network error')).called(1);
        verifyNever(
          mockRepository.updateStatus(any, any, error: anyNamed('error')),
        );
      });

      test('marks permanently failed when max retries exceeded', () async {
        final job = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-1',
          payload: {},
          attempts: 5, // max retries
          createdAt: now,
          updatedAt: now,
        );

        final failedJob = job.copyWith(
          status: SyncJobStatus.failed,
          lastError: 'Max retries exceeded: Network error',
        );

        when(mockRepository.getById('job-1')).thenAnswer((_) async => job);
        when(
          mockRepository.updateStatus(
            'job-1',
            SyncJobStatus.failed,
            error: 'Max retries exceeded: Network error',
          ),
        ).thenAnswer((_) async => failedJob);

        final result = await service.handleFailure('job-1', 'Network error');

        expect(result?.lastError, contains('Max retries exceeded'));
        verify(
          mockRepository.updateStatus(
            'job-1',
            SyncJobStatus.failed,
            error: 'Max retries exceeded: Network error',
          ),
        ).called(1);
        verifyNever(mockRepository.markFailed(any, any));
      });

      test('returns null for non-existent job', () async {
        when(
          mockRepository.getById('non-existent'),
        ).thenAnswer((_) async => null);

        final result = await service.handleFailure('non-existent', 'error');

        expect(result, isNull);
      });
    });

    group('completeJob', () {
      test('calls repository markCompleted', () async {
        when(mockRepository.markCompleted('job-1')).thenAnswer((_) async => {});

        await service.completeJob('job-1');

        verify(mockRepository.markCompleted('job-1')).called(1);
      });
    });

    group('cancelJobsFor', () {
      test('cancels jobs for specific type and target', () async {
        when(
          mockRepository.cancelJobsForTarget(SyncJobType.progress, 'book-123'),
        ).thenAnswer((_) async => 2);

        final result = await service.cancelJobsFor(
          SyncJobType.progress,
          'book-123',
        );

        expect(result, 2);
        verify(
          mockRepository.cancelJobsForTarget(SyncJobType.progress, 'book-123'),
        ).called(1);
      });
    });

    group('getStats', () {
      test('returns queue statistics', () async {
        const stats = SyncQueueStats(
          pendingCount: 5,
          failedCount: 2,
          inProgressCount: 1,
        );

        when(mockRepository.getStats()).thenAnswer((_) async => stats);

        final result = await service.getStats();

        expect(result.pendingCount, 5);
        expect(result.failedCount, 2);
        expect(result.inProgressCount, 1);
        expect(result.totalCount, 8);
      });
    });

    group('cleanup', () {
      test('cleans up old jobs with default duration', () async {
        when(
          mockRepository.cleanupOldJobs(olderThan: anyNamed('olderThan')),
        ).thenAnswer((_) async => 3);

        final result = await service.cleanup();

        expect(result, 3);
        verify(
          mockRepository.cleanupOldJobs(olderThan: const Duration(days: 7)),
        ).called(1);
      });

      test('cleans up old jobs with custom duration', () async {
        when(
          mockRepository.cleanupOldJobs(olderThan: anyNamed('olderThan')),
        ).thenAnswer((_) async => 10);

        final result = await service.cleanup(
          olderThan: const Duration(days: 30),
        );

        expect(result, 10);
        verify(
          mockRepository.cleanupOldJobs(olderThan: const Duration(days: 30)),
        ).called(1);
      });
    });

    group('clearAll', () {
      test('clears all jobs from queue', () async {
        when(mockRepository.clearAll()).thenAnswer((_) async => {});

        await service.clearAll();

        verify(mockRepository.clearAll()).called(1);
      });
    });

    group('enqueueProgressSync', () {
      test('creates progress sync job with high priority', () async {
        final expectedJob = SyncJob(
          id: 'progress_book-123',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {
            'bookId': 'book-123',
            'sourceCatalogId': 'catalog-1',
            'sourceEntryId': 'entry-1',
            'progress': 0.75,
            'cfi': 'epubcfi(/6/4!/4/1:0)',
          },
          priority: SyncJobPriority.high,
          createdAt: now,
          updatedAt: now,
        );

        when(mockRepository.enqueue(any)).thenAnswer((_) async => expectedJob);

        await service.enqueueProgressSync(
          bookId: 'book-123',
          sourceCatalogId: 'catalog-1',
          sourceEntryId: 'entry-1',
          progress: 0.75,
          cfi: 'epubcfi(/6/4!/4/1:0)',
        );

        final captured = verify(mockRepository.enqueue(captureAny)).captured;
        final capturedJob = captured.single as SyncJob;
        expect(capturedJob.type, SyncJobType.progress);
        expect(capturedJob.priority, SyncJobPriority.high);
        expect(capturedJob.payload['bookId'], 'book-123');
        expect(capturedJob.payload['progress'], 0.75);
        expect(capturedJob.payload['cfi'], 'epubcfi(/6/4!/4/1:0)');
      });

      test('includes updatedAt timestamp in payload', () async {
        final updatedAt = DateTime(2024, 1, 15);

        when(mockRepository.enqueue(any)).thenAnswer(
          (_) async => SyncJob(
            id: 'progress_book-123',
            type: SyncJobType.progress,
            targetId: 'book-123',
            payload: {},
            createdAt: now,
            updatedAt: now,
          ),
        );

        await service.enqueueProgressSync(
          bookId: 'book-123',
          sourceCatalogId: 'catalog-1',
          sourceEntryId: 'entry-1',
          progress: 0.5,
          cfi: null,
          updatedAt: updatedAt,
        );

        final captured = verify(mockRepository.enqueue(captureAny)).captured;
        final capturedJob = captured.single as SyncJob;
        expect(capturedJob.payload['updatedAt'], updatedAt.toIso8601String());
      });
    });

    group('enqueueCatalogSync', () {
      test('creates catalog sync job with normal priority', () async {
        when(mockRepository.enqueue(any)).thenAnswer(
          (_) async => SyncJob(
            id: 'catalog_cat-456',
            type: SyncJobType.catalog,
            targetId: 'cat-456',
            payload: {},
            createdAt: now,
            updatedAt: now,
          ),
        );

        await service.enqueueCatalogSync(
          catalogId: 'cat-456',
          catalogType: 'opds',
          feedUrl: 'https://example.com/feed.xml',
        );

        final captured = verify(mockRepository.enqueue(captureAny)).captured;
        final capturedJob = captured.single as SyncJob;
        expect(capturedJob.type, SyncJobType.catalog);
        expect(capturedJob.priority, SyncJobPriority.normal);
        expect(capturedJob.payload['catalogId'], 'cat-456');
        expect(capturedJob.payload['catalogType'], 'opds');
        expect(capturedJob.payload['feedUrl'], 'https://example.com/feed.xml');
      });

      test('omits feedUrl when not provided', () async {
        when(mockRepository.enqueue(any)).thenAnswer(
          (_) async => SyncJob(
            id: 'catalog_cat-789',
            type: SyncJobType.catalog,
            targetId: 'cat-789',
            payload: {},
            createdAt: now,
            updatedAt: now,
          ),
        );

        await service.enqueueCatalogSync(
          catalogId: 'cat-789',
          catalogType: 'kavita',
        );

        final captured = verify(mockRepository.enqueue(captureAny)).captured;
        final capturedJob = captured.single as SyncJob;
        expect(capturedJob.payload.containsKey('feedUrl'), isFalse);
      });
    });

    group('enqueueFeedSync', () {
      test('creates feed sync job with low priority', () async {
        when(mockRepository.enqueue(any)).thenAnswer(
          (_) async => SyncJob(
            id: 'feed_feed-123',
            type: SyncJobType.feed,
            targetId: 'feed-123',
            payload: {},
            createdAt: now,
            updatedAt: now,
          ),
        );

        await service.enqueueFeedSync(
          feedId: 'feed-123',
          feedUrl: 'https://example.com/rss.xml',
        );

        final captured = verify(mockRepository.enqueue(captureAny)).captured;
        final capturedJob = captured.single as SyncJob;
        expect(capturedJob.type, SyncJobType.feed);
        expect(capturedJob.priority, SyncJobPriority.low);
        expect(capturedJob.payload['feedId'], 'feed-123');
        expect(capturedJob.payload['feedUrl'], 'https://example.com/rss.xml');
      });
    });

    group('hasPendingJobs', () {
      test('returns true when pending jobs exist', () async {
        const stats = SyncQueueStats(
          pendingCount: 3,
          failedCount: 0,
          inProgressCount: 0,
        );

        when(mockRepository.getStats()).thenAnswer((_) async => stats);

        final result = await service.hasPendingJobs();

        expect(result, isTrue);
      });

      test('returns true when failed jobs exist', () async {
        const stats = SyncQueueStats(
          pendingCount: 0,
          failedCount: 2,
          inProgressCount: 0,
        );

        when(mockRepository.getStats()).thenAnswer((_) async => stats);

        final result = await service.hasPendingJobs();

        expect(result, isTrue);
      });

      test('returns false when no pending or failed jobs', () async {
        const stats = SyncQueueStats(
          pendingCount: 0,
          failedCount: 0,
          inProgressCount: 1,
        );

        when(mockRepository.getStats()).thenAnswer((_) async => stats);

        final result = await service.hasPendingJobs();

        expect(result, isFalse);
      });
    });

    group('getJobsByType', () {
      test('returns jobs filtered by type', () async {
        final jobs = [
          SyncJob(
            id: 'progress_book-1',
            type: SyncJobType.progress,
            targetId: 'book-1',
            payload: {},
            createdAt: now,
            updatedAt: now,
          ),
          SyncJob(
            id: 'progress_book-2',
            type: SyncJobType.progress,
            targetId: 'book-2',
            payload: {},
            createdAt: now,
            updatedAt: now,
          ),
        ];

        when(
          mockRepository.getJobsByType(SyncJobType.progress),
        ).thenAnswer((_) async => jobs);

        final result = await service.getJobsByType(SyncJobType.progress);

        expect(result, jobs);
        expect(result.length, 2);
        verify(mockRepository.getJobsByType(SyncJobType.progress)).called(1);
      });
    });

    group('custom maxRetries', () {
      test('uses custom maxRetries value', () async {
        final customService = SyncQueueService(
          repository: mockRepository,
          maxRetries: 3,
        );

        final job = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-1',
          payload: {},
          attempts: 3, // equals custom max
          createdAt: now,
          updatedAt: now,
        );

        final failedJob = job.copyWith(
          status: SyncJobStatus.failed,
          lastError: 'Max retries exceeded: error',
        );

        when(mockRepository.getById('job-1')).thenAnswer((_) async => job);
        when(
          mockRepository.updateStatus(
            'job-1',
            SyncJobStatus.failed,
            error: 'Max retries exceeded: error',
          ),
        ).thenAnswer((_) async => failedJob);

        await customService.handleFailure('job-1', 'error');

        // Should mark as permanently failed because attempts >= maxRetries
        verify(
          mockRepository.updateStatus(
            'job-1',
            SyncJobStatus.failed,
            error: 'Max retries exceeded: error',
          ),
        ).called(1);
        verifyNever(mockRepository.markFailed(any, any));
      });
    });
  });

  group('SyncQueueStats', () {
    test('totalCount sums all counts', () {
      const stats = SyncQueueStats(
        pendingCount: 5,
        failedCount: 3,
        inProgressCount: 2,
      );

      expect(stats.totalCount, 10);
    });

    test('hasJobs returns true when totalCount > 0', () {
      const stats = SyncQueueStats(
        pendingCount: 1,
        failedCount: 0,
        inProgressCount: 0,
      );

      expect(stats.hasJobs, isTrue);
    });

    test('hasJobs returns false when totalCount is 0', () {
      const stats = SyncQueueStats(
        pendingCount: 0,
        failedCount: 0,
        inProgressCount: 0,
      );

      expect(stats.hasJobs, isFalse);
    });

    test('oldestPendingJob is optional', () {
      const statsWithout = SyncQueueStats(
        pendingCount: 0,
        failedCount: 0,
        inProgressCount: 0,
      );

      final statsWith = SyncQueueStats(
        pendingCount: 1,
        failedCount: 0,
        inProgressCount: 0,
        oldestPendingJob: DateTime(2024, 1, 1),
      );

      expect(statsWithout.oldestPendingJob, isNull);
      expect(statsWith.oldestPendingJob, DateTime(2024, 1, 1));
    });
  });
}
