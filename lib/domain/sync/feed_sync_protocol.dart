import 'progress_sync_protocol.dart';

/// Result of a feed sync operation
class FeedSyncResult {
  /// ID of the feed that was synced
  final String feedId;

  /// Number of items added
  final int itemsAdded;

  /// Number of items updated
  final int itemsUpdated;

  /// Number of starred items merged from other devices
  final int starredMerged;

  /// Number of read state changes merged
  final int readStateMerged;

  /// Errors that occurred during sync
  final List<SyncError> errors;

  /// When the sync completed
  final DateTime syncedAt;

  const FeedSyncResult({
    required this.feedId,
    required this.itemsAdded,
    required this.itemsUpdated,
    required this.starredMerged,
    required this.readStateMerged,
    required this.errors,
    required this.syncedAt,
  });

  /// Whether any errors occurred
  bool get hasErrors => errors.isNotEmpty;

  /// Whether the sync was successful
  bool get isSuccessful => errors.isEmpty;

  @override
  String toString() =>
      'FeedSyncResult(feed: $feedId, +$itemsAdded ~$itemsUpdated, '
      'starred: $starredMerged, read: $readStateMerged)';
}

/// Protocol for synchronizing RSS/Atom feeds
///
/// Implementations handle refreshing feed content and syncing
/// read/starred state across devices.
abstract class FeedSyncProtocol {
  /// Sync all feeds
  ///
  /// Returns results for each feed that was synced
  Future<List<FeedSyncResult>> syncAllFeeds();

  /// Sync a specific feed
  ///
  /// [feedId] The local feed ID
  /// [feedUrl] The URL of the feed
  Future<FeedSyncResult> syncFeed({
    required String feedId,
    required String feedUrl,
  });

  /// Merge starred state across devices
  ///
  /// Uses union merge: items starred on any device stay starred
  /// [feedId] The feed to merge starred items for
  /// [remoteStarredIds] IDs of items starred on other devices
  Future<void> mergeStarredState({
    required String feedId,
    required List<String> remoteStarredIds,
  });

  /// Get items that need to sync their starred state
  ///
  /// [feedId] The feed to check
  Future<List<String>> getLocalStarredIds(String feedId);
}
