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
    super.facetGroup,
    super.activeFacet,
    super.count,
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

    // Parse facet attributes (OPDS 1.1+)
    // opds:facetGroup - the group this facet belongs to
    final facetGroup =
        element.getAttribute('opds:facetGroup') ??
        _getNamespacedAttribute(element, 'facetGroup');

    // opds:activeFacet - whether this facet is active
    final activeFacetStr =
        element.getAttribute('opds:activeFacet') ??
        _getNamespacedAttribute(element, 'activeFacet');
    final activeFacet = activeFacetStr?.toLowerCase() == 'true';

    // thr:count - number of items matching this facet
    final countStr =
        element.getAttribute('thr:count') ??
        _getNamespacedAttribute(element, 'count');
    final count = countStr != null ? int.tryParse(countStr) : null;

    return OpdsLinkModel(
      href: href,
      rel: rel,
      type: type,
      title: title,
      length: length,
      price: price,
      currency: currency,
      facetGroup: facetGroup,
      activeFacet: activeFacetStr != null ? activeFacet : null,
      count: count,
    );
  }

  /// Get an attribute that may have a namespace prefix
  static String? _getNamespacedAttribute(XmlElement element, String localName) {
    // Try common namespace prefixes
    for (final prefix in ['opds', 'thr', 'opensearch']) {
      final value = element.getAttribute('$prefix:$localName');
      if (value != null) return value;
    }
    // Try without namespace
    return element.getAttribute(localName);
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
      facetGroup: link.facetGroup,
      activeFacet: link.activeFacet,
      count: link.count,
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
      facetGroup: facetGroup,
      activeFacet: activeFacet,
      count: count,
    );
  }
}
