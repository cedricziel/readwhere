import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/opds/cached_opds_feed_model.dart';
import '../../data/services/book_import_service.dart';
import '../../data/services/kavita_api_service.dart';
import '../../data/services/opds_cache_service.dart';
import '../../data/services/opds_client_service.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/catalog.dart';
import '../../domain/entities/opds_entry.dart';
import '../../domain/entities/opds_feed.dart';
import '../../domain/entities/opds_link.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/repositories/catalog_repository.dart';

/// Provider for managing OPDS catalog state and operations
///
/// This provider handles:
/// - Managing catalog (server) connections
/// - Browsing OPDS feeds
/// - Downloading books from catalogs
/// - Progress sync with Kavita servers
class CatalogsProvider extends ChangeNotifier {
  final CatalogRepository _catalogRepository;
  final OpdsClientService _opdsClientService;
  final OpdsCacheService _cacheService;
  final KavitaApiService _kavitaApiService;
  final BookImportService _importService;
  final BookRepository _bookRepository;

  // Nextcloud integration (from readwhere_nextcloud package)
  final NextcloudProvider? _nextcloudProvider;
  final CredentialStorage? _credentialStorage;

  CatalogsProvider({
    required CatalogRepository catalogRepository,
    required OpdsClientService opdsClientService,
    required OpdsCacheService cacheService,
    required KavitaApiService kavitaApiService,
    required BookImportService importService,
    required BookRepository bookRepository,
    NextcloudProvider? nextcloudProvider,
    CredentialStorage? credentialStorage,
  }) : _catalogRepository = catalogRepository,
       _opdsClientService = opdsClientService,
       _cacheService = cacheService,
       _kavitaApiService = kavitaApiService,
       _importService = importService,
       _bookRepository = bookRepository,
       _nextcloudProvider = nextcloudProvider,
       _credentialStorage = credentialStorage;

  // State
  List<Catalog> _catalogs = [];
  Catalog? _selectedCatalog;
  OpdsFeed? _currentFeed;
  final List<OpdsFeed> _navigationStack = [];
  final List<String> _navigationUrlStack = [];
  String? _currentFeedUrl;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  final Map<String, double> _downloadProgress = {};
  final Set<String> _downloadedEntryIds = {};
  final Map<String, String> _entryIdToBookId = {};

  // Cache state
  bool _isFromCache = false;
  DateTime? _cachedAt;
  DateTime? _cacheExpiresAt;

  // Nextcloud state - delegates to NextcloudProvider from package
  // Local state kept for backward compatibility with existing UI

  // Getters
  List<Catalog> get catalogs => List.unmodifiable(_catalogs);
  Catalog? get selectedCatalog => _selectedCatalog;
  OpdsFeed? get currentFeed => _currentFeed;
  List<OpdsFeed> get navigationStack => List.unmodifiable(_navigationStack);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int get catalogCount => _catalogs.length;

  // Cache getters
  bool get isFromCache => _isFromCache;
  DateTime? get cachedAt => _cachedAt;
  DateTime? get cacheExpiresAt => _cacheExpiresAt;

  /// Whether the cached data is still fresh (not expired)
  bool get isCacheFresh =>
      !_isFromCache ||
      (_cacheExpiresAt != null && DateTime.now().isBefore(_cacheExpiresAt!));

  /// Human-readable cache age text
  String get cacheAgeText {
    if (!_isFromCache || _cachedAt == null) return '';
    final age = DateTime.now().difference(_cachedAt!);
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }

  // Nextcloud getters - delegate to NextcloudProvider
  String? get oAuthLoginUrl => _nextcloudProvider?.pendingOAuthFlow?.loginUrl;
  bool get isPollingOAuth => _nextcloudProvider?.isPollingOAuth ?? false;
  String get currentNextcloudPath => _nextcloudProvider?.currentPath ?? '/';
  List<NextcloudFile> get nextcloudFiles => _nextcloudProvider?.files ?? [];
  bool get canNavigateNextcloudBack =>
      (_nextcloudProvider?.breadcrumbs.length ?? 0) > 1;

  /// Whether we can navigate back in the feed stack
  bool get canNavigateBack => _navigationStack.isNotEmpty;

  /// Get the breadcrumb titles for navigation
  List<String> get breadcrumbs {
    final crumbs = <String>[];
    if (_selectedCatalog != null) {
      crumbs.add(_selectedCatalog!.name);
    }
    for (final feed in _navigationStack) {
      crumbs.add(feed.title);
    }
    if (_currentFeed != null && _navigationStack.isEmpty) {
      // Don't duplicate root feed title
    } else if (_currentFeed != null) {
      crumbs.add(_currentFeed!.title);
    }
    return crumbs;
  }

  // Catalog Management

  /// Load all catalogs from the repository
  Future<void> loadCatalogs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _catalogs = await _catalogRepository.getAll();
      await _loadDownloadedEntryIds();
    } catch (e) {
      _error = 'Failed to load catalogs: $e';
      _catalogs = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load entry IDs of books already downloaded from catalogs
  Future<void> _loadDownloadedEntryIds() async {
    try {
      final books = await _bookRepository.getAll();
      _downloadedEntryIds.clear();
      _entryIdToBookId.clear();
      for (final book in books) {
        if (book.sourceEntryId != null) {
          _downloadedEntryIds.add(book.sourceEntryId!);
          _entryIdToBookId[book.sourceEntryId!] = book.id;
        }
      }
    } catch (e) {
      debugPrint('Failed to load downloaded entry IDs: $e');
    }
  }

  /// Get the book ID for a downloaded entry
  ///
  /// Returns the book ID if the entry has been downloaded, null otherwise.
  String? getBookIdForEntry(String entryId) {
    return _entryIdToBookId[entryId];
  }

  /// Validate a catalog URL and optionally authenticate
  ///
  /// Returns the parsed feed if valid, throws exception otherwise.
  Future<OpdsFeed> validateCatalog(
    String url, {
    String? apiKey,
    CatalogType type = CatalogType.opds,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String opdsUrl = url;

      // For Kavita, construct OPDS URL from base URL and API key
      if (type == CatalogType.kavita && apiKey != null) {
        final baseUrl = url.endsWith('/')
            ? url.substring(0, url.length - 1)
            : url;
        opdsUrl = '$baseUrl/api/opds/$apiKey';
      }

      // Validate by fetching the root feed
      final feed = await _opdsClientService.validateCatalog(opdsUrl);
      return feed;
    } catch (e) {
      _error = 'Validation failed: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new catalog (server connection)
  Future<Catalog?> addCatalog({
    required String name,
    required String url,
    String? apiKey,
    CatalogType type = CatalogType.opds,
    String? iconUrl,
    String? serverVersion,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if catalog with same URL exists
      final existing = await _catalogRepository.findByUrl(url);
      if (existing != null) {
        _error = 'A catalog with this URL already exists';
        return null;
      }

      final catalog = Catalog(
        id: const Uuid().v4(),
        name: name,
        url: url,
        iconUrl: iconUrl,
        addedAt: DateTime.now(),
        apiKey: apiKey,
        type: type,
        serverVersion: serverVersion,
      );

      final inserted = await _catalogRepository.insert(catalog);
      _catalogs.insert(0, inserted);
      return inserted;
    } catch (e) {
      _error = 'Failed to add catalog: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update an existing catalog
  Future<Catalog?> updateCatalog(Catalog catalog) async {
    _error = null;

    try {
      final updated = await _catalogRepository.update(catalog);
      final index = _catalogs.indexWhere((c) => c.id == catalog.id);
      if (index != -1) {
        _catalogs[index] = updated;
      }
      notifyListeners();
      return updated;
    } catch (e) {
      _error = 'Failed to update catalog: $e';
      notifyListeners();
      return null;
    }
  }

  /// Remove a catalog
  Future<bool> removeCatalog(String id) async {
    _error = null;

    try {
      final success = await _catalogRepository.delete(id);
      if (success) {
        _catalogs.removeWhere((c) => c.id == id);
        if (_selectedCatalog?.id == id) {
          _selectedCatalog = null;
          _currentFeed = null;
          _navigationStack.clear();
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = 'Failed to remove catalog: $e';
      notifyListeners();
      return false;
    }
  }

  // Feed Navigation

  /// Open a catalog and fetch its root feed
  ///
  /// [strategy] - Optional fetch strategy (defaults to networkFirst)
  Future<void> openCatalog(Catalog catalog, {FetchStrategy? strategy}) async {
    _isLoading = true;
    _error = null;
    _selectedCatalog = catalog;
    _navigationStack.clear();
    _navigationUrlStack.clear();
    _searchQuery = '';
    _currentFeedUrl = catalog.opdsUrl;
    notifyListeners();

    try {
      final result = await _cacheService.fetchFeed(
        catalogId: catalog.id,
        url: catalog.opdsUrl,
        strategy: strategy ?? FetchStrategy.networkFirst,
      );
      _currentFeed = result.feed;
      _updateCacheState(result);
      await _catalogRepository.updateLastAccessed(catalog.id);
    } catch (e) {
      _error = 'Failed to open catalog: $e';
      _currentFeed = null;
      _clearCacheState();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update cache state from a CachedFeedResult
  void _updateCacheState(CachedFeedResult result) {
    _isFromCache = result.isFromCache;
    _cachedAt = result.cachedAt;
    _cacheExpiresAt = result.expiresAt;
  }

  /// Clear cache state
  void _clearCacheState() {
    _isFromCache = false;
    _cachedAt = null;
    _cacheExpiresAt = null;
  }

  /// Navigate to a feed via a link
  ///
  /// [strategy] - Optional fetch strategy (defaults to networkFirst)
  Future<void> navigateToFeed(OpdsLink link, {FetchStrategy? strategy}) async {
    if (_currentFeed == null || _selectedCatalog == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Save current feed and URL to stack for back navigation
      _navigationStack.add(_currentFeed!);
      if (_currentFeedUrl != null) {
        _navigationUrlStack.add(_currentFeedUrl!);
      }

      // Resolve URL and fetch new feed
      final baseUrl = _selectedCatalog?.opdsUrl ?? '';
      final url = _opdsClientService.resolveCoverUrl(baseUrl, link.href);
      final resolvedUrl = url.isNotEmpty ? url : link.href;

      final result = await _cacheService.fetchFeed(
        catalogId: _selectedCatalog!.id,
        url: resolvedUrl,
        strategy: strategy ?? FetchStrategy.networkFirst,
      );
      _currentFeed = result.feed;
      _currentFeedUrl = resolvedUrl;
      _updateCacheState(result);
      _searchQuery = '';
    } catch (e) {
      _error = 'Failed to navigate: $e';
      // Restore previous feed
      if (_navigationStack.isNotEmpty) {
        _currentFeed = _navigationStack.removeLast();
      }
      if (_navigationUrlStack.isNotEmpty) {
        _currentFeedUrl = _navigationUrlStack.removeLast();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Navigate back in the feed stack
  void navigateBack() {
    if (_navigationStack.isEmpty) return;

    _currentFeed = _navigationStack.removeLast();
    if (_navigationUrlStack.isNotEmpty) {
      _currentFeedUrl = _navigationUrlStack.removeLast();
    }
    _searchQuery = '';
    _error = null;
    // Note: we keep the cache state from the current feed - we don't track it per-feed
    notifyListeners();
  }

  /// Clear navigation and close catalog
  void closeCatalog() {
    _selectedCatalog = null;
    _currentFeed = null;
    _currentFeedUrl = null;
    _navigationStack.clear();
    _navigationUrlStack.clear();
    _searchQuery = '';
    _error = null;
    _clearCacheState();
    notifyListeners();
  }

  /// Force refresh the current feed from network
  Future<void> refreshCurrentFeed() async {
    if (_selectedCatalog == null || _currentFeedUrl == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _cacheService.refreshFeed(
        _selectedCatalog!.id,
        _currentFeedUrl!,
      );
      _currentFeed = result.feed;
      _updateCacheState(result);
    } catch (e) {
      _error = 'Failed to refresh: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch next page of current feed
  Future<void> loadNextPage() async {
    if (_currentFeed == null || !_currentFeed!.hasNextPage) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final nextLink = _currentFeed!.nextPageLink!;
      final nextFeed = await _opdsClientService.fetchFeed(nextLink.href);

      // Merge entries
      final mergedEntries = [..._currentFeed!.entries, ...nextFeed.entries];
      _currentFeed = _currentFeed!.copyWith(
        entries: mergedEntries,
        links: nextFeed.links, // Update pagination links
      );
    } catch (e) {
      _error = 'Failed to load more: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search

  /// Search within the current catalog
  Future<void> search(String query) async {
    if (_currentFeed == null || query.isEmpty) {
      clearSearch();
      return;
    }

    _isLoading = true;
    _error = null;
    _searchQuery = query;
    notifyListeners();

    try {
      final searchFeed = await _opdsClientService.search(_currentFeed!, query);
      _navigationStack.add(_currentFeed!);
      _currentFeed = searchFeed;
    } catch (e) {
      _error = 'Search failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear search and return to previous feed
  void clearSearch() {
    if (_searchQuery.isNotEmpty && _navigationStack.isNotEmpty) {
      _currentFeed = _navigationStack.removeLast();
    }
    _searchQuery = '';
    _error = null;
    notifyListeners();
  }

  // Book Download & Import

  /// Check if an entry has already been downloaded
  bool isBookInLibrary(String entryId) {
    return _downloadedEntryIds.contains(entryId);
  }

  /// Get download progress for an entry (0.0 to 1.0)
  double getDownloadProgress(String entryId) {
    return _downloadProgress[entryId] ?? 0.0;
  }

  /// Check if an entry is currently downloading
  bool isDownloading(String entryId) {
    return _downloadProgress.containsKey(entryId);
  }

  /// Download and import a book from an OPDS entry
  ///
  /// Returns the imported Book if successful, null otherwise.
  Future<Book?> downloadAndImportBook(OpdsEntry entry) async {
    if (_selectedCatalog == null) {
      _error = 'No catalog selected';
      notifyListeners();
      return null;
    }

    // Check if the entry has any supported formats
    if (entry.hasOnlyUnsupportedFormats) {
      final formats = entry.unsupportedFormats.join(', ').toUpperCase();
      _error =
          'Format not supported: $formats. '
          'Supported formats are: ${AppConstants.supportedBookFormats.join(', ').toUpperCase()}';
      notifyListeners();
      return null;
    }

    // Get the best supported acquisition link
    final acquisitionLink = entry.bestSupportedAcquisitionLink;
    if (acquisitionLink == null) {
      _error = 'No download link available';
      notifyListeners();
      return null;
    }

    _error = null;
    _downloadProgress[entry.id] = 0.0;
    notifyListeners();

    try {
      // Download the book file
      final filePath = await _opdsClientService.downloadBook(
        acquisitionLink,
        _selectedCatalog!.id,
        onProgress: (progress) {
          _downloadProgress[entry.id] = progress;
          notifyListeners();
        },
      );

      // Import the downloaded file
      final book = await _importService.importBook(filePath);

      // Add source tracking info
      final bookWithSource = book.copyWith(
        sourceCatalogId: _selectedCatalog!.id,
        sourceEntryId: entry.id,
      );

      // Save to repository
      final savedBook = await _bookRepository.insert(bookWithSource);

      // Update local tracking
      _downloadedEntryIds.add(entry.id);
      _entryIdToBookId[entry.id] = savedBook.id;

      // Clean up temp file (the import service copies it)
      try {
        await File(filePath).delete();
      } catch (_) {}

      return savedBook;
    } catch (e) {
      _error = 'Download failed: $e';
      return null;
    } finally {
      _downloadProgress.remove(entry.id);
      notifyListeners();
    }
  }

  // Kavita Progress Sync

  /// Sync reading progress to Kavita server
  ///
  /// Call this when closing a book that came from a Kavita catalog.
  Future<void> syncProgressToKavita({
    required Book book,
    required double progress,
    required int pageNum,
  }) async {
    if (!book.isFromCatalog || book.sourceCatalogId == null) return;

    try {
      final catalog = await _catalogRepository.getById(book.sourceCatalogId!);
      if (catalog == null || !catalog.isKavita || catalog.apiKey == null) {
        return;
      }

      // Parse Kavita IDs from source entry ID
      // Entry ID format: "kavita:chapterId:volumeId:seriesId:libraryId"
      final parts = book.sourceEntryId?.split(':') ?? [];
      if (parts.length < 5 || parts[0] != 'kavita') return;

      final chapterId = int.tryParse(parts[1]) ?? 0;
      final volumeId = int.tryParse(parts[2]) ?? 0;
      final seriesId = int.tryParse(parts[3]) ?? 0;
      final libraryId = int.tryParse(parts[4]) ?? 0;

      final kavitaProgress = KavitaProgress(
        chapterId: chapterId,
        volumeId: volumeId,
        seriesId: seriesId,
        libraryId: libraryId,
        pageNum: pageNum,
      );

      await _kavitaApiService.updateProgress(
        catalog.url,
        catalog.apiKey!,
        kavitaProgress,
      );

      debugPrint('Synced progress to Kavita: page $pageNum');
    } catch (e) {
      debugPrint('Failed to sync progress to Kavita: $e');
    }
  }

  /// Fetch reading progress from Kavita server
  Future<KavitaProgress?> fetchProgressFromKavita(Book book) async {
    if (!book.isFromCatalog || book.sourceCatalogId == null) return null;

    try {
      final catalog = await _catalogRepository.getById(book.sourceCatalogId!);
      if (catalog == null || !catalog.isKavita || catalog.apiKey == null) {
        return null;
      }

      // Parse chapter ID from source entry ID
      final parts = book.sourceEntryId?.split(':') ?? [];
      if (parts.length < 2 || parts[0] != 'kavita') return null;

      final chapterId = int.tryParse(parts[1]) ?? 0;
      if (chapterId == 0) return null;

      return await _kavitaApiService.getProgress(
        catalog.url,
        catalog.apiKey!,
        chapterId,
      );
    } catch (e) {
      debugPrint('Failed to fetch progress from Kavita: $e');
      return null;
    }
  }

  /// Clear any error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============================================================
  // NEXTCLOUD METHODS - Delegate to NextcloudProvider/NextcloudClient
  // ============================================================

  /// Validate Nextcloud server credentials
  Future<NextcloudServerInfo> validateNextcloud(
    String serverUrl,
    String username,
    String appPassword,
  ) async {
    if (_nextcloudProvider == null) {
      throw Exception('Nextcloud service not available');
    }
    return await _nextcloudProvider.validateCredentials(
      serverUrl,
      username,
      appPassword,
    );
  }

  /// Start Nextcloud OAuth2 Login Flow v2
  Future<void> startNextcloudOAuth(String serverUrl) async {
    if (_nextcloudProvider == null) {
      throw Exception('Nextcloud service not available');
    }

    await _nextcloudProvider.startOAuthFlow(serverUrl);
    notifyListeners();
  }

  /// Poll for OAuth flow completion
  /// Returns LoginFlowResult when complete, null if still pending
  Future<LoginFlowResult?> pollNextcloudOAuth() async {
    if (_nextcloudProvider == null) {
      return null;
    }

    final result = await _nextcloudProvider.pollOAuthFlow();

    if (result != null) {
      notifyListeners();
    }

    return result;
  }

  /// Cancel OAuth flow
  void cancelNextcloudOAuth() {
    _nextcloudProvider?.cancelOAuthFlow();
    notifyListeners();
  }

  /// Add a Nextcloud catalog
  Future<Catalog?> addNextcloudCatalog({
    required String name,
    required String url,
    required String username,
    required String appPassword,
    String? userId,
    String? booksFolder,
    String? serverVersion,
  }) async {
    debugPrint(
      'addNextcloudCatalog called: name=$name, url=$url, username=$username',
    );

    if (_credentialStorage == null) {
      debugPrint('addNextcloudCatalog: Credential storage is null!');
      throw Exception('Credential storage not available');
    }

    try {
      final id = const Uuid().v4();
      debugPrint('addNextcloudCatalog: Generated ID: $id');

      // Store password securely
      await _credentialStorage.saveAppPassword(id, appPassword);
      debugPrint('addNextcloudCatalog: Saved app password');

      final catalog = Catalog(
        id: id,
        name: name,
        url: url,
        type: CatalogType.nextcloud,
        addedAt: DateTime.now(),
        username: username,
        userId: userId ?? username,
        booksFolder: booksFolder ?? '/Books',
        serverVersion: serverVersion,
      );

      debugPrint('addNextcloudCatalog: Inserting catalog into repository...');
      await _catalogRepository.insert(catalog);
      debugPrint(
        'addNextcloudCatalog: Catalog inserted, reloading catalogs...',
      );
      _catalogs = await _catalogRepository.getAll();
      debugPrint(
        'addNextcloudCatalog: Success! Total catalogs: ${_catalogs.length}',
      );
      notifyListeners();

      return catalog;
    } catch (e, stackTrace) {
      debugPrint('addNextcloudCatalog ERROR: $e');
      debugPrint('Stack trace: $stackTrace');
      _error = 'Failed to add Nextcloud catalog: $e';
      notifyListeners();
      return null;
    }
  }

  /// Open Nextcloud browser for a catalog
  Future<void> openNextcloudBrowser(Catalog catalog) async {
    if (_nextcloudProvider == null) {
      throw Exception('Nextcloud service not available');
    }

    _selectedCatalog = catalog;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _nextcloudProvider.openBrowser(
        catalogId: catalog.id,
        serverUrl: catalog.url,
        userId: catalog.userId ?? catalog.username ?? '',
        username: catalog.username,
        booksFolder: catalog.effectiveBooksFolder,
      );
    } catch (e) {
      _error = 'Failed to open Nextcloud: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Navigate to a path in Nextcloud browser
  Future<void> navigateNextcloudTo(String path) async {
    if (_selectedCatalog == null || _nextcloudProvider == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _nextcloudProvider.navigateTo(path);
    } catch (e) {
      _error = 'Failed to navigate: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Navigate back in Nextcloud browser
  Future<void> navigateNextcloudBack() async {
    if (_nextcloudProvider == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _nextcloudProvider.navigateBack();
    } catch (e) {
      _error = 'Failed to navigate back: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh current Nextcloud directory
  Future<void> refreshNextcloudDirectory() async {
    if (_nextcloudProvider == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _nextcloudProvider.refresh();
    } catch (e) {
      _error = 'Failed to refresh: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Close Nextcloud browser
  void closeNextcloudBrowser() {
    _selectedCatalog = null;
    _nextcloudProvider?.closeBrowser();
    _error = null;
    notifyListeners();
  }

  /// Download and import a book from Nextcloud
  Future<Book?> downloadNextcloudBook(NextcloudFile file) async {
    if (_selectedCatalog == null || _nextcloudProvider == null) {
      return null;
    }

    final entryId = 'nextcloud:${file.path}';

    try {
      // Create temp file path
      final tempDir = Directory.systemTemp;
      final tempPath = '${tempDir.path}/${file.name}';

      _downloadProgress[entryId] = 0.0;
      notifyListeners();

      // Download file using NextcloudProvider
      final downloadedFile = await _nextcloudProvider.downloadFile(
        file,
        tempPath,
      );

      if (downloadedFile == null) {
        throw Exception('Download failed');
      }

      _downloadProgress[entryId] = 1.0;
      notifyListeners();

      // Import the downloaded file
      final book = await _importService.importBook(tempPath);

      _downloadProgress.remove(entryId);
      _downloadedEntryIds.add(entryId);
      notifyListeners();

      // Clean up temp file
      try {
        await File(tempPath).delete();
      } catch (_) {}

      return book;
    } catch (e) {
      _downloadProgress.remove(entryId);
      _error = 'Download failed: $e';
      notifyListeners();
      return null;
    }
  }

  /// Get Nextcloud breadcrumbs for current path
  List<String> get nextcloudBreadcrumbs =>
      _nextcloudProvider?.breadcrumbs ?? ['/'];

  /// Delete a Nextcloud catalog and its credentials
  Future<void> removeNextcloudCatalog(Catalog catalog) async {
    if (_credentialStorage != null) {
      await _credentialStorage.deleteCredentials(catalog.id);
    }
    await removeCatalog(catalog.id);
  }
}
