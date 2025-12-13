import 'package:http/http.dart' as http;

import 'ocs_api_service.dart';
import 'models/server_info.dart';
import '../auth/models/login_flow_init.dart';
import '../auth/models/login_flow_result.dart';
import '../storage/credential_storage.dart';
import '../webdav/nextcloud_webdav.dart';
import '../webdav/nextcloud_file.dart';

/// Main facade for Nextcloud operations
///
/// Provides a unified interface for:
/// - OCS API authentication (app passwords, OAuth2)
/// - WebDAV file operations
/// - Credential storage
class NextcloudClient {
  /// OCS API service for authentication
  final OcsApiService api;

  /// WebDAV service for file operations
  final NextcloudWebDav webdav;

  /// Credential storage
  final NextcloudCredentialStorage storage;

  NextcloudClient({
    required this.api,
    required this.webdav,
    required this.storage,
  });

  /// Create a NextcloudClient with default services
  factory NextcloudClient.create({
    http.Client? httpClient,
    required NextcloudCredentialStorage credentialStorage,
    String userAgent = 'ReadWhere/1.0.0 Nextcloud',
  }) {
    final client = httpClient ?? http.Client();

    return NextcloudClient(
      api: OcsApiService(client, userAgent: userAgent),
      webdav:
          NextcloudWebDav(credentialStorage, userAgent: '$userAgent-WebDAV'),
      storage: credentialStorage,
    );
  }

  // ===== Authentication =====

  /// Validate app password and return server info
  Future<NextcloudServerInfo> validateAppPassword(
    String serverUrl,
    String username,
    String appPassword,
  ) =>
      api.validateAppPassword(serverUrl, username, appPassword);

  /// Initiate OAuth2 Login Flow v2
  Future<LoginFlowInit> initiateOAuthFlow(String serverUrl) =>
      api.initiateOAuthFlow(serverUrl);

  /// Poll for OAuth2 completion
  Future<LoginFlowResult?> pollOAuthFlow(
    String pollEndpoint,
    String pollToken,
  ) =>
      api.pollOAuthFlow(pollEndpoint, pollToken);

  /// Check if a URL is a valid Nextcloud server
  Future<bool> isNextcloudServer(String serverUrl) =>
      api.isNextcloudServer(serverUrl);

  // ===== Credential Management =====

  /// Save app password for a catalog
  Future<void> saveCredentials(String catalogId, String appPassword) =>
      storage.saveAppPassword(catalogId, appPassword);

  /// Delete credentials for a catalog
  Future<void> deleteCredentials(String catalogId) =>
      storage.deleteCredentials(catalogId);

  /// Check if credentials exist
  Future<bool> hasCredentials(String catalogId) =>
      storage.hasCredentials(catalogId);

  // ===== File Operations =====

  /// List directory contents
  Future<List<NextcloudFile>> listDirectory({
    required String serverUrl,
    required String userId,
    required String catalogId,
    required String? username,
    required String path,
  }) =>
      webdav.listDirectory(
        serverUrl: serverUrl,
        userId: userId,
        catalogId: catalogId,
        username: username,
        path: path,
      );

  /// List directory contents using direct credentials (without storage lookup)
  ///
  /// This is useful for browsing before credentials are saved, such as
  /// during catalog setup when selecting a starting folder.
  Future<List<NextcloudFile>> listDirectoryWithCredentials({
    required String serverUrl,
    required String userId,
    required String username,
    required String password,
    required String path,
  }) =>
      webdav.listDirectoryWithCredentials(
        serverUrl: serverUrl,
        userId: userId,
        username: username,
        password: password,
        path: path,
      );

  /// Download a file
  Future<void> downloadFile({
    required String serverUrl,
    required String userId,
    required String catalogId,
    required String? username,
    required String remotePath,
    required String localPath,
    void Function(int received, int total)? onProgress,
  }) async {
    await webdav.downloadFile(
      serverUrl: serverUrl,
      userId: userId,
      catalogId: catalogId,
      username: username,
      remotePath: remotePath,
      localPath: localPath,
      onProgress: onProgress,
    );
  }
}
