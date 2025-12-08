import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;

/// Options for HTML sanitization.
class SanitizeOptions {
  /// Whether to allow style attributes (default: true).
  final bool allowStyles;

  /// Whether to allow data: URIs for images (default: true).
  final bool allowDataImages;

  /// Custom set of allowed tags (null = use default whitelist).
  final Set<String>? allowedTags;

  /// Custom set of allowed attributes (null = use default whitelist).
  final Set<String>? allowedAttributes;

  const SanitizeOptions({
    this.allowStyles = true,
    this.allowDataImages = true,
    this.allowedTags,
    this.allowedAttributes,
  });

  /// Default options with reasonable security settings.
  static const SanitizeOptions defaultOptions = SanitizeOptions();

  /// Strict options that remove all styles and data URIs.
  static const SanitizeOptions strict = SanitizeOptions(
    allowStyles: false,
    allowDataImages: false,
  );
}

/// HTML sanitizer for EPUB content to prevent XSS attacks.
///
/// This sanitizer uses a whitelist approach to allow only safe HTML elements
/// and attributes while removing potentially dangerous content like scripts,
/// event handlers, and malicious URLs.
class HtmlSanitizer {
  HtmlSanitizer._();

  /// Default whitelist of allowed HTML elements.
  static const Set<String> defaultAllowedTags = {
    // Document structure
    'html', 'head', 'body', 'title',
    // Semantic sections
    'article', 'section', 'nav', 'aside', 'header', 'footer', 'main',
    // Headings
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hgroup',
    // Text content
    'p', 'div', 'span', 'blockquote', 'pre', 'address',
    'figure', 'figcaption', 'hr',
    // Lists
    'ul', 'ol', 'li', 'dl', 'dt', 'dd',
    // Text formatting
    'a', 'em', 'strong', 'small', 'cite', 'q', 'dfn', 'abbr',
    'time', 'code', 'var', 'samp', 'kbd', 'sub', 'sup',
    'i', 'b', 'u', 's', 'mark', 'ruby', 'rt', 'rp',
    'bdi', 'bdo', 'wbr', 'br',
    // Images and media (video/audio stripped, img allowed)
    'img', 'picture', 'source',
    // Tables
    'table', 'caption', 'thead', 'tbody', 'tfoot', 'tr', 'th', 'td',
    'colgroup', 'col',
    // Embedded content (safe only)
    'svg', 'math',
    // Meta (only safe ones)
    'link', 'style', 'meta',
  };

  /// Elements that must be completely removed (including children).
  static const Set<String> _dangerousTags = {
    'script',
    'iframe',
    'object',
    'embed',
    'applet',
    'form',
    'input',
    'button',
    'select',
    'textarea',
    'frame',
    'frameset',
    'base',
    'template',
  };

  /// Default whitelist of allowed attributes.
  static const Set<String> defaultAllowedAttributes = {
    // Global attributes
    'id', 'class', 'lang', 'dir', 'title', 'hidden', 'tabindex',
    // Text direction
    'translate',
    // Links
    'href', 'target', 'rel', 'type', 'hreflang',
    // Images
    'src', 'srcset', 'alt', 'width', 'height', 'loading', 'decoding',
    // Tables
    'colspan', 'rowspan', 'headers', 'scope',
    // Lists
    'start', 'reversed', 'value',
    // Media
    'sizes',
    // Misc
    'datetime', 'cite', 'data',
    // ARIA (all aria-* allowed via pattern)
    // Style (conditionally allowed)
    'style',
    // SVG common attributes
    'viewBox', 'xmlns', 'fill', 'stroke', 'transform', 'd', 'points',
    'cx', 'cy', 'r', 'rx', 'ry', 'x', 'y', 'x1', 'y1', 'x2', 'y2',
    'preserveAspectRatio',
  };

  /// Attribute patterns that indicate event handlers.
  static final RegExp _eventHandlerPattern =
      RegExp(r'^on\w+$', caseSensitive: false);

  /// Patterns for dangerous URL schemes.
  static final RegExp _dangerousUrlPattern = RegExp(
    r'^(javascript|vbscript|data:text/html|data:application)',
    caseSensitive: false,
  );

  /// Sanitize HTML string, removing dangerous elements and attributes.
  ///
  /// Returns sanitized HTML that is safe to render in a WebView or HTML widget.
  static String sanitize(String html, {SanitizeOptions? options}) {
    options ??= SanitizeOptions.defaultOptions;
    final document = html_parser.parse(html);
    _sanitizeNode(document.documentElement, options);
    return document.outerHtml;
  }

  /// Sanitize and return only the body content.
  static String sanitizeBody(String html, {SanitizeOptions? options}) {
    options ??= SanitizeOptions.defaultOptions;
    final document = html_parser.parse(html);
    _sanitizeNode(document.documentElement, options);
    return document.body?.innerHtml ?? '';
  }

  /// Check if HTML contains potentially dangerous content.
  ///
  /// This is a quick check without full sanitization, useful for
  /// flagging content that needs review.
  static bool containsDangerousContent(String html) {
    final lowerHtml = html.toLowerCase();

    // Check for dangerous tags
    for (final tag in _dangerousTags) {
      if (lowerHtml.contains('<$tag')) return true;
    }

    // Check for event handlers
    if (_eventHandlerPattern.hasMatch(html)) return true;

    // Check for javascript: URLs
    if (lowerHtml.contains('javascript:')) return true;

    // Check for data:text/html
    if (lowerHtml.contains('data:text/html')) return true;

    return false;
  }

  /// Sanitizes a DOM node and its children recursively.
  static void _sanitizeNode(
      html_dom.Element? element, SanitizeOptions options) {
    if (element == null) return;

    final allowedTags = options.allowedTags ?? defaultAllowedTags;
    final allowedAttrs = options.allowedAttributes ?? defaultAllowedAttributes;

    // Process children first (collect to avoid concurrent modification)
    final children = element.children.toList();
    for (final child in children) {
      _sanitizeElement(child, allowedTags, allowedAttrs, options);
    }
  }

  static void _sanitizeElement(
    html_dom.Element element,
    Set<String> allowedTags,
    Set<String> allowedAttrs,
    SanitizeOptions options,
  ) {
    final tagName = element.localName?.toLowerCase() ?? '';

    // Remove dangerous elements completely
    if (_dangerousTags.contains(tagName)) {
      element.remove();
      return;
    }

    // Check for meta refresh (sneaky redirect)
    if (tagName == 'meta') {
      final httpEquiv = element.attributes['http-equiv']?.toLowerCase();
      if (httpEquiv == 'refresh') {
        element.remove();
        return;
      }
    }

    // Remove link elements that aren't stylesheets
    if (tagName == 'link') {
      final rel = element.attributes['rel']?.toLowerCase();
      if (rel != 'stylesheet') {
        element.remove();
        return;
      }
    }

    // Recursively sanitize children first
    final children = element.children.toList();
    for (final child in children) {
      _sanitizeElement(child, allowedTags, allowedAttrs, options);
    }

    // If tag not in whitelist, unwrap it (keep children)
    if (!allowedTags.contains(tagName)) {
      _unwrapElement(element);
      return;
    }

    // Sanitize attributes
    _sanitizeAttributes(element, allowedAttrs, options);
  }

  /// Remove an element but keep its children.
  static void _unwrapElement(html_dom.Element element) {
    final parent = element.parent;
    if (parent == null) return;

    // Move all children to parent before this element
    final children = element.nodes.toList();
    for (final child in children) {
      parent.insertBefore(child, element);
    }
    element.remove();
  }

  /// Sanitize attributes of an element.
  static void _sanitizeAttributes(
    html_dom.Element element,
    Set<String> allowedAttrs,
    SanitizeOptions options,
  ) {
    final tagName = element.localName?.toLowerCase() ?? '';

    // Get list of attribute names to check
    final attrNames = element.attributes.keys.toList();

    for (final attrKey in attrNames) {
      final attrName = attrKey.toString();
      final attrLower = attrName.toLowerCase();

      // Remove all event handlers (on*)
      if (_eventHandlerPattern.hasMatch(attrLower)) {
        element.attributes.remove(attrKey);
        continue;
      }

      // Check style attribute
      if (attrLower == 'style') {
        if (!options.allowStyles) {
          element.attributes.remove(attrKey);
        } else {
          // Sanitize style content
          final style = element.attributes[attrKey];
          if (style != null) {
            element.attributes[attrKey] = _sanitizeStyle(style);
          }
        }
        continue;
      }

      // Allow aria-* and data-* attributes
      if (attrLower.startsWith('aria-') || attrLower.startsWith('data-')) {
        continue;
      }

      // Remove non-whitelisted attributes
      if (!allowedAttrs.contains(attrLower)) {
        element.attributes.remove(attrKey);
        continue;
      }

      // Validate URL attributes
      if (_isUrlAttribute(attrLower)) {
        final value = element.attributes[attrKey];
        if (value != null && !_isSafeUrl(value, tagName, attrLower, options)) {
          element.attributes.remove(attrKey);
        }
      }
    }

    // Special handling for srcdoc (always remove)
    element.attributes.remove('srcdoc');
  }

  /// Check if an attribute typically contains a URL.
  static bool _isUrlAttribute(String attrName) {
    return const {
      'href',
      'src',
      'srcset',
      'action',
      'formaction',
      'poster',
      'data'
    }.contains(attrName.toLowerCase());
  }

  /// Check if a URL is safe.
  static bool _isSafeUrl(
    String url,
    String tagName,
    String attrName,
    SanitizeOptions options,
  ) {
    final trimmedUrl = url.trim().toLowerCase();

    // Block javascript: and vbscript: URLs
    if (_dangerousUrlPattern.hasMatch(trimmedUrl)) {
      return false;
    }

    // Handle data: URLs
    if (trimmedUrl.startsWith('data:')) {
      // Allow data:image/* for images if enabled
      if (tagName == 'img' && attrName == 'src') {
        if (options.allowDataImages && trimmedUrl.startsWith('data:image/')) {
          return true;
        }
      }
      // Block all other data: URLs
      return false;
    }

    // Allow relative URLs, http, https
    if (trimmedUrl.startsWith('http://') ||
        trimmedUrl.startsWith('https://') ||
        trimmedUrl.startsWith('//') ||
        trimmedUrl.startsWith('#') ||
        trimmedUrl.startsWith('mailto:') ||
        !trimmedUrl.contains(':')) {
      return true;
    }

    return false;
  }

  /// Sanitize inline style content.
  ///
  /// Removes potentially dangerous CSS like expression(), url() with
  /// javascript, behavior:, and -moz-binding.
  static String _sanitizeStyle(String style) {
    // Remove CSS expressions (IE)
    var sanitized = style.replaceAll(
      RegExp(r'expression\s*\([^)]*\)', caseSensitive: false),
      '',
    );

    // Remove url() with javascript or data:text
    sanitized = sanitized.replaceAll(
      RegExp(r'url\s*\(\s*["\x27]?\s*(javascript|data:text)[^)]*\)',
          caseSensitive: false),
      '',
    );

    // Remove behavior (IE)
    sanitized = sanitized.replaceAll(
      RegExp(r'behavior\s*:\s*[^;]+', caseSensitive: false),
      '',
    );

    // Remove -moz-binding
    sanitized = sanitized.replaceAll(
      RegExp(r'-moz-binding\s*:\s*[^;]+', caseSensitive: false),
      '',
    );

    return sanitized;
  }
}
