/// Capabilities that a catalog provider may support.
///
/// Use these to determine what features are available for a given catalog
/// and adapt the UI accordingly.
enum CatalogCapability {
  /// Provider supports browsing catalog entries.
  browse,

  /// Provider supports searching within the catalog.
  search,

  /// Provider supports downloading files from the catalog.
  download,

  /// Provider supports paginated results.
  pagination,

  /// Provider supports syncing reading progress.
  progressSync,

  /// Provider supports OAuth2 authentication.
  oauthAuth,

  /// Provider supports basic authentication.
  basicAuth,

  /// Provider supports API key authentication.
  apiKeyAuth,

  /// Provider supports bearer token authentication.
  bearerAuth,

  /// Provider requires no authentication.
  noAuth,

  /// Provider supports streaming/partial downloads.
  streaming,

  /// Provider supports file previews/thumbnails.
  previews,

  /// Provider supports favorites/bookmarks.
  favorites,

  /// Provider supports collections/shelves.
  collections,

  /// Provider supports user ratings.
  ratings,

  /// Provider supports reading lists.
  readingLists,
}
