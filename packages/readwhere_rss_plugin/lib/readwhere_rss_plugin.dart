/// RSS and OPML integration plugin for ReadWhere.
///
/// This package provides:
/// - Unified RssPlugin with CatalogBrowsingCapability
/// - CatalogProvider implementation for RSS/Atom feeds (legacy)
/// - OPML import/export services
/// - Adapters for converting RSS entities to catalog entries
library;

// ===== New Unified Plugin System =====
export 'src/rss_plugin.dart';

// ===== Legacy Provider (maintained for backward compatibility) =====
export 'src/provider/rss_account_provider.dart';
export 'src/provider/rss_catalog_provider.dart';

// Adapters
export 'src/adapters/rss_catalog_adapters.dart';

// Cache
export 'src/cache/rss_cache_interface.dart';

// OPML Services
export 'src/opml/opml_export_service.dart';
export 'src/opml/opml_import_service.dart';
