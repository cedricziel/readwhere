import '../../domain/entities/feed_item.dart';
import '../../domain/repositories/feed_item_repository.dart';
import '../database/database_helper.dart';
import '../database/tables/feed_items_table.dart';
import '../models/feed_item_model.dart';

/// Implementation of FeedItemRepository using SQLite database
class FeedItemRepositoryImpl implements FeedItemRepository {
  final DatabaseHelper _databaseHelper;

  FeedItemRepositoryImpl(this._databaseHelper);

  @override
  Future<List<FeedItem>> getByFeedId(
    String feedId, {
    bool unreadOnly = false,
    int? limit,
  }) async {
    final db = await _databaseHelper.database;

    String? where = '${FeedItemsTable.columnFeedId} = ?';
    List<Object?> whereArgs = [feedId];

    if (unreadOnly) {
      where += ' AND ${FeedItemsTable.columnIsRead} = 0';
    }

    final maps = await db.query(
      FeedItemsTable.tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: '${FeedItemsTable.columnPubDate} DESC',
      limit: limit,
    );

    return maps.map((map) => FeedItemModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<FeedItem?> getById(String id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      FeedItemsTable.tableName,
      where: '${FeedItemsTable.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return FeedItemModel.fromMap(maps.first).toEntity();
  }

  @override
  Future<void> upsertItems(String feedId, List<FeedItem> items) async {
    if (items.isEmpty) return;

    final db = await _databaseHelper.database;

    // Get existing items to preserve read/starred state
    final existingMaps = await db.query(
      FeedItemsTable.tableName,
      columns: [
        FeedItemsTable.columnId,
        FeedItemsTable.columnIsRead,
        FeedItemsTable.columnIsStarred,
      ],
      where: '${FeedItemsTable.columnFeedId} = ?',
      whereArgs: [feedId],
    );

    final existingStates = <String, Map<String, int>>{};
    for (final map in existingMaps) {
      final id = map[FeedItemsTable.columnId] as String;
      existingStates[id] = {
        'isRead': map[FeedItemsTable.columnIsRead] as int,
        'isStarred': map[FeedItemsTable.columnIsStarred] as int,
      };
    }

    // Use a batch for efficient bulk operations
    final batch = db.batch();

    for (final item in items) {
      final model = FeedItemModel.fromEntity(item);
      final map = model.toMap();

      // Preserve existing read/starred state if item exists
      if (existingStates.containsKey(item.id)) {
        map[FeedItemsTable.columnIsRead] = existingStates[item.id]!['isRead'];
        map[FeedItemsTable.columnIsStarred] =
            existingStates[item.id]!['isStarred'];

        batch.update(
          FeedItemsTable.tableName,
          map,
          where: '${FeedItemsTable.columnId} = ?',
          whereArgs: [item.id],
        );
      } else {
        batch.insert(FeedItemsTable.tableName, map);
      }
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<void> markAsRead(String itemId) async {
    final db = await _databaseHelper.database;
    await db.update(
      FeedItemsTable.tableName,
      {FeedItemsTable.columnIsRead: 1},
      where: '${FeedItemsTable.columnId} = ?',
      whereArgs: [itemId],
    );
  }

  @override
  Future<void> markAsUnread(String itemId) async {
    final db = await _databaseHelper.database;
    await db.update(
      FeedItemsTable.tableName,
      {FeedItemsTable.columnIsRead: 0},
      where: '${FeedItemsTable.columnId} = ?',
      whereArgs: [itemId],
    );
  }

  @override
  Future<void> markAllAsRead(String feedId) async {
    final db = await _databaseHelper.database;
    await db.update(
      FeedItemsTable.tableName,
      {FeedItemsTable.columnIsRead: 1},
      where: '${FeedItemsTable.columnFeedId} = ?',
      whereArgs: [feedId],
    );
  }

  @override
  Future<void> toggleStarred(String itemId) async {
    final db = await _databaseHelper.database;

    // Get current state
    final maps = await db.query(
      FeedItemsTable.tableName,
      columns: [FeedItemsTable.columnIsStarred],
      where: '${FeedItemsTable.columnId} = ?',
      whereArgs: [itemId],
    );

    if (maps.isEmpty) return;

    final currentStarred = (maps.first[FeedItemsTable.columnIsStarred] as int);
    final newStarred = currentStarred == 1 ? 0 : 1;

    await db.update(
      FeedItemsTable.tableName,
      {FeedItemsTable.columnIsStarred: newStarred},
      where: '${FeedItemsTable.columnId} = ?',
      whereArgs: [itemId],
    );
  }

  @override
  Future<int> getUnreadCount(String feedId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM ${FeedItemsTable.tableName}
      WHERE ${FeedItemsTable.columnFeedId} = ?
        AND ${FeedItemsTable.columnIsRead} = 0
      ''',
      [feedId],
    );
    return result.first['count'] as int;
  }

  @override
  Future<Map<String, int>> getAllUnreadCounts() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT ${FeedItemsTable.columnFeedId}, COUNT(*) as count
      FROM ${FeedItemsTable.tableName}
      WHERE ${FeedItemsTable.columnIsRead} = 0
      GROUP BY ${FeedItemsTable.columnFeedId}
      ''');

    final counts = <String, int>{};
    for (final row in result) {
      counts[row[FeedItemsTable.columnFeedId] as String] = row['count'] as int;
    }
    return counts;
  }

  @override
  Future<void> deleteOldItems(String feedId, {int keepCount = 100}) async {
    final db = await _databaseHelper.database;

    // Delete items beyond the keep count, but keep starred items
    await db.rawDelete(
      '''
      DELETE FROM ${FeedItemsTable.tableName}
      WHERE ${FeedItemsTable.columnFeedId} = ?
        AND ${FeedItemsTable.columnIsStarred} = 0
        AND ${FeedItemsTable.columnId} NOT IN (
          SELECT ${FeedItemsTable.columnId}
          FROM ${FeedItemsTable.tableName}
          WHERE ${FeedItemsTable.columnFeedId} = ?
          ORDER BY ${FeedItemsTable.columnPubDate} DESC
          LIMIT ?
        )
      ''',
      [feedId, feedId, keepCount],
    );
  }

  @override
  Future<void> deleteByFeedId(String feedId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      FeedItemsTable.tableName,
      where: '${FeedItemsTable.columnFeedId} = ?',
      whereArgs: [feedId],
    );
  }

  @override
  Future<List<FeedItem>> getStarredItems() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      FeedItemsTable.tableName,
      where: '${FeedItemsTable.columnIsStarred} = 1',
      orderBy: '${FeedItemsTable.columnPubDate} DESC',
    );
    return maps.map((map) => FeedItemModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<void> updateFullContent(String itemId, String fullContent) async {
    final db = await _databaseHelper.database;
    await db.update(
      FeedItemsTable.tableName,
      {
        FeedItemsTable.columnFullContent: fullContent,
        FeedItemsTable.columnContentScrapedAt:
            DateTime.now().millisecondsSinceEpoch,
      },
      where: '${FeedItemsTable.columnId} = ?',
      whereArgs: [itemId],
    );
  }
}
