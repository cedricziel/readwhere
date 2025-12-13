import '../entities/sync_job.dart';

/// Statistics about the sync job queue
class SyncQueueStats {
  /// Number of pending jobs
  final int pendingCount;

  /// Number of failed jobs
  final int failedCount;

  /// Number of in-progress jobs
  final int inProgressCount;

  /// Timestamp of the oldest pending job
  final DateTime? oldestPendingJob;

  const SyncQueueStats({
    required this.pendingCount,
    required this.failedCount,
    required this.inProgressCount,
    this.oldestPendingJob,
  });

  /// Total number of jobs in the queue
  int get totalCount => pendingCount + failedCount + inProgressCount;

  /// Whether there are any jobs to process
  bool get hasJobs => totalCount > 0;
}

/// Abstract repository interface for managing sync jobs
///
/// This interface defines all operations for managing the background
/// sync job queue. Jobs are persisted to allow resumption after app restart.
abstract class SyncJobRepository {
  /// Enqueue a new job (upserts if same type+targetId exists)
  ///
  /// If a job with the same type and targetId already exists,
  /// it will be updated with the new payload and reset to pending status.
  /// [job] The job to enqueue
  Future<SyncJob> enqueue(SyncJob job);

  /// Get all pending jobs ready to process
  ///
  /// Returns jobs that are pending or failed with retry time passed.
  /// Jobs are ordered by priority (high first) then creation time (oldest first).
  /// [limit] Maximum number of jobs to return
  Future<List<SyncJob>> getPendingJobs({int limit = 10});

  /// Get jobs by type
  ///
  /// [type] The type of jobs to retrieve
  Future<List<SyncJob>> getJobsByType(SyncJobType type);

  /// Get a specific job by ID
  ///
  /// [id] The unique identifier of the job
  Future<SyncJob?> getById(String id);

  /// Update job status
  ///
  /// [id] The job ID
  /// [status] The new status
  /// [error] Optional error message (for failed status)
  Future<SyncJob?> updateStatus(
    String id,
    SyncJobStatus status, {
    String? error,
  });

  /// Mark job as failed with retry scheduling
  ///
  /// Increments the attempt counter and schedules the next retry
  /// using exponential backoff.
  /// [id] The job ID
  /// [error] The error message
  Future<SyncJob?> markFailed(String id, String error);

  /// Mark job as completed and remove from queue
  ///
  /// [id] The job ID
  Future<void> markCompleted(String id);

  /// Cancel all jobs for a specific target
  ///
  /// [type] The job type
  /// [targetId] The target ID
  Future<int> cancelJobsForTarget(SyncJobType type, String targetId);

  /// Delete old completed jobs
  ///
  /// [olderThan] Remove jobs completed before this duration
  Future<int> cleanupOldJobs({Duration olderThan = const Duration(days: 7)});

  /// Get queue statistics
  Future<SyncQueueStats> getStats();

  /// Delete all jobs in the queue
  Future<void> clearAll();
}
