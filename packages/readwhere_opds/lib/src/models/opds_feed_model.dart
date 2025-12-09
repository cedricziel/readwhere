import 'package:xml/xml.dart';

import '../entities/opds_entry.dart';
import '../entities/opds_feed.dart';
import '../entities/opds_link.dart';
import 'opds_entry_model.dart';
import 'opds_link_model.dart';

/// Data model for OpdsFeed with XML parsing support
class OpdsFeedModel extends OpdsFeed {
  const OpdsFeedModel({
    required super.id,
    required super.title,
    super.subtitle,
    required super.updated,
    super.author,
    super.iconUrl,
    required super.links,
    required super.entries,
    super.kind,
    super.totalResults,
    super.itemsPerPage,
    super.startIndex,
  });

  /// Parse an OpdsFeed from an XML document string
  ///
  /// The feed follows the OPDS 1.2 specification which is based on Atom:
  /// https://specs.opds.io/opds-1.2.html
  factory OpdsFeedModel.fromXmlString(String xmlString, {String? baseUrl}) {
    final document = XmlDocument.parse(xmlString);
    return OpdsFeedModel.fromXmlDocument(document, baseUrl: baseUrl);
  }

  /// Parse an OpdsFeed from an XmlDocument
  factory OpdsFeedModel.fromXmlDocument(
    XmlDocument document, {
    String? baseUrl,
  }) {
    final feed = document.rootElement;

    // Verify this is an Atom feed
    if (feed.localName != 'feed') {
      throw FormatException('Invalid OPDS feed: root element is not "feed"');
    }

    // Parse feed ID
    final id = _getElementText(feed, 'id') ?? baseUrl ?? '';

    // Parse title
    final title = _getElementText(feed, 'title') ?? 'Untitled Feed';

    // Parse subtitle
    final subtitle = _getElementText(feed, 'subtitle');

    // Parse updated timestamp
    final updatedStr = _getElementText(feed, 'updated');
    final updated = updatedStr != null
        ? DateTime.tryParse(updatedStr) ?? DateTime.now()
        : DateTime.now();

    // Parse author
    final authorElement = feed.findElements('author').firstOrNull;
    final author = authorElement != null
        ? _getElementText(authorElement, 'name')
        : null;

    // Parse icon
    final iconUrl = _getElementText(feed, 'icon');

    // Parse links
    final linkElements = feed.findElements('link');
    final links = linkElements
        .map((e) => OpdsLinkModel.fromXmlElement(e, baseUrl: baseUrl))
        .toList();

    // Parse entries
    final entryElements = feed.findElements('entry');
    final entries = entryElements
        .map((e) => OpdsEntryModel.fromXmlElement(e, baseUrl: baseUrl))
        .toList();

    // Determine feed kind based on content
    final kind = _determineFeedKind(links, entries);

    // Parse OpenSearch pagination info
    int? totalResults;
    int? itemsPerPage;
    int? startIndex;

    final totalResultsStr =
        _getElementText(feed, 'opensearch:totalResults') ??
        _getElementText(feed, 'totalResults');
    if (totalResultsStr != null) {
      totalResults = int.tryParse(totalResultsStr);
    }

    final itemsPerPageStr =
        _getElementText(feed, 'opensearch:itemsPerPage') ??
        _getElementText(feed, 'itemsPerPage');
    if (itemsPerPageStr != null) {
      itemsPerPage = int.tryParse(itemsPerPageStr);
    }

    final startIndexStr =
        _getElementText(feed, 'opensearch:startIndex') ??
        _getElementText(feed, 'startIndex');
    if (startIndexStr != null) {
      startIndex = int.tryParse(startIndexStr);
    }

    return OpdsFeedModel(
      id: id,
      title: title,
      subtitle: subtitle,
      updated: updated,
      author: author,
      iconUrl: iconUrl,
      links: links,
      entries: entries,
      kind: kind,
      totalResults: totalResults,
      itemsPerPage: itemsPerPage,
      startIndex: startIndex,
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

    // Try with different namespace prefixes
    for (final child in parent.childElements) {
      final localName = child.localName;
      final fullName = child.name.toString();
      if (localName == name ||
          fullName == name ||
          fullName.endsWith(':$name')) {
        final text = child.innerText.trim();
        return text.isNotEmpty ? text : null;
      }
    }

    return null;
  }

  /// Determine the feed kind based on links and entries
  static OpdsFeedKind _determineFeedKind(
    List<OpdsLink> links,
    List<OpdsEntry> entries,
  ) {
    // Check self link type
    final selfLink = links.where((l) => l.rel == OpdsLinkRel.self).firstOrNull;
    if (selfLink != null) {
      if (selfLink.type.contains('kind=navigation')) {
        return OpdsFeedKind.navigation;
      }
      if (selfLink.type.contains('kind=acquisition')) {
        return OpdsFeedKind.acquisition;
      }
    }

    // Infer from entries
    if (entries.isEmpty) {
      return OpdsFeedKind.unknown;
    }

    // If any entry has acquisition links, it's an acquisition feed
    final hasAcquisitions = entries.any((e) => e.isBook);
    if (hasAcquisitions) {
      return OpdsFeedKind.acquisition;
    }

    // If entries only have navigation links, it's a navigation feed
    final hasNavigation = entries.any((e) => e.isNavigation);
    if (hasNavigation) {
      return OpdsFeedKind.navigation;
    }

    return OpdsFeedKind.unknown;
  }

  /// Create from domain entity
  factory OpdsFeedModel.fromEntity(OpdsFeed feed) {
    return OpdsFeedModel(
      id: feed.id,
      title: feed.title,
      subtitle: feed.subtitle,
      updated: feed.updated,
      author: feed.author,
      iconUrl: feed.iconUrl,
      links: feed.links,
      entries: feed.entries,
      kind: feed.kind,
      totalResults: feed.totalResults,
      itemsPerPage: feed.itemsPerPage,
      startIndex: feed.startIndex,
    );
  }

  /// Convert to domain entity
  OpdsFeed toEntity() {
    return OpdsFeed(
      id: id,
      title: title,
      subtitle: subtitle,
      updated: updated,
      author: author,
      iconUrl: iconUrl,
      links: links,
      entries: entries,
      kind: kind,
      totalResults: totalResults,
      itemsPerPage: itemsPerPage,
      startIndex: startIndex,
    );
  }
}
