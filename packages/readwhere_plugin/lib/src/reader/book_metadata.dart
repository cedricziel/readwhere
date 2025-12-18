import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'toc_entry.dart';

/// Type of encryption/DRM detected in an EPUB.
enum EpubEncryptionType {
  /// No encryption detected.
  none,

  /// Adobe Digital Editions DRM (ADEPT).
  adobeDrm,

  /// Apple FairPlay DRM (used by Apple Books).
  appleFairPlay,

  /// Readium LCP (Licensed Content Protection).
  lcp,

  /// IDPF font obfuscation (not DRM, just font protection).
  fontObfuscation,

  /// Unknown encryption type.
  unknown,
}

/// Represents metadata parsed from a book file
class BookMetadata extends Equatable {
  final String title;
  final String author;
  final String? description;
  final String? publisher;
  final String? language;
  final DateTime? publishedDate;
  final Uint8List? coverImage;
  final List<TocEntry> tableOfContents;

  /// Type of encryption/DRM detected (EPUB only).
  final EpubEncryptionType encryptionType;

  /// Human-readable description of encryption status.
  final String? encryptionDescription;

  /// Passphrase hint for LCP-protected books.
  final String? lcpPassphraseHint;

  /// Whether this book is a fixed-layout EPUB.
  final bool isFixedLayout;

  /// Whether this EPUB has media overlays (audio sync).
  final bool hasMediaOverlays;

  const BookMetadata({
    required this.title,
    required this.author,
    this.description,
    this.publisher,
    this.language,
    this.publishedDate,
    this.coverImage,
    this.tableOfContents = const [],
    this.encryptionType = EpubEncryptionType.none,
    this.encryptionDescription,
    this.lcpPassphraseHint,
    this.isFixedLayout = false,
    this.hasMediaOverlays = false,
  });

  /// Whether this book has DRM that prevents reading.
  bool get hasDrm =>
      encryptionType != EpubEncryptionType.none &&
      encryptionType != EpubEncryptionType.fontObfuscation;

  /// Whether this LCP book requires a passphrase to read.
  bool get requiresLcpPassphrase => encryptionType == EpubEncryptionType.lcp;

  /// Creates a copy of this BookMetadata with the given fields replaced
  BookMetadata copyWith({
    String? title,
    String? author,
    String? description,
    String? publisher,
    String? language,
    DateTime? publishedDate,
    Uint8List? coverImage,
    List<TocEntry>? tableOfContents,
    EpubEncryptionType? encryptionType,
    String? encryptionDescription,
    String? lcpPassphraseHint,
    bool? isFixedLayout,
    bool? hasMediaOverlays,
  }) {
    return BookMetadata(
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      publisher: publisher ?? this.publisher,
      language: language ?? this.language,
      publishedDate: publishedDate ?? this.publishedDate,
      coverImage: coverImage ?? this.coverImage,
      tableOfContents: tableOfContents ?? this.tableOfContents,
      encryptionType: encryptionType ?? this.encryptionType,
      encryptionDescription:
          encryptionDescription ?? this.encryptionDescription,
      lcpPassphraseHint: lcpPassphraseHint ?? this.lcpPassphraseHint,
      isFixedLayout: isFixedLayout ?? this.isFixedLayout,
      hasMediaOverlays: hasMediaOverlays ?? this.hasMediaOverlays,
    );
  }

  @override
  List<Object?> get props => [
    title,
    author,
    description,
    publisher,
    language,
    publishedDate,
    coverImage,
    tableOfContents,
    encryptionType,
    encryptionDescription,
    lcpPassphraseHint,
    isFixedLayout,
    hasMediaOverlays,
  ];

  @override
  String toString() {
    return 'BookMetadata(title: $title, author: $author, '
        'publisher: $publisher, language: $language, '
        'hasCover: ${coverImage != null}, tocEntries: ${tableOfContents.length}, '
        'encryption: $encryptionType, isFixedLayout: $isFixedLayout, '
        'hasMediaOverlays: $hasMediaOverlays)';
  }
}
