import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Fallback EPUB reader that manually parses EPUB archives when epubx fails.
///
/// This handles EPUBs with non-standard or malformed navigation structures
/// that cause the epubx package to crash.
class EpubFallbackReader {
  final Archive _archive;
  final Map<String, ArchiveFile> _files = {};

  String? _title;
  String? _author;
  final List<String> _spineItems = [];
  final Map<String, String> _manifest = {}; // id -> href
  String _rootPath = '';

  EpubFallbackReader._(this._archive) {
    for (final file in _archive) {
      _files[file.name] = file;
    }
  }

  /// Parse an EPUB file using the fallback reader
  static Future<EpubFallbackReader> parse(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return parseBytes(bytes);
  }

  /// Parse EPUB bytes using the fallback reader
  static EpubFallbackReader parseBytes(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final reader = EpubFallbackReader._(archive);
    reader._parseContainer();
    return reader;
  }

  String get title => _title ?? 'Unknown Title';
  String get author => _author ?? 'Unknown Author';
  int get chapterCount => _spineItems.length;
  List<String> get spineItems => List.unmodifiable(_spineItems);

  /// Parse the container.xml to find the OPF file
  void _parseContainer() {
    final containerFile = _files['META-INF/container.xml'];
    if (containerFile == null) return;

    try {
      final content = String.fromCharCodes(containerFile.content as List<int>);
      final doc = XmlDocument.parse(content);

      // Find the rootfile element
      final rootfileElements = doc.findAllElements('rootfile');
      for (final element in rootfileElements) {
        final fullPath = element.getAttribute('full-path');
        if (fullPath != null) {
          // Extract root path (directory of OPF file)
          final lastSlash = fullPath.lastIndexOf('/');
          _rootPath = lastSlash > 0 ? fullPath.substring(0, lastSlash + 1) : '';

          _parseOpf(fullPath);
          break;
        }
      }
    } catch (e) {
      // Ignore container parsing errors
    }
  }

  /// Parse the OPF file for metadata and spine
  void _parseOpf(String opfPath) {
    final opfFile = _files[opfPath];
    if (opfFile == null) return;

    try {
      final content = String.fromCharCodes(opfFile.content as List<int>);
      final doc = XmlDocument.parse(content);

      // Extract metadata
      _parseMetadata(doc);

      // Build manifest map
      _parseManifest(doc);

      // Parse spine
      _parseSpine(doc);
    } catch (e) {
      // Ignore OPF parsing errors
    }
  }

  void _parseMetadata(XmlDocument doc) {
    // Try to find title
    for (final element in doc.findAllElements('dc:title')) {
      _title = element.innerText.trim();
      break;
    }
    // Fallback: title without namespace
    if (_title == null) {
      for (final element in doc.findAllElements('title')) {
        _title = element.innerText.trim();
        break;
      }
    }

    // Try to find author/creator
    for (final element in doc.findAllElements('dc:creator')) {
      _author = element.innerText.trim();
      break;
    }
    if (_author == null) {
      for (final element in doc.findAllElements('creator')) {
        _author = element.innerText.trim();
        break;
      }
    }
  }

  void _parseManifest(XmlDocument doc) {
    for (final element in doc.findAllElements('item')) {
      final id = element.getAttribute('id');
      final href = element.getAttribute('href');
      if (id != null && href != null) {
        _manifest[id] = href;
      }
    }
  }

  void _parseSpine(XmlDocument doc) {
    for (final element in doc.findAllElements('itemref')) {
      final idref = element.getAttribute('idref');
      if (idref != null && _manifest.containsKey(idref)) {
        _spineItems.add(_manifest[idref]!);
      }
    }
  }

  /// Get the HTML content of a chapter by index
  String? getChapterContent(int index) {
    if (index < 0 || index >= _spineItems.length) return null;

    final href = _spineItems[index];
    final fullPath = _rootPath + href;

    // Try exact path first, then try without root path
    var file = _files[fullPath] ?? _files[href];

    // Try URL-decoded version
    if (file == null) {
      final decoded = Uri.decodeComponent(href);
      file = _files[_rootPath + decoded] ?? _files[decoded];
    }

    if (file == null) return null;

    try {
      return String.fromCharCodes(file.content as List<int>);
    } catch (e) {
      return null;
    }
  }

  /// Get the cover image if available
  Uint8List? getCover() {
    // Common cover file patterns
    final coverPatterns = [
      'cover.jpg',
      'cover.jpeg',
      'cover.png',
      'images/cover.jpg',
      'images/cover.jpeg',
      'images/cover.png',
      'OEBPS/cover.jpg',
      'OEBPS/images/cover.jpg',
    ];

    for (final pattern in coverPatterns) {
      final file = _files[pattern] ?? _files[_rootPath + pattern];
      if (file != null) {
        return Uint8List.fromList(file.content as List<int>);
      }
    }

    // Look for any image file with 'cover' in the name
    for (final entry in _files.entries) {
      if (entry.key.toLowerCase().contains('cover') &&
          (entry.key.endsWith('.jpg') ||
              entry.key.endsWith('.jpeg') ||
              entry.key.endsWith('.png'))) {
        return Uint8List.fromList(entry.value.content as List<int>);
      }
    }

    return null;
  }

  /// Get all chapter titles (extracted from spine item filenames)
  List<String> getChapterTitles() {
    return _spineItems.map((href) {
      // Extract filename without extension
      final name = href.split('/').last;
      final dotIndex = name.lastIndexOf('.');
      return dotIndex > 0 ? name.substring(0, dotIndex) : name;
    }).toList();
  }
}
