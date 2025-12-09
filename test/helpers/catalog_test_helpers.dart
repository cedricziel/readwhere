import 'package:readwhere/domain/entities/catalog.dart';

/// Creates a test Catalog fixture with sensible defaults
///
/// All parameters are optional and will use default test values if not provided.
Catalog createTestCatalog({
  String id = 'test-catalog-id',
  String name = 'Test Catalog',
  String url = 'https://example.com/catalog',
  String? iconUrl,
  DateTime? addedAt,
  DateTime? lastAccessedAt,
  String? apiKey,
  CatalogType type = CatalogType.opds,
  String? serverVersion,
  String? username,
  String? booksFolder,
  String? userId,
}) {
  return Catalog(
    id: id,
    name: name,
    url: url,
    iconUrl: iconUrl,
    addedAt: addedAt ?? DateTime(2024, 1, 1),
    lastAccessedAt: lastAccessedAt,
    apiKey: apiKey,
    type: type,
    serverVersion: serverVersion,
    username: username,
    booksFolder: booksFolder,
    userId: userId,
  );
}

/// Creates a test RSS feed catalog
Catalog createTestRssFeed({
  String id = 'test-rss-feed',
  String name = 'Test RSS Feed',
  String url = 'https://example.com/feed.xml',
  String? iconUrl,
  DateTime? addedAt,
  DateTime? lastAccessedAt,
}) {
  return createTestCatalog(
    id: id,
    name: name,
    url: url,
    iconUrl: iconUrl,
    addedAt: addedAt,
    lastAccessedAt: lastAccessedAt,
    type: CatalogType.rss,
  );
}

/// Creates a test Kavita server catalog
Catalog createTestKavitaServer({
  String id = 'test-kavita-server',
  String name = 'Test Kavita Server',
  String url = 'https://kavita.example.com',
  String apiKey = 'test-api-key',
  String? serverVersion,
  DateTime? addedAt,
  DateTime? lastAccessedAt,
}) {
  return createTestCatalog(
    id: id,
    name: name,
    url: url,
    apiKey: apiKey,
    addedAt: addedAt,
    lastAccessedAt: lastAccessedAt,
    type: CatalogType.kavita,
    serverVersion: serverVersion,
  );
}

/// Creates a test Nextcloud catalog
Catalog createTestNextcloudServer({
  String id = 'test-nextcloud-server',
  String name = 'Test Nextcloud',
  String url = 'https://nextcloud.example.com',
  String? username,
  String? booksFolder,
  String? userId,
  String? serverVersion,
  DateTime? addedAt,
  DateTime? lastAccessedAt,
}) {
  return createTestCatalog(
    id: id,
    name: name,
    url: url,
    username: username,
    booksFolder: booksFolder,
    userId: userId,
    addedAt: addedAt,
    lastAccessedAt: lastAccessedAt,
    type: CatalogType.nextcloud,
    serverVersion: serverVersion,
  );
}

/// Creates multiple test RSS feeds with unique IDs
List<Catalog> createTestRssFeeds(int count) {
  return List.generate(
    count,
    (index) => createTestRssFeed(
      id: 'test-rss-feed-$index',
      name: 'RSS Feed ${index + 1}',
      url: 'https://example$index.com/feed.xml',
    ),
  );
}

/// Creates a mixed list of catalogs (servers + feeds)
List<Catalog> createMixedCatalogs() {
  return [
    createTestKavitaServer(id: 'kavita-1', name: 'My Kavita'),
    createTestRssFeed(id: 'rss-1', name: 'Tech News'),
    createTestNextcloudServer(id: 'nextcloud-1', name: 'My Cloud'),
    createTestRssFeed(id: 'rss-2', name: 'Book Reviews'),
    createTestCatalog(id: 'opds-1', name: 'Public Library'),
  ];
}
