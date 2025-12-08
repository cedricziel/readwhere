import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

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

  CatalogsProvider({
    required CatalogRepository catalogRepository,
    required OpdsClientService opdsClientService,
    required OpdsCacheService cacheService,
    required KavitaApiService kavitaApiService,
    required BookImportService importService,
    required BookRepository bookRepository,
  }) : _catalogRepository = catalogRepository,
       _opdsClientService = opdsClientService,
       _cacheService = cacheService,
       _kavitaApiService = kavitaApiService,
       _importService = importService,
       _bookRepository = bookRepository;

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

  // Cache state
  bool _isFromCache = false;
  DateTime? _cachedAt;
  DateTime? _cacheExpiresAt;

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
      for (final book in books) {
        if (book.sourceEntryId != null) {
          _downloadedEntryIds.add(book.sourceEntryId!);
        }
      }
    } catch (e) {
      debugPrint('Failed to load downloaded entry IDs: $e');
    }
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

    final acquisitionLink = entry.bestAcquisitionLink;
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
}
