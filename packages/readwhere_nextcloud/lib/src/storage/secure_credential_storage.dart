import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart' as plugin;

import 'credential_storage.dart';

/// Secure credential storage using flutter_secure_storage
///
/// Uses encrypted storage on both Android (EncryptedSharedPreferences)
/// and iOS (Keychain).
///
/// Implements both [NextcloudCredentialStorage] for Nextcloud-specific
/// operations and [plugin.CredentialStorage] for generic plugin compatibility.
class SecureCredentialStorage
    implements NextcloudCredentialStorage, plugin.CredentialStorage {
  final FlutterSecureStorage _storage;

  /// Key prefixes for different credential types
  static const String _appPasswordPrefix = 'nc_app_password_';
  static const String _accessTokenPrefix = 'nc_access_token_';
  static const String _credentialPrefix = 'catalog_';

  SecureCredentialStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  // ===== NextcloudCredentialStorage implementation =====

  @override
  Future<void> saveAppPassword(String catalogId, String appPassword) async {
    await _storage.write(
      key: '$_appPasswordPrefix$catalogId',
      value: appPassword,
    );
  }

  @override
  Future<String?> getAppPassword(String catalogId) async {
    return await _storage.read(key: '$_appPasswordPrefix$catalogId');
  }

  @override
  Future<void> saveAccessToken(String catalogId, String accessToken) async {
    await _storage.write(
      key: '$_accessTokenPrefix$catalogId',
      value: accessToken,
    );
  }

  @override
  Future<String?> getAccessToken(String catalogId) async {
    return await _storage.read(key: '$_accessTokenPrefix$catalogId');
  }

  @override
  Future<void> deleteCredentials(String catalogId) async {
    await _storage.delete(key: '$_appPasswordPrefix$catalogId');
    await _storage.delete(key: '$_accessTokenPrefix$catalogId');
  }

  @override
  Future<bool> hasCredentials(String catalogId) async {
    final appPassword = await getAppPassword(catalogId);
    final accessToken = await getAccessToken(catalogId);
    return appPassword != null || accessToken != null;
  }

  @override
  Future<String?> getCredential(String catalogId) async {
    final appPassword = await getAppPassword(catalogId);
    if (appPassword != null) return appPassword;
    return await getAccessToken(catalogId);
  }

  @override
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  // ===== plugin.CredentialStorage implementation =====

  String _genericKey(String catalogId, String credentialType) =>
      '$_credentialPrefix${catalogId}_$credentialType';

  @override
  Future<void> save(
    String catalogId,
    String credentialType,
    String value,
  ) async {
    // Map common types to Nextcloud-specific storage for interoperability
    if (credentialType == plugin.CredentialType.appPassword) {
      await saveAppPassword(catalogId, value);
    } else if (credentialType == plugin.CredentialType.accessToken) {
      await saveAccessToken(catalogId, value);
    } else {
      await _storage.write(
        key: _genericKey(catalogId, credentialType),
        value: value,
      );
    }
  }

  @override
  Future<String?> get(String catalogId, String credentialType) async {
    // Map common types to Nextcloud-specific storage for interoperability
    if (credentialType == plugin.CredentialType.appPassword) {
      return getAppPassword(catalogId);
    } else if (credentialType == plugin.CredentialType.accessToken) {
      return getAccessToken(catalogId);
    } else {
      return _storage.read(key: _genericKey(catalogId, credentialType));
    }
  }

  @override
  Future<void> delete(String catalogId, String credentialType) async {
    if (credentialType == plugin.CredentialType.appPassword) {
      await _storage.delete(key: '$_appPasswordPrefix$catalogId');
    } else if (credentialType == plugin.CredentialType.accessToken) {
      await _storage.delete(key: '$_accessTokenPrefix$catalogId');
    } else {
      await _storage.delete(key: _genericKey(catalogId, credentialType));
    }
  }

  @override
  Future<void> deleteAllForCatalog(String catalogId) async {
    // Delete Nextcloud-specific credentials
    await deleteCredentials(catalogId);
    // Note: Generic credentials would need to be tracked separately
    // for complete cleanup, but this covers the common case
  }
}
