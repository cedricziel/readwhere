import 'dart:io';

import 'package:xml/xml.dart';

import '../models/webdav_file.dart';

/// Parser for WebDAV PROPFIND XML responses
class PropfindParser {
  /// Parse a PROPFIND XML response into a list of WebDavFile objects
  ///
  /// [xmlData] - The XML response body
  /// [basePath] - The path that was queried (used for relative path extraction)
  /// [skipFirst] - Whether to skip the first entry (usually the directory itself)
  /// [pathExtractor] - Optional custom function to extract relative paths from hrefs
  static List<WebDavFile> parse(
    String xmlData, {
    String basePath = '/',
    bool skipFirst = true,
    String Function(String href)? pathExtractor,
  }) {
    final document = XmlDocument.parse(xmlData);
    final responses = document.findAllElements('d:response');

    final files = <WebDavFile>[];
    var isFirst = true;

    for (final response in responses) {
      // Skip the first entry if requested (usually the directory itself)
      if (skipFirst && isFirst) {
        isFirst = false;
        continue;
      }
      isFirst = false;

      final file = _parseResponse(response, pathExtractor);
      if (file != null) {
        files.add(file);
      }
    }

    // Sort: directories first, then by name
    files.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return files;
  }

  static WebDavFile? _parseResponse(
    XmlElement response,
    String Function(String href)? pathExtractor,
  ) {
    final href = response.findElements('d:href').firstOrNull?.innerText ?? '';
    final propstat = response.findElements('d:propstat').firstOrNull;
    final prop = propstat?.findElements('d:prop').firstOrNull;

    if (prop == null) return null;

    final displayName =
        prop.findElements('d:displayname').firstOrNull?.innerText;
    final contentType =
        prop.findElements('d:getcontenttype').firstOrNull?.innerText;
    final contentLength =
        prop.findElements('d:getcontentlength').firstOrNull?.innerText;
    final lastModified =
        prop.findElements('d:getlastmodified').firstOrNull?.innerText;
    final etag = prop.findElements('d:getetag').firstOrNull?.innerText;
    final resourceType = prop.findElements('d:resourcetype').firstOrNull;

    // Check for OwnCloud size as fallback
    final ocSize = prop.findElements('oc:size').firstOrNull?.innerText;

    final isDirectory =
        resourceType?.findElements('d:collection').isNotEmpty ?? false;

    // Extract file name from href
    final decodedHref = Uri.decodeFull(href);
    final name = displayName ??
        decodedHref.split('/').where((s) => s.isNotEmpty).lastOrNull ??
        '';

    // Build the relative path
    final path = pathExtractor != null
        ? pathExtractor(decodedHref)
        : _defaultPathExtractor(decodedHref);

    return WebDavFile(
      path: path,
      name: name,
      isDirectory: isDirectory,
      size: contentLength != null
          ? int.tryParse(contentLength)
          : (ocSize != null ? int.tryParse(ocSize) : null),
      lastModified: lastModified != null ? _parseHttpDate(lastModified) : null,
      mimeType: isDirectory ? null : contentType,
      etag: etag?.replaceAll('"', ''),
    );
  }

  /// Default path extractor - just returns the href as-is
  static String _defaultPathExtractor(String href) {
    // Clean up the path
    var path = href;
    // Remove trailing slash for non-root paths
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return path.isEmpty ? '/' : path;
  }

  /// Parse HTTP date format (RFC 7231)
  static DateTime? _parseHttpDate(String date) {
    try {
      return HttpDate.parse(date);
    } catch (_) {
      return null;
    }
  }
}
