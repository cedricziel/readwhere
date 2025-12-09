import 'package:flutter/foundation.dart';
import 'package:readwhere_opds/readwhere_opds.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

import '../api/kavita_api_client.dart';
import '../models/kavita_progress.dart';

/// Callback for importing a downloaded book file.
///
/// Returns the imported book ID if successful.
typedef KavitaBookImportCallback =
    Future<String?> Function(
      String filePath, {
      String? sourceCatalogId,
      String? sourceEntryId,
    });

/// Callback for fetching catalog info by ID.
typedef CatalogLookup = Future<KavitaCatalogInfo?> Function(String catalogId);

/// Minimal catalog info needed for Kavita progress sync.
class KavitaCatalogInfo {
  final String id;
  final String url;
  final String? apiKey;

  const KavitaCatalogInfo({required this.id, required this.url, this.apiKey});
}

/// Minimal book info needed for progress sync.
class KavitaBookInfo {
  final String? sourceCatalogId;
  final String? sourceEntryId;

  const KavitaBookInfo({this.sourceCatalogId, this.sourceEntryId});

  bool get isFromCatalog => sourceCatalogId != null;
}

/// State provider for Kavita server browsing and progress sync.
///
/// Composes [OpdsProvider] internally for OPDS feed browsing, since Kavita
/// servers expose an OPDS interface. Adds Kavita-specific functionality:
/// - Reading progress sync (get and update)
/// - Kavita entry ID parsing
///
/// This provider extends [BrowsingProvider] for common interface compliance
/// and forwards [OpdsProvider] state changes to its own listeners.
class KavitaProvider extends BrowsingProvider {
  final KavitaApiClient _kavitaClient;
  final OpdsProvider _opdsProvider;
  final CatalogLookup? _catalogLookup;

  KavitaProvider({
    required KavitaApiClient kavitaClient,
    required OpdsProvider opdsProvider,
    CatalogLookup? catalogLookup,
  }) : _kavitaClient = kavitaClient,
       _opdsProvider = opdsProvider,
       _catalogLookup = catalogLookup {
    // Forward OpdsProvider notifications to our listeners
    _opdsProvider.addListener(_onOpdsProviderChanged);
  }

  void _onOpdsProviderChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _opdsProvider.removeListener(_onOpdsProviderChanged);
    super.dispose();
  }

  // ===== Delegate BrowsingProvider interface to OpdsProvider =====

  @override
  bool get isLoading => _opdsProvider.isLoading;

  @override
  String? get error => _opdsProvider.error;

  @override
  void clearError() => _opdsProvider.clearError();

  @override
  bool get canNavigateBack => _opdsProvider.canNavigateBack;

  @override
  List<String> get breadcrumbs => _opdsProvider.breadcrumbs;

  @override
  Future<bool> navigateBack() => _opdsProvider.navigateBack();

  @override
  Future<void> refresh() => _opdsProvider.refresh();

  @override
  void closeBrowser() => _opdsProvider.closeBrowser();

  @override
  double? getDownloadProgress(String itemId) =>
      _opdsProvider.getDownloadProgress(itemId);

  @override
  bool isDownloaded(String itemId) => _opdsProvider.isDownloaded(itemId);

  // ===== Delegate OPDS-specific operations =====

  /// The current OPDS feed being displayed
  OpdsFeed? get currentFeed => _opdsProvider.currentFeed;

  /// Current search query
  String get searchQuery => _opdsProvider.searchQuery;

  /// Whether currently searching
  bool get isSearching => _opdsProvider.isSearching;

  /// Whether feed data came from cache
  bool get isFromCache => _opdsProvider.isFromCache;

  /// When the cached data was stored
  DateTime? get cachedAt => _opdsProvider.cachedAt;

  /// Human-readable cache age text
  String get cacheAgeText => _opdsProvider.cacheAgeText;

  /// Whether cached data is still fresh
  bool get isCacheFresh => _opdsProvider.isCacheFresh;

  /// Get book ID for a downloaded entry
  String? getBookIdForEntry(String entryId) =>
      _opdsProvider.getBookIdForEntry(entryId);

  /// Open a Kavita catalog
  ///
  /// [catalogId] - Unique identifier for the catalog
  /// [serverUrl] - Base Kavita server URL
  /// [apiKey] - User's OPDS API key for this Kavita server
  /// [strategy] - Optional fetch strategy
  Future<void> openCatalog({
    required String catalogId,
    required String serverUrl,
    required String apiKey,
    FetchStrategy strategy = FetchStrategy.networkFirst,
  }) async {
    // Construct Kavita OPDS URL from base URL and API key
    final baseUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    final opdsUrl = '$baseUrl/api/opds/$apiKey';

    await _opdsProvider.openCatalog(
      catalogId: catalogId,
      catalogUrl: opdsUrl,
      strategy: strategy,
    );
  }

  /// Navigate to a feed via a link
  Future<void> navigateToFeed(
    OpdsLink link, {
    FetchStrategy strategy = FetchStrategy.networkFirst,
  }) => _opdsProvider.navigateToFeed(link, strategy: strategy);

  /// Fetch next page of current feed
  Future<void> loadNextPage() => _opdsProvider.loadNextPage();

  /// Search within the current catalog
  Future<void> search(String query) => _opdsProvider.search(query);

  /// Clear search and return to previous feed
  void clearSearch() => _opdsProvider.clearSearch();

  /// Download and import a book from a Kavita OPDS entry
  Future<String?> downloadAndImportBook(
    OpdsEntry entry, {
    Set<String> supportedFormats = const {'epub', 'cbz', 'cbr', 'pdf'},
  }) => _opdsProvider.downloadAndImportBook(
    entry,
    supportedFormats: supportedFormats,
  );

  /// Mark entries as already downloaded
  void setDownloadedEntries(Map<String, String> entryIdToBookId) =>
      _opdsProvider.setDownloadedEntries(entryIdToBookId);

  // ===== Kavita-Specific Operations =====

  /// Sync reading progress to Kavita server
  ///
  /// Call this when closing a book that came from a Kavita catalog.
  /// [book] - Book info with source catalog and entry IDs
  /// [pageNum] - Current page number
  Future<void> syncProgressToKavita({
    required KavitaBookInfo book,
    required int pageNum,
  }) async {
    if (!book.isFromCatalog || book.sourceCatalogId == null) return;
    if (_catalogLookup == null) return;

    try {
      final catalog = await _catalogLookup(book.sourceCatalogId!);
      if (catalog == null || catalog.apiKey == null) {
        return;
      }

      // Parse Kavita IDs from source entry ID
      final ids = parseKavitaEntryId(book.sourceEntryId);
      if (ids == null) return;

      final progress = KavitaProgress(
        chapterId: ids.chapterId,
        volumeId: ids.volumeId,
        seriesId: ids.seriesId,
        libraryId: ids.libraryId,
        pageNum: pageNum,
      );

      await _kavitaClient.updateProgress(
        catalog.url,
        catalog.apiKey!,
        progress,
      );

      debugPrint('KavitaProvider: Synced progress to Kavita: page $pageNum');
    } catch (e) {
      debugPrint('KavitaProvider: Failed to sync progress to Kavita: $e');
    }
  }

  /// Fetch reading progress from Kavita server
  ///
  /// [book] - Book info with source catalog and entry IDs
  /// Returns the progress if available, null otherwise.
  Future<KavitaProgress?> fetchProgressFromKavita(KavitaBookInfo book) async {
    if (!book.isFromCatalog || book.sourceCatalogId == null) return null;
    if (_catalogLookup == null) return null;

    try {
      final catalog = await _catalogLookup(book.sourceCatalogId!);
      if (catalog == null || catalog.apiKey == null) {
        return null;
      }

      // Parse chapter ID from source entry ID
      final ids = parseKavitaEntryId(book.sourceEntryId);
      if (ids == null || ids.chapterId == 0) return null;

      return await _kavitaClient.getProgress(
        catalog.url,
        catalog.apiKey!,
        ids.chapterId,
      );
    } catch (e) {
      debugPrint('KavitaProvider: Failed to fetch progress from Kavita: $e');
      return null;
    }
  }

  /// Parse Kavita IDs from a source entry ID
  ///
  /// Entry ID format: "kavita:chapterId:volumeId:seriesId:libraryId"
  /// Returns null if the format is invalid.
  static KavitaEntryIds? parseKavitaEntryId(String? entryId) {
    if (entryId == null) return null;

    final parts = entryId.split(':');
    if (parts.length < 5 || parts[0] != 'kavita') return null;

    final chapterId = int.tryParse(parts[1]) ?? 0;
    final volumeId = int.tryParse(parts[2]) ?? 0;
    final seriesId = int.tryParse(parts[3]) ?? 0;
    final libraryId = int.tryParse(parts[4]) ?? 0;

    return KavitaEntryIds(
      chapterId: chapterId,
      volumeId: volumeId,
      seriesId: seriesId,
      libraryId: libraryId,
    );
  }

  /// Build a Kavita entry ID string
  ///
  /// Format: "kavita:chapterId:volumeId:seriesId:libraryId"
  static String buildKavitaEntryId({
    required int chapterId,
    required int volumeId,
    required int seriesId,
    required int libraryId,
  }) {
    return 'kavita:$chapterId:$volumeId:$seriesId:$libraryId';
  }
}

/// Parsed Kavita entry IDs
class KavitaEntryIds {
  final int chapterId;
  final int volumeId;
  final int seriesId;
  final int libraryId;

  const KavitaEntryIds({
    required this.chapterId,
    required this.volumeId,
    required this.seriesId,
    required this.libraryId,
  });
}
