import 'dart:convert';

import '../../domain/entities/book.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';
import '../database/tables/books_table.dart';

/// Data model for Book entity with database serialization support
///
/// This model extends the domain entity with methods for converting
/// to and from database representations (Map format for SQLite).
class BookModel extends Book {
  const BookModel({
    required super.id,
    required super.title,
    required super.author,
    required super.filePath,
    super.coverPath,
    required super.format,
    required super.fileSize,
    required super.addedAt,
    super.lastOpenedAt,
    super.isFavorite,
    super.readingProgress,
    super.encryptionType,
    super.isFixedLayout,
    super.hasMediaOverlays,
    super.sourceCatalogId,
    super.sourceEntryId,
    super.publisher,
    super.description,
    super.language,
    super.publishedDate,
    super.subjects,
  });

  /// Create a BookModel from a Map (SQLite row)
  ///
  /// Converts database column types to Dart types:
  /// - INTEGER timestamps to DateTime
  /// - INTEGER boolean (0/1) to bool
  /// - TEXT encryption type to EpubEncryptionType enum
  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      id: map[BooksTable.columnId] as String,
      title: map[BooksTable.columnTitle] as String,
      author: map[BooksTable.columnAuthor] as String? ?? '',
      filePath: map[BooksTable.columnFilePath] as String,
      coverPath: map[BooksTable.columnCoverPath] as String?,
      format: map[BooksTable.columnFormat] as String,
      fileSize: map[BooksTable.columnFileSize] as int? ?? 0,
      addedAt: DateTime.fromMillisecondsSinceEpoch(
        map[BooksTable.columnAddedAt] as int,
      ),
      lastOpenedAt: map[BooksTable.columnLastOpenedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[BooksTable.columnLastOpenedAt] as int,
            )
          : null,
      isFavorite: (map[BooksTable.columnIsFavorite] as int) == 1,
      readingProgress: null, // Reading progress is stored separately
      encryptionType: _parseEncryptionType(
        map[BooksTable.columnEncryptionType] as String?,
      ),
      isFixedLayout: (map[BooksTable.columnIsFixedLayout] as int?) == 1,
      hasMediaOverlays: (map[BooksTable.columnHasMediaOverlays] as int?) == 1,
      sourceCatalogId: map[BooksTable.columnSourceCatalogId] as String?,
      sourceEntryId: map[BooksTable.columnSourceEntryId] as String?,
      publisher: map[BooksTable.columnPublisher] as String?,
      description: map[BooksTable.columnDescription] as String?,
      language: map[BooksTable.columnLanguage] as String?,
      publishedDate: map[BooksTable.columnPublishedDate] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[BooksTable.columnPublishedDate] as int,
            )
          : null,
      subjects: _parseSubjects(map[BooksTable.columnSubjects] as String?),
    );
  }

  /// Parse subjects JSON array from database string
  static List<String> _parseSubjects(String? value) {
    if (value == null || value.isEmpty) return const [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded.cast<String>();
      }
    } catch (_) {
      // If JSON parsing fails, try comma-separated fallback
      return value.split(',').map((s) => s.trim()).toList();
    }
    return const [];
  }

  /// Parse encryption type string to enum
  static EpubEncryptionType _parseEncryptionType(String? value) {
    switch (value) {
      case 'adobeDrm':
        return EpubEncryptionType.adobeDrm;
      case 'appleFairPlay':
        return EpubEncryptionType.appleFairPlay;
      case 'lcp':
        return EpubEncryptionType.lcp;
      case 'fontObfuscation':
        return EpubEncryptionType.fontObfuscation;
      case 'unknown':
        return EpubEncryptionType.unknown;
      case 'none':
      default:
        return EpubEncryptionType.none;
    }
  }

  /// Create a BookModel from a domain entity
  factory BookModel.fromEntity(Book book) {
    return BookModel(
      id: book.id,
      title: book.title,
      author: book.author,
      filePath: book.filePath,
      coverPath: book.coverPath,
      format: book.format,
      fileSize: book.fileSize,
      addedAt: book.addedAt,
      lastOpenedAt: book.lastOpenedAt,
      isFavorite: book.isFavorite,
      readingProgress: book.readingProgress,
      encryptionType: book.encryptionType,
      isFixedLayout: book.isFixedLayout,
      hasMediaOverlays: book.hasMediaOverlays,
      sourceCatalogId: book.sourceCatalogId,
      sourceEntryId: book.sourceEntryId,
      publisher: book.publisher,
      description: book.description,
      language: book.language,
      publishedDate: book.publishedDate,
      subjects: book.subjects,
    );
  }

  /// Convert to a Map for SQLite storage
  ///
  /// Converts Dart types to database column types:
  /// - DateTime to INTEGER (milliseconds since epoch)
  /// - bool to INTEGER (0 or 1)
  /// - EpubEncryptionType enum to TEXT
  Map<String, dynamic> toMap() {
    return {
      BooksTable.columnId: id,
      BooksTable.columnTitle: title,
      BooksTable.columnAuthor: author,
      BooksTable.columnFilePath: filePath,
      BooksTable.columnCoverPath: coverPath,
      BooksTable.columnFormat: format,
      BooksTable.columnFileSize: fileSize,
      BooksTable.columnAddedAt: addedAt.millisecondsSinceEpoch,
      BooksTable.columnLastOpenedAt: lastOpenedAt?.millisecondsSinceEpoch,
      BooksTable.columnIsFavorite: isFavorite ? 1 : 0,
      BooksTable.columnEncryptionType: encryptionType.name,
      BooksTable.columnIsFixedLayout: isFixedLayout ? 1 : 0,
      BooksTable.columnHasMediaOverlays: hasMediaOverlays ? 1 : 0,
      BooksTable.columnSourceCatalogId: sourceCatalogId,
      BooksTable.columnSourceEntryId: sourceEntryId,
      BooksTable.columnPublisher: publisher,
      BooksTable.columnDescription: description,
      BooksTable.columnLanguage: language,
      BooksTable.columnPublishedDate: publishedDate?.millisecondsSinceEpoch,
      BooksTable.columnSubjects: subjects.isNotEmpty
          ? jsonEncode(subjects)
          : null,
    };
  }

  /// Convert to domain entity (Book)
  Book toEntity() {
    return Book(
      id: id,
      title: title,
      author: author,
      filePath: filePath,
      coverPath: coverPath,
      format: format,
      fileSize: fileSize,
      addedAt: addedAt,
      lastOpenedAt: lastOpenedAt,
      isFavorite: isFavorite,
      readingProgress: readingProgress,
      encryptionType: encryptionType,
      isFixedLayout: isFixedLayout,
      hasMediaOverlays: hasMediaOverlays,
      sourceCatalogId: sourceCatalogId,
      sourceEntryId: sourceEntryId,
      publisher: publisher,
      description: description,
      language: language,
      publishedDate: publishedDate,
      subjects: subjects,
    );
  }
}
