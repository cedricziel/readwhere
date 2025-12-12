/// OPDS catalog provider for ReadWhere.
///
/// This package provides OPDS 1.x and 2.0 catalog support including:
/// - Feed parsing from XML
/// - HTTP client for fetching feeds
/// - AccountProvider implementation
/// - Injectable cache interface
library;

// Entities
export 'src/entities/opds_feed.dart';
export 'src/entities/opds_entry.dart';
export 'src/entities/opds_link.dart';
export 'src/entities/opds_facet.dart';

// Models (XML parsing)
export 'src/models/opds_feed_model.dart';
export 'src/models/opds_entry_model.dart';
export 'src/models/opds_link_model.dart';

// Client
export 'src/client/opds_client.dart';
export 'src/client/opds_exception.dart';

// Providers
export 'src/provider/opds_account_provider.dart';
export 'src/provider/opds_provider.dart';

// Cache interface
export 'src/cache/opds_cache_interface.dart';

// Adapters
export 'src/adapters/opds_adapters.dart';
