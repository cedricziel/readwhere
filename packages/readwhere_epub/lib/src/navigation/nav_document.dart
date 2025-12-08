import 'package:xml/xml.dart';

import '../errors/epub_exception.dart';
import '../utils/xml_utils.dart';
import 'toc.dart';

/// Parses EPUB 3 navigation documents.
///
/// The navigation document is an XHTML file containing <nav> elements
/// with epub:type attributes for toc, page-list, and landmarks.
class NavDocumentParser {
  NavDocumentParser._();

  /// Parses a navigation document and returns an [EpubNavigation].
  ///
  /// Throws [EpubParseException] if the document is invalid.
  static EpubNavigation parse(String xhtml, {String? documentPath}) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(xhtml);
    } on XmlException catch (e) {
      throw EpubParseException(
        'Failed to parse navigation document: ${e.message}',
        documentPath: documentPath,
        cause: e,
      );
    }

    // Find the root html element
    final html = document.rootElement;
    if (html.localName != 'html') {
      throw EpubParseException(
        'Invalid navigation document: expected <html> root element',
        documentPath: documentPath,
      );
    }

    // Find body
    final body = XmlUtils.findChildByLocalNameOrNull(html, 'body');
    if (body == null) {
      throw EpubParseException(
        'Invalid navigation document: missing <body> element',
        documentPath: documentPath,
      );
    }

    // Find all nav elements
    final navElements = _findAllNavElements(body);

    // Parse TOC
    final tocNav = _findNavByType(navElements, 'toc');
    final tableOfContents = tocNav != null ? _parseToc(tocNav) : <TocEntry>[];

    // Parse page-list
    final pageListNav = _findNavByType(navElements, 'page-list');
    final pageList =
        pageListNav != null ? _parsePageList(pageListNav) : <PageEntry>[];

    // Parse landmarks
    final landmarksNav = _findNavByType(navElements, 'landmarks');
    final landmarks =
        landmarksNav != null ? _parseLandmarks(landmarksNav) : <Landmark>[];

    return EpubNavigation(
      tableOfContents: tableOfContents,
      pageList: pageList,
      landmarks: landmarks,
      source: NavigationSource.navDocument,
    );
  }

  /// Finds all nav elements recursively.
  static List<XmlElement> _findAllNavElements(XmlElement root) {
    final navs = <XmlElement>[];

    void findNavs(XmlElement element) {
      if (element.localName == 'nav') {
        navs.add(element);
      }
      for (final child in element.childElements) {
        findNavs(child);
      }
    }

    findNavs(root);
    return navs;
  }

  /// Finds a nav element by epub:type.
  static XmlElement? _findNavByType(List<XmlElement> navElements, String type) {
    for (final nav in navElements) {
      final epubType =
          nav.getAttribute('type', namespace: EpubNamespaces.epub) ??
              nav.getAttribute('epub:type');

      if (epubType != null) {
        // epub:type can contain multiple space-separated values
        final types = epubType.split(' ').map((t) => t.trim().toLowerCase());
        if (types.contains(type.toLowerCase())) {
          return nav;
        }
      }
    }
    return null;
  }

  /// Parses the table of contents from a nav element.
  static List<TocEntry> _parseToc(XmlElement navElement) {
    // Find the ol element
    final ol = XmlUtils.findChildByLocalNameOrNull(navElement, 'ol');
    if (ol == null) return [];

    return _parseOlEntries(ol, 0);
  }

  /// Recursively parses ol/li entries.
  static List<TocEntry> _parseOlEntries(XmlElement ol, int level) {
    final entries = <TocEntry>[];
    var index = 0;

    for (final li in XmlUtils.findAllChildrenByLocalName(ol, 'li')) {
      final entry = _parseLiEntry(li, level, index);
      if (entry != null) {
        entries.add(entry);
        index++;
      }
    }

    return entries;
  }

  /// Parses a single li entry.
  static TocEntry? _parseLiEntry(XmlElement li, int level, int index) {
    // Find the anchor or span
    final anchor = XmlUtils.findChildByLocalNameOrNull(li, 'a');
    final span = XmlUtils.findChildByLocalNameOrNull(li, 'span');

    String? href;
    String? title;

    if (anchor != null) {
      href = anchor.getAttribute('href');
      title = XmlUtils.extractPlainText(anchor).trim();
    } else if (span != null) {
      title = XmlUtils.extractPlainText(span).trim();
    }

    if (title == null || title.isEmpty) {
      return null;
    }

    // Check for hidden attribute
    final hidden = li.getAttribute('hidden') != null;

    // Parse children (nested ol)
    final childOl = XmlUtils.findChildByLocalNameOrNull(li, 'ol');
    final children =
        childOl != null ? _parseOlEntries(childOl, level + 1) : <TocEntry>[];

    return TocEntry(
      id: 'toc-$level-$index',
      title: title,
      href: href ?? '',
      level: level,
      children: children,
      hidden: hidden,
    );
  }

  /// Parses the page list from a nav element.
  static List<PageEntry> _parsePageList(XmlElement navElement) {
    final ol = XmlUtils.findChildByLocalNameOrNull(navElement, 'ol');
    if (ol == null) return [];

    final pages = <PageEntry>[];

    for (final li in XmlUtils.findAllChildrenByLocalName(ol, 'li')) {
      final anchor = XmlUtils.findChildByLocalNameOrNull(li, 'a');
      if (anchor == null) continue;

      final href = anchor.getAttribute('href');
      final label = XmlUtils.extractPlainText(anchor).trim();

      if (href != null && label.isNotEmpty) {
        pages.add(PageEntry(
          href: href,
          label: label,
          pageNumber: int.tryParse(label),
        ));
      }
    }

    return pages;
  }

  /// Parses landmarks from a nav element.
  static List<Landmark> _parseLandmarks(XmlElement navElement) {
    final ol = XmlUtils.findChildByLocalNameOrNull(navElement, 'ol');
    if (ol == null) return [];

    final landmarks = <Landmark>[];

    for (final li in XmlUtils.findAllChildrenByLocalName(ol, 'li')) {
      final anchor = XmlUtils.findChildByLocalNameOrNull(li, 'a');
      if (anchor == null) continue;

      final href = anchor.getAttribute('href');
      final title = XmlUtils.extractPlainText(anchor).trim();
      final epubType =
          anchor.getAttribute('type', namespace: EpubNamespaces.epub) ??
              anchor.getAttribute('epub:type');

      if (href != null && title.isNotEmpty && epubType != null) {
        landmarks.add(Landmark(
          href: href,
          title: title,
          type: LandmarkType.fromEpubType(epubType),
        ));
      }
    }

    return landmarks;
  }
}
