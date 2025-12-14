import '../../domain/entities/annotation.dart';
import '../database/tables/annotations_table.dart';

/// Data model for Annotation entity with database serialization support
///
/// This model extends the domain entity with methods for converting
/// to and from database representations (Map format for SQLite).
class AnnotationModel extends Annotation {
  const AnnotationModel({
    required super.id,
    required super.bookId,
    super.chapterId,
    required super.cfiStart,
    required super.cfiEnd,
    required super.text,
    super.note,
    required super.color,
    required super.createdAt,
  });

  /// Create an AnnotationModel from a Map (SQLite row)
  ///
  /// Converts database column types to Dart types:
  /// - INTEGER timestamps to DateTime
  /// - TEXT color to AnnotationColor enum
  factory AnnotationModel.fromMap(Map<String, dynamic> map) {
    return AnnotationModel(
      id: map[AnnotationsTable.columnId] as String,
      bookId: map[AnnotationsTable.columnBookId] as String,
      chapterId: map[AnnotationsTable.columnChapterId] as String?,
      cfiStart: map[AnnotationsTable.columnCfiStart] as String? ?? '',
      cfiEnd: map[AnnotationsTable.columnCfiEnd] as String? ?? '',
      text: map[AnnotationsTable.columnText] as String? ?? '',
      note: map[AnnotationsTable.columnNote] as String?,
      color: _parseColor(map[AnnotationsTable.columnColor] as String?),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[AnnotationsTable.columnCreatedAt] as int,
      ),
    );
  }

  /// Create an AnnotationModel from a domain entity
  factory AnnotationModel.fromEntity(Annotation annotation) {
    return AnnotationModel(
      id: annotation.id,
      bookId: annotation.bookId,
      chapterId: annotation.chapterId,
      cfiStart: annotation.cfiStart,
      cfiEnd: annotation.cfiEnd,
      text: annotation.text,
      note: annotation.note,
      color: annotation.color,
      createdAt: annotation.createdAt,
    );
  }

  /// Convert to a Map for SQLite storage
  ///
  /// Converts Dart types to database column types:
  /// - DateTime to INTEGER (milliseconds since epoch)
  /// - AnnotationColor to TEXT (enum name)
  Map<String, dynamic> toMap() {
    return {
      AnnotationsTable.columnId: id,
      AnnotationsTable.columnBookId: bookId,
      AnnotationsTable.columnChapterId: chapterId,
      AnnotationsTable.columnCfiStart: cfiStart,
      AnnotationsTable.columnCfiEnd: cfiEnd,
      AnnotationsTable.columnText: text,
      AnnotationsTable.columnNote: note,
      AnnotationsTable.columnColor: color.name,
      AnnotationsTable.columnCreatedAt: createdAt.millisecondsSinceEpoch,
    };
  }

  /// Convert to domain entity (Annotation)
  Annotation toEntity() {
    return Annotation(
      id: id,
      bookId: bookId,
      chapterId: chapterId,
      cfiStart: cfiStart,
      cfiEnd: cfiEnd,
      text: text,
      note: note,
      color: color,
      createdAt: createdAt,
    );
  }

  /// Parse color string to AnnotationColor enum
  ///
  /// Returns yellow as default if the color string is null or invalid.
  static AnnotationColor _parseColor(String? colorName) {
    if (colorName == null || colorName.isEmpty) {
      return AnnotationColor.yellow;
    }
    return AnnotationColor.values.firstWhere(
      (c) => c.name == colorName,
      orElse: () => AnnotationColor.yellow,
    );
  }
}
