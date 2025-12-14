import 'package:equatable/equatable.dart';

/// Type of sync job to be performed
enum SyncJobType {
  /// Sync reading progress to remote server
  progress,

  /// Refresh catalog data from remote server
  catalog,

  /// Refresh RSS feed from remote server
  feed,

  /// Sync RSS feeds from Nextcloud News app
  nextcloudNews,
}

/// Status of a sync job
enum SyncJobStatus {
  /// Job is waiting to be processed
  pending,

  /// Job is currently being processed
  inProgress,

  /// Job failed and may be retried
  failed,

  /// Job completed successfully
  completed,
}

/// Priority level for sync jobs
///
/// Higher priority jobs are processed first.
enum SyncJobPriority {
  /// Low priority (e.g., feed refresh)
  low(0),

  /// Normal priority (e.g., catalog refresh)
  normal(1),

  /// High priority (e.g., reading progress sync)
  high(2);

  final int value;
  const SyncJobPriority(this.value);

  static SyncJobPriority fromValue(int value) {
    return SyncJobPriority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => SyncJobPriority.normal,
    );
  }
}

/// Represents a sync job in the background sync queue
///
/// Sync jobs are persisted to the database and processed when
/// network connectivity is available. Failed jobs are retried
/// with exponential backoff.
class SyncJob extends Equatable {
  final String id;
  final SyncJobType type;
  final String targetId;
  final Map<String, dynamic> payload;
  final SyncJobStatus status;
  final SyncJobPriority priority;
  final int attempts;
  final DateTime? nextRetryAt;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SyncJob({
    required this.id,
    required this.type,
    required this.targetId,
    required this.payload,
    this.status = SyncJobStatus.pending,
    this.priority = SyncJobPriority.normal,
    this.attempts = 0,
    this.nextRetryAt,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this SyncJob with the given fields replaced
  SyncJob copyWith({
    String? id,
    SyncJobType? type,
    String? targetId,
    Map<String, dynamic>? payload,
    SyncJobStatus? status,
    SyncJobPriority? priority,
    int? attempts,
    DateTime? nextRetryAt,
    String? lastError,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SyncJob(
      id: id ?? this.id,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      attempts: attempts ?? this.attempts,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate next retry time using exponential backoff
  ///
  /// Base delay: 30 seconds
  /// Max delay: 1 hour
  /// Formula: min(30s * 2^attempts, 1 hour)
  static DateTime calculateNextRetry(int attempts) {
    const baseDelaySeconds = 30;
    const maxDelaySeconds = 3600; // 1 hour

    // 2^attempts with clamping to avoid overflow
    final multiplier = 1 << attempts.clamp(0, 10);
    final delaySeconds = (baseDelaySeconds * multiplier).clamp(
      0,
      maxDelaySeconds,
    );

    return DateTime.now().add(Duration(seconds: delaySeconds));
  }

  /// Maximum number of retry attempts before giving up
  static const int maxRetries = 5;

  /// Whether this job has exceeded the maximum retry attempts
  bool get hasExceededMaxRetries => attempts >= maxRetries;

  /// Whether this job is ready to be retried
  bool get isReadyForRetry {
    if (status != SyncJobStatus.failed) return false;
    if (nextRetryAt == null) return true;
    return DateTime.now().isAfter(nextRetryAt!);
  }

  /// Whether this job can be processed now
  bool get canProcess {
    return status == SyncJobStatus.pending ||
        (status == SyncJobStatus.failed && isReadyForRetry);
  }

  @override
  List<Object?> get props => [
    id,
    type,
    targetId,
    status,
    priority,
    attempts,
    updatedAt,
  ];

  @override
  String toString() {
    return 'SyncJob(id: $id, type: ${type.name}, targetId: $targetId, '
        'status: ${status.name}, attempts: $attempts)';
  }
}
