import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/synology_session.dart';
import 'session_storage.dart';

/// Secure implementation of [SynologySessionStorage] using flutter_secure_storage.
class SecureSynologySessionStorage implements SynologySessionStorage {
  /// Creates a new [SecureSynologySessionStorage].
  SecureSynologySessionStorage({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _secureStorage;

  // Key prefixes for different data types
  static const String _sessionPrefix = 'synology_session_';
  static const String _accountPrefix = 'synology_account_';
  static const String _passwordPrefix = 'synology_password_';

  String _sessionKey(String catalogId) => '$_sessionPrefix$catalogId';
  String _accountKey(String catalogId) => '$_accountPrefix$catalogId';
  String _passwordKey(String catalogId) => '$_passwordPrefix$catalogId';

  @override
  Future<void> saveSession(String catalogId, SynologySession session) async {
    await _secureStorage.write(
      key: _sessionKey(catalogId),
      value: session.toJsonString(),
    );
  }

  @override
  Future<SynologySession?> getSession(String catalogId) async {
    final jsonString = await _secureStorage.read(key: _sessionKey(catalogId));
    if (jsonString == null) return null;

    try {
      return SynologySession.fromJsonString(jsonString);
    } catch (e) {
      // Invalid JSON, delete the corrupted data
      await deleteSession(catalogId);
      return null;
    }
  }

  @override
  Future<void> deleteSession(String catalogId) async {
    await _secureStorage.delete(key: _sessionKey(catalogId));
  }

  @override
  Future<bool> hasSession(String catalogId) async {
    final value = await _secureStorage.read(key: _sessionKey(catalogId));
    return value != null;
  }

  @override
  Future<void> saveCredentials(
    String catalogId,
    String account,
    String password,
  ) async {
    await Future.wait([
      _secureStorage.write(key: _accountKey(catalogId), value: account),
      _secureStorage.write(key: _passwordKey(catalogId), value: password),
    ]);
  }

  @override
  Future<(String account, String password)?> getCredentials(
    String catalogId,
  ) async {
    final results = await Future.wait([
      _secureStorage.read(key: _accountKey(catalogId)),
      _secureStorage.read(key: _passwordKey(catalogId)),
    ]);

    final account = results[0];
    final password = results[1];

    if (account == null || password == null) return null;
    return (account, password);
  }

  @override
  Future<void> deleteCredentials(String catalogId) async {
    await Future.wait([
      _secureStorage.delete(key: _accountKey(catalogId)),
      _secureStorage.delete(key: _passwordKey(catalogId)),
    ]);
  }

  @override
  Future<bool> hasCredentials(String catalogId) async {
    final account = await _secureStorage.read(key: _accountKey(catalogId));
    final password = await _secureStorage.read(key: _passwordKey(catalogId));
    return account != null && password != null;
  }

  @override
  Future<void> deleteAll() async {
    final allKeys = await _secureStorage.readAll();
    final keysToDelete = allKeys.keys.where(
      (key) =>
          key.startsWith(_sessionPrefix) ||
          key.startsWith(_accountPrefix) ||
          key.startsWith(_passwordPrefix),
    );

    await Future.wait(
      keysToDelete.map((key) => _secureStorage.delete(key: key)),
    );
  }

  @override
  Future<void> deleteAllForCatalog(String catalogId) async {
    await Future.wait([
      deleteSession(catalogId),
      deleteCredentials(catalogId),
    ]);
  }
}
