/// Core plugin interfaces for ReadWhere catalog providers.
///
/// This package provides abstract interfaces and base classes for building
/// catalog providers that integrate with various book sources like OPDS feeds,
/// Nextcloud instances, Kavita servers, and more.
///
/// ## Key Interfaces
///
/// - [CatalogProvider] - Interface for browsing and downloading from catalogs
/// - [AccountProvider] - Interface for authentication with catalog services
/// - [CredentialStorage] - Interface for secure credential storage
/// - [CatalogProviderRegistry] - Registry for managing providers
///
/// ## Entity Interfaces
///
/// - [CatalogInfo] - Information about a configured catalog
/// - [AccountInfo] - Information about an authenticated account
/// - [CatalogEntry] - An entry in a catalog (book, collection, navigation)
/// - [CatalogFile] - A downloadable file
/// - [CatalogLink] - A navigation link
/// - [BrowseResult] - Result of browsing/searching a catalog
/// - [ValidationResult] - Result of validating a catalog
///
/// ## Authentication
///
/// - [AuthType] - Types of authentication (basic, OAuth2, API key, etc.)
/// - [AuthCredentials] - Base class for credential types
/// - [BasicAuthCredentials], [OAuth2Credentials], etc. - Specific credentials
/// - [OAuthFlowInit], [OAuthFlowResult] - OAuth flow data
///
/// ## Example
///
/// ```dart
/// // Implement a catalog provider
/// class MyProvider implements CatalogProvider {
///   @override
///   String get id => 'my_provider';
///
///   @override
///   String get name => 'My Provider';
///
///   @override
///   String get description => 'Access My Book Service';
///
///   @override
///   Set<CatalogCapability> get capabilities => {
///     CatalogCapability.browse,
///     CatalogCapability.search,
///     CatalogCapability.download,
///   };
///
///   // ... implement other methods
/// }
///
/// // Register the provider
/// final registry = CatalogProviderRegistry();
/// registry.register(MyProvider());
///
/// // Use the provider
/// final catalog = MyCatalog(...);
/// final provider = registry.getForCatalog(catalog);
/// final result = await provider?.browse(catalog);
/// ```
library;

// Catalog
export 'src/catalog/catalog_capability.dart';
export 'src/catalog/catalog_provider.dart';
export 'src/catalog/catalog_provider_registry.dart';

// Account
export 'src/account/account_provider.dart';
export 'src/account/auth_credentials.dart';

// Storage
export 'src/storage/credential_storage.dart';

// Entities
export 'src/entities/account_info.dart';
export 'src/entities/browse_result.dart';
export 'src/entities/catalog_entry.dart';
export 'src/entities/catalog_file.dart';
export 'src/entities/catalog_info.dart';
export 'src/entities/catalog_link.dart';
export 'src/entities/validation_result.dart';
