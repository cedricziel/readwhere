import 'package:xml/xml.dart';

import '../entities/rss_category.dart';
import '../entities/rss_channel.dart';
import '../entities/rss_enclosure.dart';
import '../entities/rss_feed.dart';
import '../entities/rss_item.dart';

/// Parser for RSS 2.0 feeds
class Rss2Parser {
  /// Parse an RSS 2.0 feed from XML content
  static RssFeed parse(String xmlContent, String feedUrl) {
    final document = XmlDocument.parse(xmlContent);
    final rss = document.rootElement;

    if (rss.name.local != 'rss') {
      throw FormatException(
        'Not a valid RSS 2.0 feed: root element is not <rss>',
      );
    }

    final channelElement = rss.findElements('channel').firstOrNull;
    if (channelElement == null) {
      throw const FormatException(
        'Not a valid RSS 2.0 feed: no <channel> element',
      );
    }

    final channel = _parseChannel(channelElement);
    final items = _parseItems(channelElement);

    return RssFeed(
      id: feedUrl,
      title: channel.title,
      description: channel.description,
      link: channel.link,
      imageUrl: channel.imageUrl,
      lastBuildDate: channel.lastBuildDate,
      pubDate: channel.pubDate,
      format: RssFeedFormat.rss2,
      channel: channel,
      items: items,
      feedUrl: feedUrl,
      language: channel.language,
      copyright: channel.copyright,
      generator: channel.generator,
    );
  }

  static RssChannel _parseChannel(XmlElement channel) {
    return RssChannel(
      title: _getText(channel, 'title') ?? 'Untitled Feed',
      description: _getText(channel, 'description'),
      link: _getText(channel, 'link'),
      language: _getText(channel, 'language'),
      copyright: _getText(channel, 'copyright'),
      managingEditor: _getText(channel, 'managingEditor'),
      webMaster: _getText(channel, 'webMaster'),
      pubDate: _parseDate(_getText(channel, 'pubDate')),
      lastBuildDate: _parseDate(_getText(channel, 'lastBuildDate')),
      categories: _parseCategories(channel),
      generator: _getText(channel, 'generator'),
      docs: _getText(channel, 'docs'),
      ttl: _parseInt(_getText(channel, 'ttl')),
      imageUrl: _parseImageUrl(channel),
      imageTitle: _parseImageField(channel, 'title'),
      imageLink: _parseImageField(channel, 'link'),
      imageWidth: _parseInt(_parseImageField(channel, 'width')),
      imageHeight: _parseInt(_parseImageField(channel, 'height')),
    );
  }

  static List<String> _parseCategories(XmlElement element) {
    return element
        .findElements('category')
        .map((e) => e.innerText.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static String? _parseImageUrl(XmlElement channel) {
    // Try <image><url> first
    final imageElement = channel.findElements('image').firstOrNull;
    if (imageElement != null) {
      final url = _getText(imageElement, 'url');
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }

    // Try itunes:image
    final itunesImage = channel
        .findAllElements('*')
        .where((e) => e.name.local == 'image' && e.name.prefix == 'itunes')
        .firstOrNull;
    if (itunesImage != null) {
      return itunesImage.getAttribute('href');
    }

    return null;
  }

  static String? _parseImageField(XmlElement channel, String field) {
    final imageElement = channel.findElements('image').firstOrNull;
    if (imageElement != null) {
      return _getText(imageElement, field);
    }
    return null;
  }

  static List<RssItem> _parseItems(XmlElement channel) {
    return channel.findElements('item').map(_parseItem).toList();
  }

  static RssItem _parseItem(XmlElement item) {
    final guid = _getText(item, 'guid');
    final link = _getText(item, 'link');
    final id = guid ?? link ?? DateTime.now().millisecondsSinceEpoch.toString();

    return RssItem(
      id: id,
      title: _getText(item, 'title') ?? 'Untitled',
      description: _getText(item, 'description'),
      content: _getContentEncoded(item),
      link: link,
      author: _getText(item, 'author') ?? _getDcCreator(item),
      pubDate: _parseDate(_getText(item, 'pubDate')),
      enclosures: _parseEnclosures(item),
      categories: item
          .findElements('category')
          .map(
            (e) => RssCategory(
              label: e.innerText.trim(),
              domain: e.getAttribute('domain'),
            ),
          )
          .toList(),
      thumbnailUrl: _parseThumbnailUrl(item),
      commentsUrl: _getText(item, 'comments'),
      sourceTitle: _parseSourceTitle(item),
      sourceUrl: _parseSourceUrl(item),
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
    final dcCreator = item
        .findAllElements('*')
        .where((e) => e.name.local == 'creator' && e.name.prefix == 'dc')
        .firstOrNull;

    return dcCreator?.innerText.trim();
  }

  static List<RssEnclosure> _parseEnclosures(XmlElement item) {
    final enclosures = <RssEnclosure>[];

    // Parse standard enclosures
    for (final e in item.findElements('enclosure')) {
      final url = e.getAttribute('url');
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

    // Parse media:content elements
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

  static String? _parseThumbnailUrl(XmlElement item) {
    // Try media:thumbnail
    final mediaThumbnail = item
        .findAllElements('*')
        .where((e) => e.name.local == 'thumbnail' && e.name.prefix == 'media')
        .firstOrNull;
    if (mediaThumbnail != null) {
      return mediaThumbnail.getAttribute('url');
    }

    // Try itunes:image
    final itunesImage = item
        .findAllElements('*')
        .where((e) => e.name.local == 'image' && e.name.prefix == 'itunes')
        .firstOrNull;
    if (itunesImage != null) {
      return itunesImage.getAttribute('href');
    }

    // Try media:content with medium="image"
    final mediaImage = item
        .findAllElements('*')
        .where(
          (e) =>
              e.name.local == 'content' &&
              e.name.prefix == 'media' &&
              e.getAttribute('medium') == 'image',
        )
        .firstOrNull;
    if (mediaImage != null) {
      return mediaImage.getAttribute('url');
    }

    return null;
  }

  static String? _parseSourceTitle(XmlElement item) {
    final source = item.findElements('source').firstOrNull;
    return source?.innerText.trim();
  }

  static String? _parseSourceUrl(XmlElement item) {
    final source = item.findElements('source').firstOrNull;
    return source?.getAttribute('url');
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

    // Try RFC 2822 format (common in RSS)
    try {
      return _parseRfc2822(dateStr);
    } catch (_) {}

    // Try ISO 8601 format
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}

    return null;
  }

  static DateTime _parseRfc2822(String dateStr) {
    // RFC 2822: "Sat, 07 Sep 2002 00:00:01 GMT"
    final months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };

    // Remove day name if present
    var s = dateStr;
    final commaIndex = s.indexOf(',');
    if (commaIndex != -1) {
      s = s.substring(commaIndex + 1).trim();
    }

    final parts = s.split(RegExp(r'\s+'));
    if (parts.length < 4) throw const FormatException('Invalid RFC 2822 date');

    final day = int.parse(parts[0]);
    final month = months[parts[1]];
    if (month == null) throw const FormatException('Invalid month');
    final year = int.parse(parts[2]);

    var hour = 0, minute = 0, second = 0;
    if (parts.length > 3) {
      final timeParts = parts[3].split(':');
      hour = int.parse(timeParts[0]);
      if (timeParts.length > 1) minute = int.parse(timeParts[1]);
      if (timeParts.length > 2) second = int.parse(timeParts[2]);
    }

    return DateTime.utc(year, month, day, hour, minute, second);
  }
}
