/// Abstract interface for storing Nextcloud credentials
///
/// Implement this interface to provide custom credential storage.
/// The package provides a default implementation using flutter_secure_storage.
///
/// This is a Nextcloud-specific interface. For the generic plugin interface,
/// see `CredentialStorage` from `readwhere_plugin`.
abstract class NextcloudCredentialStorage {
  /// Save an app password for a catalog
  Future<void> saveAppPassword(String catalogId, String appPassword);

  /// Get the app password for a catalog
  Future<String?> getAppPassword(String catalogId);

  /// Save an access token (from OAuth flow)
  Future<void> saveAccessToken(String catalogId, String accessToken);

  /// Get the access token for a catalog
  Future<String?> getAccessToken(String catalogId);

  /// Delete all credentials for a catalog
  Future<void> deleteCredentials(String catalogId);

  /// Check if credentials exist for a catalog
  Future<bool> hasCredentials(String catalogId);

  /// Get the credential (either app password or access token) for a catalog
  ///
  /// Returns app password if available, otherwise access token.
  Future<String?> getCredential(String catalogId);

  /// Delete all stored credentials
  Future<void> deleteAll();
}

/// Deprecated: Use [NextcloudCredentialStorage] instead.
///
/// This typedef exists for backward compatibility.
@Deprecated('Use NextcloudCredentialStorage instead')
typedef CredentialStorage = NextcloudCredentialStorage;
