import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../domain/repositories/nextcloud_news_mapping_repository.dart';
import '../database/database_helper.dart';
import '../database/tables/nextcloud_news_mappings_table.dart';

/// Implementation of NextcloudNewsMappingRepository using SQLite
///
/// This implementation uses DatabaseHelper to perform CRUD operations
/// on Nextcloud News ID mappings stored in the local SQLite database.
class NextcloudNewsMappingRepositoryImpl
    implements NextcloudNewsMappingRepository {
  final DatabaseHelper _databaseHelper;
  final Uuid _uuid = const Uuid();

  NextcloudNewsMappingRepositoryImpl(this._databaseHelper);

  // ===== Feed Mappings =====

  @override
  Future<String?> getLocalFeedId(String catalogId, int ncFeedId) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        NextcloudNewsFeedMappingsTable.tableName,
        columns: [NextcloudNewsFeedMappingsTable.columnLocalFeedId],
        where:
            '''
          ${NextcloudNewsFeedMappingsTable.columnCatalogId} = ?
          AND ${NextcloudNewsFeedMappingsTable.columnNcFeedId} = ?
        ''',
        whereArgs: [catalogId, ncFeedId],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return maps.first[NextcloudNewsFeedMappingsTable.columnLocalFeedId]
          as String;
    } catch (e) {
      throw Exception('Failed to get local feed ID: $e');
    }
  }

  @override
  Future<int?> getNcFeedId(String catalogId, String localFeedId) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        NextcloudNewsFeedMappingsTable.tableName,
        columns: [NextcloudNewsFeedMappingsTable.columnNcFeedId],
        where:
            '''
          ${NextcloudNewsFeedMappingsTable.columnCatalogId} = ?
          AND ${NextcloudNewsFeedMappingsTable.columnLocalFeedId} = ?
        ''',
        whereArgs: [catalogId, localFeedId],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return maps.first[NextcloudNewsFeedMappingsTable.columnNcFeedId] as int;
    } catch (e) {
      throw Exception('Failed to get Nextcloud News feed ID: $e');
    }
  }

  @override
  Future<List<NewsFeedMapping>> getFeedMappingsForCatalog(
    String catalogId,
  ) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        NextcloudNewsFeedMappingsTable.tableName,
        where: '${NextcloudNewsFeedMappingsTable.columnCatalogId} = ?',
        whereArgs: [catalogId],
        orderBy: '${NextcloudNewsFeedMappingsTable.columnCreatedAt} ASC',
      );

      return maps.map(_mapToFeedMapping).toList();
    } catch (e) {
      throw Exception('Failed to get feed mappings for catalog: $e');
    }
  }

  @override
  Future<NewsFeedMapping?> getFeedMappingByUrl(
    String catalogId,
    String feedUrl,
  ) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        NextcloudNewsFeedMappingsTable.tableName,
        where:
            '''
          ${NextcloudNewsFeedMappingsTable.columnCatalogId} = ?
          AND ${NextcloudNewsFeedMappingsTable.columnFeedUrl} = ?
        ''',
        whereArgs: [catalogId, feedUrl],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return _mapToFeedMapping(maps.first);
    } catch (e) {
      throw Exception('Failed to get feed mapping by URL: $e');
    }
  }

  @override
  Future<NewsFeedMapping> saveFeedMapping({
    required String catalogId,
    required int ncFeedId,
    required String localFeedId,
    required String feedUrl,
  }) async {
    try {
      final db = await _databaseHelper.database;
      final now = DateTime.now();
      final id = _uuid.v4();

      final data = {
        NextcloudNewsFeedMappingsTable.columnId: id,
        NextcloudNewsFeedMappingsTable.columnCatalogId: catalogId,
        NextcloudNewsFeedMappingsTable.columnNcFeedId: ncFeedId,
        NextcloudNewsFeedMappingsTable.columnLocalFeedId: localFeedId,
        NextcloudNewsFeedMappingsTable.columnFeedUrl: feedUrl,
        NextcloudNewsFeedMappingsTable.columnCreatedAt:
            now.millisecondsSinceEpoch,
      };

      await db.insert(
        NextcloudNewsFeedMappingsTable.tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return NewsFeedMapping(
        id: id,
        catalogId: catalogId,
        ncFeedId: ncFeedId,
        localFeedId: localFeedId,
        feedUrl: feedUrl,
        createdAt: now,
      );
    } catch (e) {
      throw Exception('Failed to save feed mapping: $e');
    }
  }

  @override
  Future<void> deleteFeedMapping(String catalogId, int ncFeedId) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        NextcloudNewsFeedMappingsTable.tableName,
        where:
            '''
          ${NextcloudNewsFeedMappingsTable.columnCatalogId} = ?
          AND ${NextcloudNewsFeedMappingsTable.columnNcFeedId} = ?
        ''',
        whereArgs: [catalogId, ncFeedId],
      );
    } catch (e) {
      throw Exception('Failed to delete feed mapping: $e');
    }
  }

  // ===== Item Mappings =====

  @override
  Future<String?> getLocalItemId(String catalogId, int ncItemId) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        NextcloudNewsItemMappingsTable.tableName,
        columns: [NextcloudNewsItemMappingsTable.columnLocalItemId],
        where:
            '''
          ${NextcloudNewsItemMappingsTable.columnCatalogId} = ?
          AND ${NextcloudNewsItemMappingsTable.columnNcItemId} = ?
        ''',
        whereArgs: [catalogId, ncItemId],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return maps.first[NextcloudNewsItemMappingsTable.columnLocalItemId]
          as String;
    } catch (e) {
      throw Exception('Failed to get local item ID: $e');
    }
  }

  @override
  Future<int?> getNcItemId(String catalogId, String localItemId) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        NextcloudNewsItemMappingsTable.tableName,
        columns: [NextcloudNewsItemMappingsTable.columnNcItemId],
        where:
            '''
          ${NextcloudNewsItemMappingsTable.columnCatalogId} = ?
          AND ${NextcloudNewsItemMappingsTable.columnLocalItemId} = ?
        ''',
        whereArgs: [catalogId, localItemId],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return maps.first[NextcloudNewsItemMappingsTable.columnNcItemId] as int;
    } catch (e) {
      throw Exception('Failed to get Nextcloud News item ID: $e');
    }
  }

  @override
  Future<List<NewsItemMapping>> getItemMappingsForFeed(
    String catalogId,
    int ncFeedId,
  ) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        NextcloudNewsItemMappingsTable.tableName,
        where:
            '''
          ${NextcloudNewsItemMappingsTable.columnCatalogId} = ?
          AND ${NextcloudNewsItemMappingsTable.columnNcFeedId} = ?
        ''',
        whereArgs: [catalogId, ncFeedId],
        orderBy: '${NextcloudNewsItemMappingsTable.columnCreatedAt} ASC',
      );

      return maps.map(_mapToItemMapping).toList();
    } catch (e) {
      throw Exception('Failed to get item mappings for feed: $e');
    }
  }

  @override
  Future<Map<int, String>> getLocalItemIds(
    String catalogId,
    List<int> ncItemIds,
  ) async {
    if (ncItemIds.isEmpty) {
      return {};
    }

    try {
      final db = await _databaseHelper.database;
      final placeholders = ncItemIds.map((_) => '?').join(',');

      final List<Map<String, dynamic>> maps = await db.query(
        NextcloudNewsItemMappingsTable.tableName,
        columns: [
          NextcloudNewsItemMappingsTable.columnNcItemId,
          NextcloudNewsItemMappingsTable.columnLocalItemId,
        ],
        where:
            '''
          ${NextcloudNewsItemMappingsTable.columnCatalogId} = ?
          AND ${NextcloudNewsItemMappingsTable.columnNcItemId} IN ($placeholders)
        ''',
        whereArgs: [catalogId, ...ncItemIds],
      );

      final result = <int, String>{};
      for (final map in maps) {
        final ncItemId =
            map[NextcloudNewsItemMappingsTable.columnNcItemId] as int;
        final localItemId =
            map[NextcloudNewsItemMappingsTable.columnLocalItemId] as String;
        result[ncItemId] = localItemId;
      }
      return result;
    } catch (e) {
      throw Exception('Failed to get local item IDs: $e');
    }
  }

  @override
  Future<NewsItemMapping> saveItemMapping({
    required String catalogId,
    required int ncItemId,
    required String localItemId,
    required int ncFeedId,
    required String localFeedId,
  }) async {
    try {
      final db = await _databaseHelper.database;
      final now = DateTime.now();
      final id = _uuid.v4();

      final data = {
        NextcloudNewsItemMappingsTable.columnId: id,
        NextcloudNewsItemMappingsTable.columnCatalogId: catalogId,
        NextcloudNewsItemMappingsTable.columnNcItemId: ncItemId,
        NextcloudNewsItemMappingsTable.columnLocalItemId: localItemId,
        NextcloudNewsItemMappingsTable.columnNcFeedId: ncFeedId,
        NextcloudNewsItemMappingsTable.columnLocalFeedId: localFeedId,
        NextcloudNewsItemMappingsTable.columnCreatedAt:
            now.millisecondsSinceEpoch,
      };

      await db.insert(
        NextcloudNewsItemMappingsTable.tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return NewsItemMapping(
        id: id,
        catalogId: catalogId,
        ncItemId: ncItemId,
        localItemId: localItemId,
        ncFeedId: ncFeedId,
        localFeedId: localFeedId,
        createdAt: now,
      );
    } catch (e) {
      throw Exception('Failed to save item mapping: $e');
    }
  }

  @override
  Future<void> saveItemMappings(List<NewsItemMapping> mappings) async {
    if (mappings.isEmpty) {
      return;
    }

    try {
      final db = await _databaseHelper.database;

      await db.transaction((txn) async {
        final batch = txn.batch();

        for (final mapping in mappings) {
          final data = {
            NextcloudNewsItemMappingsTable.columnId: mapping.id,
            NextcloudNewsItemMappingsTable.columnCatalogId: mapping.catalogId,
            NextcloudNewsItemMappingsTable.columnNcItemId: mapping.ncItemId,
            NextcloudNewsItemMappingsTable.columnLocalItemId:
                mapping.localItemId,
            NextcloudNewsItemMappingsTable.columnNcFeedId: mapping.ncFeedId,
            NextcloudNewsItemMappingsTable.columnLocalFeedId:
                mapping.localFeedId,
            NextcloudNewsItemMappingsTable.columnCreatedAt:
                mapping.createdAt.millisecondsSinceEpoch,
          };

          batch.insert(
            NextcloudNewsItemMappingsTable.tableName,
            data,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await batch.commit(noResult: true);
      });
    } catch (e) {
      throw Exception('Failed to save item mappings: $e');
    }
  }

  @override
  Future<void> deleteItemMapping(String catalogId, int ncItemId) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        NextcloudNewsItemMappingsTable.tableName,
        where:
            '''
          ${NextcloudNewsItemMappingsTable.columnCatalogId} = ?
          AND ${NextcloudNewsItemMappingsTable.columnNcItemId} = ?
        ''',
        whereArgs: [catalogId, ncItemId],
      );
    } catch (e) {
      throw Exception('Failed to delete item mapping: $e');
    }
  }

  // ===== Cleanup Operations =====

  @override
  Future<void> deleteMappingsForCatalog(String catalogId) async {
    try {
      final db = await _databaseHelper.database;

      await db.transaction((txn) async {
        // Delete item mappings first (child records)
        await txn.delete(
          NextcloudNewsItemMappingsTable.tableName,
          where: '${NextcloudNewsItemMappingsTable.columnCatalogId} = ?',
          whereArgs: [catalogId],
        );

        // Delete feed mappings
        await txn.delete(
          NextcloudNewsFeedMappingsTable.tableName,
          where: '${NextcloudNewsFeedMappingsTable.columnCatalogId} = ?',
          whereArgs: [catalogId],
        );
      });
    } catch (e) {
      throw Exception('Failed to delete mappings for catalog: $e');
    }
  }

  @override
  Future<void> deleteItemMappingsForFeed(String catalogId, int ncFeedId) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        NextcloudNewsItemMappingsTable.tableName,
        where:
            '''
          ${NextcloudNewsItemMappingsTable.columnCatalogId} = ?
          AND ${NextcloudNewsItemMappingsTable.columnNcFeedId} = ?
        ''',
        whereArgs: [catalogId, ncFeedId],
      );
    } catch (e) {
      throw Exception('Failed to delete item mappings for feed: $e');
    }
  }

  @override
  Future<int> getFeedMappingCount(String catalogId) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery(
        '''
        SELECT COUNT(*) as count FROM ${NextcloudNewsFeedMappingsTable.tableName}
        WHERE ${NextcloudNewsFeedMappingsTable.columnCatalogId} = ?
      ''',
        [catalogId],
      );

      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Failed to get feed mapping count: $e');
    }
  }

  @override
  Future<int> getItemMappingCount(String catalogId) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery(
        '''
        SELECT COUNT(*) as count FROM ${NextcloudNewsItemMappingsTable.tableName}
        WHERE ${NextcloudNewsItemMappingsTable.columnCatalogId} = ?
      ''',
        [catalogId],
      );

      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Failed to get item mapping count: $e');
    }
  }

  // ===== Helper Methods =====

  NewsFeedMapping _mapToFeedMapping(Map<String, dynamic> map) {
    return NewsFeedMapping(
      id: map[NextcloudNewsFeedMappingsTable.columnId] as String,
      catalogId: map[NextcloudNewsFeedMappingsTable.columnCatalogId] as String,
      ncFeedId: map[NextcloudNewsFeedMappingsTable.columnNcFeedId] as int,
      localFeedId:
          map[NextcloudNewsFeedMappingsTable.columnLocalFeedId] as String,
      feedUrl: map[NextcloudNewsFeedMappingsTable.columnFeedUrl] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[NextcloudNewsFeedMappingsTable.columnCreatedAt] as int,
      ),
    );
  }

  NewsItemMapping _mapToItemMapping(Map<String, dynamic> map) {
    return NewsItemMapping(
      id: map[NextcloudNewsItemMappingsTable.columnId] as String,
      catalogId: map[NextcloudNewsItemMappingsTable.columnCatalogId] as String,
      ncItemId: map[NextcloudNewsItemMappingsTable.columnNcItemId] as int,
      localItemId:
          map[NextcloudNewsItemMappingsTable.columnLocalItemId] as String,
      ncFeedId: map[NextcloudNewsItemMappingsTable.columnNcFeedId] as int,
      localFeedId:
          map[NextcloudNewsItemMappingsTable.columnLocalFeedId] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[NextcloudNewsItemMappingsTable.columnCreatedAt] as int,
      ),
    );
  }
}
