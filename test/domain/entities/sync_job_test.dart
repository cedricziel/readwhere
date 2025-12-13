import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/domain/entities/sync_job.dart';

void main() {
  group('SyncJob', () {
    final now = DateTime.now();
    final later = now.add(const Duration(hours: 1));

    group('constructor', () {
      test('creates job with required fields and defaults', () {
        final job = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {'progress': 0.5},
          createdAt: now,
          updatedAt: now,
        );

        expect(job.id, 'job-1');
        expect(job.type, SyncJobType.progress);
        expect(job.targetId, 'book-123');
        expect(job.payload, {'progress': 0.5});
        expect(job.status, SyncJobStatus.pending);
        expect(job.priority, SyncJobPriority.normal);
        expect(job.attempts, 0);
        expect(job.nextRetryAt, isNull);
        expect(job.lastError, isNull);
        expect(job.createdAt, now);
        expect(job.updatedAt, now);
      });

      test('creates job with all fields', () {
        final job = SyncJob(
          id: 'job-2',
          type: SyncJobType.catalog,
          targetId: 'catalog-456',
          payload: {'url': 'https://example.com'},
          status: SyncJobStatus.failed,
          priority: SyncJobPriority.high,
          attempts: 3,
          nextRetryAt: later,
          lastError: 'Network error',
          createdAt: now,
          updatedAt: later,
        );

        expect(job.status, SyncJobStatus.failed);
        expect(job.priority, SyncJobPriority.high);
        expect(job.attempts, 3);
        expect(job.nextRetryAt, later);
        expect(job.lastError, 'Network error');
      });
    });

    group('copyWith', () {
      test('copies job with updated status', () {
        final original = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {'progress': 0.5},
          createdAt: now,
          updatedAt: now,
        );

        final updated = original.copyWith(
          status: SyncJobStatus.inProgress,
          updatedAt: later,
        );

        expect(updated.id, original.id);
        expect(updated.type, original.type);
        expect(updated.targetId, original.targetId);
        expect(updated.status, SyncJobStatus.inProgress);
        expect(updated.updatedAt, later);
      });

      test('copies job with incremented attempts and error', () {
        final original = SyncJob(
          id: 'job-1',
          type: SyncJobType.feed,
          targetId: 'feed-789',
          payload: {},
          attempts: 2,
          createdAt: now,
          updatedAt: now,
        );

        final retryAt = now.add(const Duration(minutes: 30));
        final updated = original.copyWith(
          attempts: original.attempts + 1,
          lastError: 'Connection timeout',
          nextRetryAt: retryAt,
          status: SyncJobStatus.failed,
        );

        expect(updated.attempts, 3);
        expect(updated.lastError, 'Connection timeout');
        expect(updated.nextRetryAt, retryAt);
        expect(updated.status, SyncJobStatus.failed);
      });
    });

    group('SyncJobType', () {
      test('has correct string values', () {
        expect(SyncJobType.progress.name, 'progress');
        expect(SyncJobType.catalog.name, 'catalog');
        expect(SyncJobType.feed.name, 'feed');
      });

      test('fromString parses valid types', () {
        expect(SyncJobType.values.byName('progress'), SyncJobType.progress);
        expect(SyncJobType.values.byName('catalog'), SyncJobType.catalog);
        expect(SyncJobType.values.byName('feed'), SyncJobType.feed);
      });
    });

    group('SyncJobStatus', () {
      test('has correct string values', () {
        expect(SyncJobStatus.pending.name, 'pending');
        expect(SyncJobStatus.inProgress.name, 'inProgress');
        expect(SyncJobStatus.completed.name, 'completed');
        expect(SyncJobStatus.failed.name, 'failed');
      });
    });

    group('SyncJobPriority', () {
      test('has correct values', () {
        expect(SyncJobPriority.low.value, 0);
        expect(SyncJobPriority.normal.value, 1);
        expect(SyncJobPriority.high.value, 2);
      });

      test('fromValue returns correct priority', () {
        expect(SyncJobPriority.fromValue(0), SyncJobPriority.low);
        expect(SyncJobPriority.fromValue(1), SyncJobPriority.normal);
        expect(SyncJobPriority.fromValue(2), SyncJobPriority.high);
      });

      test('fromValue returns normal for unknown values', () {
        expect(SyncJobPriority.fromValue(99), SyncJobPriority.normal);
        expect(SyncJobPriority.fromValue(-1), SyncJobPriority.normal);
      });
    });

    group('hasExceededMaxRetries', () {
      test('returns false when under max retries', () {
        final job = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {},
          attempts: 3,
          createdAt: now,
          updatedAt: now,
        );

        expect(job.hasExceededMaxRetries, isFalse);
      });

      test('returns true when at max retries', () {
        final job = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {},
          attempts: SyncJob.maxRetries,
          createdAt: now,
          updatedAt: now,
        );

        expect(job.hasExceededMaxRetries, isTrue);
      });

      test('returns true when above max retries', () {
        final job = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {},
          attempts: SyncJob.maxRetries + 1,
          createdAt: now,
          updatedAt: now,
        );

        expect(job.hasExceededMaxRetries, isTrue);
      });
    });

    group('isReadyForRetry', () {
      test('returns false for non-failed jobs', () {
        final job = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {},
          status: SyncJobStatus.pending,
          createdAt: now,
          updatedAt: now,
        );

        expect(job.isReadyForRetry, isFalse);
      });

      test('returns true for failed job with no nextRetryAt', () {
        final job = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {},
          status: SyncJobStatus.failed,
          nextRetryAt: null,
          createdAt: now,
          updatedAt: now,
        );

        expect(job.isReadyForRetry, isTrue);
      });

      test('returns true for failed job past retry time', () {
        final pastRetryTime = DateTime.now().subtract(
          const Duration(minutes: 5),
        );
        final job = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {},
          status: SyncJobStatus.failed,
          nextRetryAt: pastRetryTime,
          createdAt: now,
          updatedAt: now,
        );

        expect(job.isReadyForRetry, isTrue);
      });

      test('returns false for failed job before retry time', () {
        final futureRetryTime = DateTime.now().add(const Duration(minutes: 30));
        final job = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {},
          status: SyncJobStatus.failed,
          nextRetryAt: futureRetryTime,
          createdAt: now,
          updatedAt: now,
        );

        expect(job.isReadyForRetry, isFalse);
      });
    });

    group('canProcess', () {
      test('returns true for pending jobs', () {
        final job = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {},
          status: SyncJobStatus.pending,
          createdAt: now,
          updatedAt: now,
        );

        expect(job.canProcess, isTrue);
      });

      test('returns true for failed jobs ready for retry', () {
        final pastRetryTime = DateTime.now().subtract(
          const Duration(minutes: 5),
        );
        final job = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {},
          status: SyncJobStatus.failed,
          nextRetryAt: pastRetryTime,
          createdAt: now,
          updatedAt: now,
        );

        expect(job.canProcess, isTrue);
      });

      test('returns false for in-progress jobs', () {
        final job = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {},
          status: SyncJobStatus.inProgress,
          createdAt: now,
          updatedAt: now,
        );

        expect(job.canProcess, isFalse);
      });

      test('returns false for completed jobs', () {
        final job = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {},
          status: SyncJobStatus.completed,
          createdAt: now,
          updatedAt: now,
        );

        expect(job.canProcess, isFalse);
      });

      test('returns false for failed jobs not ready for retry', () {
        final futureRetryTime = DateTime.now().add(const Duration(minutes: 30));
        final job = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {},
          status: SyncJobStatus.failed,
          nextRetryAt: futureRetryTime,
          createdAt: now,
          updatedAt: now,
        );

        expect(job.canProcess, isFalse);
      });
    });

    group('calculateNextRetry', () {
      test('returns 30 seconds for first retry', () {
        final before = DateTime.now();
        final retry = SyncJob.calculateNextRetry(0);
        final after = DateTime.now();

        // Should be approximately 30 seconds from now
        expect(retry.isAfter(before.add(const Duration(seconds: 29))), isTrue);
        expect(retry.isBefore(after.add(const Duration(seconds: 31))), isTrue);
      });

      test('returns 60 seconds for second retry', () {
        final before = DateTime.now();
        final retry = SyncJob.calculateNextRetry(1);

        // Should be approximately 60 seconds from now (30 * 2^1)
        expect(retry.isAfter(before.add(const Duration(seconds: 59))), isTrue);
      });

      test('returns 120 seconds for third retry', () {
        final before = DateTime.now();
        final retry = SyncJob.calculateNextRetry(2);

        // Should be approximately 120 seconds from now (30 * 2^2)
        expect(retry.isAfter(before.add(const Duration(seconds: 119))), isTrue);
      });

      test('caps at 1 hour for many retries', () {
        final before = DateTime.now();
        final retry = SyncJob.calculateNextRetry(10);

        // Should be capped at 1 hour
        expect(
          retry.isBefore(before.add(const Duration(hours: 1, seconds: 2))),
          isTrue,
        );
        expect(retry.isAfter(before.add(const Duration(minutes: 59))), isTrue);
      });
    });

    group('equality', () {
      test('jobs with same properties are equal', () {
        final job1 = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {'progress': 0.5},
          createdAt: now,
          updatedAt: now,
        );

        final job2 = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {'progress': 0.5},
          createdAt: now,
          updatedAt: now,
        );

        expect(job1, equals(job2));
        expect(job1.hashCode, equals(job2.hashCode));
      });

      test('jobs with different ids are not equal', () {
        final job1 = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {},
          createdAt: now,
          updatedAt: now,
        );

        final job2 = SyncJob(
          id: 'job-2',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {},
          createdAt: now,
          updatedAt: now,
        );

        expect(job1, isNot(equals(job2)));
      });

      test('jobs with different status are not equal', () {
        final job1 = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {},
          status: SyncJobStatus.pending,
          createdAt: now,
          updatedAt: now,
        );

        final job2 = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {},
          status: SyncJobStatus.completed,
          createdAt: now,
          updatedAt: now,
        );

        expect(job1, isNot(equals(job2)));
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        final job = SyncJob(
          id: 'job-1',
          type: SyncJobType.progress,
          targetId: 'book-123',
          payload: {},
          status: SyncJobStatus.pending,
          attempts: 2,
          createdAt: now,
          updatedAt: now,
        );

        final str = job.toString();
        expect(str, contains('job-1'));
        expect(str, contains('progress'));
        expect(str, contains('book-123'));
        expect(str, contains('pending'));
        expect(str, contains('2'));
      });
    });
  });
}
