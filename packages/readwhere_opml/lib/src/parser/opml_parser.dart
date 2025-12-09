import 'dart:io';

import 'package:xml/xml.dart';

import '../entities/opml_document.dart';
import '../entities/opml_head.dart';
import '../entities/opml_outline.dart';
import 'opml_exception.dart';

/// Parser for OPML 1.0 and 2.0 documents
class OpmlParser {
  /// Parse an OPML document from XML string
  static OpmlDocument parse(String xml) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(xml);
    } catch (e) {
      throw OpmlParseException('Invalid XML', e);
    }

    final opml = document.rootElement;
    if (opml.name.local.toLowerCase() != 'opml') {
      throw const OpmlFormatException('Root element is not <opml>');
    }

    final version = opml.getAttribute('version') ?? '1.0';

    // Parse head
    final headElement = opml.findElements('head').firstOrNull;
    final head = headElement != null ? _parseHead(headElement) : null;

    // Parse body
    final bodyElement = opml.findElements('body').firstOrNull;
    if (bodyElement == null) {
      throw const OpmlFormatException('No <body> element found');
    }

    final outlines = _parseOutlines(bodyElement);

    return OpmlDocument(version: version, head: head, outlines: outlines);
  }

  /// Parse an OPML document from a file
  static Future<OpmlDocument> parseFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw OpmlParseException('File not found: $filePath');
    }

    final content = await file.readAsString();
    return parse(content);
  }

  /// Parse an OPML document from a file synchronously
  static OpmlDocument parseFileSync(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw OpmlParseException('File not found: $filePath');
    }

    final content = file.readAsStringSync();
    return parse(content);
  }

  /// Extract all feeds from an OPML document (flattened)
  static List<OpmlOutline> extractFeeds(OpmlDocument doc) {
    return doc.allFeeds;
  }

  /// Try to parse, returning null on failure
  static OpmlDocument? tryParse(String xml) {
    try {
      return parse(xml);
    } catch (_) {
      return null;
    }
  }

  static OpmlHead _parseHead(XmlElement head) {
    return OpmlHead(
      title: _getText(head, 'title'),
      dateCreated: _parseDate(_getText(head, 'dateCreated')),
      dateModified: _parseDate(_getText(head, 'dateModified')),
      ownerName: _getText(head, 'ownerName'),
      ownerEmail: _getText(head, 'ownerEmail'),
      ownerId: _getText(head, 'ownerId'),
      docs: _getText(head, 'docs'),
      expansionState: _getText(head, 'expansionState'),
      vertScrollState: _parseInt(_getText(head, 'vertScrollState')),
      windowTop: _parseInt(_getText(head, 'windowTop')),
      windowLeft: _parseInt(_getText(head, 'windowLeft')),
      windowBottom: _parseInt(_getText(head, 'windowBottom')),
      windowRight: _parseInt(_getText(head, 'windowRight')),
    );
  }

  static List<OpmlOutline> _parseOutlines(XmlElement parent) {
    return parent.findElements('outline').map(_parseOutline).toList();
  }

  static OpmlOutline _parseOutline(XmlElement outline) {
    // Parse children recursively
    final children = _parseOutlines(outline);

    // Collect custom attributes (non-standard)
    final customAttributes = <String, String>{};
    final standardAttributes = {
      'text',
      'title',
      'type',
      'xmlUrl',
      'htmlUrl',
      'description',
      'language',
      'version',
      'isComment',
      'isBreakpoint',
      'created',
      'category',
    };

    for (final attr in outline.attributes) {
      if (!standardAttributes.contains(attr.name.local)) {
        customAttributes[attr.name.local] = attr.value;
      }
    }

    return OpmlOutline(
      text: outline.getAttribute('text'),
      title: outline.getAttribute('title'),
      type: outline.getAttribute('type'),
      xmlUrl: outline.getAttribute('xmlUrl'),
      htmlUrl: outline.getAttribute('htmlUrl'),
      description: outline.getAttribute('description'),
      language: outline.getAttribute('language'),
      version: outline.getAttribute('version'),
      isComment: _parseBool(outline.getAttribute('isComment')),
      isBreakpoint: _parseBool(outline.getAttribute('isBreakpoint')),
      created: _parseDate(outline.getAttribute('created')),
      category: outline.getAttribute('category'),
      children: children,
      customAttributes: customAttributes,
    );
  }

  static String? _getText(XmlElement element, String name) {
    final child = element.findElements(name).firstOrNull;
    final text = child?.innerText.trim();
    return (text != null && text.isNotEmpty) ? text : null;
  }

  static int? _parseInt(String? value) {
    if (value == null) return null;
    return int.tryParse(value);
  }

  static bool? _parseBool(String? value) {
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }

  static DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    // Try RFC 2822 format first (common in OPML)
    try {
      return _parseRfc2822(dateStr);
    } catch (_) {}

    // Try ISO 8601
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}

    return null;
  }

  static DateTime _parseRfc2822(String dateStr) {
    final months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };

    var s = dateStr;
    final commaIndex = s.indexOf(',');
    if (commaIndex != -1) {
      s = s.substring(commaIndex + 1).trim();
    }

    final parts = s.split(RegExp(r'\s+'));
    if (parts.length < 4) throw const FormatException('Invalid RFC 2822 date');

    final day = int.parse(parts[0]);
    final month = months[parts[1]];
    if (month == null) throw const FormatException('Invalid month');
    final year = int.parse(parts[2]);

    var hour = 0, minute = 0, second = 0;
    if (parts.length > 3) {
      final timeParts = parts[3].split(':');
      hour = int.parse(timeParts[0]);
      if (timeParts.length > 1) minute = int.parse(timeParts[1]);
      if (timeParts.length > 2) second = int.parse(timeParts[2]);
    }

    return DateTime.utc(year, month, day, hour, minute, second);
  }
}
