import 'package:sqflite/sqflite.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../database/database_helper.dart';
import '../database/tables/books_table.dart';
import '../models/book_model.dart';

/// Implementation of BookRepository using SQLite
///
/// This implementation uses DatabaseHelper to perform CRUD operations
/// on books stored in the local SQLite database.
class BookRepositoryImpl implements BookRepository {
  final DatabaseHelper _databaseHelper;

  BookRepositoryImpl(this._databaseHelper);

  @override
  Future<List<Book>> getAll() async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        BooksTable.tableName,
        orderBy: '${BooksTable.columnAddedAt} DESC',
      );

      return maps.map((map) => BookModel.fromMap(map).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to retrieve books: $e');
    }
  }

  @override
  Future<Book?> getById(String id) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        BooksTable.tableName,
        where: '${BooksTable.columnId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return BookModel.fromMap(maps.first).toEntity();
    } catch (e) {
      throw Exception('Failed to retrieve book with id $id: $e');
    }
  }

  @override
  Future<Book> insert(Book book) async {
    try {
      final db = await _databaseHelper.database;
      final model = BookModel.fromEntity(book);

      await db.insert(
        BooksTable.tableName,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );

      return book;
    } catch (e) {
      throw Exception('Failed to insert book: $e');
    }
  }

  @override
  Future<Book> update(Book book) async {
    try {
      final db = await _databaseHelper.database;
      final model = BookModel.fromEntity(book);

      final count = await db.update(
        BooksTable.tableName,
        model.toMap(),
        where: '${BooksTable.columnId} = ?',
        whereArgs: [book.id],
      );

      if (count == 0) {
        throw Exception('Book with id ${book.id} not found');
      }

      return book;
    } catch (e) {
      throw Exception('Failed to update book: $e');
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      final db = await _databaseHelper.database;
      final count = await db.delete(
        BooksTable.tableName,
        where: '${BooksTable.columnId} = ?',
        whereArgs: [id],
      );

      return count > 0;
    } catch (e) {
      throw Exception('Failed to delete book with id $id: $e');
    }
  }

  @override
  Future<List<Book>> getRecent({int limit = 10}) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        BooksTable.tableName,
        where: '${BooksTable.columnLastOpenedAt} IS NOT NULL',
        orderBy: '${BooksTable.columnLastOpenedAt} DESC',
        limit: limit,
      );

      return maps.map((map) => BookModel.fromMap(map).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to retrieve recent books: $e');
    }
  }

  @override
  Future<List<Book>> getFavorites() async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        BooksTable.tableName,
        where: '${BooksTable.columnIsFavorite} = ?',
        whereArgs: [1],
        orderBy: '${BooksTable.columnTitle} ASC',
      );

      return maps.map((map) => BookModel.fromMap(map).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to retrieve favorite books: $e');
    }
  }

  @override
  Future<List<Book>> search(String query) async {
    try {
      final db = await _databaseHelper.database;
      final searchPattern = '%$query%';

      final List<Map<String, dynamic>> maps = await db.query(
        BooksTable.tableName,
        where: '${BooksTable.columnTitle} LIKE ? OR ${BooksTable.columnAuthor} LIKE ?',
        whereArgs: [searchPattern, searchPattern],
        orderBy: '${BooksTable.columnTitle} ASC',
      );

      return maps.map((map) => BookModel.fromMap(map).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to search books: $e');
    }
  }

  @override
  Future<void> updateLastOpened(String id) async {
    try {
      final db = await _databaseHelper.database;
      final now = DateTime.now();

      final count = await db.update(
        BooksTable.tableName,
        {BooksTable.columnLastOpenedAt: now.millisecondsSinceEpoch},
        where: '${BooksTable.columnId} = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw Exception('Book with id $id not found');
      }
    } catch (e) {
      throw Exception('Failed to update last opened timestamp: $e');
    }
  }

  @override
  Future<Book> toggleFavorite(String id) async {
    try {
      final db = await _databaseHelper.database;

      // First, get the current book
      final book = await getById(id);
      if (book == null) {
        throw Exception('Book with id $id not found');
      }

      // Toggle the favorite status
      final newFavoriteStatus = !book.isFavorite;

      await db.update(
        BooksTable.tableName,
        {BooksTable.columnIsFavorite: newFavoriteStatus ? 1 : 0},
        where: '${BooksTable.columnId} = ?',
        whereArgs: [id],
      );

      // Return the updated book
      return book.copyWith(isFavorite: newFavoriteStatus);
    } catch (e) {
      throw Exception('Failed to toggle favorite status: $e');
    }
  }
}
