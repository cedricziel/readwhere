import 'package:xml/xml.dart';

/// Common XML namespaces used in EPUB documents.
class EpubNamespaces {
  EpubNamespaces._();

  /// OPF (Open Packaging Format) namespace
  static const String opf = 'http://www.idpf.org/2007/opf';

  /// Dublin Core metadata namespace
  static const String dc = 'http://purl.org/dc/elements/1.1/';

  /// DCMI Terms namespace
  static const String dcterms = 'http://purl.org/dc/terms/';

  /// XHTML namespace
  static const String xhtml = 'http://www.w3.org/1999/xhtml';

  /// EPUB namespace (for epub:type attribute)
  static const String epub = 'http://www.idpf.org/2007/ops';

  /// Container namespace
  static const String container =
      'urn:oasis:names:tc:opendocument:xmlns:container';

  /// Encryption namespace
  static const String encryption = 'http://www.w3.org/2001/04/xmlenc#';

  /// XML digital signatures namespace
  static const String dsig = 'http://www.w3.org/2000/09/xmldsig#';
}

/// Utility functions for working with XML in EPUB files.
class XmlUtils {
  XmlUtils._();

  /// Parses an XML string into an [XmlDocument].
  ///
  /// Returns null if parsing fails instead of throwing.
  static XmlDocument? tryParse(String xml) {
    try {
      return XmlDocument.parse(xml);
    } catch (_) {
      return null;
    }
  }

  /// Finds the first child element with the given local name.
  ///
  /// Ignores namespace for matching, useful when namespace prefixes vary.
  static XmlElement? findChildByLocalName(XmlElement parent, String localName) {
    return parent.childElements.firstWhere(
      (e) => e.localName == localName,
      orElse: () => throw StateError('Element not found'),
    );
  }

  /// Finds the first child element with the given local name, or null.
  static XmlElement? findChildByLocalNameOrNull(
    XmlElement parent,
    String localName,
  ) {
    try {
      return parent.childElements.firstWhere(
        (e) => e.localName == localName,
      );
    } catch (_) {
      return null;
    }
  }

  /// Finds all child elements with the given local name.
  static Iterable<XmlElement> findAllChildrenByLocalName(
    XmlElement parent,
    String localName,
  ) {
    return parent.childElements.where((e) => e.localName == localName);
  }

  /// Finds an element by local name and namespace.
  static XmlElement? findElementByNs(
    XmlElement parent,
    String localName,
    String namespace,
  ) {
    try {
      return parent.childElements.firstWhere(
        (e) => e.localName == localName && e.namespaceUri == namespace,
      );
    } catch (_) {
      return null;
    }
  }

  /// Finds all elements by local name and namespace.
  static Iterable<XmlElement> findAllElementsByNs(
    XmlElement parent,
    String localName,
    String namespace,
  ) {
    return parent.childElements.where(
      (e) => e.localName == localName && e.namespaceUri == namespace,
    );
  }

  /// Gets the text content of a child element, or null if not found.
  static String? getChildText(XmlElement parent, String localName) {
    final child = findChildByLocalNameOrNull(parent, localName);
    return child?.innerText.trim();
  }

  /// Gets the text content of a child element in a specific namespace.
  static String? getChildTextNs(
    XmlElement parent,
    String localName,
    String namespace,
  ) {
    final child = findElementByNs(parent, localName, namespace);
    return child?.innerText.trim();
  }

  /// Gets an attribute value, checking both with and without namespace.
  static String? getAttribute(
    XmlElement element,
    String name, {
    String? namespace,
  }) {
    // Try with namespace first if provided
    if (namespace != null) {
      final value = element.getAttribute(name, namespace: namespace);
      if (value != null) return value;
    }
    // Fall back to attribute without namespace
    return element.getAttribute(name);
  }

  /// Gets an attribute value as an integer, or null if not found or invalid.
  static int? getAttributeInt(
    XmlElement element,
    String name, {
    String? namespace,
  }) {
    final value = getAttribute(element, name, namespace: namespace);
    if (value == null) return null;
    return int.tryParse(value);
  }

  /// Gets an attribute value as a boolean.
  ///
  /// Returns true for "yes", "true", "1" (case-insensitive).
  static bool getAttributeBool(
    XmlElement element,
    String name, {
    String? namespace,
    bool defaultValue = false,
  }) {
    final value = getAttribute(element, name, namespace: namespace);
    if (value == null) return defaultValue;
    final lower = value.toLowerCase();
    return lower == 'yes' || lower == 'true' || lower == '1';
  }

  /// Recursively finds elements matching a predicate.
  static Iterable<XmlElement> findDescendants(
    XmlElement root,
    bool Function(XmlElement) predicate,
  ) sync* {
    for (final child in root.childElements) {
      if (predicate(child)) {
        yield child;
      }
      yield* findDescendants(child, predicate);
    }
  }

  /// Gets the text content of an element, stripping whitespace.
  static String getText(XmlElement element) {
    return element.innerText.trim();
  }

  /// Gets the inner XML as a string.
  static String getInnerXml(XmlElement element) {
    return element.children.map((n) => n.toXmlString()).join();
  }

  /// Finds an element by ID attribute.
  static XmlElement? getElementById(XmlElement root, String id) {
    return findDescendants(
      root,
      (e) => e.getAttribute('id') == id,
    ).firstOrNull;
  }

  /// Extracts all text nodes recursively as plain text.
  static String extractPlainText(XmlNode node) {
    if (node is XmlText) {
      return node.value;
    }
    if (node is XmlElement) {
      return node.children.map(extractPlainText).join();
    }
    return '';
  }
}

/// Extension methods for [XmlElement].
extension XmlElementExtensions on XmlElement {
  /// Gets child elements with the given local name.
  Iterable<XmlElement> childrenByLocalName(String localName) {
    return childElements.where((e) => e.localName == localName);
  }

  /// Gets the first child element with the given local name.
  XmlElement? firstChildByLocalName(String localName) {
    return childElements.where((e) => e.localName == localName).firstOrNull;
  }

  /// Gets the text content trimmed.
  String get trimmedText => innerText.trim();

  /// Gets an attribute, falling back to non-namespaced version.
  String? getAttributeOrNull(String name, {String? namespace}) {
    return XmlUtils.getAttribute(this, name, namespace: namespace);
  }
}
