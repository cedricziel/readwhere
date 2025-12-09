import 'package:readwhere_opds/readwhere_opds.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/repositories/opds_cache_repository.dart';
import '../database/database_helper.dart';
import '../database/tables/cached_opds_entries_table.dart';
import '../database/tables/cached_opds_feeds_table.dart';
import '../database/tables/cached_opds_links_table.dart';
import '../models/opds/cached_opds_entry_model.dart';
import '../models/opds/cached_opds_feed_model.dart';
import '../models/opds/cached_opds_link_model.dart';

/// Implementation of OpdsCacheRepository using SQLite database
class OpdsCacheRepositoryImpl implements OpdsCacheRepository {
  final DatabaseHelper _databaseHelper;

  OpdsCacheRepositoryImpl(this._databaseHelper);

  @override
  Future<CachedFeedResult?> getCachedFeed(String catalogId, String url) async {
    final db = await _databaseHelper.database;

    // Get the feed
    final feedMaps = await db.query(
      CachedOpdsFeedsTable.tableName,
      where:
          '${CachedOpdsFeedsTable.columnCatalogId} = ? AND ${CachedOpdsFeedsTable.columnUrl} = ?',
      whereArgs: [catalogId, url],
    );

    if (feedMaps.isEmpty) return null;

    final feedModel = CachedOpdsFeedModel.fromMap(feedMaps.first);

    // Get feed-level links
    final feedLinkMaps = await db.query(
      CachedOpdsLinksTable.tableName,
      where: '${CachedOpdsLinksTable.columnFeedId} = ?',
      whereArgs: [feedModel.id],
      orderBy: CachedOpdsLinksTable.columnLinkOrder,
    );
    final feedLinks = feedLinkMaps
        .map((m) => CachedOpdsLinkModel.fromMap(m).toLink())
        .toList();

    // Get entries
    final entryMaps = await db.query(
      CachedOpdsEntriesTable.tableName,
      where: '${CachedOpdsEntriesTable.columnFeedId} = ?',
      whereArgs: [feedModel.id],
      orderBy: CachedOpdsEntriesTable.columnEntryOrder,
    );

    final entries = await Future.wait(
      entryMaps.map((entryMap) async {
        final entryModel = CachedOpdsEntryModel.fromMap(entryMap);

        // Get entry links
        final entryLinkMaps = await db.query(
          CachedOpdsLinksTable.tableName,
          where: '${CachedOpdsLinksTable.columnEntryId} = ?',
          whereArgs: [entryModel.id],
          orderBy: CachedOpdsLinksTable.columnLinkOrder,
        );
        final entryLinks = entryLinkMaps
            .map((m) => CachedOpdsLinkModel.fromMap(m).toLink())
            .toList();

        return entryModel.toEntry(entryLinks);
      }),
    );

    return feedModel.toCachedResult(entries: entries, links: feedLinks);
  }

  @override
  Future<void> cacheFeed(String catalogId, String url, OpdsFeed feed) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      // Delete existing cache for this URL (cascade deletes entries and links)
      await txn.delete(
        CachedOpdsFeedsTable.tableName,
        where:
            '${CachedOpdsFeedsTable.columnCatalogId} = ? AND ${CachedOpdsFeedsTable.columnUrl} = ?',
        whereArgs: [catalogId, url],
      );

      // Insert feed
      final feedModel = CachedOpdsFeedModel.fromFeed(
        catalogId: catalogId,
        url: url,
        feed: feed,
      );
      await txn.insert(CachedOpdsFeedsTable.tableName, feedModel.toMap());

      // Insert feed-level links
      for (var i = 0; i < feed.links.length; i++) {
        final linkModel = CachedOpdsLinkModel.fromLink(
          feed.links[i],
          feedId: feedModel.id,
          order: i,
        );
        await txn.insert(CachedOpdsLinksTable.tableName, linkModel.toMap());
      }

      // Insert entries and their links
      for (var i = 0; i < feed.entries.length; i++) {
        final entry = feed.entries[i];
        final entryModel = CachedOpdsEntryModel.fromEntry(
          entry,
          feedModel.id,
          i,
        );
        await txn.insert(CachedOpdsEntriesTable.tableName, entryModel.toMap());

        // Insert entry links
        for (var j = 0; j < entry.links.length; j++) {
          final linkModel = CachedOpdsLinkModel.fromLink(
            entry.links[j],
            entryId: entry.id,
            order: j,
          );
          await txn.insert(CachedOpdsLinksTable.tableName, linkModel.toMap());
        }
      }
    });
  }

  @override
  Future<bool> hasFreshCache(String catalogId, String url) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final result = await db.query(
      CachedOpdsFeedsTable.tableName,
      columns: [CachedOpdsFeedsTable.columnExpiresAt],
      where:
          '${CachedOpdsFeedsTable.columnCatalogId} = ? AND ${CachedOpdsFeedsTable.columnUrl} = ? AND ${CachedOpdsFeedsTable.columnExpiresAt} > ?',
      whereArgs: [catalogId, url, now],
    );

    return result.isNotEmpty;
  }

  @override
  Future<void> deleteFeedCache(String catalogId, String url) async {
    final db = await _databaseHelper.database;
    await db.delete(
      CachedOpdsFeedsTable.tableName,
      where:
          '${CachedOpdsFeedsTable.columnCatalogId} = ? AND ${CachedOpdsFeedsTable.columnUrl} = ?',
      whereArgs: [catalogId, url],
    );
  }

  @override
  Future<void> deleteCatalogCache(String catalogId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      CachedOpdsFeedsTable.tableName,
      where: '${CachedOpdsFeedsTable.columnCatalogId} = ?',
      whereArgs: [catalogId],
    );
  }

  @override
  Future<int> deleteExpiredCache() async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    return await db.delete(
      CachedOpdsFeedsTable.tableName,
      where: '${CachedOpdsFeedsTable.columnExpiresAt} < ?',
      whereArgs: [now],
    );
  }

  @override
  Future<CacheStats> getCacheStats(String catalogId) async {
    final db = await _databaseHelper.database;

    // Count feeds
    final feedCountResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${CachedOpdsFeedsTable.tableName} WHERE ${CachedOpdsFeedsTable.columnCatalogId} = ?',
      [catalogId],
    );
    final feedCount = Sqflite.firstIntValue(feedCountResult) ?? 0;

    // Count entries
    final entryCountResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM ${CachedOpdsEntriesTable.tableName} e
      INNER JOIN ${CachedOpdsFeedsTable.tableName} f ON e.${CachedOpdsEntriesTable.columnFeedId} = f.${CachedOpdsFeedsTable.columnId}
      WHERE f.${CachedOpdsFeedsTable.columnCatalogId} = ?
    ''',
      [catalogId],
    );
    final entryCount = Sqflite.firstIntValue(entryCountResult) ?? 0;

    // Get oldest and newest cache timestamps
    final timestampResult = await db.rawQuery(
      '''
      SELECT MIN(${CachedOpdsFeedsTable.columnCachedAt}) as oldest,
             MAX(${CachedOpdsFeedsTable.columnCachedAt}) as newest
      FROM ${CachedOpdsFeedsTable.tableName}
      WHERE ${CachedOpdsFeedsTable.columnCatalogId} = ?
    ''',
      [catalogId],
    );

    DateTime? oldestCache;
    DateTime? newestCache;
    if (timestampResult.isNotEmpty) {
      final oldest = timestampResult.first['oldest'] as int?;
      final newest = timestampResult.first['newest'] as int?;
      if (oldest != null) {
        oldestCache = DateTime.fromMillisecondsSinceEpoch(oldest);
      }
      if (newest != null) {
        newestCache = DateTime.fromMillisecondsSinceEpoch(newest);
      }
    }

    // Estimate size (rough approximation)
    final totalSizeBytes = (feedCount * 500) + (entryCount * 1000);

    return CacheStats(
      feedCount: feedCount,
      entryCount: entryCount,
      totalSizeBytes: totalSizeBytes,
      oldestCache: oldestCache,
      newestCache: newestCache,
    );
  }

  @override
  Future<CacheStats> getAllCacheStats() async {
    final db = await _databaseHelper.database;

    // Count feeds
    final feedCountResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${CachedOpdsFeedsTable.tableName}',
    );
    final feedCount = Sqflite.firstIntValue(feedCountResult) ?? 0;

    // Count entries
    final entryCountResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${CachedOpdsEntriesTable.tableName}',
    );
    final entryCount = Sqflite.firstIntValue(entryCountResult) ?? 0;

    // Get oldest and newest cache timestamps
    final timestampResult = await db.rawQuery('''
      SELECT MIN(${CachedOpdsFeedsTable.columnCachedAt}) as oldest,
             MAX(${CachedOpdsFeedsTable.columnCachedAt}) as newest
      FROM ${CachedOpdsFeedsTable.tableName}
    ''');

    DateTime? oldestCache;
    DateTime? newestCache;
    if (timestampResult.isNotEmpty) {
      final oldest = timestampResult.first['oldest'] as int?;
      final newest = timestampResult.first['newest'] as int?;
      if (oldest != null) {
        oldestCache = DateTime.fromMillisecondsSinceEpoch(oldest);
      }
      if (newest != null) {
        newestCache = DateTime.fromMillisecondsSinceEpoch(newest);
      }
    }

    // Estimate size
    final totalSizeBytes = (feedCount * 500) + (entryCount * 1000);

    return CacheStats(
      feedCount: feedCount,
      entryCount: entryCount,
      totalSizeBytes: totalSizeBytes,
      oldestCache: oldestCache,
      newestCache: newestCache,
    );
  }

  @override
  Future<void> clearAllCache() async {
    final db = await _databaseHelper.database;
    await db.delete(CachedOpdsFeedsTable.tableName);
  }
}
