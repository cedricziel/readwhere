import 'package:sqflite/sqflite.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../database/database_helper.dart';
import '../database/tables/bookmarks_table.dart';
import '../models/bookmark_model.dart';

/// Implementation of BookmarkRepository using SQLite
///
/// This implementation uses DatabaseHelper to perform CRUD operations
/// on bookmarks stored in the local SQLite database.
class BookmarkRepositoryImpl implements BookmarkRepository {
  final DatabaseHelper _databaseHelper;

  BookmarkRepositoryImpl(this._databaseHelper);

  @override
  Future<List<Bookmark>> getBookmarksForBook(String bookId) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        BookmarksTable.tableName,
        where: '${BookmarksTable.columnBookId} = ?',
        whereArgs: [bookId],
        orderBy: '${BookmarksTable.columnCreatedAt} DESC',
      );

      return maps.map((map) => BookmarkModel.fromMap(map).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to retrieve bookmarks for book $bookId: $e');
    }
  }

  @override
  Future<Bookmark> addBookmark(Bookmark bookmark) async {
    try {
      final db = await _databaseHelper.database;
      final model = BookmarkModel.fromEntity(bookmark);

      await db.insert(
        BookmarksTable.tableName,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );

      return bookmark;
    } catch (e) {
      throw Exception('Failed to add bookmark: $e');
    }
  }

  @override
  Future<bool> deleteBookmark(String id) async {
    try {
      final db = await _databaseHelper.database;
      final count = await db.delete(
        BookmarksTable.tableName,
        where: '${BookmarksTable.columnId} = ?',
        whereArgs: [id],
      );

      return count > 0;
    } catch (e) {
      throw Exception('Failed to delete bookmark with id $id: $e');
    }
  }

  @override
  Future<Bookmark> updateBookmark(Bookmark bookmark) async {
    try {
      final db = await _databaseHelper.database;
      final model = BookmarkModel.fromEntity(bookmark);

      final count = await db.update(
        BookmarksTable.tableName,
        model.toMap(),
        where: '${BookmarksTable.columnId} = ?',
        whereArgs: [bookmark.id],
      );

      if (count == 0) {
        throw Exception('Bookmark with id ${bookmark.id} not found');
      }

      return bookmark;
    } catch (e) {
      throw Exception('Failed to update bookmark: $e');
    }
  }
}
