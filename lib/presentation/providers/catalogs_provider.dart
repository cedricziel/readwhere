import 'package:flutter/foundation.dart';
import 'package:readwhere_kavita/readwhere_kavita.dart';
import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';
import 'package:readwhere_opds/readwhere_opds.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/catalog.dart';
import '../../domain/repositories/catalog_repository.dart';

/// Provider for managing the catalog (server) list.
///
/// This provider handles:
/// - Loading/saving the list of catalogs
/// - Adding, updating, and removing catalogs
/// - Catalog validation (routes to appropriate client)
///
/// For browsing catalogs, use the type-specific providers:
/// - [OpdsProvider] for OPDS catalogs
/// - [KavitaProvider] for Kavita servers
/// - [NextcloudProvider] for Nextcloud servers
class CatalogsProvider extends ChangeNotifier {
  final CatalogRepository _catalogRepository;
  final OpdsClient _opdsClient;
  final KavitaApiClient _kavitaApiClient;
  final NextcloudProvider? _nextcloudProvider;
  final NextcloudCredentialStorage? _credentialStorage;

  CatalogsProvider({
    required CatalogRepository catalogRepository,
    required OpdsClient opdsClient,
    required KavitaApiClient kavitaApiClient,
    NextcloudProvider? nextcloudProvider,
    NextcloudCredentialStorage? credentialStorage,
  }) : _catalogRepository = catalogRepository,
       _opdsClient = opdsClient,
       _kavitaApiClient = kavitaApiClient,
       _nextcloudProvider = nextcloudProvider,
       _credentialStorage = credentialStorage;

  // State
  List<Catalog> _catalogs = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Catalog> get catalogs => List.unmodifiable(_catalogs);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get catalogCount => _catalogs.length;

  // ===== Catalog List Management =====

  /// Load all catalogs from the repository
  Future<void> loadCatalogs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _catalogs = await _catalogRepository.getAll();
    } catch (e) {
      _error = 'Failed to load catalogs: $e';
      _catalogs = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get a catalog by ID
  Future<Catalog?> getCatalogById(String id) async {
    return await _catalogRepository.getById(id);
  }

  /// Add a new OPDS catalog
  Future<Catalog?> addOpdsCatalog({
    required String name,
    required String url,
    String? iconUrl,
  }) async {
    return _addCatalog(
      name: name,
      url: url,
      type: CatalogType.opds,
      iconUrl: iconUrl,
    );
  }

  /// Add a new Kavita catalog
  Future<Catalog?> addKavitaCatalog({
    required String name,
    required String url,
    required String apiKey,
    String? serverVersion,
    String? iconUrl,
  }) async {
    return _addCatalog(
      name: name,
      url: url,
      type: CatalogType.kavita,
      apiKey: apiKey,
      serverVersion: serverVersion,
      iconUrl: iconUrl,
    );
  }

  /// Add a new Nextcloud catalog
  Future<Catalog?> addNextcloudCatalog({
    required String name,
    required String url,
    required String username,
    required String appPassword,
    String? userId,
    String? booksFolder,
    String? serverVersion,
  }) async {
    debugPrint('addNextcloudCatalog: name=$name, url=$url, username=$username');

    if (_credentialStorage == null) {
      debugPrint('addNextcloudCatalog: Credential storage is null!');
      _error = 'Credential storage not available';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id = const Uuid().v4();
      debugPrint('addNextcloudCatalog: Generated ID: $id');

      // Store password securely
      await _credentialStorage.saveAppPassword(id, appPassword);
      debugPrint('addNextcloudCatalog: Saved app password');

      final catalog = Catalog(
        id: id,
        name: name,
        url: url,
        type: CatalogType.nextcloud,
        addedAt: DateTime.now(),
        username: username,
        userId: userId ?? username,
        booksFolder: booksFolder ?? '/Books',
        serverVersion: serverVersion,
      );

      debugPrint('addNextcloudCatalog: Inserting catalog into repository...');
      await _catalogRepository.insert(catalog);
      _catalogs = await _catalogRepository.getAll();
      debugPrint(
        'addNextcloudCatalog: Success! Total catalogs: ${_catalogs.length}',
      );

      return catalog;
    } catch (e, stackTrace) {
      debugPrint('addNextcloudCatalog ERROR: $e');
      debugPrint('Stack trace: $stackTrace');
      _error = 'Failed to add Nextcloud catalog: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generic add catalog (internal)
  Future<Catalog?> _addCatalog({
    required String name,
    required String url,
    required CatalogType type,
    String? apiKey,
    String? iconUrl,
    String? serverVersion,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if catalog with same URL exists
      final existing = await _catalogRepository.findByUrl(url);
      if (existing != null) {
        _error = 'A catalog with this URL already exists';
        return null;
      }

      final catalog = Catalog(
        id: const Uuid().v4(),
        name: name,
        url: url,
        iconUrl: iconUrl,
        addedAt: DateTime.now(),
        apiKey: apiKey,
        type: type,
        serverVersion: serverVersion,
      );

      final inserted = await _catalogRepository.insert(catalog);
      _catalogs.insert(0, inserted);
      return inserted;
    } catch (e) {
      _error = 'Failed to add catalog: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update an existing catalog
  Future<Catalog?> updateCatalog(Catalog catalog) async {
    _error = null;

    try {
      final updated = await _catalogRepository.update(catalog);
      final index = _catalogs.indexWhere((c) => c.id == catalog.id);
      if (index != -1) {
        _catalogs[index] = updated;
      }
      notifyListeners();
      return updated;
    } catch (e) {
      _error = 'Failed to update catalog: $e';
      notifyListeners();
      return null;
    }
  }

  /// Remove a catalog
  Future<bool> removeCatalog(String id) async {
    _error = null;

    try {
      // Get catalog to check type
      final catalog = _catalogs.firstWhere(
        (c) => c.id == id,
        orElse: () => throw Exception('Catalog not found'),
      );

      // Delete associated credentials for Nextcloud
      if (catalog.type == CatalogType.nextcloud && _credentialStorage != null) {
        await _credentialStorage.deleteCredentials(id);
      }

      final success = await _catalogRepository.delete(id);
      if (success) {
        _catalogs.removeWhere((c) => c.id == id);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = 'Failed to remove catalog: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update last accessed timestamp for a catalog
  Future<void> updateLastAccessed(String catalogId) async {
    await _catalogRepository.updateLastAccessed(catalogId);
  }

  // ===== Validation =====

  /// Validate an OPDS catalog URL
  ///
  /// Returns the parsed feed if valid, throws exception otherwise.
  Future<OpdsFeed> validateOpdsCatalog(String url) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final feed = await _opdsClient.validateCatalog(url);
      return feed;
    } catch (e) {
      _error = 'Validation failed: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Validate a Kavita server and API key
  ///
  /// Returns the server info if valid, throws exception otherwise.
  Future<KavitaServerInfo> validateKavitaServer(
    String serverUrl,
    String apiKey,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final serverInfo = await _kavitaApiClient.authenticate(serverUrl, apiKey);

      // Also validate the OPDS endpoint works
      final baseUrl = serverUrl.endsWith('/')
          ? serverUrl.substring(0, serverUrl.length - 1)
          : serverUrl;
      final opdsUrl = '$baseUrl/api/opds/$apiKey';
      await _opdsClient.validateCatalog(opdsUrl);

      return serverInfo;
    } catch (e) {
      _error = 'Validation failed: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Validate Nextcloud server credentials
  Future<NextcloudServerInfo> validateNextcloud(
    String serverUrl,
    String username,
    String appPassword,
  ) async {
    if (_nextcloudProvider == null) {
      throw Exception('Nextcloud service not available');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      return await _nextcloudProvider.validateCredentials(
        serverUrl,
        username,
        appPassword,
      );
    } catch (e) {
      _error = 'Validation failed: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===== Nextcloud OAuth =====

  /// Get OAuth login URL if an OAuth flow is pending
  String? get oAuthLoginUrl => _nextcloudProvider?.pendingOAuthFlow?.loginUrl;

  /// Whether currently polling for OAuth completion
  bool get isPollingOAuth => _nextcloudProvider?.isPollingOAuth ?? false;

  /// Start Nextcloud OAuth2 Login Flow v2
  Future<void> startNextcloudOAuth(String serverUrl) async {
    if (_nextcloudProvider == null) {
      throw Exception('Nextcloud service not available');
    }

    await _nextcloudProvider.startOAuthFlow(serverUrl);
    notifyListeners();
  }

  /// Poll for OAuth flow completion
  /// Returns LoginFlowResult when complete, null if still pending
  Future<LoginFlowResult?> pollNextcloudOAuth() async {
    if (_nextcloudProvider == null) {
      return null;
    }

    final result = await _nextcloudProvider.pollOAuthFlow();
    if (result != null) {
      notifyListeners();
    }
    return result;
  }

  /// Cancel OAuth flow
  void cancelNextcloudOAuth() {
    _nextcloudProvider?.cancelOAuthFlow();
    notifyListeners();
  }

  /// Clear any error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
