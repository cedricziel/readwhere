import 'package:sqflite/sqflite.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/repositories/reading_progress_repository.dart';
import '../database/database_helper.dart';
import '../database/tables/reading_progress_table.dart';
import '../models/reading_progress_model.dart';

/// Implementation of ReadingProgressRepository using SQLite
///
/// This implementation uses DatabaseHelper to perform CRUD operations
/// on reading progress records stored in the local SQLite database.
class ReadingProgressRepositoryImpl implements ReadingProgressRepository {
  final DatabaseHelper _databaseHelper;

  ReadingProgressRepositoryImpl(this._databaseHelper);

  @override
  Future<ReadingProgress?> getProgressForBook(String bookId) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        ReadingProgressTable.tableName,
        where: '${ReadingProgressTable.columnBookId} = ?',
        whereArgs: [bookId],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return ReadingProgressModel.fromMap(maps.first).toEntity();
    } catch (e) {
      throw Exception(
        'Failed to retrieve reading progress for book $bookId: $e',
      );
    }
  }

  @override
  Future<ReadingProgress> saveProgress(ReadingProgress progress) async {
    try {
      final db = await _databaseHelper.database;
      final model = ReadingProgressModel.fromEntity(progress);

      // Check if progress already exists for this book
      final existing = await getProgressForBook(progress.bookId);

      if (existing != null) {
        // Update existing progress
        await db.update(
          ReadingProgressTable.tableName,
          model.toMap(),
          where: '${ReadingProgressTable.columnBookId} = ?',
          whereArgs: [progress.bookId],
        );
      } else {
        // Insert new progress
        await db.insert(
          ReadingProgressTable.tableName,
          model.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return progress;
    } catch (e) {
      throw Exception('Failed to save reading progress: $e');
    }
  }

  @override
  Future<bool> deleteProgressForBook(String bookId) async {
    try {
      final db = await _databaseHelper.database;
      final count = await db.delete(
        ReadingProgressTable.tableName,
        where: '${ReadingProgressTable.columnBookId} = ?',
        whereArgs: [bookId],
      );

      return count > 0;
    } catch (e) {
      throw Exception('Failed to delete reading progress for book $bookId: $e');
    }
  }
}
