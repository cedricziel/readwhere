import 'dart:io';

import 'package:flutter/foundation.dart';

import '../api/nextcloud_client.dart';
import '../api/models/server_info.dart';
import '../auth/models/login_flow_init.dart';
import '../auth/models/login_flow_result.dart';
import '../webdav/nextcloud_file.dart';

/// State provider for Nextcloud operations
///
/// Manages:
/// - File browser state (current path, files, loading)
/// - OAuth flow state
/// - Download progress tracking
class NextcloudProvider extends ChangeNotifier {
  final NextcloudClient _client;

  NextcloudProvider(this._client);

  // ===== Browser State =====

  String _currentPath = '/';
  String get currentPath => _currentPath;

  List<NextcloudFile> _files = [];
  List<NextcloudFile> get files => List.unmodifiable(_files);

  List<String> _pathStack = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Active catalog info (set when opening browser)
  String? _catalogId;
  String? _serverUrl;
  String? _userId;
  String? _username;

  // ===== OAuth State =====

  LoginFlowInit? _pendingOAuthFlow;
  LoginFlowInit? get pendingOAuthFlow => _pendingOAuthFlow;

  bool _isPollingOAuth = false;
  bool get isPollingOAuth => _isPollingOAuth;

  // ===== Download Progress =====

  final Map<String, double> _downloadProgress = {};

  /// Get download progress for a file path (0.0 to 1.0)
  double? getDownloadProgress(String path) => _downloadProgress[path];

  // ===== Browser Operations =====

  /// Open the browser for a catalog
  Future<void> openBrowser({
    required String catalogId,
    required String serverUrl,
    required String userId,
    String? username,
    String booksFolder = '/',
  }) async {
    _catalogId = catalogId;
    _serverUrl = serverUrl;
    _userId = userId;
    _username = username;
    _currentPath = booksFolder;
    _pathStack = [booksFolder];

    await _loadDirectory();
  }

  /// Navigate to a path
  Future<void> navigateTo(String path) async {
    // Save state for rollback on error
    final previousPath = _currentPath;
    final previousStackLength = _pathStack.length;

    _pathStack.add(path);
    _currentPath = path;

    await _loadDirectory();

    // Rollback on error to prevent "stuck in imaginary folder"
    if (_error != null) {
      _pathStack.removeRange(previousStackLength, _pathStack.length);
      _currentPath = previousPath;
      // Keep error message but restore path state
      notifyListeners();
    }
  }

  /// Navigate back
  Future<bool> navigateBack() async {
    if (_pathStack.length <= 1) return false;

    _pathStack.removeLast();
    _currentPath = _pathStack.last;
    await _loadDirectory();
    return true;
  }

  /// Navigate back without making a network request.
  ///
  /// Use this when in error state to allow escaping without requiring network.
  /// Returns false if at root level (caller should exit browser).
  bool navigateBackWithoutLoad() {
    if (_pathStack.length <= 1) return false;

    _pathStack.removeLast();
    _currentPath = _pathStack.last;
    _error = null;
    _files = []; // Clear files since we don't have cached data
    notifyListeners();
    return true;
  }

  /// Refresh current directory
  Future<void> refresh() async {
    await _loadDirectory();
  }

  /// Close the browser
  void closeBrowser() {
    _catalogId = null;
    _serverUrl = null;
    _userId = null;
    _username = null;
    _currentPath = '/';
    _pathStack = [];
    _files = [];
    _error = null;
    notifyListeners();
  }

  /// Get breadcrumb list for current path
  List<String> get breadcrumbs {
    if (_currentPath == '/' || _currentPath.isEmpty) {
      return ['Home'];
    }

    final parts = _currentPath.split('/').where((s) => s.isNotEmpty).toList();
    return ['Home', ...parts];
  }

  Future<void> _loadDirectory() async {
    if (_catalogId == null || _serverUrl == null || _userId == null) {
      _error = 'Browser not initialized';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _files = await _client.listDirectory(
        serverUrl: _serverUrl!,
        userId: _userId!,
        catalogId: _catalogId!,
        username: _username,
        path: _currentPath,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _files = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===== Download Operations =====

  /// Download a file and return the local path
  Future<File?> downloadFile(
    NextcloudFile file,
    String localPath,
  ) async {
    if (_catalogId == null || _serverUrl == null || _userId == null) {
      return null;
    }

    final progressKey = file.path;
    _downloadProgress[progressKey] = 0.0;
    notifyListeners();

    try {
      await _client.downloadFile(
        serverUrl: _serverUrl!,
        userId: _userId!,
        catalogId: _catalogId!,
        username: _username,
        remotePath: file.path,
        localPath: localPath,
        onProgress: (received, total) {
          if (total > 0) {
            _downloadProgress[progressKey] = received / total;
            notifyListeners();
          }
        },
      );

      _downloadProgress[progressKey] = 1.0;
      notifyListeners();

      return File(localPath);
    } catch (e) {
      _downloadProgress.remove(progressKey);
      notifyListeners();
      rethrow;
    }
  }

  // ===== OAuth Operations =====

  /// Start OAuth flow for a server
  Future<LoginFlowInit> startOAuthFlow(String serverUrl) async {
    _pendingOAuthFlow = await _client.initiateOAuthFlow(serverUrl);
    notifyListeners();
    return _pendingOAuthFlow!;
  }

  /// Poll for OAuth completion
  ///
  /// Returns the result when complete, or null if still pending.
  Future<LoginFlowResult?> pollOAuthFlow() async {
    if (_pendingOAuthFlow == null) return null;

    _isPollingOAuth = true;
    notifyListeners();

    try {
      final result = await _client.pollOAuthFlow(
        _pendingOAuthFlow!.pollEndpoint,
        _pendingOAuthFlow!.pollToken,
      );

      if (result != null) {
        _pendingOAuthFlow = null;
        _isPollingOAuth = false;
        notifyListeners();
      }

      return result;
    } catch (e) {
      _isPollingOAuth = false;
      _pendingOAuthFlow = null;
      notifyListeners();
      rethrow;
    }
  }

  /// Cancel OAuth flow
  void cancelOAuthFlow() {
    _pendingOAuthFlow = null;
    _isPollingOAuth = false;
    notifyListeners();
  }

  // ===== Authentication =====

  /// Validate app password credentials
  Future<NextcloudServerInfo> validateCredentials(
    String serverUrl,
    String username,
    String appPassword,
  ) =>
      _client.validateAppPassword(serverUrl, username, appPassword);

  /// Save credentials for a catalog
  Future<void> saveCredentials(String catalogId, String appPassword) =>
      _client.saveCredentials(catalogId, appPassword);

  /// Delete credentials for a catalog
  Future<void> deleteCredentials(String catalogId) =>
      _client.deleteCredentials(catalogId);

  /// Check if a URL is a valid Nextcloud server
  Future<bool> isNextcloudServer(String serverUrl) =>
      _client.isNextcloudServer(serverUrl);
}
