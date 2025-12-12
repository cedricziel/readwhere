import 'package:equatable/equatable.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

/// Represents a book in the library
class Book extends Equatable {
  final String id;
  final String title;
  final String author;
  final String filePath;
  final String? coverPath;
  final String format; // epub, pdf, mobi, etc.
  final int fileSize; // in bytes
  final DateTime addedAt;
  final DateTime? lastOpenedAt;
  final bool isFavorite;
  final double? readingProgress; // 0.0 to 1.0

  /// Encryption type for EPUB books
  final EpubEncryptionType encryptionType;

  /// Whether this book is a fixed-layout EPUB
  final bool isFixedLayout;

  /// Whether this EPUB has media overlays (audio sync)
  final bool hasMediaOverlays;

  /// ID of the catalog this book was downloaded from (null for local imports)
  final String? sourceCatalogId;

  /// Entry ID in the source catalog (for tracking remote books)
  final String? sourceEntryId;

  // Extended metadata fields

  /// Publisher name
  final String? publisher;

  /// Book description/summary
  final String? description;

  /// Primary language (BCP 47 code like "en", "de")
  final String? language;

  /// Publication date
  final DateTime? publishedDate;

  /// Subject categories/tags
  final List<String> subjects;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.filePath,
    this.coverPath,
    required this.format,
    required this.fileSize,
    required this.addedAt,
    this.lastOpenedAt,
    this.isFavorite = false,
    this.readingProgress,
    this.encryptionType = EpubEncryptionType.none,
    this.isFixedLayout = false,
    this.hasMediaOverlays = false,
    this.sourceCatalogId,
    this.sourceEntryId,
    this.publisher,
    this.description,
    this.language,
    this.publishedDate,
    this.subjects = const [],
  }) : assert(
         readingProgress == null ||
             (readingProgress >= 0.0 && readingProgress <= 1.0),
         'Reading progress must be between 0.0 and 1.0',
       );

  /// Whether this book has DRM that prevents reading.
  bool get hasDrm =>
      encryptionType != EpubEncryptionType.none &&
      encryptionType != EpubEncryptionType.fontObfuscation;

  /// Whether this book was downloaded from a remote catalog
  bool get isFromCatalog =>
      sourceCatalogId != null && sourceCatalogId!.isNotEmpty;

  /// Creates a copy of this Book with the given fields replaced with new values
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? filePath,
    String? coverPath,
    String? format,
    int? fileSize,
    DateTime? addedAt,
    DateTime? lastOpenedAt,
    bool? isFavorite,
    double? readingProgress,
    EpubEncryptionType? encryptionType,
    bool? isFixedLayout,
    bool? hasMediaOverlays,
    String? sourceCatalogId,
    String? sourceEntryId,
    String? publisher,
    String? description,
    String? language,
    DateTime? publishedDate,
    List<String>? subjects,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      coverPath: coverPath ?? this.coverPath,
      format: format ?? this.format,
      fileSize: fileSize ?? this.fileSize,
      addedAt: addedAt ?? this.addedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      readingProgress: readingProgress ?? this.readingProgress,
      encryptionType: encryptionType ?? this.encryptionType,
      isFixedLayout: isFixedLayout ?? this.isFixedLayout,
      hasMediaOverlays: hasMediaOverlays ?? this.hasMediaOverlays,
      sourceCatalogId: sourceCatalogId ?? this.sourceCatalogId,
      sourceEntryId: sourceEntryId ?? this.sourceEntryId,
      publisher: publisher ?? this.publisher,
      description: description ?? this.description,
      language: language ?? this.language,
      publishedDate: publishedDate ?? this.publishedDate,
      subjects: subjects ?? this.subjects,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    author,
    filePath,
    coverPath,
    format,
    fileSize,
    addedAt,
    lastOpenedAt,
    isFavorite,
    readingProgress,
    encryptionType,
    isFixedLayout,
    hasMediaOverlays,
    sourceCatalogId,
    sourceEntryId,
    publisher,
    description,
    language,
    publishedDate,
    subjects,
  ];

  @override
  String toString() {
    return 'Book(id: $id, title: $title, author: $author, format: $format, '
        'progress: ${readingProgress?.toStringAsFixed(2) ?? "none"})';
  }
}
