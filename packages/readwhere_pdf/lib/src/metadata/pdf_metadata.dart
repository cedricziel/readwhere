import 'package:equatable/equatable.dart';

/// Metadata extracted from a PDF document.
class PdfMetadata with EquatableMixin {
  /// The document title.
  final String? title;

  /// The document author.
  final String? author;

  /// The document subject.
  final String? subject;

  /// Keywords associated with the document.
  final String? keywords;

  /// The application that created the document.
  final String? creator;

  /// The PDF producer (e.g., the library that generated the PDF).
  final String? producer;

  /// The date the document was created.
  final DateTime? creationDate;

  /// The date the document was last modified.
  final DateTime? modificationDate;

  const PdfMetadata({
    this.title,
    this.author,
    this.subject,
    this.keywords,
    this.creator,
    this.producer,
    this.creationDate,
    this.modificationDate,
  });

  /// Creates an empty metadata instance.
  const PdfMetadata.empty()
    : title = null,
      author = null,
      subject = null,
      keywords = null,
      creator = null,
      producer = null,
      creationDate = null,
      modificationDate = null;

  /// Whether this metadata has any non-null values.
  bool get hasContent =>
      title != null ||
      author != null ||
      subject != null ||
      keywords != null ||
      creator != null ||
      producer != null ||
      creationDate != null ||
      modificationDate != null;

  @override
  List<Object?> get props => [
    title,
    author,
    subject,
    keywords,
    creator,
    producer,
    creationDate,
    modificationDate,
  ];

  @override
  String toString() {
    return 'PdfMetadata('
        'title: $title, '
        'author: $author, '
        'subject: $subject, '
        'keywords: $keywords, '
        'creator: $creator, '
        'producer: $producer, '
        'creationDate: $creationDate, '
        'modificationDate: $modificationDate)';
  }
}
