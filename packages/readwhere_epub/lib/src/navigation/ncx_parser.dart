import 'package:xml/xml.dart';

import '../errors/epub_exception.dart';
import '../utils/xml_utils.dart';
import 'toc.dart';

/// Parses EPUB 2 NCX (Navigation Center eXtended) documents.
///
/// The NCX is an XML file that defines the table of contents for EPUB 2
/// publications. It uses navMap, pageList, and navList elements.
class NcxParser {
  NcxParser._();

  /// Parses an NCX document and returns an [EpubNavigation].
  ///
  /// Throws [EpubParseException] if the document is invalid.
  static EpubNavigation parse(String xml, {String? documentPath}) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(xml);
    } on XmlException catch (e) {
      throw EpubParseException(
        'Failed to parse NCX document: ${e.message}',
        documentPath: documentPath,
        cause: e,
      );
    }

    final ncx = document.rootElement;
    if (ncx.localName != 'ncx') {
      throw EpubParseException(
        'Invalid NCX document: expected <ncx> root element',
        documentPath: documentPath,
      );
    }

    // Parse navMap (table of contents)
    final navMap = XmlUtils.findChildByLocalNameOrNull(ncx, 'navMap');
    final tableOfContents =
        navMap != null ? _parseNavMap(navMap) : <TocEntry>[];

    // Parse pageList
    final pageListElement =
        XmlUtils.findChildByLocalNameOrNull(ncx, 'pageList');
    final pageList = pageListElement != null
        ? _parsePageList(pageListElement)
        : <PageEntry>[];

    return EpubNavigation(
      tableOfContents: tableOfContents,
      pageList: pageList,
      landmarks: const [], // NCX doesn't have landmarks
      source: NavigationSource.ncx,
    );
  }

  /// Parses the navMap element.
  static List<TocEntry> _parseNavMap(XmlElement navMap) {
    final entries = <TocEntry>[];

    for (final navPoint
        in XmlUtils.findAllChildrenByLocalName(navMap, 'navPoint')) {
      final entry = _parseNavPoint(navPoint, 0);
      if (entry != null) {
        entries.add(entry);
      }
    }

    return entries;
  }

  /// Recursively parses a navPoint element.
  static TocEntry? _parseNavPoint(XmlElement navPoint, int level) {
    // Get ID
    final id = navPoint.getAttribute('id') ??
        'nav-$level-${DateTime.now().millisecondsSinceEpoch}';

    // Note: playOrder attribute is available but not currently used
    // final playOrderStr = navPoint.getAttribute('playOrder');

    // Get navLabel/text
    final navLabel = XmlUtils.findChildByLocalNameOrNull(navPoint, 'navLabel');
    String? title;
    if (navLabel != null) {
      final text = XmlUtils.findChildByLocalNameOrNull(navLabel, 'text');
      if (text != null) {
        title = text.innerText.trim();
      }
    }

    if (title == null || title.isEmpty) {
      return null;
    }

    // Get content src
    final content = XmlUtils.findChildByLocalNameOrNull(navPoint, 'content');
    final href = content?.getAttribute('src') ?? '';

    // Parse child navPoints
    final children = <TocEntry>[];
    for (final childNavPoint
        in XmlUtils.findAllChildrenByLocalName(navPoint, 'navPoint')) {
      final childEntry = _parseNavPoint(childNavPoint, level + 1);
      if (childEntry != null) {
        children.add(childEntry);
      }
    }

    return TocEntry(
      id: id,
      title: title,
      href: href,
      level: level,
      children: children,
    );
  }

  /// Parses the pageList element.
  static List<PageEntry> _parsePageList(XmlElement pageList) {
    final pages = <PageEntry>[];

    for (final pageTarget
        in XmlUtils.findAllChildrenByLocalName(pageList, 'pageTarget')) {
      // Get navLabel/text
      final navLabel =
          XmlUtils.findChildByLocalNameOrNull(pageTarget, 'navLabel');
      String? label;
      if (navLabel != null) {
        final text = XmlUtils.findChildByLocalNameOrNull(navLabel, 'text');
        if (text != null) {
          label = text.innerText.trim();
        }
      }

      // Get content src
      final content =
          XmlUtils.findChildByLocalNameOrNull(pageTarget, 'content');
      final href = content?.getAttribute('src');

      // Get value attribute (page number)
      final value = pageTarget.getAttribute('value');

      if (href != null && label != null && label.isNotEmpty) {
        pages.add(PageEntry(
          href: href,
          label: label,
          pageNumber: value != null ? int.tryParse(value) : int.tryParse(label),
        ));
      }
    }

    return pages;
  }

  /// Extracts the document title from the NCX docTitle element.
  static String? extractTitle(String xml) {
    try {
      final document = XmlDocument.parse(xml);
      final ncx = document.rootElement;
      final docTitle = XmlUtils.findChildByLocalNameOrNull(ncx, 'docTitle');
      if (docTitle != null) {
        final text = XmlUtils.findChildByLocalNameOrNull(docTitle, 'text');
        return text?.innerText.trim();
      }
    } catch (_) {
      // Ignore parsing errors
    }
    return null;
  }

  /// Extracts document authors from the NCX docAuthor elements.
  static List<String> extractAuthors(String xml) {
    final authors = <String>[];
    try {
      final document = XmlDocument.parse(xml);
      final ncx = document.rootElement;
      for (final docAuthor
          in XmlUtils.findAllChildrenByLocalName(ncx, 'docAuthor')) {
        final text = XmlUtils.findChildByLocalNameOrNull(docAuthor, 'text');
        if (text != null) {
          final author = text.innerText.trim();
          if (author.isNotEmpty) {
            authors.add(author);
          }
        }
      }
    } catch (_) {
      // Ignore parsing errors
    }
    return authors;
  }
}
