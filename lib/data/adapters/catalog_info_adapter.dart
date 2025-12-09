import 'package:readwhere_plugin/readwhere_plugin.dart';

import '../../domain/entities/catalog.dart';

/// Adapter that wraps a [Catalog] entity to implement [CatalogInfo].
///
/// This allows domain [Catalog] entities to be used with the unified
/// plugin system which expects [CatalogInfo] instances.
class CatalogInfoAdapter implements CatalogInfo {
  /// The underlying [Catalog] entity.
  final Catalog catalog;

  /// Creates an adapter for the given [Catalog].
  const CatalogInfoAdapter(this.catalog);

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
    if (catalog.apiKey != null) 'apiKey': catalog.apiKey,
    if (catalog.serverVersion != null) 'serverVersion': catalog.serverVersion,
    if (catalog.username != null) 'username': catalog.username,
    if (catalog.booksFolder != null) 'booksFolder': catalog.booksFolder,
    if (catalog.userId != null) 'userId': catalog.userId,
  };
}

/// Extension to easily convert [Catalog] to [CatalogInfo].
extension CatalogToCatalogInfo on Catalog {
  /// Convert this [Catalog] to a [CatalogInfo] for use with unified plugins.
  CatalogInfo toCatalogInfo() => CatalogInfoAdapter(this);
}
