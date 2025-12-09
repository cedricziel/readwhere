import 'package:readwhere_plugin/readwhere_plugin.dart';

import '../entities/catalog.dart';

/// Adapts the app's [Catalog] entity to the plugin's [CatalogInfo] interface.
///
/// This allows the existing Catalog entity to be used with the new
/// plugin-based provider system without modifying the entity itself.
class CatalogInfoAdapter implements CatalogInfo {
  /// Creates an adapter for the given catalog.
  const CatalogInfoAdapter(this.catalog);

  /// The underlying catalog entity.
  final Catalog catalog;

  @override
  String get id => catalog.id;

  @override
  String get name => catalog.name;

  @override
  String get url => catalog.url;

  @override
  String get providerType => catalog.type.name;

  @override
  DateTime get addedAt => catalog.addedAt;

  @override
  DateTime? get lastAccessedAt => catalog.lastAccessedAt;

  @override
  String? get iconUrl => catalog.iconUrl;

  @override
  Map<String, dynamic> get providerConfig => {
    // Common fields
    if (catalog.apiKey != null) 'apiKey': catalog.apiKey,
    if (catalog.serverVersion != null) 'serverVersion': catalog.serverVersion,

    // Nextcloud-specific fields
    if (catalog.username != null) 'username': catalog.username,
    if (catalog.userId != null) 'userId': catalog.userId,
    if (catalog.booksFolder != null) 'booksFolder': catalog.booksFolder,

    // Computed fields
    'opdsUrl': catalog.opdsUrl,
    'webdavUrl': catalog.webdavUrl,
    'effectiveBooksFolder': catalog.effectiveBooksFolder,
    'requiresAuth': catalog.requiresAuth,
    'isKavita': catalog.isKavita,
    'isNextcloud': catalog.isNextcloud,
  };
}

/// Extension to easily create adapters from Catalog instances.
extension CatalogToInfoAdapter on Catalog {
  /// Converts this catalog to a [CatalogInfo] adapter.
  CatalogInfo toInfo() => CatalogInfoAdapter(this);
}
