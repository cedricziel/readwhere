import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing sensitive credentials
///
/// Uses flutter_secure_storage for encrypted storage of passwords and tokens.
/// Credentials are keyed by catalog ID to support multiple accounts.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  /// Key prefixes for different credential types
  static const String _appPasswordPrefix = 'nc_app_password_';
  static const String _accessTokenPrefix = 'nc_access_token_';

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  /// Save an app password for a Nextcloud catalog
  Future<void> saveAppPassword(String catalogId, String appPassword) async {
    await _storage.write(
      key: '$_appPasswordPrefix$catalogId',
      value: appPassword,
    );
  }

  /// Get the app password for a Nextcloud catalog
  Future<String?> getAppPassword(String catalogId) async {
    return await _storage.read(key: '$_appPasswordPrefix$catalogId');
  }

  /// Save an access token (from OAuth flow)
  Future<void> saveAccessToken(String catalogId, String accessToken) async {
    await _storage.write(
      key: '$_accessTokenPrefix$catalogId',
      value: accessToken,
    );
  }

  /// Get the access token for a catalog
  Future<String?> getAccessToken(String catalogId) async {
    return await _storage.read(key: '$_accessTokenPrefix$catalogId');
  }

  /// Delete all credentials for a catalog
  Future<void> deleteCredentials(String catalogId) async {
    await _storage.delete(key: '$_appPasswordPrefix$catalogId');
    await _storage.delete(key: '$_accessTokenPrefix$catalogId');
  }

  /// Check if credentials exist for a catalog
  Future<bool> hasCredentials(String catalogId) async {
    final appPassword = await getAppPassword(catalogId);
    final accessToken = await getAccessToken(catalogId);
    return appPassword != null || accessToken != null;
  }

  /// Get the credential (either app password or access token) for a catalog
  /// Returns app password if available, otherwise access token
  Future<String?> getCredential(String catalogId) async {
    final appPassword = await getAppPassword(catalogId);
    if (appPassword != null) return appPassword;
    return await getAccessToken(catalogId);
  }

  /// Delete all stored credentials (for logout/reset)
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
