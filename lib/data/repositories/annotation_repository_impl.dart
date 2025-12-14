import 'package:sqflite/sqflite.dart';
import '../../domain/entities/annotation.dart';
import '../../domain/repositories/annotation_repository.dart';
import '../database/database_helper.dart';
import '../database/tables/annotations_table.dart';
import '../models/annotation_model.dart';

/// Implementation of AnnotationRepository using SQLite
///
/// This implementation uses DatabaseHelper to perform CRUD operations
/// on annotations stored in the local SQLite database.
class AnnotationRepositoryImpl implements AnnotationRepository {
  final DatabaseHelper _databaseHelper;

  AnnotationRepositoryImpl(this._databaseHelper);

  @override
  Future<List<Annotation>> getAnnotationsForBook(String bookId) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        AnnotationsTable.tableName,
        where: '${AnnotationsTable.columnBookId} = ?',
        whereArgs: [bookId],
        orderBy: '${AnnotationsTable.columnCreatedAt} DESC',
      );

      return maps
          .map((map) => AnnotationModel.fromMap(map).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to retrieve annotations for book $bookId: $e');
    }
  }

  @override
  Future<List<Annotation>> getAnnotationsForChapter(
    String bookId,
    String chapterId,
  ) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        AnnotationsTable.tableName,
        where:
            '${AnnotationsTable.columnBookId} = ? AND ${AnnotationsTable.columnChapterId} = ?',
        whereArgs: [bookId, chapterId],
        orderBy: '${AnnotationsTable.columnCfiStart} ASC',
      );

      return maps
          .map((map) => AnnotationModel.fromMap(map).toEntity())
          .toList();
    } catch (e) {
      throw Exception(
        'Failed to retrieve annotations for chapter $chapterId in book $bookId: $e',
      );
    }
  }

  @override
  Future<Annotation> addAnnotation(Annotation annotation) async {
    try {
      final db = await _databaseHelper.database;
      final model = AnnotationModel.fromEntity(annotation);

      await db.insert(
        AnnotationsTable.tableName,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );

      return annotation;
    } catch (e) {
      throw Exception('Failed to add annotation: $e');
    }
  }

  @override
  Future<bool> deleteAnnotation(String id) async {
    try {
      final db = await _databaseHelper.database;
      final count = await db.delete(
        AnnotationsTable.tableName,
        where: '${AnnotationsTable.columnId} = ?',
        whereArgs: [id],
      );

      return count > 0;
    } catch (e) {
      throw Exception('Failed to delete annotation with id $id: $e');
    }
  }

  @override
  Future<Annotation> updateAnnotation(Annotation annotation) async {
    try {
      final db = await _databaseHelper.database;
      final model = AnnotationModel.fromEntity(annotation);

      final count = await db.update(
        AnnotationsTable.tableName,
        model.toMap(),
        where: '${AnnotationsTable.columnId} = ?',
        whereArgs: [annotation.id],
      );

      if (count == 0) {
        throw Exception('Annotation with id ${annotation.id} not found');
      }

      return annotation;
    } catch (e) {
      throw Exception('Failed to update annotation: $e');
    }
  }

  @override
  Future<int> deleteAnnotationsForBook(String bookId) async {
    try {
      final db = await _databaseHelper.database;
      final count = await db.delete(
        AnnotationsTable.tableName,
        where: '${AnnotationsTable.columnBookId} = ?',
        whereArgs: [bookId],
      );

      return count;
    } catch (e) {
      throw Exception('Failed to delete annotations for book $bookId: $e');
    }
  }
}
