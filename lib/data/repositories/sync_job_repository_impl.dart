import 'package:sqflite/sqflite.dart';

import '../../domain/entities/sync_job.dart';
import '../../domain/repositories/sync_job_repository.dart';
import '../database/database_helper.dart';
import '../database/tables/sync_jobs_table.dart';
import '../models/sync_job_model.dart';

/// Implementation of SyncJobRepository using SQLite
///
/// This implementation uses DatabaseHelper to perform CRUD operations
/// on sync jobs stored in the local SQLite database.
class SyncJobRepositoryImpl implements SyncJobRepository {
  final DatabaseHelper _databaseHelper;

  SyncJobRepositoryImpl(this._databaseHelper);

  @override
  Future<SyncJob> enqueue(SyncJob job) async {
    try {
      final db = await _databaseHelper.database;
      final model = SyncJobModel.fromEntity(job);

      // Use INSERT OR REPLACE to upsert based on unique constraint
      await db.insert(
        SyncJobsTable.tableName,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return job;
    } catch (e) {
      throw Exception('Failed to enqueue sync job: $e');
    }
  }

  @override
  Future<List<SyncJob>> getPendingJobs({int limit = 10}) async {
    try {
      final db = await _databaseHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Get pending jobs OR failed jobs ready for retry
      final List<Map<String, dynamic>> maps = await db.query(
        SyncJobsTable.tableName,
        where:
            '''
          (${SyncJobsTable.columnStatus} = ?
           OR (${SyncJobsTable.columnStatus} = ?
               AND (${SyncJobsTable.columnNextRetryAt} IS NULL
                    OR ${SyncJobsTable.columnNextRetryAt} <= ?)))
          AND ${SyncJobsTable.columnAttempts} < ?
        ''',
        whereArgs: [
          SyncJobStatus.pending.name,
          SyncJobStatus.failed.name,
          now,
          SyncJob.maxRetries,
        ],
        orderBy:
            '''
          ${SyncJobsTable.columnPriority} DESC,
          ${SyncJobsTable.columnCreatedAt} ASC
        ''',
        limit: limit,
      );

      return maps.map((m) => SyncJobModel.fromMap(m).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get pending sync jobs: $e');
    }
  }

  @override
  Future<List<SyncJob>> getJobsByType(SyncJobType type) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        SyncJobsTable.tableName,
        where: '${SyncJobsTable.columnJobType} = ?',
        whereArgs: [type.name],
        orderBy: '${SyncJobsTable.columnCreatedAt} ASC',
      );

      return maps.map((m) => SyncJobModel.fromMap(m).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get sync jobs by type: $e');
    }
  }

  @override
  Future<SyncJob?> getById(String id) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        SyncJobsTable.tableName,
        where: '${SyncJobsTable.columnId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return SyncJobModel.fromMap(maps.first).toEntity();
    } catch (e) {
      throw Exception('Failed to get sync job by id: $e');
    }
  }

  @override
  Future<SyncJob?> updateStatus(
    String id,
    SyncJobStatus status, {
    String? error,
  }) async {
    try {
      final db = await _databaseHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final updates = <String, dynamic>{
        SyncJobsTable.columnStatus: status.name,
        SyncJobsTable.columnUpdatedAt: now,
      };

      if (error != null) {
        updates[SyncJobsTable.columnLastError] = error;
      }

      await db.update(
        SyncJobsTable.tableName,
        updates,
        where: '${SyncJobsTable.columnId} = ?',
        whereArgs: [id],
      );

      return getById(id);
    } catch (e) {
      throw Exception('Failed to update sync job status: $e');
    }
  }

  @override
  Future<SyncJob?> markFailed(String id, String error) async {
    try {
      final job = await getById(id);
      if (job == null) return null;

      final newAttempts = job.attempts + 1;
      final nextRetry = SyncJob.calculateNextRetry(newAttempts);

      final db = await _databaseHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.update(
        SyncJobsTable.tableName,
        {
          SyncJobsTable.columnStatus: SyncJobStatus.failed.name,
          SyncJobsTable.columnAttempts: newAttempts,
          SyncJobsTable.columnNextRetryAt: nextRetry.millisecondsSinceEpoch,
          SyncJobsTable.columnLastError: error,
          SyncJobsTable.columnUpdatedAt: now,
        },
        where: '${SyncJobsTable.columnId} = ?',
        whereArgs: [id],
      );

      return getById(id);
    } catch (e) {
      throw Exception('Failed to mark sync job as failed: $e');
    }
  }

  @override
  Future<void> markCompleted(String id) async {
    try {
      final db = await _databaseHelper.database;

      // Delete the completed job from the queue
      await db.delete(
        SyncJobsTable.tableName,
        where: '${SyncJobsTable.columnId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to mark sync job as completed: $e');
    }
  }

  @override
  Future<int> cancelJobsForTarget(SyncJobType type, String targetId) async {
    try {
      final db = await _databaseHelper.database;

      return await db.delete(
        SyncJobsTable.tableName,
        where:
            '''
          ${SyncJobsTable.columnJobType} = ?
          AND ${SyncJobsTable.columnTargetId} = ?
        ''',
        whereArgs: [type.name, targetId],
      );
    } catch (e) {
      throw Exception('Failed to cancel sync jobs for target: $e');
    }
  }

  @override
  Future<int> cleanupOldJobs({
    Duration olderThan = const Duration(days: 7),
  }) async {
    try {
      final db = await _databaseHelper.database;
      final cutoff = DateTime.now().subtract(olderThan).millisecondsSinceEpoch;

      // Delete completed jobs (status is not in queue since we delete on completion)
      // and failed jobs that have exceeded max retries
      return await db.delete(
        SyncJobsTable.tableName,
        where:
            '''
          ${SyncJobsTable.columnUpdatedAt} < ?
          AND ${SyncJobsTable.columnAttempts} >= ?
        ''',
        whereArgs: [cutoff, SyncJob.maxRetries],
      );
    } catch (e) {
      throw Exception('Failed to cleanup old sync jobs: $e');
    }
  }

  @override
  Future<SyncQueueStats> getStats() async {
    try {
      final db = await _databaseHelper.database;

      // Count by status
      final pendingResult = await db.rawQuery(
        '''
        SELECT COUNT(*) as count FROM ${SyncJobsTable.tableName}
        WHERE ${SyncJobsTable.columnStatus} = ?
      ''',
        [SyncJobStatus.pending.name],
      );

      final failedResult = await db.rawQuery(
        '''
        SELECT COUNT(*) as count FROM ${SyncJobsTable.tableName}
        WHERE ${SyncJobsTable.columnStatus} = ?
        AND ${SyncJobsTable.columnAttempts} < ?
      ''',
        [SyncJobStatus.failed.name, SyncJob.maxRetries],
      );

      final inProgressResult = await db.rawQuery(
        '''
        SELECT COUNT(*) as count FROM ${SyncJobsTable.tableName}
        WHERE ${SyncJobsTable.columnStatus} = ?
      ''',
        [SyncJobStatus.inProgress.name],
      );

      // Get oldest pending job timestamp
      final oldestResult = await db.rawQuery(
        '''
        SELECT MIN(${SyncJobsTable.columnCreatedAt}) as oldest
        FROM ${SyncJobsTable.tableName}
        WHERE ${SyncJobsTable.columnStatus} = ?
      ''',
        [SyncJobStatus.pending.name],
      );

      final pendingCount = Sqflite.firstIntValue(pendingResult) ?? 0;
      final failedCount = Sqflite.firstIntValue(failedResult) ?? 0;
      final inProgressCount = Sqflite.firstIntValue(inProgressResult) ?? 0;

      DateTime? oldestPending;
      if (oldestResult.isNotEmpty && oldestResult.first['oldest'] != null) {
        oldestPending = DateTime.fromMillisecondsSinceEpoch(
          oldestResult.first['oldest'] as int,
        );
      }

      return SyncQueueStats(
        pendingCount: pendingCount,
        failedCount: failedCount,
        inProgressCount: inProgressCount,
        oldestPendingJob: oldestPending,
      );
    } catch (e) {
      throw Exception('Failed to get sync queue stats: $e');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(SyncJobsTable.tableName);
    } catch (e) {
      throw Exception('Failed to clear sync jobs: $e');
    }
  }
}
