import 'dart:io';

import 'package:readwhere_plugin/readwhere_plugin.dart';

import '../../data/adapters/catalog_info_adapter.dart';
import '../../domain/entities/catalog.dart';

/// Callback for importing a downloaded book file.
///
/// Returns the imported book ID if successful.
typedef BookImportCallback =
    Future<String?> Function(
      String filePath, {
      String? sourceCatalogId,
      String? sourceEntryId,
    });

/// Unified state provider for catalog browsing using the plugin system.
///
/// This provider wraps [CatalogBrowsingCapability] plugins to provide
/// a consistent state management interface for all catalog types
/// (OPDS, RSS, Kavita, Nextcloud, etc.).
///
/// Features:
/// - Navigation stack for back navigation
/// - Search state management
/// - Download progress tracking
/// - Breadcrumb generation
/// - Cache state awareness
class UnifiedCatalogBrowsingProvider extends BrowsingProvider {
  final UnifiedPluginRegistry _registry;
  final BookImportCallback? _importBook;

  UnifiedCatalogBrowsingProvider({
    required UnifiedPluginRegistry registry,
    BookImportCallback? importBook,
  }) : _registry = registry,
       _importBook = importBook;

  // ===== Current State =====

  Catalog? _catalog;
  CatalogInfo? _catalogInfo;
  CatalogBrowsingCapability? _plugin;

  /// The current catalog being browsed.
  Catalog? get catalog => _catalog;

  /// The active plugin for this catalog.
  CatalogBrowsingCapability? get plugin => _plugin;

  BrowseResult? _currentResult;

  /// The current browse result.
  BrowseResult? get currentResult => _currentResult;

  /// Entries in the current browse result.
  List<CatalogEntry> get entries => _currentResult?.entries ?? [];

  /// Navigation links in the current result.
  List<CatalogLink> get navigationLinks =>
      _currentResult?.navigationLinks ?? [];

  /// Whether search is available for current catalog/location.
  bool get hasSearch => _currentResult?.hasSearch ?? false;

  /// Whether there are more pages available.
  bool get hasNextPage => _currentResult?.hasNextPage ?? false;

  // ===== Navigation State =====

  final List<BrowseResult> _navigationStack = [];
  final List<String?> _pathStack = [];
  String? _currentPath;

  /// Current path within the catalog.
  String? get currentPath => _currentPath;

  // ===== Loading State =====

  bool _isLoading = false;
  @override
  bool get isLoading => _isLoading;

  String? _error;
  @override
  String? get error => _error;

  // ===== Search State =====

  String _searchQuery = '';

  /// Current search query.
  String get searchQuery => _searchQuery;

  /// Whether currently showing search results.
  bool get isSearching => _searchQuery.isNotEmpty;

  // ===== Cache State =====

  bool _isFromCache = false;

  /// Whether current result is from cache.
  bool get isFromCache => _isFromCache;

  DateTime? _cachedAt;

  /// When the cached data was stored.
  DateTime? get cachedAt => _cachedAt;

  /// Human-readable cache age text.
  String get cacheAgeText {
    if (!_isFromCache || _cachedAt == null) return '';
    final age = DateTime.now().difference(_cachedAt!);
    if (age.inMinutes < 1) return 'Just now';
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }

  // ===== Download State =====

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
    for (final result in _navigationStack) {
      if (result.title != null) {
        crumbs.add(result.title!);
      }
    }
    if (_currentResult?.title != null && _navigationStack.isNotEmpty) {
      crumbs.add(_currentResult!.title!);
    }
    return crumbs;
  }

  @override
  Future<bool> navigateBack() async {
    if (_navigationStack.isEmpty) return false;

    _currentResult = _navigationStack.removeLast();
    _currentPath = _pathStack.isNotEmpty ? _pathStack.removeLast() : null;
    _searchQuery = '';
    _error = null;
    notifyListeners();
    return true;
  }

  @override
  Future<void> refresh() async {
    if (_catalog == null || _plugin == null || _catalogInfo == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_searchQuery.isNotEmpty) {
        // Refresh search results
        _currentResult = await _plugin!.search(_catalogInfo!, _searchQuery);
      } else {
        // Refresh current path
        _currentResult = await _plugin!.browse(
          _catalogInfo!,
          path: _currentPath,
        );
      }
      _updateCacheState();
    } catch (e) {
      _error = 'Failed to refresh: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void closeBrowser() {
    _catalog = null;
    _catalogInfo = null;
    _plugin = null;
    _currentResult = null;
    _currentPath = null;
    _navigationStack.clear();
    _pathStack.clear();
    _searchQuery = '';
    _error = null;
    _isFromCache = false;
    _cachedAt = null;
    notifyListeners();
  }

  @override
  double? getDownloadProgress(String itemId) => _downloadProgress[itemId];

  @override
  bool isDownloaded(String itemId) => _downloadedEntryIds.contains(itemId);

  /// Get the book ID for a downloaded entry.
  String? getBookIdForEntry(String entryId) => _entryIdToBookId[entryId];

  // ===== Catalog Operations =====

  /// Open a catalog and fetch its root content.
  ///
  /// Finds the appropriate plugin for the catalog type and initializes
  /// browsing state.
  Future<void> openCatalog(Catalog catalog) async {
    _isLoading = true;
    _error = null;
    _catalog = catalog;
    _catalogInfo = catalog.toCatalogInfo();
    _navigationStack.clear();
    _pathStack.clear();
    _searchQuery = '';
    _currentPath = null;
    notifyListeners();

    // Find plugin for this catalog
    _plugin = _registry.forCatalog<CatalogBrowsingCapability>(_catalogInfo);

    if (_plugin == null) {
      _error = 'No plugin available for catalog type: ${catalog.type.name}';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _currentResult = await _plugin!.browse(_catalogInfo!);
      _updateCacheState();
    } catch (e) {
      _error = 'Failed to open catalog: $e';
      _currentResult = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Navigate to a path within the catalog.
  Future<void> navigateToPath(String path) async {
    if (_plugin == null || _catalogInfo == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Save current state to stack
      if (_currentResult != null) {
        _navigationStack.add(_currentResult!);
        _pathStack.add(_currentPath);
      }

      _currentResult = await _plugin!.browse(_catalogInfo!, path: path);
      _currentPath = path;
      _searchQuery = '';
      _updateCacheState();
    } catch (e) {
      _error = 'Failed to navigate: $e';
      // Restore previous state
      if (_navigationStack.isNotEmpty) {
        _currentResult = _navigationStack.removeLast();
        _currentPath = _pathStack.isNotEmpty ? _pathStack.removeLast() : null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Navigate to an entry (if it's browsable).
  Future<void> navigateToEntry(CatalogEntry entry) async {
    if (entry.links.isEmpty) return;

    // Find a browsable link
    final link = entry.links.firstWhere(
      (l) => l.rel == 'subsection' || l.rel == 'alternate' || l.rel == null,
      orElse: () => entry.links.first,
    );

    await navigateToPath(link.href);
  }

  /// Load the next page of results.
  Future<void> loadNextPage() async {
    if (_plugin == null ||
        _catalogInfo == null ||
        _currentResult == null ||
        !_currentResult!.hasNextPage) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final nextPage = (_currentResult!.page ?? 1) + 1;
      final nextResult = await _plugin!.browse(
        _catalogInfo!,
        path: _currentResult!.nextPageUrl ?? _currentPath,
        page: nextPage,
      );

      // Merge entries
      _currentResult = _currentResult!.copyWith(
        entries: [..._currentResult!.entries, ...nextResult.entries],
        page: nextResult.page,
        hasNextPage: nextResult.hasNextPage,
        nextPageUrl: nextResult.nextPageUrl,
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
    if (_plugin == null || _catalogInfo == null || query.isEmpty) {
      clearSearch();
      return;
    }

    if (!_plugin!.supportsSearch) {
      _error = 'Search not supported by this catalog';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _searchQuery = query;
    notifyListeners();

    try {
      // Save current result before search
      if (_currentResult != null && _searchQuery.isEmpty) {
        _navigationStack.add(_currentResult!);
        _pathStack.add(_currentPath);
      }

      _currentResult = await _plugin!.search(_catalogInfo!, query);
      _updateCacheState();
    } catch (e) {
      _error = 'Search failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear search and return to previous browse state.
  void clearSearch() {
    if (_searchQuery.isNotEmpty && _navigationStack.isNotEmpty) {
      _currentResult = _navigationStack.removeLast();
      _currentPath = _pathStack.isNotEmpty ? _pathStack.removeLast() : null;
    }
    _searchQuery = '';
    _error = null;
    notifyListeners();
  }

  // ===== Download =====

  /// Download and import a file from an entry.
  ///
  /// Returns the imported book ID if successful, null otherwise.
  Future<String?> downloadAndImportEntry(
    CatalogEntry entry,
    CatalogFile file,
  ) async {
    if (_catalog == null || _plugin == null || _catalogInfo == null) {
      _error = 'No catalog selected';
      notifyListeners();
      return null;
    }

    if (_importBook == null) {
      _error = 'Book import not configured';
      notifyListeners();
      return null;
    }

    _error = null;
    _downloadProgress[entry.id] = 0.0;
    notifyListeners();

    try {
      // Create temp file path
      final tempDir = Directory.systemTemp;
      final extension = file.extension ?? file.mimeType.split('/').last;
      final tempPath = '${tempDir.path}/${entry.id}.$extension';

      // Download via plugin
      await _plugin!.download(
        _catalogInfo!,
        file,
        tempPath,
        onProgress: (received, total) {
          _downloadProgress[entry.id] = total > 0 ? received / total : 0.0;
          notifyListeners();
        },
      );

      // Import the downloaded file
      final bookId = await _importBook(
        tempPath,
        sourceCatalogId: _catalog!.id,
        sourceEntryId: entry.id,
      );

      if (bookId != null) {
        _downloadedEntryIds.add(entry.id);
        _entryIdToBookId[entry.id] = bookId;
      }

      // Clean up temp file
      try {
        await File(tempPath).delete();
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

  void _updateCacheState() {
    final props = _currentResult?.properties ?? {};
    _isFromCache = props['isFromCache'] as bool? ?? false;
    final cachedAtStr = props['cachedAt'] as String?;
    _cachedAt = cachedAtStr != null ? DateTime.tryParse(cachedAtStr) : null;
  }
}
