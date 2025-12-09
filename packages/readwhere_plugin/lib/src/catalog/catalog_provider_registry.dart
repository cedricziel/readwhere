import '../account/account_provider.dart';
import '../entities/catalog_info.dart';
import 'catalog_capability.dart';
import 'catalog_provider.dart';

/// Registry for catalog providers and their associated account providers.
///
/// This is a singleton that manages the registration and lookup of
/// [CatalogProvider] implementations. Each provider is identified by
/// a unique ID (e.g., 'opds', 'nextcloud', 'kavita').
///
/// Example usage:
/// ```dart
/// // Register providers at app startup
/// final registry = CatalogProviderRegistry();
/// registry.register(
///   OpdsProvider(),
/// );
/// registry.register(
///   NextcloudCatalogProvider(),
///   accountProvider: NextcloudAccountProvider(),
/// );
///
/// // Look up a provider for a catalog
/// final provider = registry.getForCatalog(myCatalog);
/// if (provider != null) {
///   final result = await provider.browse(myCatalog);
/// }
/// ```
class CatalogProviderRegistry {
  CatalogProviderRegistry._internal();

  static final CatalogProviderRegistry _instance =
      CatalogProviderRegistry._internal();

  /// Returns the singleton instance of the registry.
  factory CatalogProviderRegistry() => _instance;

  final Map<String, CatalogProvider> _providers = {};
  final Map<String, AccountProvider> _accountProviders = {};

  /// Registers a catalog provider.
  ///
  /// [provider] is the catalog provider to register.
  /// [accountProvider] is an optional account provider for authentication.
  ///
  /// If a provider with the same ID is already registered, it will be
  /// replaced.
  void register(CatalogProvider provider, {AccountProvider? accountProvider}) {
    _providers[provider.id] = provider;
    if (accountProvider != null) {
      _accountProviders[provider.id] = accountProvider;
    }
  }

  /// Unregisters a provider by ID.
  ///
  /// Returns true if a provider was removed, false if no provider
  /// with that ID was registered.
  bool unregister(String id) {
    final removed = _providers.remove(id) != null;
    _accountProviders.remove(id);
    return removed;
  }

  /// Gets a provider by its ID.
  ///
  /// Returns null if no provider with that ID is registered.
  CatalogProvider? getById(String id) => _providers[id];

  /// Gets a provider that can handle the given catalog.
  ///
  /// First tries to find a provider by the catalog's [providerType],
  /// then falls back to checking [canHandle] on all providers.
  ///
  /// Returns null if no suitable provider is found.
  CatalogProvider? getForCatalog(CatalogInfo catalog) {
    // First, try to find by provider type
    final byType = _providers[catalog.providerType];
    if (byType != null && byType.canHandle(catalog)) {
      return byType;
    }

    // Fall back to checking canHandle on all providers
    for (final provider in _providers.values) {
      if (provider.canHandle(catalog)) {
        return provider;
      }
    }

    return null;
  }

  /// Gets all registered providers.
  List<CatalogProvider> getAll() => List.unmodifiable(_providers.values);

  /// Gets all provider IDs.
  List<String> getAllIds() => List.unmodifiable(_providers.keys);

  /// Gets all providers that have a specific capability.
  List<CatalogProvider> getByCapability(CatalogCapability capability) {
    return _providers.values.where((p) => p.hasCapability(capability)).toList();
  }

  /// Gets the account provider for a catalog provider.
  ///
  /// Returns null if no account provider is registered for that ID.
  AccountProvider? getAccountProvider(String providerId) =>
      _accountProviders[providerId];

  /// Gets the account provider for a catalog.
  ///
  /// Returns null if no account provider is available.
  AccountProvider? getAccountProviderForCatalog(CatalogInfo catalog) =>
      _accountProviders[catalog.providerType];

  /// Checks if a provider with the given ID is registered.
  bool isRegistered(String id) => _providers.containsKey(id);

  /// Checks if an account provider is registered for the given provider ID.
  bool hasAccountProvider(String providerId) =>
      _accountProviders.containsKey(providerId);

  /// Gets the number of registered providers.
  int get length => _providers.length;

  /// Whether any providers are registered.
  bool get isEmpty => _providers.isEmpty;

  /// Whether any providers are registered.
  bool get isNotEmpty => _providers.isNotEmpty;

  /// Clears all registered providers.
  ///
  /// This is primarily useful for testing.
  void clear() {
    _providers.clear();
    _accountProviders.clear();
  }
}
