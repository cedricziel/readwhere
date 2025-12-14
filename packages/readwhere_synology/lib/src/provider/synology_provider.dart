import 'dart:io';

import 'package:flutter/foundation.dart';

import '../api/models/synology_file.dart';
import '../api/synology_client.dart';
import '../auth/synology_session.dart';
import '../exceptions/synology_exception.dart';

/// Provider for Synology Drive file browser state management.
class SynologyProvider extends ChangeNotifier {
  /// Creates a new [SynologyProvider].
  SynologyProvider(this._client);

  final SynologyClient _client;

  // Browser state
  String? _catalogId;
  String? _serverUrl;
  String _currentPath = '/mydrive';
  final List<String> _pathStack = [];
  List<SynologyFile> _files = [];
  bool _isLoading = false;
  String? _error;

  // Download tracking
  final Map<String, double> _downloadProgress = {};

  // Search state
  String? _searchQuery;
  bool _isSearching = false;

  // Getters
  String? get catalogId => _catalogId;
  String? get serverUrl => _serverUrl;
  String get currentPath => _currentPath;
  List<SynologyFile> get files => List.unmodifiable(_files);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSearching => _isSearching;
  String? get searchQuery => _searchQuery;

  /// Whether the browser is currently open.
  bool get isOpen => _catalogId != null;

  /// Returns directories from the current file list.
  List<SynologyFile> get directories =>
      _files.where((f) => f.isDirectory).toList();

  /// Returns files (non-directories) from the current file list.
  List<SynologyFile> get filesOnly =>
      _files.where((f) => !f.isDirectory).toList();

  /// Returns only supported book files.
  List<SynologyFile> get books =>
      _files.where((f) => f.isSupportedBook).toList();

  /// Returns breadcrumb path segments for navigation.
  List<String> get breadcrumbs {
    if (_currentPath == '/mydrive' || _currentPath.isEmpty) {
      return ['My Drive'];
    }

    final parts = _currentPath.split('/').where((p) => p.isNotEmpty).toList();
    final result = <String>[];

    for (var i = 0; i < parts.length; i++) {
      if (i == 0 && parts[i] == 'mydrive') {
        result.add('My Drive');
      } else {
        result.add(parts[i]);
      }
    }

    return result;
  }

  /// Gets the download progress for a file path.
  double? getDownloadProgress(String path) => _downloadProgress[path];

  /// Opens the file browser for a catalog.
  Future<void> openBrowser({
    required String catalogId,
    required String serverUrl,
    String startPath = '/mydrive',
  }) async {
    _catalogId = catalogId;
    _serverUrl = serverUrl;
    _currentPath = startPath;
    _pathStack.clear();
    _files = [];
    _error = null;
    _searchQuery = null;
    _isSearching = false;
    notifyListeners();

    await _loadCurrentDirectory();
  }

  /// Closes the file browser and clears state.
  void closeBrowser() {
    _catalogId = null;
    _serverUrl = null;
    _currentPath = '/mydrive';
    _pathStack.clear();
    _files = [];
    _error = null;
    _downloadProgress.clear();
    _searchQuery = null;
    _isSearching = false;
    notifyListeners();
  }

  /// Navigates to a directory.
  Future<void> navigateTo(String path) async {
    if (_catalogId == null) return;

    // Save current path for back navigation
    _pathStack.add(_currentPath);
    _currentPath = path;
    _searchQuery = null;
    _isSearching = false;
    notifyListeners();

    try {
      await _loadCurrentDirectory();
    } catch (e) {
      // Rollback on error
      if (_pathStack.isNotEmpty) {
        _currentPath = _pathStack.removeLast();
      }
      rethrow;
    }
  }

  /// Navigates back to the previous directory.
  ///
  /// Returns true if navigation occurred, false if already at root.
  Future<bool> navigateBack() async {
    if (_pathStack.isEmpty) return false;

    _currentPath = _pathStack.removeLast();
    _searchQuery = null;
    _isSearching = false;
    notifyListeners();

    await _loadCurrentDirectory();
    return true;
  }

  /// Navigates back without loading (for error recovery).
  bool navigateBackWithoutLoad() {
    if (_pathStack.isEmpty) return false;

    _currentPath = _pathStack.removeLast();
    _error = null;
    notifyListeners();
    return true;
  }

  /// Refreshes the current directory.
  Future<void> refresh() async {
    if (_isSearching && _searchQuery != null) {
      await search(_searchQuery!);
    } else {
      await _loadCurrentDirectory();
    }
  }

  /// Searches for files.
  Future<void> search(String query) async {
    if (_catalogId == null || query.isEmpty) return;

    _searchQuery = query;
    _isSearching = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _client.search(_catalogId!, query);
      _files = result.items;
      _error = null;
    } on SynologyException catch (e) {
      _error = e.message;
      _files = [];
    } catch (e) {
      _error = 'Search failed: $e';
      _files = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears search and returns to directory browsing.
  Future<void> clearSearch() async {
    _searchQuery = null;
    _isSearching = false;
    notifyListeners();
    await _loadCurrentDirectory();
  }

  /// Downloads a file.
  ///
  /// Returns the downloaded file, or null on failure.
  Future<File?> downloadFile(
    SynologyFile file,
    String localPath,
  ) async {
    if (_catalogId == null) return null;

    _downloadProgress[file.path] = 0.0;
    notifyListeners();

    try {
      final result = await _client.downloadFile(
        _catalogId!,
        file.path,
        localPath,
        onProgress: (received, total) {
          if (total > 0) {
            _downloadProgress[file.path] = received / total;
            notifyListeners();
          }
        },
      );

      _downloadProgress[file.path] = 1.0;
      notifyListeners();

      return result;
    } catch (e) {
      _downloadProgress.remove(file.path);
      notifyListeners();
      rethrow;
    }
  }

  /// Clears download progress for a file.
  void clearDownloadProgress(String path) {
    _downloadProgress.remove(path);
    notifyListeners();
  }

  /// Authenticates with the Synology NAS.
  Future<SynologySession> authenticate({
    required String catalogId,
    required String serverUrl,
    required String account,
    required String password,
  }) async {
    return _client.authenticate(
      catalogId: catalogId,
      serverUrl: serverUrl,
      account: account,
      password: password,
    );
  }

  /// Validates connection without storing credentials.
  Future<bool> validateConnection(
    String serverUrl,
    String account,
    String password,
  ) async {
    return _client.validateConnection(serverUrl, account, password);
  }

  /// Logs out and clears stored data.
  Future<void> logout() async {
    if (_catalogId != null) {
      await _client.logout(_catalogId!);
    }
    closeBrowser();
  }

  /// Creates a folder in the current directory.
  Future<SynologyFile?> createFolder(String name) async {
    if (_catalogId == null) return null;

    final path = '$_currentPath/$name';
    try {
      final folder = await _client.createFolder(_catalogId!, path);
      await _loadCurrentDirectory();
      return folder;
    } catch (e) {
      rethrow;
    }
  }

  /// Validates credentials without storing them.
  ///
  /// Throws [SynologyException] if validation fails.
  Future<void> validateCredentials(
    String serverUrl,
    String username,
    String password,
  ) async {
    final success = await _client.validateConnection(
      serverUrl,
      username,
      password,
    );
    if (!success) {
      throw SynologyException('Failed to validate credentials');
    }
  }

  /// Stores credentials securely for a catalog.
  Future<void> storeCredentials(
    String catalogId,
    String username,
    String password,
  ) async {
    await _client.storeCredentials(catalogId, username, password);
  }

  /// Clears stored credentials for a catalog.
  Future<void> clearCredentials(String catalogId) async {
    await _client.clearCredentials(catalogId);
  }

  Future<void> _loadCurrentDirectory() async {
    if (_catalogId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _client.listDirectory(_catalogId!, _currentPath);
      _files = result.items;
      _error = null;
    } on SynologyException catch (e) {
      _error = e.message;
      _files = [];
    } catch (e) {
      _error = 'Failed to load directory: $e';
      _files = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
