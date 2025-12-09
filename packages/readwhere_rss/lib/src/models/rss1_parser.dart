import 'package:xml/xml.dart';

import '../entities/rss_category.dart';
import '../entities/rss_enclosure.dart';
import '../entities/rss_feed.dart';
import '../entities/rss_item.dart';

/// Parser for RSS 1.0 (RDF) feeds
class Rss1Parser {
  /// Parse an RSS 1.0 feed from XML content
  static RssFeed parse(String xmlContent, String feedUrl) {
    final document = XmlDocument.parse(xmlContent);
    final rdf = document.rootElement;

    // RSS 1.0 uses RDF as root element
    if (rdf.name.local != 'RDF') {
      throw FormatException(
        'Not a valid RSS 1.0 feed: root element is not <rdf:RDF>',
      );
    }

    // Parse channel element
    final channelElement = rdf.findAllElements('channel').firstOrNull;
    if (channelElement == null) {
      throw const FormatException(
        'Not a valid RSS 1.0 feed: no <channel> element',
      );
    }

    final title = _getText(channelElement, 'title') ?? 'Untitled Feed';
    final description = _getText(channelElement, 'description');
    final link = _getText(channelElement, 'link');
    final imageUrl = _parseImageUrl(rdf);
    final dcDate = _getText(channelElement, 'date'); // dc:date

    // Parse items
    final items = rdf.findAllElements('item').map(_parseItem).toList();

    return RssFeed(
      id: feedUrl,
      title: title,
      description: description,
      link: link,
      imageUrl: imageUrl,
      lastBuildDate: _parseDate(dcDate),
      format: RssFeedFormat.rss1,
      items: items,
      feedUrl: feedUrl,
    );
  }

  static RssItem _parseItem(XmlElement item) {
    final about = item.getAttribute('about', namespace: '*'); // rdf:about
    final link = _getText(item, 'link');
    final id =
        about ?? link ?? DateTime.now().millisecondsSinceEpoch.toString();

    return RssItem(
      id: id,
      title: _getText(item, 'title') ?? 'Untitled',
      description: _getText(item, 'description'),
      content: _getContentEncoded(item),
      link: link,
      author: _getDcCreator(item),
      pubDate: _parseDate(_getText(item, 'date')),
      enclosures: _parseEnclosures(item),
      categories: _parseCategories(item),
      thumbnailUrl: _parseThumbnailUrl(item),
    );
  }

  static String? _getContentEncoded(XmlElement item) {
    // Try content:encoded namespace
    final contentEncoded = item
        .findAllElements('*')
        .where((e) => e.name.local == 'encoded' && e.name.prefix == 'content')
        .firstOrNull;

    if (contentEncoded != null) {
      return contentEncoded.innerText.trim();
    }

    return null;
  }

  static String? _getDcCreator(XmlElement item) {
    // dc:creator
    final dcCreator = item
        .findAllElements('*')
        .where((e) => e.name.local == 'creator' && e.name.prefix == 'dc')
        .firstOrNull;

    return dcCreator?.innerText.trim();
  }

  static List<RssEnclosure> _parseEnclosures(XmlElement item) {
    final enclosures = <RssEnclosure>[];

    // RSS 1.0 doesn't have standard enclosures, but some feeds use mod_enclosure
    for (final e
        in item
            .findAllElements('*')
            .where(
              (e) => e.name.local == 'enclosure' && e.name.prefix == 'enc',
            )) {
      final url =
          e.getAttribute('url') ?? e.getAttribute('resource', namespace: '*');
      if (url != null && url.isNotEmpty) {
        enclosures.add(
          RssEnclosure(
            url: url,
            type: e.getAttribute('type'),
            length: _parseInt(e.getAttribute('length')),
          ),
        );
      }
    }

    // Try media:content
    for (final e
        in item
            .findAllElements('*')
            .where(
              (e) => e.name.local == 'content' && e.name.prefix == 'media',
            )) {
      final url = e.getAttribute('url');
      if (url != null && url.isNotEmpty) {
        enclosures.add(
          RssEnclosure(
            url: url,
            type: e.getAttribute('type'),
            length: _parseInt(e.getAttribute('fileSize')),
          ),
        );
      }
    }

    return enclosures;
  }

  static List<RssCategory> _parseCategories(XmlElement item) {
    final categories = <RssCategory>[];

    // dc:subject
    for (final e
        in item
            .findAllElements('*')
            .where((e) => e.name.local == 'subject' && e.name.prefix == 'dc')) {
      final label = e.innerText.trim();
      if (label.isNotEmpty) {
        categories.add(RssCategory(label: label));
      }
    }

    return categories;
  }

  static String? _parseImageUrl(XmlElement rdf) {
    // RSS 1.0 has image as a top-level element
    final imageElement = rdf.findAllElements('image').firstOrNull;
    if (imageElement != null) {
      return _getText(imageElement, 'url');
    }
    return null;
  }

  static String? _parseThumbnailUrl(XmlElement item) {
    // Try media:thumbnail
    final mediaThumbnail = item
        .findAllElements('*')
        .where((e) => e.name.local == 'thumbnail' && e.name.prefix == 'media')
        .firstOrNull;
    if (mediaThumbnail != null) {
      return mediaThumbnail.getAttribute('url');
    }

    return null;
  }

  static String? _getText(XmlElement element, String name) {
    // Try without namespace first
    var child = element.findElements(name).firstOrNull;

    // Try with dc namespace
    child ??= element
        .findAllElements('*')
        .where((e) => e.name.local == name && e.name.prefix == 'dc')
        .firstOrNull;

    final text = child?.innerText.trim();
    return (text != null && text.isNotEmpty) ? text : null;
  }

  static int? _parseInt(String? value) {
    if (value == null) return null;
    return int.tryParse(value);
  }

  static DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    try {
      // ISO 8601 format (common in RSS 1.0 with dc:date)
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }
}
