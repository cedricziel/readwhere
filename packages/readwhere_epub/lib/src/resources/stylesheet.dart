import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'resource.dart';

/// An EPUB CSS stylesheet resource.
class EpubStylesheet extends EpubResource {
  /// Raw bytes of the stylesheet.
  final Uint8List bytes;

  const EpubStylesheet({
    required super.id,
    required super.href,
    required this.bytes,
    super.properties,
  }) : super(mediaType: 'text/css');

  /// CSS content as string.
  String get content => utf8.decode(bytes, allowMalformed: true);

  @override
  int get size => bytes.length;

  /// Extracts all @import URLs from the stylesheet.
  List<String> get importUrls {
    final imports = <String>[];
    // Match @import url("...") or @import "..."
    final regex = RegExp(
        r'''@import\s+(?:url\(["']?([^"')\s]+)["']?\)|["']([^"']+)["'])''');

    for (final match in regex.allMatches(content)) {
      final url = match.group(1) ?? match.group(2);
      if (url != null && url.isNotEmpty) {
        imports.add(url);
      }
    }
    return imports;
  }

  /// Extracts all url() references from the stylesheet.
  List<String> get urlReferences {
    final urls = <String>[];
    final regex = RegExp(r'''url\(["']?([^"')\s]+)["']?\)''');

    for (final match in regex.allMatches(content)) {
      final url = match.group(1);
      if (url != null && url.isNotEmpty && !url.startsWith('data:')) {
        urls.add(url);
      }
    }
    return urls;
  }

  /// Extracts all font-face src URLs.
  List<String> get fontUrls {
    final fonts = <String>[];
    final regex = RegExp(
      r'''@font-face\s*\{[^}]*src\s*:\s*[^;]*url\(["']?([^"')\s]+)["']?\)''',
      multiLine: true,
    );

    for (final match in regex.allMatches(content)) {
      final url = match.group(1);
      if (url != null && url.isNotEmpty) {
        fonts.add(url);
      }
    }
    return fonts;
  }

  @override
  List<Object?> get props => [id, href, mediaType, bytes, properties];
}

/// A collection of stylesheets for an EPUB.
class StylesheetCollection extends Equatable {
  /// All stylesheets in the EPUB.
  final List<EpubStylesheet> stylesheets;

  const StylesheetCollection(this.stylesheets);

  /// Gets a stylesheet by ID.
  EpubStylesheet? getById(String id) {
    return stylesheets.where((s) => s.id == id).firstOrNull;
  }

  /// Gets a stylesheet by href.
  EpubStylesheet? getByHref(String href) {
    final normalizedHref = href.toLowerCase();
    return stylesheets
        .where((s) => s.href.toLowerCase() == normalizedHref)
        .firstOrNull;
  }

  /// All CSS content concatenated.
  String get combinedContent {
    return stylesheets.map((s) => s.content).join('\n\n');
  }

  /// Number of stylesheets.
  int get length => stylesheets.length;

  /// Whether the collection is empty.
  bool get isEmpty => stylesheets.isEmpty;

  /// Whether the collection is not empty.
  bool get isNotEmpty => stylesheets.isNotEmpty;

  @override
  List<Object?> get props => [stylesheets];
}
