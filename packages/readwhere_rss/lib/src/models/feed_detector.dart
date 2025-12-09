import 'package:xml/xml.dart';

import '../entities/rss_feed.dart';
import 'atom_parser.dart';
import 'rss1_parser.dart';
import 'rss2_parser.dart';

/// Detects and parses RSS/Atom feed formats
class FeedDetector {
  /// Detect the format of a feed from its XML content
  static RssFeedFormat detect(String xmlContent) {
    try {
      final document = XmlDocument.parse(xmlContent);
      final root = document.rootElement;
      final rootName = root.name.local.toLowerCase();

      // Check for Atom
      if (rootName == 'feed') {
        return RssFeedFormat.atom;
      }

      // Check for RSS 1.0 (RDF)
      if (rootName == 'rdf') {
        return RssFeedFormat.rss1;
      }

      // Check for RSS 2.0
      if (rootName == 'rss') {
        return RssFeedFormat.rss2;
      }

      return RssFeedFormat.unknown;
    } catch (_) {
      return RssFeedFormat.unknown;
    }
  }

  /// Parse a feed from XML content, auto-detecting the format
  static RssFeed parse(String xmlContent, String feedUrl) {
    final format = detect(xmlContent);

    switch (format) {
      case RssFeedFormat.rss2:
        return Rss2Parser.parse(xmlContent, feedUrl);
      case RssFeedFormat.atom:
        return AtomParser.parse(xmlContent, feedUrl);
      case RssFeedFormat.rss1:
        return Rss1Parser.parse(xmlContent, feedUrl);
      case RssFeedFormat.unknown:
        throw FormatException(
          'Unable to detect feed format. Content does not appear to be RSS or Atom.',
        );
    }
  }

  /// Check if the content appears to be a valid feed
  static bool isValidFeed(String content) {
    try {
      return detect(content) != RssFeedFormat.unknown;
    } catch (_) {
      return false;
    }
  }

  /// Try to parse and return feed, or null if invalid
  static RssFeed? tryParse(String xmlContent, String feedUrl) {
    try {
      return parse(xmlContent, feedUrl);
    } catch (_) {
      return null;
    }
  }
}
