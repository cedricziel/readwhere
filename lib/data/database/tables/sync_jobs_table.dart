/// Sync jobs table schema for background sync queue
///
/// This table stores pending, in-progress, and failed sync operations
/// that will be processed when network connectivity is available.
class SyncJobsTable {
  static const String tableName = 'sync_jobs';

  // Column names
  static const String columnId = 'id';
  static const String columnJobType = 'job_type';
  static const String columnTargetId = 'target_id';
  static const String columnPayload = 'payload';
  static const String columnStatus = 'status';
  static const String columnPriority = 'priority';
  static const String columnAttempts = 'attempts';
  static const String columnNextRetryAt = 'next_retry_at';
  static const String columnLastError = 'last_error';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  /// Map of column names for easy reference
  static const Map<String, String> columns = {
    'id': columnId,
    'jobType': columnJobType,
    'targetId': columnTargetId,
    'payload': columnPayload,
    'status': columnStatus,
    'priority': columnPriority,
    'attempts': columnAttempts,
    'nextRetryAt': columnNextRetryAt,
    'lastError': columnLastError,
    'createdAt': columnCreatedAt,
    'updatedAt': columnUpdatedAt,
  };

  /// Returns the SQL query to create the sync_jobs table
  static String createTableQuery() {
    return '''
      CREATE TABLE $tableName (
        $columnId TEXT PRIMARY KEY,
        $columnJobType TEXT NOT NULL,
        $columnTargetId TEXT NOT NULL,
        $columnPayload TEXT NOT NULL,
        $columnStatus TEXT NOT NULL DEFAULT 'pending',
        $columnPriority INTEGER NOT NULL DEFAULT 1,
        $columnAttempts INTEGER NOT NULL DEFAULT 0,
        $columnNextRetryAt INTEGER,
        $columnLastError TEXT,
        $columnCreatedAt INTEGER NOT NULL,
        $columnUpdatedAt INTEGER NOT NULL,
        UNIQUE($columnJobType, $columnTargetId)
      )
    ''';
  }

  /// Returns indices to improve query performance
  static List<String> createIndices() {
    return [
      'CREATE INDEX idx_sync_jobs_status ON $tableName($columnStatus)',
      'CREATE INDEX idx_sync_jobs_next_retry ON $tableName($columnNextRetryAt)',
      'CREATE INDEX idx_sync_jobs_type_target ON $tableName($columnJobType, $columnTargetId)',
      'CREATE INDEX idx_sync_jobs_priority ON $tableName($columnPriority DESC, $columnCreatedAt ASC)',
    ];
  }

  /// Returns migration queries for version 12
  static List<String> migrationV12() {
    return [createTableQuery(), ...createIndices()];
  }
}
