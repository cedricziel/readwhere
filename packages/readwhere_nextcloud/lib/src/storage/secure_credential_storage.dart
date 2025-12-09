import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'credential_storage.dart';

/// Secure credential storage using flutter_secure_storage
///
/// Uses encrypted storage on both Android (EncryptedSharedPreferences)
/// and iOS (Keychain).
class SecureCredentialStorage implements CredentialStorage {
  final FlutterSecureStorage _storage;

  /// Key prefixes for different credential types
  static const String _appPasswordPrefix = 'nc_app_password_';
  static const String _accessTokenPrefix = 'nc_access_token_';

  SecureCredentialStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

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
}
