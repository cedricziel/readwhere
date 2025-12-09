import 'package:xml/xml.dart';

import '../entities/opml_document.dart';
import '../entities/opml_head.dart';
import '../entities/opml_outline.dart';

/// Writer for generating OPML documents
class OpmlWriter {
  /// Convert an OpmlDocument to XML string
  static String write(OpmlDocument doc) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');

    builder.element(
      'opml',
      nest: () {
        builder.attribute('version', doc.version);

        // Head
        if (doc.head != null) {
          _writeHead(builder, doc.head!);
        }

        // Body
        builder.element(
          'body',
          nest: () {
            for (final outline in doc.outlines) {
              _writeOutline(builder, outline);
            }
          },
        );
      },
    );

    return builder.buildDocument().toXmlString(pretty: true);
  }

  /// Create an OPML document from a list of feed URLs
  static String fromFeeds(
    List<FeedInfo> feeds, {
    String? title,
    String? ownerName,
    String? ownerEmail,
  }) {
    final outlines = feeds
        .map(
          (f) => OpmlOutline(
            text: f.title,
            title: f.title,
            type: 'rss',
            xmlUrl: f.xmlUrl,
            htmlUrl: f.htmlUrl,
            description: f.description,
          ),
        )
        .toList();

    final doc = OpmlDocument(
      version: '2.0',
      head: OpmlHead(
        title: title ?? 'Exported Feeds',
        dateCreated: DateTime.now(),
        ownerName: ownerName,
        ownerEmail: ownerEmail,
      ),
      outlines: outlines,
    );

    return write(doc);
  }

  /// Create a simple OPML from feed URLs with titles
  static String fromFeedUrls(Map<String, String> urlToTitle, {String? title}) {
    final feeds = urlToTitle.entries
        .map((e) => FeedInfo(xmlUrl: e.key, title: e.value))
        .toList();
    return fromFeeds(feeds, title: title);
  }

  static void _writeHead(XmlBuilder builder, OpmlHead head) {
    builder.element(
      'head',
      nest: () {
        if (head.title != null) {
          builder.element('title', nest: head.title);
        }
        if (head.dateCreated != null) {
          builder.element('dateCreated', nest: _formatDate(head.dateCreated!));
        }
        if (head.dateModified != null) {
          builder.element(
            'dateModified',
            nest: _formatDate(head.dateModified!),
          );
        }
        if (head.ownerName != null) {
          builder.element('ownerName', nest: head.ownerName);
        }
        if (head.ownerEmail != null) {
          builder.element('ownerEmail', nest: head.ownerEmail);
        }
        if (head.ownerId != null) {
          builder.element('ownerId', nest: head.ownerId);
        }
        if (head.docs != null) {
          builder.element('docs', nest: head.docs);
        }
      },
    );
  }

  static void _writeOutline(XmlBuilder builder, OpmlOutline outline) {
    builder.element(
      'outline',
      nest: () {
        if (outline.text != null) {
          builder.attribute('text', outline.text!);
        }
        if (outline.title != null) {
          builder.attribute('title', outline.title!);
        }
        if (outline.type != null) {
          builder.attribute('type', outline.type!);
        }
        if (outline.xmlUrl != null) {
          builder.attribute('xmlUrl', outline.xmlUrl!);
        }
        if (outline.htmlUrl != null) {
          builder.attribute('htmlUrl', outline.htmlUrl!);
        }
        if (outline.description != null) {
          builder.attribute('description', outline.description!);
        }
        if (outline.language != null) {
          builder.attribute('language', outline.language!);
        }
        if (outline.version != null) {
          builder.attribute('version', outline.version!);
        }
        if (outline.isComment != null) {
          builder.attribute('isComment', outline.isComment.toString());
        }
        if (outline.isBreakpoint != null) {
          builder.attribute('isBreakpoint', outline.isBreakpoint.toString());
        }
        if (outline.created != null) {
          builder.attribute('created', _formatDate(outline.created!));
        }
        if (outline.category != null) {
          builder.attribute('category', outline.category!);
        }

        // Custom attributes
        for (final entry in outline.customAttributes.entries) {
          builder.attribute(entry.key, entry.value);
        }

        // Children
        for (final child in outline.children) {
          _writeOutline(builder, child);
        }
      },
    );
  }

  static String _formatDate(DateTime date) {
    // RFC 2822 format
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final utc = date.toUtc();
    final dayName = days[utc.weekday % 7];
    final monthName = months[utc.month - 1];

    return '$dayName, ${utc.day.toString().padLeft(2, '0')} $monthName ${utc.year} '
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')}:'
        '${utc.second.toString().padLeft(2, '0')} GMT';
  }
}

/// Information about a feed for export
class FeedInfo {
  /// Feed URL
  final String xmlUrl;

  /// Feed title
  final String title;

  /// Website URL
  final String? htmlUrl;

  /// Feed description
  final String? description;

  const FeedInfo({
    required this.xmlUrl,
    required this.title,
    this.htmlUrl,
    this.description,
  });
}
