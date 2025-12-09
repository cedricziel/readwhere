import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

import '../cache/opds_cache_interface.dart';
import '../client/opds_client.dart';
import '../entities/opds_entry.dart';
import '../entities/opds_feed.dart';
import '../entities/opds_link.dart';

/// Callback for importing a downloaded book file.
///
/// Returns the imported book ID if successful.
typedef BookImportCallback =
    Future<String?> Function(
      String filePath, {
      String? sourceCatalogId,
      String? sourceEntryId,
    });

/// State provider for OPDS catalog browsing.
///
/// Manages:
/// - Feed navigation state (current feed, navigation stack)
/// - Cache state (freshness, timestamps)
/// - Search state
/// - Download progress tracking
///
/// This provider extends [BrowsingProvider] for common interface compliance
/// and uses [ChangeNotifier] for Flutter state management.
class OpdsProvider extends BrowsingProvider {
  final OpdsClient _opdsClient;
  final OpdsCacheInterface _cache;
  final BookImportCallback? _importBook;

  OpdsProvider({
    required OpdsClient opdsClient,
    required OpdsCacheInterface cache,
    BookImportCallback? importBook,
  }) : _opdsClient = opdsClient,
       _cache = cache,
       _importBook = importBook;

  // ===== State =====

  String? _catalogId;
  String? _catalogUrl;

  OpdsFeed? _currentFeed;
  OpdsFeed? get currentFeed => _currentFeed;

  final List<OpdsFeed> _navigationStack = [];
  final List<String> _navigationUrlStack = [];
  String? _currentFeedUrl;

  bool _isLoading = false;
  @override
  bool get isLoading => _isLoading;

  String? _error;
  @override
  String? get error => _error;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  bool get isSearching => _searchQuery.isNotEmpty;

  // Cache state
  bool _isFromCache = false;
  bool get isFromCache => _isFromCache;

  DateTime? _cachedAt;
  DateTime? get cachedAt => _cachedAt;

  DateTime? _cacheExpiresAt;
  DateTime? get cacheExpiresAt => _cacheExpiresAt;

  /// Whether the cached data is still fresh
  bool get isCacheFresh {
    if (!_isFromCache || _cacheExpiresAt == null) return true;
    return DateTime.now().isBefore(_cacheExpiresAt!);
  }

  /// Human-readable cache age text
  String get cacheAgeText {
    if (!_isFromCache || _cachedAt == null) return '';
    final age = DateTime.now().difference(_cachedAt!);
    if (age.inMinutes < 1) return 'Just now';
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }

  // Download tracking
  final Map<String, double> _downloadProgress = {};
  final Set<String> _downloadedEntryIds = {};
  final Map<String, String> _entryIdToBookId = {};

  // ===== BrowsingProvider Interface =====

  @override
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  bool get canNavigateBack => _navigationStack.isNotEmpty;

  @override
  List<String> get breadcrumbs {
    final crumbs = <String>['Home'];
    for (final feed in _navigationStack) {
      crumbs.add(feed.title);
    }
    if (_currentFeed != null && _navigationStack.isNotEmpty) {
      crumbs.add(_currentFeed!.title);
    }
    return crumbs;
  }

  @override
  Future<bool> navigateBack() async {
    if (_navigationStack.isEmpty) return false;

    _currentFeed = _navigationStack.removeLast();
    if (_navigationUrlStack.isNotEmpty) {
      _currentFeedUrl = _navigationUrlStack.removeLast();
    }
    _searchQuery = '';
    _error = null;
    notifyListeners();
    return true;
  }

  @override
  Future<void> refresh() async {
    await refreshCurrentFeed();
  }

  @override
  void closeBrowser() {
    _catalogId = null;
    _catalogUrl = null;
    _currentFeed = null;
    _currentFeedUrl = null;
    _navigationStack.clear();
    _navigationUrlStack.clear();
    _searchQuery = '';
    _error = null;
    _clearCacheState();
    notifyListeners();
  }

  @override
  double? getDownloadProgress(String itemId) => _downloadProgress[itemId];

  @override
  bool isDownloaded(String itemId) => _downloadedEntryIds.contains(itemId);

  /// Get the book ID for a downloaded entry
  String? getBookIdForEntry(String entryId) => _entryIdToBookId[entryId];

  // ===== OPDS-Specific Operations =====

  /// Open a catalog and fetch its root feed.
  ///
  /// [catalogId] - Unique identifier for the catalog
  /// [catalogUrl] - Base OPDS URL for the catalog
  /// [strategy] - Optional fetch strategy (defaults to networkFirst)
  Future<void> openCatalog({
    required String catalogId,
    required String catalogUrl,
    FetchStrategy strategy = FetchStrategy.networkFirst,
  }) async {
    _isLoading = true;
    _error = null;
    _catalogId = catalogId;
    _catalogUrl = catalogUrl;
    _navigationStack.clear();
    _navigationUrlStack.clear();
    _searchQuery = '';
    _currentFeedUrl = catalogUrl;
    notifyListeners();

    try {
      final result = await _cache.fetchFeed(
        catalogId: catalogId,
        url: catalogUrl,
        strategy: strategy,
      );
      _currentFeed = result.feed;
      _updateCacheState(result);
    } catch (e) {
      _error = 'Failed to open catalog: $e';
      _currentFeed = null;
      _clearCacheState();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Navigate to a feed via a link.
  Future<void> navigateToFeed(
    OpdsLink link, {
    FetchStrategy strategy = FetchStrategy.networkFirst,
  }) async {
    if (_currentFeed == null || _catalogId == null) return;

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
      final baseUrl = _catalogUrl ?? '';
      final url = _opdsClient.resolveCoverUrl(baseUrl, link.href);
      final resolvedUrl = url.isNotEmpty ? url : link.href;

      final result = await _cache.fetchFeed(
        catalogId: _catalogId!,
        url: resolvedUrl,
        strategy: strategy,
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

  /// Force refresh the current feed from network.
  Future<void> refreshCurrentFeed() async {
    if (_catalogId == null || _currentFeedUrl == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _cache.fetchFeed(
        catalogId: _catalogId!,
        url: _currentFeedUrl!,
        strategy: FetchStrategy.networkOnly,
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

  /// Fetch next page of current feed.
  Future<void> loadNextPage() async {
    if (_currentFeed == null || !_currentFeed!.hasNextPage) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final nextLink = _currentFeed!.nextPageLink!;
      final nextFeed = await _opdsClient.fetchFeed(nextLink.href);

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

  // ===== Search =====

  /// Search within the current catalog.
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
      final searchFeed = await _opdsClient.search(_currentFeed!, query);
      _navigationStack.add(_currentFeed!);
      _currentFeed = searchFeed;
    } catch (e) {
      _error = 'Search failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear search and return to previous feed.
  void clearSearch() {
    if (_searchQuery.isNotEmpty && _navigationStack.isNotEmpty) {
      _currentFeed = _navigationStack.removeLast();
    }
    _searchQuery = '';
    _error = null;
    notifyListeners();
  }

  // ===== Download & Import =====

  /// Download and import a book from an OPDS entry.
  ///
  /// Returns the imported book ID if successful, null otherwise.
  /// Set [supportedFormats] to filter which formats are accepted.
  Future<String?> downloadAndImportBook(
    OpdsEntry entry, {
    Set<String> supportedFormats = const {'epub', 'cbz', 'cbr', 'pdf'},
  }) async {
    if (_catalogId == null) {
      _error = 'No catalog selected';
      notifyListeners();
      return null;
    }

    if (_importBook == null) {
      _error = 'Book import not configured';
      notifyListeners();
      return null;
    }

    // Check if the entry has any supported formats
    final hasSupported = entry.acquisitionLinks.any((link) {
      final ext = _getExtensionFromMimeType(link.type);
      return supportedFormats.contains(ext);
    });

    if (!hasSupported) {
      _error = 'No supported format available';
      notifyListeners();
      return null;
    }

    // Get the best supported acquisition link
    final acquisitionLink = _getBestAcquisitionLink(entry, supportedFormats);
    if (acquisitionLink == null) {
      _error = 'No download link available';
      notifyListeners();
      return null;
    }

    _error = null;
    _downloadProgress[entry.id] = 0.0;
    notifyListeners();

    try {
      // Download the book file to temp directory
      final filePath = await _opdsClient.downloadBook(
        acquisitionLink,
        Directory.systemTemp,
        onProgress: (progress) {
          _downloadProgress[entry.id] = progress;
          notifyListeners();
        },
      );

      // Import the downloaded file
      final bookId = await _importBook(
        filePath,
        sourceCatalogId: _catalogId,
        sourceEntryId: entry.id,
      );

      if (bookId != null) {
        // Update local tracking
        _downloadedEntryIds.add(entry.id);
        _entryIdToBookId[entry.id] = bookId;
      }

      // Clean up temp file
      try {
        await File(filePath).delete();
      } catch (_) {}

      return bookId;
    } catch (e) {
      _error = 'Download failed: $e';
      return null;
    } finally {
      _downloadProgress.remove(entry.id);
      notifyListeners();
    }
  }

  /// Mark entries as already downloaded (e.g., loaded from database).
  void setDownloadedEntries(Map<String, String> entryIdToBookId) {
    _downloadedEntryIds.addAll(entryIdToBookId.keys);
    _entryIdToBookId.addAll(entryIdToBookId);
  }

  // ===== Private Helpers =====

  void _updateCacheState(CachedFeedResult result) {
    _isFromCache = result.isFromCache;
    _cachedAt = result.cachedAt;
    _cacheExpiresAt = result.expiresAt;
  }

  void _clearCacheState() {
    _isFromCache = false;
    _cachedAt = null;
    _cacheExpiresAt = null;
  }

  String? _getExtensionFromMimeType(String? mimeType) {
    if (mimeType == null) return null;
    if (mimeType.contains('epub')) return 'epub';
    if (mimeType.contains('cbz') || mimeType.contains('zip')) return 'cbz';
    if (mimeType.contains('cbr') || mimeType.contains('rar')) return 'cbr';
    if (mimeType.contains('pdf')) return 'pdf';
    return null;
  }

  OpdsLink? _getBestAcquisitionLink(OpdsEntry entry, Set<String> formats) {
    // Prefer in order: epub, cbz, cbr, pdf
    final priorities = ['epub', 'cbz', 'cbr', 'pdf'];
    for (final format in priorities) {
      if (!formats.contains(format)) continue;
      for (final link in entry.acquisitionLinks) {
        final ext = _getExtensionFromMimeType(link.type);
        if (ext == format) return link;
      }
    }
    return null;
  }
}
