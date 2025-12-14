import '../auth/synology_session.dart';

/// Abstract interface for storing Synology Drive sessions and credentials.
abstract class SynologySessionStorage {
  /// Saves a session for the given catalog.
  Future<void> saveSession(String catalogId, SynologySession session);

  /// Gets the session for the given catalog.
  Future<SynologySession?> getSession(String catalogId);

  /// Deletes the session for the given catalog.
  Future<void> deleteSession(String catalogId);

  /// Checks if a session exists for the given catalog.
  Future<bool> hasSession(String catalogId);

  /// Saves credentials for re-authentication.
  ///
  /// These are stored securely and used to refresh expired sessions.
  Future<void> saveCredentials(
    String catalogId,
    String account,
    String password,
  );

  /// Gets saved credentials for the given catalog.
  ///
  /// Returns a tuple of (account, password) or null if not found.
  Future<(String account, String password)?> getCredentials(String catalogId);

  /// Deletes credentials for the given catalog.
  Future<void> deleteCredentials(String catalogId);

  /// Checks if credentials exist for the given catalog.
  Future<bool> hasCredentials(String catalogId);

  /// Deletes all sessions and credentials.
  Future<void> deleteAll();

  /// Deletes all data for a specific catalog.
  Future<void> deleteAllForCatalog(String catalogId);
}
