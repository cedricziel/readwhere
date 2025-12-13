/// Error that occurred during sync
class SyncError {
  /// ID of the record that failed
  final String recordId;

  /// Operation that failed
  final String operation;

  /// Error message
  final String message;

  const SyncError({
    required this.recordId,
    required this.operation,
    required this.message,
  });

  @override
  String toString() => 'SyncError($operation on $recordId: $message)';
}

/// Result of a progress sync operation
class ProgressSyncResult {
  /// Number of records uploaded to remote
  final int uploaded;

  /// Number of records downloaded from remote
  final int downloaded;

  /// Number of records that required merge
  final int merged;

  /// Number of unresolved conflicts
  final int conflicts;

  /// Errors that occurred during sync
  final List<SyncError> errors;

  /// When the sync completed
  final DateTime syncedAt;

  const ProgressSyncResult({
    required this.uploaded,
    required this.downloaded,
    required this.merged,
    required this.conflicts,
    required this.errors,
    required this.syncedAt,
  });

  /// Whether any errors occurred
  bool get hasErrors => errors.isNotEmpty;

  /// Whether the sync was fully successful
  bool get isFullySuccessful => errors.isEmpty && conflicts == 0;

  /// Create a successful result with no operations
  const ProgressSyncResult.empty()
    : uploaded = 0,
      downloaded = 0,
      merged = 0,
      conflicts = 0,
      errors = const [],
      syncedAt = const Duration(milliseconds: 0) as DateTime;

  @override
  String toString() =>
      'ProgressSyncResult(up: $uploaded, down: $downloaded, merged: $merged, '
      'conflicts: $conflicts, errors: ${errors.length})';
}

/// Strategies for resolving sync conflicts
enum ConflictResolutionStrategy {
  /// Use the record with highest progress (default for reading progress)
  furthestProgress,

  /// Use the most recently updated record
  mostRecent,

  /// Always prefer local changes
  preferLocal,

  /// Always prefer remote changes
  preferRemote,
}

/// Protocol for synchronizing reading progress with remote servers
///
/// Implementations handle the two-way sync of reading progress
/// with catalog servers that support progress tracking (e.g., Kavita).
abstract class ProgressSyncProtocol {
  /// Perform full bidirectional sync for a catalog
  ///
  /// [catalogId] The catalog to sync progress for
  /// [forceFullSync] If true, sync all books regardless of dirty state
  Future<ProgressSyncResult> syncAll({
    required String catalogId,
    bool forceFullSync = false,
  });

  /// Sync progress for a single book
  ///
  /// [catalogId] The catalog the book belongs to
  /// [bookId] The local book ID
  /// [remoteBookId] The remote server book identifier
  Future<void> syncBook({
    required String catalogId,
    required String bookId,
    required String remoteBookId,
  });

  /// Push all dirty local records to remote
  ///
  /// [catalogId] The catalog to push changes for
  Future<int> pushDirtyRecords({required String catalogId});

  /// Pull changes from remote server
  ///
  /// [catalogId] The catalog to pull from
  Future<int> pullRemoteChanges({required String catalogId});
}
