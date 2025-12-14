import '../../domain/entities/sync_job.dart';
import '../../domain/repositories/sync_job_repository.dart';

/// Service for managing the background sync job queue
///
/// This service provides a high-level API for enqueueing sync jobs
/// with automatic deduplication, retry logic, and priority handling.
class SyncQueueService {
  final SyncJobRepository _repository;
  final int _maxRetries;

  SyncQueueService({required SyncJobRepository repository, int maxRetries = 5})
    : _repository = repository,
      _maxRetries = maxRetries;

  /// Enqueue a sync job with deduplication
  ///
  /// If a job with the same type and targetId already exists,
  /// it will be updated rather than creating a duplicate.
  Future<SyncJob> enqueue({
    required SyncJobType type,
    required String targetId,
    required Map<String, dynamic> payload,
    SyncJobPriority priority = SyncJobPriority.normal,
  }) async {
    final now = DateTime.now();
    final job = SyncJob(
      id: '${type.name}_$targetId',
      type: type,
      targetId: targetId,
      payload: payload,
      priority: priority,
      status: SyncJobStatus.pending,
      attempts: 0,
      createdAt: now,
      updatedAt: now,
    );

    return _repository.enqueue(job);
  }

  /// Get next batch of jobs ready to process
  ///
  /// Returns pending jobs and failed jobs that are ready for retry,
  /// ordered by priority then age.
  Future<List<SyncJob>> getNextBatch({int limit = 10}) async {
    return _repository.getPendingJobs(limit: limit);
  }

  /// Mark job as in progress
  ///
  /// Call this before starting to process a job.
  Future<SyncJob?> startJob(String id) async {
    return _repository.updateStatus(id, SyncJobStatus.inProgress);
  }

  /// Handle job failure with retry logic
  ///
  /// If the job has not exceeded max retries, it will be scheduled
  /// for retry with exponential backoff. Otherwise, it will be
  /// marked as permanently failed.
  Future<SyncJob?> handleFailure(String id, String error) async {
    final job = await _repository.getById(id);
    if (job == null) return null;

    if (job.attempts >= _maxRetries) {
      // Max retries exceeded, mark as permanently failed
      return _repository.updateStatus(
        id,
        SyncJobStatus.failed,
        error: 'Max retries exceeded: $error',
      );
    }

    // Schedule retry with exponential backoff
    return _repository.markFailed(id, error);
  }

  /// Mark job as successfully completed
  ///
  /// Removes the job from the queue.
  Future<void> completeJob(String id) async {
    await _repository.markCompleted(id);
  }

  /// Cancel all jobs for a specific target
  Future<int> cancelJobsFor(SyncJobType type, String targetId) async {
    return _repository.cancelJobsForTarget(type, targetId);
  }

  /// Get queue statistics
  Future<SyncQueueStats> getStats() async {
    return _repository.getStats();
  }

  /// Cleanup old failed jobs
  Future<int> cleanup({Duration olderThan = const Duration(days: 7)}) async {
    return _repository.cleanupOldJobs(olderThan: olderThan);
  }

  /// Clear all jobs in the queue
  Future<void> clearAll() async {
    await _repository.clearAll();
  }

  // Convenience methods for specific job types

  /// Enqueue a reading progress sync job
  ///
  /// Progress sync jobs have high priority as they represent
  /// user reading activity that should be synced quickly.
  Future<SyncJob> enqueueProgressSync({
    required String bookId,
    required String sourceCatalogId,
    required String sourceEntryId,
    required double progress,
    required String? cfi,
    DateTime? updatedAt,
  }) async {
    return enqueue(
      type: SyncJobType.progress,
      targetId: bookId,
      payload: {
        'bookId': bookId,
        'sourceCatalogId': sourceCatalogId,
        'sourceEntryId': sourceEntryId,
        'progress': progress,
        'cfi': cfi,
        'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
      },
      priority: SyncJobPriority.high,
    );
  }

  /// Enqueue a catalog refresh sync job
  ///
  /// Catalog sync jobs have normal priority.
  Future<SyncJob> enqueueCatalogSync({
    required String catalogId,
    required String catalogType,
    String? feedUrl,
  }) async {
    return enqueue(
      type: SyncJobType.catalog,
      targetId: catalogId,
      payload: {
        'catalogId': catalogId,
        'catalogType': catalogType,
        if (feedUrl != null) 'feedUrl': feedUrl,
      },
      priority: SyncJobPriority.normal,
    );
  }

  /// Enqueue an RSS feed refresh sync job
  ///
  /// Feed sync jobs have low priority as they are less time-sensitive.
  Future<SyncJob> enqueueFeedSync({
    required String feedId,
    required String feedUrl,
  }) async {
    return enqueue(
      type: SyncJobType.feed,
      targetId: feedId,
      payload: {'feedId': feedId, 'feedUrl': feedUrl},
      priority: SyncJobPriority.low,
    );
  }

  /// Enqueue a Nextcloud News sync job
  ///
  /// Syncs RSS feeds and article state from Nextcloud News app.
  /// Has low priority as it's not user-initiated.
  Future<SyncJob> enqueueNextcloudNewsSync({required String catalogId}) async {
    return enqueue(
      type: SyncJobType.nextcloudNews,
      targetId: catalogId,
      payload: {'catalogId': catalogId},
      priority: SyncJobPriority.low,
    );
  }

  /// Check if there are any pending jobs
  Future<bool> hasPendingJobs() async {
    final stats = await getStats();
    return stats.pendingCount > 0 || stats.failedCount > 0;
  }

  /// Get jobs by type
  Future<List<SyncJob>> getJobsByType(SyncJobType type) async {
    return _repository.getJobsByType(type);
  }
}
