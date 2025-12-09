import 'package:xml/xml.dart';

import '../entities/opds_entry.dart';
import '../entities/opds_link.dart';
import 'opds_link_model.dart';

/// Data model for OpdsEntry with XML parsing support
class OpdsEntryModel extends OpdsEntry {
  const OpdsEntryModel({
    required super.id,
    required super.title,
    super.author,
    super.summary,
    required super.updated,
    required super.links,
    super.categories,
    super.publisher,
    super.language,
    super.published,
    super.seriesName,
    super.seriesPosition,
  });

  /// Parse an OpdsEntry from an XML atom:entry element
  ///
  /// Handles standard Atom elements as well as Dublin Core (dc:)
  /// and OPDS-specific extensions.
  factory OpdsEntryModel.fromXmlElement(XmlElement element, {String? baseUrl}) {
    // Parse ID
    final id = _getElementText(element, 'id') ?? '';

    // Parse title
    final title = _getElementText(element, 'title') ?? 'Untitled';

    // Parse author(s)
    final authorElements = element.findElements('author');
    final authors = authorElements
        .map((e) => _getElementText(e, 'name'))
        .where((name) => name != null && name.isNotEmpty)
        .join(', ');
    final author = authors.isNotEmpty ? authors : null;

    // Parse summary/content
    final summary =
        _getElementText(element, 'summary') ??
        _getElementText(element, 'content');

    // Parse updated timestamp
    final updatedStr = _getElementText(element, 'updated');
    final updated = updatedStr != null
        ? DateTime.tryParse(updatedStr) ?? DateTime.now()
        : DateTime.now();

    // Parse links - cast to List<OpdsLink> to avoid type issues with firstWhere
    final linkElements = element.findElements('link');
    final List<OpdsLink> links = linkElements
        .map(
          (e) => OpdsLinkModel.fromXmlElement(e, baseUrl: baseUrl) as OpdsLink,
        )
        .toList();

    // Parse categories
    final categoryElements = element.findElements('category');
    final categories = categoryElements
        .map((e) => e.getAttribute('label') ?? e.getAttribute('term'))
        .where((c) => c != null)
        .cast<String>()
        .toList();

    // Parse Dublin Core metadata
    final publisher =
        _getElementText(element, 'dc:publisher') ??
        _getElementText(element, 'publisher');
    final language =
        _getElementText(element, 'dc:language') ??
        _getElementText(element, 'language');

    // Parse published date
    final publishedStr =
        _getElementText(element, 'dc:date') ??
        _getElementText(element, 'published');
    final published = publishedStr != null
        ? DateTime.tryParse(publishedStr)
        : null;

    // Parse series info (calibre extension)
    String? seriesName;
    int? seriesPosition;
    final seriesElements = element.findElements('calibre:series');
    if (seriesElements.isNotEmpty) {
      seriesName = seriesElements.first.innerText;
    }
    final seriesIndexElements = element.findElements('calibre:series_index');
    if (seriesIndexElements.isNotEmpty) {
      seriesPosition = int.tryParse(seriesIndexElements.first.innerText);
    }

    return OpdsEntryModel(
      id: id,
      title: title,
      author: author,
      summary: summary,
      updated: updated,
      links: links,
      categories: categories,
      publisher: publisher,
      language: language,
      published: published,
      seriesName: seriesName,
      seriesPosition: seriesPosition,
    );
  }

  /// Get text content of a child element by name
  static String? _getElementText(XmlElement parent, String name) {
    // Try direct child first
    final elements = parent.findElements(name);
    if (elements.isNotEmpty) {
      final text = elements.first.innerText.trim();
      return text.isNotEmpty ? text : null;
    }

    // Try with namespaces
    for (final child in parent.childElements) {
      if (child.localName == name || child.name.toString() == name) {
        final text = child.innerText.trim();
        return text.isNotEmpty ? text : null;
      }
    }

    return null;
  }

  /// Create from domain entity
  factory OpdsEntryModel.fromEntity(OpdsEntry entry) {
    return OpdsEntryModel(
      id: entry.id,
      title: entry.title,
      author: entry.author,
      summary: entry.summary,
      updated: entry.updated,
      links: entry.links,
      categories: entry.categories,
      publisher: entry.publisher,
      language: entry.language,
      published: entry.published,
      seriesName: entry.seriesName,
      seriesPosition: entry.seriesPosition,
    );
  }

  /// Convert to domain entity
  OpdsEntry toEntity() {
    return OpdsEntry(
      id: id,
      title: title,
      author: author,
      summary: summary,
      updated: updated,
      links: links,
      categories: categories,
      publisher: publisher,
      language: language,
      published: published,
      seriesName: seriesName,
      seriesPosition: seriesPosition,
    );
  }
}
