/// Represents a feed mapping between Nextcloud News and local RSS catalog
class NewsFeedMapping {
  /// Unique mapping ID
  final String id;

  /// Nextcloud catalog ID this mapping belongs to
  final String catalogId;

  /// Nextcloud News feed ID
  final int ncFeedId;

  /// Local RSS catalog ID
  final String localFeedId;

  /// Feed URL (for deduplication)
  final String feedUrl;

  /// When this mapping was created
  final DateTime createdAt;

  const NewsFeedMapping({
    required this.id,
    required this.catalogId,
    required this.ncFeedId,
    required this.localFeedId,
    required this.feedUrl,
    required this.createdAt,
  });
}

/// Represents an item mapping between Nextcloud News and local feed items
class NewsItemMapping {
  /// Unique mapping ID
  final String id;

  /// Nextcloud catalog ID this mapping belongs to
  final String catalogId;

  /// Nextcloud News item ID
  final int ncItemId;

  /// Local feed item ID
  final String localItemId;

  /// Nextcloud News feed ID
  final int ncFeedId;

  /// Local RSS catalog ID
  final String localFeedId;

  /// When this mapping was created
  final DateTime createdAt;

  const NewsItemMapping({
    required this.id,
    required this.catalogId,
    required this.ncItemId,
    required this.localItemId,
    required this.ncFeedId,
    required this.localFeedId,
    required this.createdAt,
  });
}

/// Abstract repository interface for managing Nextcloud News ID mappings
///
/// This repository tracks the relationship between Nextcloud News IDs
/// and local app IDs for feeds and items, enabling bidirectional lookup
/// during sync operations.
abstract class NextcloudNewsMappingRepository {
  // ===== Feed Mappings =====

  /// Get the local feed ID for a Nextcloud News feed
  ///
  /// [catalogId] The Nextcloud catalog ID
  /// [ncFeedId] The Nextcloud News feed ID
  /// Returns the local RSS catalog ID if mapping exists
  Future<String?> getLocalFeedId(String catalogId, int ncFeedId);

  /// Get the Nextcloud News feed ID for a local feed
  ///
  /// [catalogId] The Nextcloud catalog ID
  /// [localFeedId] The local RSS catalog ID
  /// Returns the Nextcloud News feed ID if mapping exists
  Future<int?> getNcFeedId(String catalogId, String localFeedId);

  /// Get all feed mappings for a Nextcloud catalog
  ///
  /// [catalogId] The Nextcloud catalog ID
  Future<List<NewsFeedMapping>> getFeedMappingsForCatalog(String catalogId);

  /// Find a feed mapping by URL
  ///
  /// This is used for deduplication - find existing local feeds by URL
  /// [catalogId] The Nextcloud catalog ID
  /// [feedUrl] The feed URL to search for
  Future<NewsFeedMapping?> getFeedMappingByUrl(
    String catalogId,
    String feedUrl,
  );

  /// Save a feed mapping
  ///
  /// [catalogId] The Nextcloud catalog ID
  /// [ncFeedId] The Nextcloud News feed ID
  /// [localFeedId] The local RSS catalog ID
  /// [feedUrl] The feed URL (for deduplication)
  Future<NewsFeedMapping> saveFeedMapping({
    required String catalogId,
    required int ncFeedId,
    required String localFeedId,
    required String feedUrl,
  });

  /// Delete a feed mapping
  ///
  /// [catalogId] The Nextcloud catalog ID
  /// [ncFeedId] The Nextcloud News feed ID
  Future<void> deleteFeedMapping(String catalogId, int ncFeedId);

  // ===== Item Mappings =====

  /// Get the local item ID for a Nextcloud News item
  ///
  /// [catalogId] The Nextcloud catalog ID
  /// [ncItemId] The Nextcloud News item ID
  /// Returns the local feed item ID if mapping exists
  Future<String?> getLocalItemId(String catalogId, int ncItemId);

  /// Get the Nextcloud News item ID for a local item
  ///
  /// [catalogId] The Nextcloud catalog ID
  /// [localItemId] The local feed item ID
  /// Returns the Nextcloud News item ID if mapping exists
  Future<int?> getNcItemId(String catalogId, String localItemId);

  /// Get all item mappings for a specific feed
  ///
  /// [catalogId] The Nextcloud catalog ID
  /// [ncFeedId] The Nextcloud News feed ID
  Future<List<NewsItemMapping>> getItemMappingsForFeed(
    String catalogId,
    int ncFeedId,
  );

  /// Get item mappings for multiple Nextcloud item IDs
  ///
  /// This is useful for batch operations during sync
  /// [catalogId] The Nextcloud catalog ID
  /// [ncItemIds] List of Nextcloud News item IDs to look up
  Future<Map<int, String>> getLocalItemIds(
    String catalogId,
    List<int> ncItemIds,
  );

  /// Save an item mapping
  ///
  /// [catalogId] The Nextcloud catalog ID
  /// [ncItemId] The Nextcloud News item ID
  /// [localItemId] The local feed item ID
  /// [ncFeedId] The Nextcloud News feed ID
  /// [localFeedId] The local RSS catalog ID
  Future<NewsItemMapping> saveItemMapping({
    required String catalogId,
    required int ncItemId,
    required String localItemId,
    required int ncFeedId,
    required String localFeedId,
  });

  /// Save multiple item mappings in a batch
  ///
  /// More efficient than saving one at a time during sync
  Future<void> saveItemMappings(List<NewsItemMapping> mappings);

  /// Delete an item mapping
  ///
  /// [catalogId] The Nextcloud catalog ID
  /// [ncItemId] The Nextcloud News item ID
  Future<void> deleteItemMapping(String catalogId, int ncItemId);

  // ===== Cleanup Operations =====

  /// Delete all mappings for a Nextcloud catalog
  ///
  /// Called when a catalog is deleted or News sync is disabled
  /// [catalogId] The Nextcloud catalog ID
  Future<void> deleteMappingsForCatalog(String catalogId);

  /// Delete all item mappings for a feed
  ///
  /// Called when a feed is deleted
  /// [catalogId] The Nextcloud catalog ID
  /// [ncFeedId] The Nextcloud News feed ID
  Future<void> deleteItemMappingsForFeed(String catalogId, int ncFeedId);

  /// Get count of feed mappings for a catalog
  ///
  /// [catalogId] The Nextcloud catalog ID
  Future<int> getFeedMappingCount(String catalogId);

  /// Get count of item mappings for a catalog
  ///
  /// [catalogId] The Nextcloud catalog ID
  Future<int> getItemMappingCount(String catalogId);
}
