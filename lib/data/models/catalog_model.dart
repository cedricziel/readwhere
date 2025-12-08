import '../../domain/entities/catalog.dart';
import '../database/tables/catalogs_table.dart';

/// Data model for Catalog entity with database serialization support
class CatalogModel extends Catalog {
  const CatalogModel({
    required super.id,
    required super.name,
    required super.url,
    super.iconUrl,
    required super.addedAt,
    super.lastAccessedAt,
    super.apiKey,
    super.type,
    super.serverVersion,
  });

  /// Create a CatalogModel from a Map (SQLite row)
  factory CatalogModel.fromMap(Map<String, dynamic> map) {
    return CatalogModel(
      id: map[CatalogsTable.columnId] as String,
      name: map[CatalogsTable.columnName] as String,
      url: map[CatalogsTable.columnUrl] as String,
      iconUrl: map[CatalogsTable.columnIconUrl] as String?,
      addedAt: DateTime.fromMillisecondsSinceEpoch(
        map[CatalogsTable.columnAddedAt] as int,
      ),
      lastAccessedAt: map[CatalogsTable.columnLastAccessedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[CatalogsTable.columnLastAccessedAt] as int,
            )
          : null,
      apiKey: map[CatalogsTable.columnApiKey] as String?,
      type: _parseCatalogType(map[CatalogsTable.columnType] as String?),
      serverVersion: map[CatalogsTable.columnServerVersion] as String?,
    );
  }

  /// Parse catalog type string to enum
  static CatalogType _parseCatalogType(String? value) {
    switch (value) {
      case 'kavita':
        return CatalogType.kavita;
      case 'opds':
      default:
        return CatalogType.opds;
    }
  }

  /// Create a CatalogModel from a domain entity
  factory CatalogModel.fromEntity(Catalog catalog) {
    return CatalogModel(
      id: catalog.id,
      name: catalog.name,
      url: catalog.url,
      iconUrl: catalog.iconUrl,
      addedAt: catalog.addedAt,
      lastAccessedAt: catalog.lastAccessedAt,
      apiKey: catalog.apiKey,
      type: catalog.type,
      serverVersion: catalog.serverVersion,
    );
  }

  /// Convert to a Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      CatalogsTable.columnId: id,
      CatalogsTable.columnName: name,
      CatalogsTable.columnUrl: url,
      CatalogsTable.columnIconUrl: iconUrl,
      CatalogsTable.columnAddedAt: addedAt.millisecondsSinceEpoch,
      CatalogsTable.columnLastAccessedAt:
          lastAccessedAt?.millisecondsSinceEpoch,
      CatalogsTable.columnApiKey: apiKey,
      CatalogsTable.columnType: type.name,
      CatalogsTable.columnServerVersion: serverVersion,
    };
  }

  /// Convert to domain entity (Catalog)
  Catalog toEntity() {
    return Catalog(
      id: id,
      name: name,
      url: url,
      iconUrl: iconUrl,
      addedAt: addedAt,
      lastAccessedAt: lastAccessedAt,
      apiKey: apiKey,
      type: type,
      serverVersion: serverVersion,
    );
  }
}
