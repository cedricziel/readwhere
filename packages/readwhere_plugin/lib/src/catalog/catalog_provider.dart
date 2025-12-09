import '../entities/browse_result.dart';
import '../entities/catalog_file.dart';
import '../entities/catalog_info.dart';
import '../entities/validation_result.dart';
import 'catalog_capability.dart';

/// Callback for download progress.
typedef ProgressCallback = void Function(int received, int total);

/// Interface for catalog content providers.
///
/// Implementations provide access to book catalogs like OPDS feeds,
/// Nextcloud file servers, Kavita instances, etc.
///
/// Each provider is identified by a unique [id] (e.g., 'opds', 'nextcloud',
/// 'kavita') and declares its [capabilities] so the UI can adapt accordingly.
///
/// Example implementation:
/// ```dart
/// class OpdsProvider implements CatalogProvider {
///   @override
///   String get id => 'opds';
///
///   @override
///   String get name => 'OPDS Catalog';
///
///   @override
///   String get description => 'Browse OPDS 1.x and 2.0 catalogs';
///
///   @override
///   Set<CatalogCapability> get capabilities => {
///     CatalogCapability.browse,
///     CatalogCapability.search,
///     CatalogCapability.download,
///     CatalogCapability.pagination,
///     CatalogCapability.noAuth,
///     CatalogCapability.basicAuth,
///   };
///
///   // ... implement other methods
/// }
/// ```
abstract class CatalogProvider {
  /// Unique identifier for this provider (e.g., 'opds', 'nextcloud', 'kavita').
  String get id;

  /// Human-readable name for this provider.
  String get name;

  /// Description of what this provider does.
  String get description;

  /// The capabilities this provider supports.
  Set<CatalogCapability> get capabilities;

  /// Returns true if this provider can handle the given catalog.
  ///
  /// Typically checks the [CatalogInfo.providerType] but may also
  /// inspect the URL or other properties.
  bool canHandle(CatalogInfo catalog);

  /// Validates that the catalog is accessible and properly configured.
  ///
  /// Returns information about the server if validation succeeds,
  /// or an error if it fails.
  Future<ValidationResult> validate(CatalogInfo catalog);

  /// Browses the catalog at the given path.
  ///
  /// [path] is the path within the catalog to browse. Pass null or empty
  /// string for the root.
  /// [page] is the page number for paginated results (1-indexed).
  ///
  /// Returns a [BrowseResult] containing the entries at that path.
  Future<BrowseResult> browse(CatalogInfo catalog, {String? path, int? page});

  /// Searches the catalog for entries matching the query.
  ///
  /// [query] is the search term.
  /// [page] is the page number for paginated results (1-indexed).
  ///
  /// Throws [UnsupportedError] if the provider doesn't support search.
  /// Check [capabilities] before calling.
  Future<BrowseResult> search(CatalogInfo catalog, String query, {int? page});

  /// Downloads a file from the catalog to a local path.
  ///
  /// [file] is the catalog file to download.
  /// [localPath] is the path where the file should be saved.
  /// [onProgress] is an optional callback for download progress.
  ///
  /// Throws [UnsupportedError] if the provider doesn't support download.
  Future<void> download(
    CatalogInfo catalog,
    CatalogFile file,
    String localPath, {
    ProgressCallback? onProgress,
  });

  /// Checks if this provider has a specific capability.
  bool hasCapability(CatalogCapability capability) =>
      capabilities.contains(capability);

  /// Checks if this provider supports search.
  bool get supportsSearch => hasCapability(CatalogCapability.search);

  /// Checks if this provider supports pagination.
  bool get supportsPagination => hasCapability(CatalogCapability.pagination);

  /// Checks if this provider supports downloading files.
  bool get supportsDownload => hasCapability(CatalogCapability.download);

  /// Checks if this provider supports progress syncing.
  bool get supportsProgressSync =>
      hasCapability(CatalogCapability.progressSync);
}
