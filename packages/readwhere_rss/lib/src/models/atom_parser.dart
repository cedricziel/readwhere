import 'package:xml/xml.dart';

import '../entities/rss_category.dart';
import '../entities/rss_enclosure.dart';
import '../entities/rss_feed.dart';
import '../entities/rss_item.dart';

/// Parser for Atom 1.0 feeds
class AtomParser {
  /// The Atom namespace
  static const atomNamespace = 'http://www.w3.org/2005/Atom';

  /// Parse an Atom feed from XML content
  static RssFeed parse(String xmlContent, String feedUrl) {
    final document = XmlDocument.parse(xmlContent);
    final feed = document.rootElement;

    if (feed.name.local != 'feed') {
      throw FormatException(
        'Not a valid Atom feed: root element is not <feed>',
      );
    }

    final title = _getText(feed, 'title') ?? 'Untitled Feed';
    final subtitle = _getText(feed, 'subtitle');
    final id = _getText(feed, 'id') ?? feedUrl;
    final updated = _parseDate(_getText(feed, 'updated'));
    final author = _parseAuthor(feed);
    final link = _parseLink(feed, 'alternate');
    final selfLink = _parseLink(feed, 'self');
    final iconUrl = _getText(feed, 'icon') ?? _getText(feed, 'logo');
    final rights = _getText(feed, 'rights');
    final generator = _parseGenerator(feed);

    final items = feed
        .findElements('entry')
        .map((e) => _parseEntry(e))
        .toList();

    return RssFeed(
      id: id,
      title: title,
      description: subtitle,
      link: link ?? selfLink,
      imageUrl: iconUrl,
      lastBuildDate: updated,
      format: RssFeedFormat.atom,
      items: items,
      feedUrl: feedUrl,
      author: author,
      copyright: rights,
      generator: generator,
    );
  }

  static RssItem _parseEntry(XmlElement entry) {
    final id =
        _getText(entry, 'id') ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final title = _getText(entry, 'title') ?? 'Untitled';
    final summary = _getText(entry, 'summary');
    final content = _parseContent(entry);
    final link = _parseLink(entry, 'alternate');
    final author = _parseAuthor(entry);
    final authorEmail = _parseAuthorEmail(entry);
    final published = _parseDate(_getText(entry, 'published'));
    final updated = _parseDate(_getText(entry, 'updated'));
    final categories = _parseCategories(entry);
    final enclosures = _parseEnclosures(entry);
    final thumbnailUrl = _parseThumbnailUrl(entry);

    return RssItem(
      id: id,
      title: title,
      description: summary,
      content: content,
      link: link,
      author: author,
      authorEmail: authorEmail,
      pubDate: published,
      updated: updated,
      enclosures: enclosures,
      categories: categories,
      thumbnailUrl: thumbnailUrl,
    );
  }

  static String? _parseContent(XmlElement entry) {
    final contentElement = entry.findElements('content').firstOrNull;
    if (contentElement == null) return null;

    final type = contentElement.getAttribute('type') ?? 'text';

    if (type == 'xhtml') {
      // Return inner XML for XHTML content
      return contentElement.children.map((n) => n.toXmlString()).join();
    }

    return contentElement.innerText.trim();
  }

  static String? _parseAuthor(XmlElement element) {
    final authorElement = element.findElements('author').firstOrNull;
    if (authorElement == null) return null;

    return _getText(authorElement, 'name');
  }

  static String? _parseAuthorEmail(XmlElement element) {
    final authorElement = element.findElements('author').firstOrNull;
    if (authorElement == null) return null;

    return _getText(authorElement, 'email');
  }

  static String? _parseLink(XmlElement element, String rel) {
    for (final link in element.findElements('link')) {
      final linkRel = link.getAttribute('rel') ?? 'alternate';
      if (linkRel == rel) {
        return link.getAttribute('href');
      }
    }
    return null;
  }

  static List<RssEnclosure> _parseEnclosures(XmlElement entry) {
    final enclosures = <RssEnclosure>[];

    for (final link in entry.findElements('link')) {
      final rel = link.getAttribute('rel');
      if (rel == 'enclosure') {
        final href = link.getAttribute('href');
        if (href != null && href.isNotEmpty) {
          enclosures.add(
            RssEnclosure(
              url: href,
              type: link.getAttribute('type'),
              length: _parseInt(link.getAttribute('length')),
              title: link.getAttribute('title'),
            ),
          );
        }
      }
    }

    // Also check for media:content
    for (final e
        in entry
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

  static List<RssCategory> _parseCategories(XmlElement entry) {
    return entry.findElements('category').map((e) {
      final term = e.getAttribute('term') ?? e.innerText.trim();
      return RssCategory(
        label: e.getAttribute('label') ?? term,
        domain: e.getAttribute('scheme'),
      );
    }).toList();
  }

  static String? _parseThumbnailUrl(XmlElement entry) {
    // Try media:thumbnail
    final mediaThumbnail = entry
        .findAllElements('*')
        .where((e) => e.name.local == 'thumbnail' && e.name.prefix == 'media')
        .firstOrNull;
    if (mediaThumbnail != null) {
      return mediaThumbnail.getAttribute('url');
    }

    // Try link with rel="thumbnail" or rel="image"
    for (final link in entry.findElements('link')) {
      final rel = link.getAttribute('rel');
      if (rel == 'thumbnail' || rel == 'image') {
        return link.getAttribute('href');
      }
    }

    return null;
  }

  static String? _parseGenerator(XmlElement feed) {
    final generatorElement = feed.findElements('generator').firstOrNull;
    if (generatorElement == null) return null;

    final text = generatorElement.innerText.trim();
    final uri = generatorElement.getAttribute('uri');
    final version = generatorElement.getAttribute('version');

    if (text.isNotEmpty) {
      if (version != null) {
        return '$text $version';
      }
      return text;
    }

    return uri;
  }

  static String? _getText(XmlElement element, String name) {
    final child = element.findElements(name).firstOrNull;
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
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }
}
