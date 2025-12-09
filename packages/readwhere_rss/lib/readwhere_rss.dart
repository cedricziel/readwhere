/// RSS and Atom feed parsing library for ReadWhere.
///
/// This package provides RSS 2.0, RSS 1.0 (RDF), and Atom 1.0 feed parsing:
/// - Auto-detection of feed format
/// - HTTP client for fetching feeds
/// - Support for enclosures (media attachments)
/// - Extensions for supported ebook/comic formats
library;

// Entities
export 'src/entities/rss_category.dart';
export 'src/entities/rss_channel.dart';
export 'src/entities/rss_enclosure.dart';
export 'src/entities/rss_feed.dart';
export 'src/entities/rss_item.dart';

// Parsers
export 'src/models/atom_parser.dart';
export 'src/models/feed_detector.dart';
export 'src/models/rss1_parser.dart';
export 'src/models/rss2_parser.dart';

// Client
export 'src/client/rss_client.dart';
export 'src/client/rss_exception.dart';

// Adapters
export 'src/adapters/rss_adapters.dart';
