import 'package:equatable/equatable.dart';

import 'opds_link.dart';

/// Represents an OPDS catalog entry (book or navigation item)
class OpdsEntry extends Equatable {
  /// Unique identifier for this entry
  final String id;

  /// Entry title
  final String title;

  /// Author name(s)
  final String? author;

  /// Entry summary/description
  final String? summary;

  /// Last update timestamp
  final DateTime updated;

  /// Links associated with this entry
  final List<OpdsLink> links;

  /// Categories/tags for this entry
  final List<String> categories;

  /// Publisher name
  final String? publisher;

  /// Language code (e.g., 'en', 'de')
  final String? language;

  /// Publication date
  final DateTime? published;

  /// Series name (if part of a series)
  final String? seriesName;

  /// Position in series
  final int? seriesPosition;

  const OpdsEntry({
    required this.id,
    required this.title,
    this.author,
    this.summary,
    required this.updated,
    required this.links,
    this.categories = const [],
    this.publisher,
    this.language,
    this.published,
    this.seriesName,
    this.seriesPosition,
  });

  /// Whether this entry is a navigation entry (folder/collection)
  bool get isNavigation {
    // If there are no acquisition links, it's likely a navigation entry
    if (!links.any((l) => l.isAcquisition)) {
      return links.any((l) => l.isNavigation);
    }
    return false;
  }

  /// Whether this entry is a book (has acquisition links)
  bool get isBook => links.any((l) => l.isAcquisition);

  /// Get the cover image URL (full size)
  String? get coverUrl {
    final imageLink = links
        .where((l) => l.rel == OpdsLinkRel.image)
        .firstOrNull;
    return imageLink?.href;
  }

  /// Get the thumbnail URL
  String? get thumbnailUrl {
    final thumbLink = links.where((l) => l.isThumbnail).firstOrNull;
    return thumbLink?.href ?? coverUrl;
  }

  /// Get the navigation link (for folder entries)
  OpdsLink? get navigationLink {
    return links.where((l) => l.isNavigation).firstOrNull;
  }

  /// Get all acquisition links
  List<OpdsLink> get acquisitionLinks {
    return links.where((l) => l.isAcquisition).toList();
  }

  /// Get acquisition links for supported formats only
  List<OpdsLink> get supportedAcquisitionLinks {
    return acquisitionLinks.where((l) => l.isSupportedFormat).toList();
  }

  /// Whether this entry has at least one supported format
  bool get hasSupportedFormat {
    return acquisitionLinks.any((l) => l.isSupportedFormat);
  }

  /// Whether this entry only has unsupported formats (no supported options)
  bool get hasOnlyUnsupportedFormats {
    return isBook && !hasSupportedFormat;
  }

  /// Get the best acquisition link (prefer EPUB, then PDF)
  OpdsLink? get bestAcquisitionLink {
    final acquisitions = acquisitionLinks;
    if (acquisitions.isEmpty) return null;

    // Prefer EPUB
    final epub = acquisitions.where((l) => l.isEpub).firstOrNull;
    if (epub != null) return epub;

    // Then PDF
    final pdf = acquisitions.where((l) => l.isPdf).firstOrNull;
    if (pdf != null) return pdf;

    // Return first available
    return acquisitions.first;
  }

  /// Get the best supported acquisition link (prefer EPUB, then PDF, then other supported)
  OpdsLink? get bestSupportedAcquisitionLink {
    final supported = supportedAcquisitionLinks;
    if (supported.isEmpty) return null;

    // Prefer EPUB
    final epub = supported.where((l) => l.isEpub).firstOrNull;
    if (epub != null) return epub;

    // Then PDF
    final pdf = supported.where((l) => l.isPdf).firstOrNull;
    if (pdf != null) return pdf;

    // Return first supported format
    return supported.first;
  }

  /// Get available formats for this book
  List<String> get availableFormats {
    return acquisitionLinks
        .map((l) => l.fileExtension)
        .where((ext) => ext != null)
        .cast<String>()
        .toSet()
        .toList();
  }

  /// Get available supported formats for this book
  List<String> get supportedFormats {
    return supportedAcquisitionLinks
        .map((l) => l.fileExtension)
        .where((ext) => ext != null)
        .cast<String>()
        .toSet()
        .toList();
  }

  /// Get available unsupported formats for this book
  List<String> get unsupportedFormats {
    return acquisitionLinks
        .where((l) => !l.isSupportedFormat)
        .map((l) => l.fileExtension)
        .where((ext) => ext != null)
        .cast<String>()
        .toSet()
        .toList();
  }

  /// Get the cover image link
  OpdsLink? get coverLink {
    return links
        .where((l) => l.rel == OpdsLinkRel.image || l.isThumbnail)
        .firstOrNull;
  }

  /// Get the preferred/best format as a string (e.g., 'epub', 'pdf')
  String? get preferredFormat {
    final best = bestAcquisitionLink;
    return best?.fileExtension;
  }

  OpdsEntry copyWith({
    String? id,
    String? title,
    String? author,
    String? summary,
    DateTime? updated,
    List<OpdsLink>? links,
    List<String>? categories,
    String? publisher,
    String? language,
    DateTime? published,
    String? seriesName,
    int? seriesPosition,
  }) {
    return OpdsEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      summary: summary ?? this.summary,
      updated: updated ?? this.updated,
      links: links ?? this.links,
      categories: categories ?? this.categories,
      publisher: publisher ?? this.publisher,
      language: language ?? this.language,
      published: published ?? this.published,
      seriesName: seriesName ?? this.seriesName,
      seriesPosition: seriesPosition ?? this.seriesPosition,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    author,
    summary,
    updated,
    links,
    categories,
    publisher,
    language,
    published,
    seriesName,
    seriesPosition,
  ];

  @override
  String toString() =>
      'OpdsEntry(id: $id, title: $title, isBook: $isBook, formats: $availableFormats)';
}
