import '../core/plugin_base.dart';
import '../entities/catalog_info.dart';

/// Capability for syncing reading progress with a remote server.
///
/// Used by services like Kavita that track reading progress
/// across devices. Not all catalog providers support this -
/// only those with progress tracking APIs.
///
/// Example:
/// ```dart
/// class KavitaPlugin extends PluginBase
///     with CatalogCapability, AccountCapability, ProgressSyncCapability {
///
///   @override
///   Future<void> syncProgress({
///     required CatalogInfo catalog,
///     required String bookIdentifier,
///     required ReadingProgressData progress,
///   }) async {
///     final ids = _parseKavitaEntryId(bookIdentifier);
///     await _apiClient.updateProgress(
///       catalog.url,
///       catalog.providerConfig['apiKey'],
///       KavitaProgress(
///         chapterId: ids.chapterId,
///         pageNum: progress.pageNumber,
///       ),
///     );
///   }
///
///   // ... implement other methods
/// }
/// ```
mixin ProgressSyncCapability on PluginBase {
  /// Sync reading progress to the remote server.
  ///
  /// [catalog] The source catalog containing server credentials.
  /// [bookIdentifier] Server-specific book identifier.
  ///   Format depends on the server (e.g., for Kavita: 'kavita:chapterId:volumeId:seriesId:libraryId').
  /// [progress] The reading progress to sync.
  ///
  /// Throws on sync failure with an appropriate error message.
  Future<void> syncProgress({
    required CatalogInfo catalog,
    required String bookIdentifier,
    required ReadingProgressData progress,
  });

  /// Fetch reading progress from the remote server.
  ///
  /// [catalog] The source catalog containing server credentials.
  /// [bookIdentifier] Server-specific book identifier.
  ///
  /// Returns null if no progress is stored on the server.
  Future<ReadingProgressData?> fetchProgress({
    required CatalogInfo catalog,
    required String bookIdentifier,
  });

  /// Mark a book as complete on the server.
  ///
  /// [catalog] The source catalog.
  /// [bookIdentifier] Server-specific book identifier.
  ///
  /// Default implementation syncs with 100% progress.
  Future<void> markAsComplete({
    required CatalogInfo catalog,
    required String bookIdentifier,
  }) async {
    await syncProgress(
      catalog: catalog,
      bookIdentifier: bookIdentifier,
      progress: ReadingProgressData(
        pageNumber: -1, // Server should interpret as complete
        percentage: 1.0,
        updatedAt: DateTime.now(),
        isComplete: true,
      ),
    );
  }

  /// Clear reading progress on the server.
  ///
  /// [catalog] The source catalog.
  /// [bookIdentifier] Server-specific book identifier.
  ///
  /// Default implementation syncs with 0% progress.
  Future<void> clearProgress({
    required CatalogInfo catalog,
    required String bookIdentifier,
  }) async {
    await syncProgress(
      catalog: catalog,
      bookIdentifier: bookIdentifier,
      progress: ReadingProgressData(
        pageNumber: 0,
        percentage: 0.0,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Fetch progress for multiple books at once.
  ///
  /// More efficient than calling [fetchProgress] multiple times
  /// if the server supports batch queries.
  ///
  /// Returns a map of book identifiers to progress data.
  /// Books without progress are not included in the result.
  ///
  /// Default implementation calls [fetchProgress] for each book.
  Future<Map<String, ReadingProgressData>> fetchProgressBatch({
    required CatalogInfo catalog,
    required List<String> bookIdentifiers,
  }) async {
    final results = <String, ReadingProgressData>{};
    for (final id in bookIdentifiers) {
      final progress = await fetchProgress(
        catalog: catalog,
        bookIdentifier: id,
      );
      if (progress != null) {
        results[id] = progress;
      }
    }
    return results;
  }
}

/// Reading progress data for sync.
class ReadingProgressData {
  /// Current page number (1-indexed).
  ///
  /// For EPUB/reflowable content, this may be an approximation
  /// or a virtual page number.
  final int pageNumber;

  /// Progress percentage (0.0 to 1.0).
  final double percentage;

  /// CFI (Canonical Fragment Identifier) for precise positioning.
  ///
  /// Used primarily for EPUB content to restore exact position.
  final String? cfi;

  /// Chapter index (0-indexed).
  final int? chapterIndex;

  /// When the progress was recorded.
  final DateTime updatedAt;

  /// Whether the book has been marked as complete.
  final bool isComplete;

  /// Device identifier for multi-device sync.
  ///
  /// Helps track which device last updated progress.
  final String? deviceId;

  /// Creates reading progress data.
  const ReadingProgressData({
    required this.pageNumber,
    required this.percentage,
    this.cfi,
    this.chapterIndex,
    required this.updatedAt,
    this.isComplete = false,
    this.deviceId,
  });

  /// Creates progress data from a percentage.
  factory ReadingProgressData.fromPercentage(
    double percentage, {
    int? pageNumber,
    String? cfi,
    int? chapterIndex,
    bool isComplete = false,
    String? deviceId,
  }) {
    return ReadingProgressData(
      pageNumber: pageNumber ?? (percentage * 100).round(),
      percentage: percentage.clamp(0.0, 1.0),
      cfi: cfi,
      chapterIndex: chapterIndex,
      updatedAt: DateTime.now(),
      isComplete: isComplete || percentage >= 1.0,
      deviceId: deviceId,
    );
  }

  /// Whether this progress is newer than another.
  bool isNewerThan(ReadingProgressData other) {
    return updatedAt.isAfter(other.updatedAt);
  }

  /// Merge with another progress, keeping the more recent one.
  ReadingProgressData mergeWith(ReadingProgressData other) {
    return isNewerThan(other) ? this : other;
  }

  @override
  String toString() =>
      'ReadingProgressData('
      'page: $pageNumber, '
      '${(percentage * 100).toStringAsFixed(1)}%, '
      'complete: $isComplete, '
      'updated: $updatedAt'
      ')';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingProgressData &&
          pageNumber == other.pageNumber &&
          percentage == other.percentage &&
          cfi == other.cfi &&
          isComplete == other.isComplete;

  @override
  int get hashCode => Object.hash(pageNumber, percentage, cfi, isComplete);
}
