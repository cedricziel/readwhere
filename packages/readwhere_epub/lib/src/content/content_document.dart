import 'package:equatable/equatable.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

import '../package/manifest/manifest.dart';
import '../utils/path_utils.dart';

/// Represents a parsed EPUB content document (chapter).
class EpubChapter extends Equatable {
  /// Manifest ID of this chapter.
  final String id;

  /// Relative href/path within the EPUB.
  final String href;

  /// Chapter title (from navigation or extracted from content).
  final String? title;

  /// Index in the spine (reading order).
  final int spineIndex;

  /// Raw XHTML/HTML content.
  final String content;

  /// Media type (should be "application/xhtml+xml").
  final String mediaType;

  /// Whether this chapter is linear (appears in reading flow).
  final bool isLinear;

  /// Properties from manifest (e.g., "scripted", "mathml", "svg").
  final Set<String> properties;

  const EpubChapter({
    required this.id,
    required this.href,
    this.title,
    required this.spineIndex,
    required this.content,
    this.mediaType = 'application/xhtml+xml',
    this.isLinear = true,
    this.properties = const {},
  });

  /// Extracts plain text from the XHTML content.
  String get plainText {
    final document = html_parser.parse(content);
    return _extractText(document.body);
  }

  /// Extracts the body content only (without html/head).
  String get bodyContent {
    final document = html_parser.parse(content);
    final body = document.body;
    if (body == null) return content;
    return body.innerHtml;
  }

  /// Gets the document title from the <title> element.
  String? get documentTitle {
    final document = html_parser.parse(content);
    final titleElement = document.head?.querySelector('title');
    return titleElement?.text.trim();
  }

  /// Extracts all linked stylesheet hrefs.
  List<String> get stylesheetHrefs {
    final document = html_parser.parse(content);
    final links = document.querySelectorAll('link[rel="stylesheet"]');
    return links
        .map((link) => link.attributes['href'])
        .where((href) => href != null && href.isNotEmpty)
        .cast<String>()
        .toList();
  }

  /// Extracts all image srcs from the content.
  List<String> get imageHrefs {
    final document = html_parser.parse(content);
    final images = document.querySelectorAll('img');
    return images
        .map((img) => img.attributes['src'])
        .where((src) => src != null && src.isNotEmpty)
        .cast<String>()
        .toList();
  }

  /// Whether this chapter contains scripts.
  bool get isScripted => properties.contains('scripted');

  /// Whether this chapter contains MathML.
  bool get hasMathML => properties.contains('mathml');

  /// Whether this chapter contains SVG.
  bool get hasSVG => properties.contains('svg');

  /// File extension of the chapter file.
  String get extension => PathUtils.extension(href);

  /// Filename without path.
  String get filename => PathUtils.basename(href);

  static String _extractText(html_dom.Element? element) {
    if (element == null) return '';
    final buffer = StringBuffer();
    for (final node in element.nodes) {
      if (node is html_dom.Text) {
        buffer.write(node.text);
      } else if (node is html_dom.Element) {
        // Add space before block elements
        if (_isBlockElement(node.localName ?? '')) {
          buffer.write(' ');
        }
        buffer.write(_extractText(node));
        if (_isBlockElement(node.localName ?? '')) {
          buffer.write(' ');
        }
      }
    }
    // Normalize whitespace
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool _isBlockElement(String tagName) {
    const blockTags = {
      'p',
      'div',
      'section',
      'article',
      'header',
      'footer',
      'nav',
      'aside',
      'h1',
      'h2',
      'h3',
      'h4',
      'h5',
      'h6',
      'blockquote',
      'pre',
      'figure',
      'figcaption',
      'ul',
      'ol',
      'li',
      'dl',
      'dt',
      'dd',
      'table',
      'tr',
      'br',
    };
    return blockTags.contains(tagName.toLowerCase());
  }

  @override
  List<Object?> get props => [
        id,
        href,
        title,
        spineIndex,
        content,
        mediaType,
        isLinear,
        properties,
      ];

  /// Creates a copy with modified fields.
  EpubChapter copyWith({
    String? id,
    String? href,
    String? title,
    int? spineIndex,
    String? content,
    String? mediaType,
    bool? isLinear,
    Set<String>? properties,
  }) {
    return EpubChapter(
      id: id ?? this.id,
      href: href ?? this.href,
      title: title ?? this.title,
      spineIndex: spineIndex ?? this.spineIndex,
      content: content ?? this.content,
      mediaType: mediaType ?? this.mediaType,
      isLinear: isLinear ?? this.isLinear,
      properties: properties ?? this.properties,
    );
  }
}

/// Content extractor for retrieving and processing chapter content.
class ContentExtractor {
  ContentExtractor._();

  /// Creates an [EpubChapter] from manifest item and content.
  static EpubChapter createChapter({
    required ManifestItem item,
    required int spineIndex,
    required String content,
    required bool isLinear,
    String? title,
  }) {
    return EpubChapter(
      id: item.id,
      href: item.href,
      title: title,
      spineIndex: spineIndex,
      content: content,
      mediaType: item.mediaType,
      isLinear: isLinear,
      properties: item.properties,
    );
  }

  /// Resolves all resource hrefs in content to absolute paths.
  ///
  /// Given a chapter path and its content, rewrites relative hrefs
  /// (images, stylesheets) to paths relative to EPUB root.
  static String resolveResourcePaths(String content, String chapterPath) {
    final document = html_parser.parse(content);

    // Resolve image sources
    for (final img in document.querySelectorAll('img')) {
      final src = img.attributes['src'];
      if (src != null && !_isAbsoluteUrl(src)) {
        img.attributes['src'] = PathUtils.resolve(chapterPath, src);
      }
    }

    // Resolve stylesheet links
    for (final link in document.querySelectorAll('link[href]')) {
      final href = link.attributes['href'];
      if (href != null && !_isAbsoluteUrl(href)) {
        link.attributes['href'] = PathUtils.resolve(chapterPath, href);
      }
    }

    // Resolve script sources
    for (final script in document.querySelectorAll('script[src]')) {
      final src = script.attributes['src'];
      if (src != null && !_isAbsoluteUrl(src)) {
        script.attributes['src'] = PathUtils.resolve(chapterPath, src);
      }
    }

    // Resolve anchor hrefs (internal links)
    for (final anchor in document.querySelectorAll('a[href]')) {
      final href = anchor.attributes['href'];
      if (href != null && !_isAbsoluteUrl(href) && !href.startsWith('#')) {
        anchor.attributes['href'] = PathUtils.resolve(chapterPath, href);
      }
    }

    return document.outerHtml;
  }

  static bool _isAbsoluteUrl(String url) {
    return url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('data:') ||
        url.startsWith('//');
  }
}
