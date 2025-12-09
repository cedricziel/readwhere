/// Interface for storing and retrieving authentication credentials.
///
/// Implementations should provide secure storage for sensitive data
/// like passwords, tokens, and API keys. The storage is organized
/// by catalog ID, allowing each catalog to have its own set of
/// credentials.
///
/// Example implementation with flutter_secure_storage:
/// ```dart
/// class SecureCredentialStorage implements CredentialStorage {
///   final FlutterSecureStorage _storage;
///
///   SecureCredentialStorage(this._storage);
///
///   String _key(String catalogId, String credentialType) =>
///       'catalog_$catalogId_$credentialType';
///
///   @override
///   Future<void> save(String catalogId, String credentialType, String value) =>
///       _storage.write(key: _key(catalogId, credentialType), value: value);
///
///   @override
///   Future<String?> get(String catalogId, String credentialType) =>
///       _storage.read(key: _key(catalogId, credentialType));
///   // ... etc
/// }
/// ```
abstract class CredentialStorage {
  /// Saves a credential value for a catalog.
  ///
  /// [catalogId] identifies the catalog these credentials belong to.
  /// [credentialType] identifies the type of credential (e.g., 'username',
  /// 'password', 'access_token', 'refresh_token', 'api_key').
  /// [value] is the credential value to store.
  Future<void> save(String catalogId, String credentialType, String value);

  /// Retrieves a credential value for a catalog.
  ///
  /// Returns null if no credential of the specified type exists for
  /// the catalog.
  Future<String?> get(String catalogId, String credentialType);

  /// Deletes a specific credential for a catalog.
  Future<void> delete(String catalogId, String credentialType);

  /// Deletes all credentials for a catalog.
  ///
  /// Call this when removing a catalog or logging out.
  Future<void> deleteAllForCatalog(String catalogId);

  /// Checks whether any credentials exist for a catalog.
  Future<bool> hasCredentials(String catalogId);

  /// Deletes all stored credentials.
  ///
  /// Use with caution - this removes all credentials for all catalogs.
  Future<void> deleteAll();
}

/// Common credential type constants.
///
/// Use these when storing/retrieving credentials to ensure consistency.
abstract class CredentialType {
  /// Username for basic auth.
  static const String username = 'username';

  /// Password for basic auth.
  static const String password = 'password';

  /// OAuth2 access token.
  static const String accessToken = 'access_token';

  /// OAuth2 refresh token.
  static const String refreshToken = 'refresh_token';

  /// Token expiration timestamp (ISO 8601).
  static const String tokenExpiry = 'token_expiry';

  /// API key.
  static const String apiKey = 'api_key';

  /// Bearer token.
  static const String bearerToken = 'bearer_token';

  /// Server URL (for OAuth flows that need it).
  static const String serverUrl = 'server_url';

  /// User ID on the remote service.
  static const String userId = 'user_id';

  /// App password (e.g., Nextcloud app passwords).
  static const String appPassword = 'app_password';
}

/// An in-memory implementation of [CredentialStorage] for testing.
///
/// This implementation stores credentials in memory and is not secure.
/// Do not use in production.
class InMemoryCredentialStorage implements CredentialStorage {
  final Map<String, Map<String, String>> _storage = {};

  @override
  Future<void> save(
    String catalogId,
    String credentialType,
    String value,
  ) async {
    _storage.putIfAbsent(catalogId, () => {});
    _storage[catalogId]![credentialType] = value;
  }

  @override
  Future<String?> get(String catalogId, String credentialType) async {
    return _storage[catalogId]?[credentialType];
  }

  @override
  Future<void> delete(String catalogId, String credentialType) async {
    _storage[catalogId]?.remove(credentialType);
  }

  @override
  Future<void> deleteAllForCatalog(String catalogId) async {
    _storage.remove(catalogId);
  }

  @override
  Future<bool> hasCredentials(String catalogId) async {
    final catalogCreds = _storage[catalogId];
    return catalogCreds != null && catalogCreds.isNotEmpty;
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }
}
