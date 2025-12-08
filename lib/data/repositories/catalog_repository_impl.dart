import '../../domain/entities/catalog.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../database/database_helper.dart';
import '../database/tables/catalogs_table.dart';
import '../models/catalog_model.dart';

/// Implementation of CatalogRepository using SQLite database
class CatalogRepositoryImpl implements CatalogRepository {
  final DatabaseHelper _databaseHelper;

  CatalogRepositoryImpl(this._databaseHelper);

  @override
  Future<List<Catalog>> getAll() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      CatalogsTable.tableName,
      orderBy: '${CatalogsTable.columnAddedAt} DESC',
    );
    return maps.map((map) => CatalogModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<Catalog?> getById(String id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      CatalogsTable.tableName,
      where: '${CatalogsTable.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return CatalogModel.fromMap(maps.first).toEntity();
  }

  @override
  Future<Catalog> insert(Catalog catalog) async {
    final db = await _databaseHelper.database;
    final model = CatalogModel.fromEntity(catalog);
    await db.insert(CatalogsTable.tableName, model.toMap());
    return catalog;
  }

  @override
  Future<Catalog> update(Catalog catalog) async {
    final db = await _databaseHelper.database;
    final model = CatalogModel.fromEntity(catalog);
    await db.update(
      CatalogsTable.tableName,
      model.toMap(),
      where: '${CatalogsTable.columnId} = ?',
      whereArgs: [catalog.id],
    );
    return catalog;
  }

  @override
  Future<bool> delete(String id) async {
    final db = await _databaseHelper.database;
    final count = await db.delete(
      CatalogsTable.tableName,
      where: '${CatalogsTable.columnId} = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  @override
  Future<void> updateLastAccessed(String id) async {
    final db = await _databaseHelper.database;
    await db.update(
      CatalogsTable.tableName,
      {
        CatalogsTable.columnLastAccessedAt:
            DateTime.now().millisecondsSinceEpoch,
      },
      where: '${CatalogsTable.columnId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<Catalog?> findByUrl(String url) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      CatalogsTable.tableName,
      where: '${CatalogsTable.columnUrl} = ?',
      whereArgs: [url],
    );
    if (maps.isEmpty) return null;
    return CatalogModel.fromMap(maps.first).toEntity();
  }
}
