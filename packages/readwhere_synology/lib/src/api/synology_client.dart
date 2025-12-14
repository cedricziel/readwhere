import 'dart:io';

import '../auth/synology_session.dart';
import '../exceptions/synology_exception.dart';
import '../storage/session_storage.dart';
import 'models/list_result.dart';
import 'models/search_result.dart';
import 'models/synology_file.dart';
import 'synology_api_service.dart';

/// High-level client for Synology Drive operations.
///
/// Handles session management, automatic re-authentication on session expiry,
/// and provides a simplified API for common operations.
class SynologyClient {
  /// Creates a new [SynologyClient].
  SynologyClient({
    required SynologyApiService api,
    required SynologySessionStorage storage,
  })  : _api = api,
        _storage = storage;

  /// Creates a [SynologyClient] with default implementations.
  factory SynologyClient.create({
    required SynologySessionStorage storage,
  }) {
    return SynologyClient(
      api: SynologyApiService(),
      storage: storage,
    );
  }

  final SynologyApiService _api;
  final SynologySessionStorage _storage;

  /// Authenticates with the Synology NAS and stores the session.
  ///
  /// Returns the created [SynologySession] on success.
  Future<SynologySession> authenticate({
    required String catalogId,
    required String serverUrl,
    required String account,
    required String password,
  }) async {
    final normalizedUrl = SynologyApiService.normalizeUrl(serverUrl);
    final result = await _api.login(normalizedUrl, account, password);

    if (!result.success || result.sessionId == null) {
      throw SynologyException(
        result.errorMessage ?? 'Authentication failed',
        errorCode: result.errorCode,
      );
    }

    final session = SynologySession(
      catalogId: catalogId,
      serverUrl: normalizedUrl,
      sessionId: result.sessionId!,
      deviceId: result.deviceId ?? '',
      createdAt: DateTime.now(),
    );

    // Store session and credentials
    await Future.wait([
      _storage.saveSession(catalogId, session),
      _storage.saveCredentials(catalogId, account, password),
    ]);

    return session;
  }

  /// Logs out from the Synology NAS and clears stored data.
  Future<void> logout(String catalogId) async {
    final session = await _storage.getSession(catalogId);
    if (session != null) {
      try {
        await _api.logout(session.serverUrl, session.sessionId);
      } catch (e) {
        // Ignore logout errors
      }
    }

    await _storage.deleteAllForCatalog(catalogId);
  }

  /// Checks if there is an active (non-expired) session for the catalog.
  Future<bool> hasActiveSession(String catalogId) async {
    final session = await _storage.getSession(catalogId);
    return session != null && !session.isExpired;
  }

  /// Gets the current session, refreshing if expired.
  ///
  /// Throws [SynologyException] if no credentials are available.
  Future<SynologySession> getOrRefreshSession(String catalogId) async {
    final session = await _storage.getSession(catalogId);

    if (session != null && !session.isExpired) {
      return session;
    }

    // Session is expired or missing, try to refresh
    final credentials = await _storage.getCredentials(catalogId);
    if (credentials == null) {
      throw const SynologyException(
        'No credentials available for re-authentication',
      );
    }

    final serverUrl =
        session?.serverUrl ?? await _getServerUrlFromCatalog(catalogId);
    if (serverUrl == null) {
      throw const SynologyException('Server URL not found');
    }

    return authenticate(
      catalogId: catalogId,
      serverUrl: serverUrl,
      account: credentials.$1,
      password: credentials.$2,
    );
  }

  /// Gets the server URL for a catalog (to be overridden or injected).
  Future<String?> _getServerUrlFromCatalog(String catalogId) async {
    // This would typically come from the catalog repository
    // For now, return null and rely on stored session having the URL
    return null;
  }

  /// Lists files in a directory.
  Future<ListResult> listDirectory(
    String catalogId,
    String path, {
    String sortBy = 'name',
    String sortDirection = 'asc',
    int offset = 0,
    int limit = 0,
    List<String>? extensions,
  }) async {
    final session = await getOrRefreshSession(catalogId);

    try {
      return await _api.listFiles(
        session.serverUrl,
        session.sessionId,
        path: path,
        sortBy: sortBy,
        sortDirection: sortDirection,
        offset: offset,
        limit: limit,
        extensions: extensions,
      );
    } on SynologyException catch (e) {
      if (e.isSessionExpired) {
        // Session expired during request, refresh and retry
        await _storage.deleteSession(catalogId);
        final newSession = await getOrRefreshSession(catalogId);
        return _api.listFiles(
          newSession.serverUrl,
          newSession.sessionId,
          path: path,
          sortBy: sortBy,
          sortDirection: sortDirection,
          offset: offset,
          limit: limit,
          extensions: extensions,
        );
      }
      rethrow;
    }
  }

  /// Gets metadata for a single file.
  Future<SynologyFile> getFileMetadata(String catalogId, String path) async {
    final session = await getOrRefreshSession(catalogId);

    try {
      return await _api.getFileMetadata(
        session.serverUrl,
        session.sessionId,
        path,
      );
    } on SynologyException catch (e) {
      if (e.isSessionExpired) {
        await _storage.deleteSession(catalogId);
        final newSession = await getOrRefreshSession(catalogId);
        return _api.getFileMetadata(
          newSession.serverUrl,
          newSession.sessionId,
          path,
        );
      }
      rethrow;
    }
  }

  /// Downloads a file to a local path.
  Future<File> downloadFile(
    String catalogId,
    String remotePath,
    String localPath, {
    void Function(int received, int total)? onProgress,
  }) async {
    final session = await getOrRefreshSession(catalogId);

    try {
      return await _api.downloadFileTo(
        session.serverUrl,
        session.sessionId,
        remotePath,
        localPath,
        onProgress: onProgress,
      );
    } on SynologyException catch (e) {
      if (e.isSessionExpired) {
        await _storage.deleteSession(catalogId);
        final newSession = await getOrRefreshSession(catalogId);
        return _api.downloadFileTo(
          newSession.serverUrl,
          newSession.sessionId,
          remotePath,
          localPath,
          onProgress: onProgress,
        );
      }
      rethrow;
    }
  }

  /// Searches for files.
  Future<SearchResult> search(
    String catalogId,
    String keyword, {
    String? fileType,
    String location = 'mydrive',
    int offset = 0,
    int limit = 100,
  }) async {
    final session = await getOrRefreshSession(catalogId);

    try {
      return await _api.search(
        session.serverUrl,
        session.sessionId,
        keyword: keyword,
        fileType: fileType,
        location: location,
        offset: offset,
        limit: limit,
      );
    } on SynologyException catch (e) {
      if (e.isSessionExpired) {
        await _storage.deleteSession(catalogId);
        final newSession = await getOrRefreshSession(catalogId);
        return _api.search(
          newSession.serverUrl,
          newSession.sessionId,
          keyword: keyword,
          fileType: fileType,
          location: location,
          offset: offset,
          limit: limit,
        );
      }
      rethrow;
    }
  }

  /// Creates a folder.
  Future<SynologyFile> createFolder(
    String catalogId,
    String path, {
    String conflictAction = 'autorename',
  }) async {
    final session = await getOrRefreshSession(catalogId);

    try {
      return await _api.createFolder(
        session.serverUrl,
        session.sessionId,
        path,
        conflictAction: conflictAction,
      );
    } on SynologyException catch (e) {
      if (e.isSessionExpired) {
        await _storage.deleteSession(catalogId);
        final newSession = await getOrRefreshSession(catalogId);
        return _api.createFolder(
          newSession.serverUrl,
          newSession.sessionId,
          path,
          conflictAction: conflictAction,
        );
      }
      rethrow;
    }
  }

  /// Validates connection to a Synology NAS without storing credentials.
  ///
  /// Returns true if login succeeds, throws [SynologyException] otherwise.
  Future<bool> validateConnection(
    String serverUrl,
    String account,
    String password,
  ) async {
    final normalizedUrl = SynologyApiService.normalizeUrl(serverUrl);
    final result = await _api.login(normalizedUrl, account, password);

    if (!result.success) {
      throw SynologyException(
        result.errorMessage ?? 'Connection failed',
        errorCode: result.errorCode,
      );
    }

    // Logout immediately since we're just validating
    if (result.sessionId != null) {
      try {
        await _api.logout(normalizedUrl, result.sessionId!);
      } catch (e) {
        // Ignore logout errors
      }
    }

    return true;
  }

  /// Stores credentials securely without authenticating.
  ///
  /// This is useful when adding a new catalog and you want to store
  /// credentials before opening the browser.
  Future<void> storeCredentials(
    String catalogId,
    String username,
    String password,
  ) async {
    await _storage.saveCredentials(catalogId, username, password);
  }

  /// Clears stored credentials and session for a catalog.
  Future<void> clearCredentials(String catalogId) async {
    await _storage.deleteAllForCatalog(catalogId);
  }
}
