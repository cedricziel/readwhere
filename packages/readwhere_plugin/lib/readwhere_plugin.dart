/// Core plugin interfaces for ReadWhere.
///
/// This package provides abstract interfaces and base classes for:
/// - **Catalog providers** - Integrate with book sources (OPDS, Kavita, etc.)
/// - **Reader plugins** - Support book formats (EPUB, CBZ, CBR, PDF, etc.)
///
/// ## Catalog Provider Interfaces
///
/// - [CatalogProvider] - Interface for browsing and downloading from catalogs
/// - [AccountProvider] - Interface for authentication with catalog services
/// - [CredentialStorage] - Interface for secure credential storage
/// - [CatalogProviderRegistry] - Registry for managing catalog providers
///
/// ## Reader Plugin Interfaces
///
/// - [ReaderPlugin] - Interface for format-specific readers
/// - [ReaderController] - Controls a reading session for an open book
/// - [PluginRegistry] - Registry for managing reader plugins
///
/// ## Data Types
///
/// ### Catalog Entities
/// - [CatalogInfo], [AccountInfo], [CatalogEntry], [CatalogFile], etc.
///
/// ### Reader Entities
/// - [BookMetadata] - Metadata extracted from a book file
/// - [TocEntry] - Table of contents entry
/// - [ReaderContent] - Content for rendering a chapter
/// - [ReadingLocation] - A location within a book
/// - [SearchResult] - A search match within a book
///
/// ## Example: Catalog Provider
///
/// ```dart
/// class MyProvider implements CatalogProvider {
///   @override
///   String get id => 'my_provider';
///   // ... implement other methods
/// }
///
/// CatalogProviderRegistry().register(MyProvider());
/// ```
///
/// ## Example: Reader Plugin
///
/// ```dart
/// class MyFormatPlugin implements ReaderPlugin {
///   @override
///   String get id => 'my_format';
///
///   @override
///   Future<bool> canHandle(String filePath) async {
///     return filePath.endsWith('.myformat');
///   }
///   // ... implement other methods
/// }
///
/// PluginRegistry().register(MyFormatPlugin());
/// ```
library;

// Catalog
export 'src/catalog/browsing_provider.dart';
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

// Reader
export 'src/reader/book_metadata.dart';
export 'src/reader/plugin_registry.dart';
export 'src/reader/reader_content.dart';
export 'src/reader/reader_controller.dart';
export 'src/reader/reader_plugin.dart';
export 'src/reader/reading_location.dart';
export 'src/reader/search_result.dart';
export 'src/reader/toc_entry.dart';
