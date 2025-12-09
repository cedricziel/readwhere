import 'package:xml/xml.dart';

import '../entities/opds_link.dart';

/// Data model for OpdsLink with XML parsing support
class OpdsLinkModel extends OpdsLink {
  const OpdsLinkModel({
    required super.href,
    required super.rel,
    required super.type,
    super.title,
    super.length,
    super.price,
    super.currency,
  });

  /// Parse an OpdsLink from an XML atom:link element
  ///
  /// Example XML:
  /// ```xml
  /// <link rel="http://opds-spec.org/acquisition"
  ///       href="/download/123.epub"
  ///       type="application/epub+zip"
  ///       title="EPUB"
  ///       length="1234567"/>
  /// ```
  factory OpdsLinkModel.fromXmlElement(XmlElement element, {String? baseUrl}) {
    var href = element.getAttribute('href') ?? '';

    // Resolve relative URLs
    if (baseUrl != null && href.isNotEmpty && !href.startsWith('http')) {
      href = _resolveUrl(baseUrl, href);
    }

    // Get rel attribute, default to 'alternate'
    final rel = element.getAttribute('rel') ?? 'alternate';

    // Get type attribute
    final type = element.getAttribute('type') ?? 'application/atom+xml';

    // Get optional attributes
    final title = element.getAttribute('title');
    final lengthStr = element.getAttribute('length');
    final length = lengthStr != null ? int.tryParse(lengthStr) : null;

    // Parse price info (OPDS 1.1+)
    String? price;
    String? currency;
    final priceElement =
        element.findElements('opds:price').firstOrNull ??
        element.findElements('price').firstOrNull;
    if (priceElement != null) {
      price = priceElement.innerText;
      currency = priceElement.getAttribute('currencycode');
    }

    return OpdsLinkModel(
      href: href,
      rel: rel,
      type: type,
      title: title,
      length: length,
      price: price,
      currency: currency,
    );
  }

  /// Resolve a relative URL against a base URL
  static String _resolveUrl(String baseUrl, String relative) {
    if (relative.startsWith('/')) {
      // Absolute path - combine with origin
      final uri = Uri.parse(baseUrl);
      return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}$relative';
    } else {
      // Relative path - resolve against base
      final baseUri = Uri.parse(baseUrl);
      return baseUri.resolve(relative).toString();
    }
  }

  /// Create from domain entity
  factory OpdsLinkModel.fromEntity(OpdsLink link) {
    return OpdsLinkModel(
      href: link.href,
      rel: link.rel,
      type: link.type,
      title: link.title,
      length: link.length,
      price: link.price,
      currency: link.currency,
    );
  }

  /// Convert to domain entity
  OpdsLink toEntity() {
    return OpdsLink(
      href: href,
      rel: rel,
      type: type,
      title: title,
      length: length,
      price: price,
      currency: currency,
    );
  }
}
