import 'dart:convert';

import '../../domain/entities/sync_job.dart';
import '../database/tables/sync_jobs_table.dart';

/// Data model for SyncJob entity with database serialization support
///
/// This model extends the domain entity with methods for converting
/// to and from database representations (Map format for SQLite).
class SyncJobModel extends SyncJob {
  const SyncJobModel({
    required super.id,
    required super.type,
    required super.targetId,
    required super.payload,
    super.status,
    super.priority,
    super.attempts,
    super.nextRetryAt,
    super.lastError,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create a SyncJobModel from a Map (SQLite row)
  ///
  /// Converts database column types to Dart types:
  /// - INTEGER timestamps to DateTime
  /// - TEXT JSON to Map for payload
  /// - TEXT enums to enum values
  factory SyncJobModel.fromMap(Map<String, dynamic> map) {
    return SyncJobModel(
      id: map[SyncJobsTable.columnId] as String,
      type: _parseJobType(map[SyncJobsTable.columnJobType] as String),
      targetId: map[SyncJobsTable.columnTargetId] as String,
      payload: _parsePayload(map[SyncJobsTable.columnPayload] as String),
      status: _parseStatus(map[SyncJobsTable.columnStatus] as String),
      priority: SyncJobPriority.fromValue(
        map[SyncJobsTable.columnPriority] as int,
      ),
      attempts: map[SyncJobsTable.columnAttempts] as int,
      nextRetryAt: map[SyncJobsTable.columnNextRetryAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[SyncJobsTable.columnNextRetryAt] as int,
            )
          : null,
      lastError: map[SyncJobsTable.columnLastError] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[SyncJobsTable.columnCreatedAt] as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map[SyncJobsTable.columnUpdatedAt] as int,
      ),
    );
  }

  /// Create a SyncJobModel from a domain entity
  factory SyncJobModel.fromEntity(SyncJob job) {
    return SyncJobModel(
      id: job.id,
      type: job.type,
      targetId: job.targetId,
      payload: job.payload,
      status: job.status,
      priority: job.priority,
      attempts: job.attempts,
      nextRetryAt: job.nextRetryAt,
      lastError: job.lastError,
      createdAt: job.createdAt,
      updatedAt: job.updatedAt,
    );
  }

  /// Convert to a Map for SQLite storage
  ///
  /// Converts Dart types to database column types:
  /// - DateTime to INTEGER (milliseconds since epoch)
  /// - Map to TEXT (JSON string) for payload
  /// - Enums to TEXT/INTEGER
  Map<String, dynamic> toMap() {
    return {
      SyncJobsTable.columnId: id,
      SyncJobsTable.columnJobType: type.name,
      SyncJobsTable.columnTargetId: targetId,
      SyncJobsTable.columnPayload: jsonEncode(payload),
      SyncJobsTable.columnStatus: status.name,
      SyncJobsTable.columnPriority: priority.value,
      SyncJobsTable.columnAttempts: attempts,
      SyncJobsTable.columnNextRetryAt: nextRetryAt?.millisecondsSinceEpoch,
      SyncJobsTable.columnLastError: lastError,
      SyncJobsTable.columnCreatedAt: createdAt.millisecondsSinceEpoch,
      SyncJobsTable.columnUpdatedAt: updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Convert to domain entity (SyncJob)
  SyncJob toEntity() {
    return SyncJob(
      id: id,
      type: type,
      targetId: targetId,
      payload: payload,
      status: status,
      priority: priority,
      attempts: attempts,
      nextRetryAt: nextRetryAt,
      lastError: lastError,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Parse job type from string
  static SyncJobType _parseJobType(String value) {
    return SyncJobType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => SyncJobType.progress,
    );
  }

  /// Parse status from string
  static SyncJobStatus _parseStatus(String value) {
    return SyncJobStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => SyncJobStatus.pending,
    );
  }

  /// Parse payload JSON string to Map
  static Map<String, dynamic> _parsePayload(String json) {
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
