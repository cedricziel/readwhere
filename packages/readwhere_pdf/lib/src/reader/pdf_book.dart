import 'package:equatable/equatable.dart';

import '../metadata/pdf_metadata.dart';
import '../navigation/pdf_outline.dart';
import '../pages/pdf_page.dart';

/// Represents a PDF book with its metadata and structure.
class PdfBook with EquatableMixin {
  /// The document metadata.
  final PdfMetadata metadata;

  /// The number of pages in the document.
  final int pageCount;

  /// The list of pages in the document.
  final List<PdfPage> pages;

  /// The document outline (table of contents), if available.
  final List<PdfOutlineEntry>? outline;

  /// Whether the document is encrypted.
  final bool isEncrypted;

  /// Whether the document requires a password to open.
  final bool requiresPassword;

  const PdfBook({
    required this.metadata,
    required this.pageCount,
    required this.pages,
    this.outline,
    this.isEncrypted = false,
    this.requiresPassword = false,
  });

  /// Creates an empty book with default values.
  const PdfBook.empty()
    : metadata = const PdfMetadata.empty(),
      pageCount = 0,
      pages = const [],
      outline = null,
      isEncrypted = false,
      requiresPassword = false;

  /// The document title, or null if not available.
  String? get title => metadata.title;

  /// The document author, or null if not available.
  String? get author => metadata.author;

  /// The document subject/description, or null if not available.
  String? get subject => metadata.subject;

  /// The application that created the document.
  String? get creator => metadata.creator;

  /// The PDF producer.
  String? get producer => metadata.producer;

  /// The date the document was created.
  DateTime? get creationDate => metadata.creationDate;

  /// The date the document was last modified.
  DateTime? get modificationDate => metadata.modificationDate;

  /// Whether the document has an outline.
  bool get hasOutline => outline != null && outline!.isNotEmpty;

  /// Gets a page by index.
  PdfPage? getPage(int index) {
    if (index < 0 || index >= pages.length) return null;
    return pages[index];
  }

  @override
  List<Object?> get props => [
    metadata,
    pageCount,
    pages,
    outline,
    isEncrypted,
    requiresPassword,
  ];

  @override
  String toString() {
    return 'PdfBook('
        'title: ${metadata.title}, '
        'author: ${metadata.author}, '
        'pageCount: $pageCount, '
        'hasOutline: $hasOutline, '
        'isEncrypted: $isEncrypted)';
  }
}
