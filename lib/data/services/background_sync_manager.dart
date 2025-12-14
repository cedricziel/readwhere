import 'dart:async';

import '../../core/background/background_constraints.dart';
import '../../core/background/background_executor.dart';
import '../../core/background/background_task.dart';
import '../../domain/entities/sync_job.dart';
import '../../domain/services/connectivity_service.dart';
import '../../presentation/providers/sync_settings_provider.dart';
import 'catalog_sync_service.dart';
import 'feed_sync_service.dart';
import 'nextcloud_news_sync_service.dart';
import 'progress_sync_service.dart';
import 'sync_queue_service.dart';

/// Task IDs for background execution
class SyncTaskIds {
  static const String periodicSync = 'com.readwhere.sync.periodic';
  static const String immediateSync = 'com.readwhere.sync.immediate';
}

/// Status of the sync manager
enum SyncStatus { idle, syncing, error }

/// Orchestrates all background sync operations.
///
/// Responsibilities:
/// - Listens to connectivity changes
/// - Processes sync job queue when conditions are met
/// - Coordinates sync protocols (progress, catalog, feed)
/// - Schedules background tasks
class BackgroundSyncManager {
  final ConnectivityService _connectivityService;
  final SyncSettingsProvider _settingsProvider;
  final SyncQueueService _queueService;
  final ProgressSyncService _progressSyncService;
  final CatalogSyncService _catalogSyncService;
  final FeedSyncService _feedSyncService;
  final NextcloudNewsSyncService? _nextcloudNewsSyncService;
  final BackgroundExecutor _backgroundExecutor;

  StreamSubscription<ConnectionStatus>? _connectivitySubscription;
  String? _periodicExecutionId;
  bool _initialized = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _lastError;

  /// Stream controller for sync status updates
  final _statusController = StreamController<SyncStatus>.broadcast();

  /// Stream of sync status updates
  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// Current sync status
  SyncStatus get status {
    if (_isSyncing) return SyncStatus.syncing;
    if (_lastError != null) return SyncStatus.error;
    return SyncStatus.idle;
  }

  /// Last sync timestamp
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Last error message if any
  String? get lastError => _lastError;

  /// Whether sync is currently in progress
  bool get isSyncing => _isSyncing;

  BackgroundSyncManager({
    required ConnectivityService connectivityService,
    required SyncSettingsProvider settingsProvider,
    required SyncQueueService queueService,
    required ProgressSyncService progressSyncService,
    required CatalogSyncService catalogSyncService,
    required FeedSyncService feedSyncService,
    NextcloudNewsSyncService? nextcloudNewsSyncService,
    required BackgroundExecutor backgroundExecutor,
  }) : _connectivityService = connectivityService,
       _settingsProvider = settingsProvider,
       _queueService = queueService,
       _progressSyncService = progressSyncService,
       _catalogSyncService = catalogSyncService,
       _feedSyncService = feedSyncService,
       _nextcloudNewsSyncService = nextcloudNewsSyncService,
       _backgroundExecutor = backgroundExecutor;

  /// Initialize the sync manager.
  ///
  /// Sets up connectivity listeners and schedules periodic sync.
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize background executor
    await _backgroundExecutor.initialize();

    // Register task handlers
    _backgroundExecutor.registerTask(
      SyncTaskIds.periodicSync,
      _handlePeriodicSyncTask,
    );
    _backgroundExecutor.registerTask(
      SyncTaskIds.immediateSync,
      _handleImmediateSyncTask,
    );

    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen(_onConnectivityChanged);

    // Listen to settings changes
    _settingsProvider.addListener(_onSettingsChanged);

    // Schedule periodic sync if enabled
    await _schedulePeriodicSyncIfNeeded();

    _initialized = true;
  }

  /// Handle connectivity changes.
  Future<void> _onConnectivityChanged(ConnectionStatus status) async {
    if (!_settingsProvider.syncEnabled) return;

    final canSync = _connectivityService.canSync(
      wifiOnlyEnabled: _settingsProvider.wifiOnly,
    );
    if (canSync) {
      // We just came online, process any pending jobs
      await processPendingJobs();
    }
  }

  /// Handle settings changes.
  Future<void> _onSettingsChanged() async {
    await _schedulePeriodicSyncIfNeeded();
  }

  /// Schedule periodic sync based on settings.
  Future<void> _schedulePeriodicSyncIfNeeded() async {
    // Cancel existing periodic task
    if (_periodicExecutionId != null) {
      await _backgroundExecutor.cancelTask(_periodicExecutionId!);
      _periodicExecutionId = null;
    }

    if (!_settingsProvider.syncEnabled) return;

    final intervalMinutes = _settingsProvider.syncIntervalMinutes;
    final frequency = Duration(minutes: intervalMinutes);

    // Determine constraints based on WiFi-only setting
    final constraints = _settingsProvider.wifiOnly
        ? BackgroundConstraints.wifiOnly
        : BackgroundConstraints.syncDefaults;

    final task = BackgroundTask(
      taskId: SyncTaskIds.periodicSync,
      name: 'Periodic Sync',
    );

    _periodicExecutionId = await _backgroundExecutor.schedulePeriodic(
      task,
      frequency: frequency,
      constraints: constraints,
    );
  }

  /// Handler for periodic sync background task.
  Future<BackgroundTaskResult> _handlePeriodicSyncTask(
    BackgroundTask task,
  ) async {
    try {
      await processPendingJobs();
      return const BackgroundTaskResult.success();
    } catch (e) {
      return BackgroundTaskResult.failure(e.toString());
    }
  }

  /// Handler for immediate sync background task.
  Future<BackgroundTaskResult> _handleImmediateSyncTask(
    BackgroundTask task,
  ) async {
    try {
      await processPendingJobs();
      return const BackgroundTaskResult.success();
    } catch (e) {
      return BackgroundTaskResult.failure(e.toString());
    }
  }

  /// Trigger an immediate sync.
  ///
  /// This processes all pending jobs if network conditions are met.
  Future<void> syncNow() async {
    if (!_settingsProvider.syncEnabled) return;
    if (_isSyncing) return;

    final canSync = _connectivityService.canSync(
      wifiOnlyEnabled: _settingsProvider.wifiOnly,
    );
    if (!canSync) {
      _lastError = 'Network conditions not met for sync';
      _statusController.add(status);
      return;
    }

    await processPendingJobs();
  }

  /// Process all pending sync jobs.
  Future<void> processPendingJobs() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _lastError = null;
    _statusController.add(SyncStatus.syncing);

    try {
      // Process jobs in batches
      const batchSize = 10;
      var hasMore = true;

      while (hasMore) {
        final jobs = await _queueService.getNextBatch(limit: batchSize);
        if (jobs.isEmpty) {
          hasMore = false;
          continue;
        }

        for (final job in jobs) {
          await _processJob(job);
        }
      }

      _lastSyncTime = DateTime.now();
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isSyncing = false;
      _statusController.add(status);
    }
  }

  /// Process a single sync job.
  Future<void> _processJob(SyncJob job) async {
    try {
      // Mark as in progress
      await _queueService.startJob(job.id);

      switch (job.type) {
        case SyncJobType.progress:
          await _processProgressJob(job);
        case SyncJobType.catalog:
          await _processCatalogJob(job);
        case SyncJobType.feed:
          await _processFeedJob(job);
        case SyncJobType.nextcloudNews:
          await _processNextcloudNewsJob(job);
      }

      // Mark job as completed
      await _queueService.completeJob(job.id);
    } catch (e) {
      // Handle failure with retry logic
      await _queueService.handleFailure(job.id, e.toString());
    }
  }

  /// Process a progress sync job.
  Future<void> _processProgressJob(SyncJob job) async {
    if (!_settingsProvider.progressSyncEnabled) return;

    final payload = job.payload;
    final bookId = payload['bookId'] as String?;
    final catalogId = payload['sourceCatalogId'] as String?;
    final entryId = payload['sourceEntryId'] as String?;

    if (bookId == null || catalogId == null || entryId == null) return;

    await _progressSyncService.syncBook(
      catalogId: catalogId,
      bookId: bookId,
      remoteBookId: entryId,
    );
  }

  /// Process a catalog sync job.
  Future<void> _processCatalogJob(SyncJob job) async {
    if (!_settingsProvider.catalogSyncEnabled) return;

    final catalogId = job.targetId;
    await _catalogSyncService.refreshCatalog(catalogId);
  }

  /// Process a feed sync job.
  Future<void> _processFeedJob(SyncJob job) async {
    if (!_settingsProvider.feedSyncEnabled) return;

    final payload = job.payload;
    final feedId = payload['feedId'] as String? ?? job.targetId;
    final feedUrl = payload['feedUrl'] as String?;

    if (feedUrl == null) return;

    await _feedSyncService.syncFeed(feedId: feedId, feedUrl: feedUrl);
  }

  /// Process a Nextcloud News sync job.
  Future<void> _processNextcloudNewsJob(SyncJob job) async {
    // Check if the service is available
    final syncService = _nextcloudNewsSyncService;
    if (syncService == null) return;

    // Use feed sync enabled setting for Nextcloud News as well
    if (!_settingsProvider.feedSyncEnabled) return;

    final catalogId = job.targetId;
    await syncService.syncFromCatalog(catalogId);
  }

  /// Schedule a progress sync for a book.
  ///
  /// Called when user closes a book to queue the progress sync.
  Future<void> scheduleProgressSync({
    required String bookId,
    String? sourceCatalogId,
    String? sourceEntryId,
    double? progress,
    String? cfi,
  }) async {
    if (!_settingsProvider.syncEnabled) return;
    if (!_settingsProvider.progressSyncEnabled) return;
    if (sourceCatalogId == null) return;
    if (sourceEntryId == null) return;

    await _queueService.enqueueProgressSync(
      bookId: bookId,
      sourceCatalogId: sourceCatalogId,
      sourceEntryId: sourceEntryId,
      progress: progress ?? 0.0,
      cfi: cfi,
    );

    // Try to sync immediately if conditions are met
    final canSync = _connectivityService.canSync(
      wifiOnlyEnabled: _settingsProvider.wifiOnly,
    );
    if (canSync) {
      await processPendingJobs();
    }
  }

  /// Schedule a catalog sync.
  ///
  /// [catalogId] - The ID of the catalog to sync
  /// [catalogType] - The type of catalog (e.g., 'opds', 'kavita')
  /// [feedUrl] - Optional feed URL for the catalog
  Future<void> scheduleCatalogSync({
    required String catalogId,
    required String catalogType,
    String? feedUrl,
  }) async {
    if (!_settingsProvider.syncEnabled) return;
    if (!_settingsProvider.catalogSyncEnabled) return;

    await _queueService.enqueueCatalogSync(
      catalogId: catalogId,
      catalogType: catalogType,
      feedUrl: feedUrl,
    );
  }

  /// Schedule a feed sync.
  ///
  /// [feedId] - The ID of the feed to sync
  /// [feedUrl] - The URL of the feed
  Future<void> scheduleFeedSync({
    required String feedId,
    required String feedUrl,
  }) async {
    if (!_settingsProvider.syncEnabled) return;
    if (!_settingsProvider.feedSyncEnabled) return;

    await _queueService.enqueueFeedSync(feedId: feedId, feedUrl: feedUrl);
  }

  /// Schedule a Nextcloud News sync.
  ///
  /// Syncs RSS feeds and article state from a Nextcloud catalog's News app.
  /// [catalogId] - The ID of the Nextcloud catalog with News sync enabled
  Future<void> scheduleNextcloudNewsSync({required String catalogId}) async {
    if (!_settingsProvider.syncEnabled) return;
    if (!_settingsProvider.feedSyncEnabled) return;
    if (_nextcloudNewsSyncService == null) return;

    await _queueService.enqueueNextcloudNewsSync(catalogId: catalogId);
  }

  /// Clear the last error.
  void clearError() {
    _lastError = null;
    _statusController.add(status);
  }

  /// Dispose resources.
  void dispose() {
    _connectivitySubscription?.cancel();
    _settingsProvider.removeListener(_onSettingsChanged);
    _backgroundExecutor.dispose();
    _statusController.close();
    _initialized = false;
  }
}
