import '../core/plugin_base.dart';
import '../entities/browse_result.dart';
import '../entities/catalog_file.dart';
import '../entities/catalog_info.dart';
import '../entities/validation_result.dart';

/// Callback for download progress (unified plugin system).
typedef PluginProgressCallback = void Function(int received, int total);

/// Features a catalog plugin can support.
///
/// Different from the legacy [CatalogCapability] enum - this is for
/// the new unified plugin system.
enum PluginCatalogFeature {
  /// Can browse folders/feeds.
  browse,

  /// Can search for content.
  search,

  /// Can download files.
  download,

  /// Supports paginated results.
  pagination,

  /// Supports streaming content (without download).
  streaming,

  /// Can show book previews.
  previews,

  /// Supports favoriting/bookmarking entries.
  favorites,

  /// Supports collections/reading lists.
  collections,

  /// Supports user ratings.
  ratings,

  /// Supports reading lists.
  readingLists,

  /// Supports offline caching.
  offlineCache,
}

/// Capability for browsing, searching, and downloading from catalogs.
///
/// Plugins with this capability can provide content from remote
/// sources like OPDS feeds, WebDAV servers, or custom APIs.
///
/// Note: This mixin is named `CatalogBrowsingCapability` to avoid
/// conflict with the legacy `CatalogCapability` enum.
///
/// Example:
/// ```dart
/// class OpdsPlugin extends PluginBase with CatalogBrowsingCapability {
///   @override
///   Set<PluginCatalogFeature> get catalogFeatures => {
///     PluginCatalogFeature.browse,
///     PluginCatalogFeature.search,
///     PluginCatalogFeature.download,
///     PluginCatalogFeature.pagination,
///   };
///
///   @override
///   bool canHandleCatalog(CatalogInfo catalog) {
///     return catalog.providerType == 'opds';
///   }
///
///   // ... implement other methods
/// }
/// ```
mixin CatalogBrowsingCapability on PluginBase {
  /// Features this catalog provider supports.
  ///
  /// The UI uses this to show/hide features (e.g., search bar)
  /// based on what the catalog supports.
  Set<PluginCatalogFeature> get catalogFeatures;

  /// Check if this plugin can handle the given catalog info.
  ///
  /// Typically checks [CatalogInfo.providerType] but may also
  /// inspect the URL or other properties.
  bool canHandleCatalog(CatalogInfo catalog);

  /// Validate that the catalog is accessible.
  ///
  /// Should verify:
  /// - Server is reachable
  /// - Credentials are valid (if required)
  /// - Response is in expected format
  ///
  /// Returns [ValidationResult.success] with server info on success,
  /// or [ValidationResult.failure] with error details on failure.
  Future<ValidationResult> validate(CatalogInfo catalog);

  /// Browse the catalog at the given path.
  ///
  /// [catalog] The catalog to browse.
  /// [path] Optional path within the catalog. Pass null or empty for root.
  /// [page] Page number for paginated results (1-indexed).
  ///
  /// Returns a [BrowseResult] containing entries at that path.
  Future<BrowseResult> browse(CatalogInfo catalog, {String? path, int? page});

  /// Search within the catalog.
  ///
  /// [catalog] The catalog to search.
  /// [query] The search term.
  /// [page] Page number for paginated results (1-indexed).
  ///
  /// Throws [UnsupportedError] if search is not supported.
  /// Check [supportsSearch] before calling.
  Future<BrowseResult> search(CatalogInfo catalog, String query, {int? page}) {
    throw UnsupportedError('Search not supported by $name');
  }

  /// Download a file from the catalog.
  ///
  /// [catalog] The source catalog.
  /// [file] The catalog file to download.
  /// [localPath] Where to save the file.
  /// [onProgress] Optional callback for download progress.
  ///
  /// Throws [UnsupportedError] if download is not supported.
  Future<void> download(
    CatalogInfo catalog,
    CatalogFile file,
    String localPath, {
    PluginProgressCallback? onProgress,
  });

  /// Get a thumbnail/preview image for an entry.
  ///
  /// [catalog] The source catalog.
  /// [imageUrl] URL of the image to fetch.
  ///
  /// Returns the image bytes, or null if not available.
  /// Default implementation returns null.
  Future<List<int>?> getThumbnail(CatalogInfo catalog, String imageUrl) async {
    return null;
  }

  // ===== Convenience Getters =====

  /// Whether this catalog supports browsing.
  bool get supportsBrowse =>
      catalogFeatures.contains(PluginCatalogFeature.browse);

  /// Whether this catalog supports search.
  bool get supportsSearch =>
      catalogFeatures.contains(PluginCatalogFeature.search);

  /// Whether this catalog supports pagination.
  bool get supportsPagination =>
      catalogFeatures.contains(PluginCatalogFeature.pagination);

  /// Whether this catalog supports downloading files.
  bool get supportsDownload =>
      catalogFeatures.contains(PluginCatalogFeature.download);

  /// Whether this catalog supports streaming.
  bool get supportsStreaming =>
      catalogFeatures.contains(PluginCatalogFeature.streaming);

  /// Whether this catalog supports offline caching.
  bool get supportsOfflineCache =>
      catalogFeatures.contains(PluginCatalogFeature.offlineCache);

  /// Check if a specific feature is supported.
  bool hasFeature(PluginCatalogFeature feature) =>
      catalogFeatures.contains(feature);
}
