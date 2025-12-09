/// Interface for catalog information.
///
/// Catalogs represent content sources like OPDS feeds, Nextcloud instances,
/// Kavita servers, etc. Implementations should provide all necessary
/// information for a [CatalogProvider] to connect and browse the catalog.
abstract class CatalogInfo {
  /// Unique identifier for this catalog.
  String get id;

  /// Human-readable name for the catalog.
  String get name;

  /// The base URL of the catalog.
  String get url;

  /// The provider type identifier (e.g., 'opds', 'nextcloud', 'kavita').
  ///
  /// This is used to look up the appropriate [CatalogProvider].
  String get providerType;

  /// When this catalog was added.
  DateTime get addedAt;

  /// When this catalog was last accessed.
  DateTime? get lastAccessedAt;

  /// Optional URL for the catalog's icon/logo.
  String? get iconUrl;

  /// Provider-specific configuration data.
  ///
  /// This allows providers to store additional data they need,
  /// such as WebDAV paths for Nextcloud or API versions for Kavita.
  Map<String, dynamic> get providerConfig;
}
