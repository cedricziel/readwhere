import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../../core/utils/logger.dart';

/// Result of scraping an article from a URL
class ScrapedArticle {
  /// The extracted article title (may differ from RSS title)
  final String? title;

  /// The main article content as clean HTML
  final String content;

  /// Plain text version of the content
  final String textContent;

  /// URL of the lead/hero image if found
  final String? leadImage;

  const ScrapedArticle({
    this.title,
    required this.content,
    required this.textContent,
    this.leadImage,
  });
}

/// Service for scraping full article content from web pages.
///
/// Uses a readability-style algorithm to extract the main content
/// from a webpage, stripping navigation, ads, and other clutter.
class ArticleScraperService {
  final http.Client _client;

  /// User agent to use for requests (identifies as a reader app)
  static const _userAgent =
      'Mozilla/5.0 (compatible; ReadWhere/1.0; +https://readwhere.app)';

  /// Tags that are unlikely to contain main content
  static const _unlikelyTags = [
    'nav',
    'footer',
    'header',
    'aside',
    'sidebar',
    'menu',
    'advertisement',
    'ad',
  ];

  /// Class/ID patterns that indicate non-content elements
  static final _unlikelyPatterns = RegExp(
    r'(comment|meta|footer|footnote|sidebar|widget|social|share|related|'
    r'advertisement|ad-|promo|sponsor|newsletter|subscription|cookie|'
    r'popup|modal|overlay|nav|menu|breadcrumb|pagination)',
    caseSensitive: false,
  );

  /// Class/ID patterns that indicate content elements
  static final _likelyPatterns = RegExp(
    r'(article|post|entry|content|story|text|body|main|page)',
    caseSensitive: false,
  );

  ArticleScraperService(this._client);

  /// Scrapes the full article content from the given URL.
  ///
  /// Returns null if the URL cannot be fetched or content cannot be extracted.
  Future<ScrapedArticle?> scrapeArticle(String url) async {
    try {
      AppLogger.info('Scraping article from: $url');

      // Fetch the page
      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': _userAgent,
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5,de;q=0.3',
        },
      );

      if (response.statusCode != 200) {
        AppLogger.warning('Failed to fetch URL: ${response.statusCode}');
        return null;
      }

      // Parse HTML
      final document = html_parser.parse(response.body);

      // Extract content
      final content = _extractContent(document);
      if (content == null || content.isEmpty) {
        AppLogger.warning('Could not extract content from: $url');
        return null;
      }

      // Extract metadata
      final title = _extractTitle(document);
      final leadImage = _extractLeadImage(document, url);
      final textContent = _htmlToText(content);

      AppLogger.info('Successfully scraped article: ${title ?? 'untitled'}');

      return ScrapedArticle(
        title: title,
        content: content,
        textContent: textContent,
        leadImage: leadImage,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error scraping article from $url', e, stackTrace);
      return null;
    }
  }

  /// Extracts the main content from the document.
  String? _extractContent(Document document) {
    // Remove unwanted elements first
    _removeUnwantedElements(document);

    // Try specific content selectors in order of preference
    Element? contentElement;

    // 1. Look for <article> element
    contentElement = document.querySelector('article');

    // 2. Look for role="main"
    contentElement ??= document.querySelector('[role="main"]');

    // 3. Look for <main> element
    contentElement ??= document.querySelector('main');

    // 4. Look for common content class names
    if (contentElement == null) {
      for (final selector in [
        '.post-content',
        '.entry-content',
        '.article-content',
        '.article-body',
        '.story-body',
        '.post-body',
        '.content-body',
        '#article-body',
        '#content',
        '#main-content',
        '.prose', // Common in modern sites
      ]) {
        contentElement = document.querySelector(selector);
        if (contentElement != null) break;
      }
    }

    // 5. Fallback: find the element with the most paragraph content
    contentElement ??= _findContentByDensity(document);

    if (contentElement == null) {
      return null;
    }

    // Clean up the content
    _cleanContent(contentElement);

    return contentElement.innerHtml;
  }

  /// Removes script, style, and other non-content elements.
  void _removeUnwantedElements(Document document) {
    // Remove scripts, styles, and other non-visible elements
    for (final selector in [
      'script',
      'style',
      'noscript',
      'iframe',
      'embed',
      'object',
      'svg',
      'canvas',
      'form',
      'input',
      'button',
      'select',
      'textarea',
    ]) {
      document.querySelectorAll(selector).forEach((e) => e.remove());
    }

    // Remove elements with unlikely tags
    for (final tag in _unlikelyTags) {
      document.querySelectorAll(tag).forEach((e) => e.remove());
    }

    // Remove elements with unlikely class/id patterns
    document.querySelectorAll('*').forEach((element) {
      final classAttr = element.attributes['class'] ?? '';
      final idAttr = element.attributes['id'] ?? '';
      final combined = '$classAttr $idAttr';

      if (_unlikelyPatterns.hasMatch(combined) &&
          !_likelyPatterns.hasMatch(combined)) {
        // Don't remove if it has a lot of text content
        final textLength = element.text.length;
        if (textLength < 200) {
          element.remove();
        }
      }
    });
  }

  /// Finds the element most likely to contain the main content
  /// based on paragraph density.
  Element? _findContentByDensity(Document document) {
    Element? bestCandidate;
    var bestScore = 0;

    // Look at divs and sections
    for (final element in document.querySelectorAll('div, section')) {
      final paragraphs = element.querySelectorAll('p');
      if (paragraphs.isEmpty) continue;

      // Score based on:
      // - Number of paragraphs
      // - Total text length
      // - Text density (text vs markup ratio)
      var score = 0;

      for (final p in paragraphs) {
        final text = p.text.trim();
        if (text.length > 50) {
          // Reasonable paragraph
          score += 1 + (text.length ~/ 100);
        }
      }

      // Bonus for likely class names
      final classAttr = element.attributes['class'] ?? '';
      final idAttr = element.attributes['id'] ?? '';
      if (_likelyPatterns.hasMatch('$classAttr $idAttr')) {
        score *= 2;
      }

      if (score > bestScore) {
        bestScore = score;
        bestCandidate = element;
      }
    }

    return bestCandidate;
  }

  /// Cleans up the content element for display.
  void _cleanContent(Element element) {
    // Remove empty elements
    element.querySelectorAll('*').forEach((e) {
      if (e.text.trim().isEmpty &&
          e.querySelectorAll('img').isEmpty &&
          e.localName != 'br' &&
          e.localName != 'hr') {
        e.remove();
      }
    });

    // Remove excessive whitespace in text nodes
    // (handled by the HTML renderer)

    // Keep only safe attributes
    element.querySelectorAll('*').forEach((e) {
      final allowedAttrs = <String>{'href', 'src', 'alt', 'title'};
      e.attributes.removeWhere((key, value) => !allowedAttrs.contains(key));
    });

    // Make links absolute (best effort)
    // Links are kept relative for now; the HTML widget handles this
  }

  /// Extracts the page title.
  String? _extractTitle(Document document) {
    // Try Open Graph title first
    final ogTitle = document.querySelector('meta[property="og:title"]');
    if (ogTitle != null) {
      return ogTitle.attributes['content'];
    }

    // Try article title
    final articleTitle = document.querySelector('article h1, .article-title');
    if (articleTitle != null) {
      return articleTitle.text.trim();
    }

    // Fall back to page title
    final title = document.querySelector('title');
    if (title != null) {
      var text = title.text.trim();
      // Remove common suffixes like " - Site Name"
      final dashIndex = text.lastIndexOf(' - ');
      if (dashIndex > 0) {
        text = text.substring(0, dashIndex);
      }
      final pipeIndex = text.lastIndexOf(' | ');
      if (pipeIndex > 0) {
        text = text.substring(0, pipeIndex);
      }
      return text;
    }

    return null;
  }

  /// Extracts the lead/hero image URL.
  String? _extractLeadImage(Document document, String baseUrl) {
    // Try Open Graph image
    final ogImage = document.querySelector('meta[property="og:image"]');
    if (ogImage != null) {
      return _makeAbsolute(ogImage.attributes['content'], baseUrl);
    }

    // Try Twitter card image
    final twitterImage = document.querySelector('meta[name="twitter:image"]');
    if (twitterImage != null) {
      return _makeAbsolute(twitterImage.attributes['content'], baseUrl);
    }

    // Try first large image in article
    final articleImages = document.querySelectorAll('article img, main img');
    for (final img in articleImages) {
      final src = img.attributes['src'];
      if (src != null && src.isNotEmpty) {
        // Skip small images (icons, avatars, etc.)
        final width = int.tryParse(img.attributes['width'] ?? '') ?? 0;
        final height = int.tryParse(img.attributes['height'] ?? '') ?? 0;
        if (width == 0 || width > 200 || height == 0 || height > 200) {
          return _makeAbsolute(src, baseUrl);
        }
      }
    }

    return null;
  }

  /// Makes a relative URL absolute.
  String? _makeAbsolute(String? url, String baseUrl) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    try {
      final base = Uri.parse(baseUrl);
      return base.resolve(url).toString();
    } catch (_) {
      return url;
    }
  }

  /// Converts HTML to plain text.
  String _htmlToText(String html) {
    final document = html_parser.parseFragment(html);
    return document.text?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
  }
}
