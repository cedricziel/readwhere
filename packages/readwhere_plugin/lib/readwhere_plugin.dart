/// Core plugin interfaces for ReadWhere.
///
/// This package provides abstract interfaces and base classes for:
/// - **Unified Plugin System** - Single plugin class with capability mixins
/// - **Catalog providers** - Integrate with book sources (OPDS, Kavita, etc.)
/// - **Reader plugins** - Support book formats (EPUB, CBZ, CBR, PDF, etc.)
///
/// ## Unified Plugin System (New)
///
/// The new unified plugin architecture uses a single [PluginBase] class
/// with capability mixins for different functionality:
///
/// - [PluginBase] - Base class for all plugins
/// - [CatalogCapability] - Browse and download from catalogs
/// - [ReaderCapability] - Read book files in specific formats
/// - [AccountCapability] - Authentication management
/// - [ProgressSyncCapability] - Sync reading progress to servers
/// - [UnifiedPluginRegistry] - Registry for all plugins
/// - [PluginStorage] - Unified storage interface
///
/// ## Example: Unified Plugin
///
/// ```dart
/// class KavitaPlugin extends PluginBase
///     with CatalogCapability, AccountCapability, ProgressSyncCapability {
///   @override
///   String get id => 'com.readwhere.kavita';
///
///   @override
///   String get name => 'Kavita';
///
///   @override
///   String get version => '1.0.0';
///
///   // ... implement capability methods
/// }
///
/// await UnifiedPluginRegistry().register(
///   KavitaPlugin(),
///   storageFactory: myStorageFactory,
///   contextFactory: myContextFactory,
/// );
/// ```
///
/// ## Legacy Interfaces (Deprecated)
///
/// The following interfaces are maintained for backward compatibility
/// but will be removed in a future version:
///
/// - [CatalogProvider] - Use [CatalogCapability] mixin instead
/// - [AccountProvider] - Use [AccountCapability] mixin instead
/// - [ReaderPlugin] - Use [ReaderCapability] mixin instead
/// - [PluginRegistry] - Use [UnifiedPluginRegistry] instead
/// - [CatalogProviderRegistry] - Use [UnifiedPluginRegistry] instead
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
library;

// ===== New Unified Plugin System =====

// Core
export 'src/core/plugin_base.dart';
export 'src/core/plugin_context.dart';
export 'src/core/unified_plugin_registry.dart';

// Capabilities
export 'src/capabilities/account_capability.dart';
export 'src/capabilities/catalog_capability.dart';
export 'src/capabilities/progress_sync_capability.dart';
export 'src/capabilities/reader_capability.dart';

// Storage
export 'src/storage/plugin_storage.dart';

// ===== Legacy Interfaces (maintained for backward compatibility) =====

// Catalog (Legacy)
export 'src/catalog/browsing_provider.dart';
export 'src/catalog/catalog_capability.dart'; // Legacy CatalogCapability enum
export 'src/catalog/catalog_provider.dart';
export 'src/catalog/catalog_provider_registry.dart';

// Account (Legacy)
export 'src/account/account_provider.dart';
export 'src/account/auth_credentials.dart';

// Storage (Legacy)
export 'src/storage/credential_storage.dart';

// ===== Shared Entities =====

export 'src/entities/account_info.dart';
export 'src/entities/browse_result.dart';
export 'src/entities/catalog_entry.dart';
export 'src/entities/catalog_file.dart';
export 'src/entities/catalog_info.dart';
export 'src/entities/catalog_link.dart';
export 'src/entities/validation_result.dart';

// ===== Reader =====

export 'src/reader/book_metadata.dart';
export 'src/reader/plugin_registry.dart';
export 'src/reader/reader_content.dart';
export 'src/reader/reader_controller.dart';
export 'src/reader/reader_plugin.dart';
export 'src/reader/reading_location.dart';
export 'src/reader/search_result.dart';
export 'src/reader/toc_entry.dart';
