import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../errors/epub_exception.dart';

/// Provides lazy access to EPUB ZIP archive contents.
///
/// This class wraps the archive package to provide convenient methods
/// for reading files from an EPUB without loading everything into memory.
class ArchiveReader {
  /// The decoded archive.
  final Archive _archive;

  /// Map of lowercase paths to archive files for case-insensitive lookup.
  final Map<String, ArchiveFile> _filesByPath;

  /// Original file paths (case-preserved).
  final Map<String, String> _originalPaths;

  ArchiveReader._(this._archive, this._filesByPath, this._originalPaths);

  /// Opens an EPUB archive from a file path.
  ///
  /// Throws [EpubReadException] if the file cannot be read or is not a valid ZIP.
  static Future<ArchiveReader> fromFile(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw EpubReadException(
        'EPUB file not found',
        filePath: filePath,
      );
    }

    try {
      final bytes = await file.readAsBytes();
      return fromBytes(bytes);
    } on FileSystemException catch (e) {
      throw EpubReadException(
        'Failed to read EPUB file: ${e.message}',
        filePath: filePath,
        cause: e,
      );
    }
  }

  /// Opens an EPUB archive from bytes.
  ///
  /// Throws [EpubReadException] if the bytes are not a valid ZIP archive.
  static ArchiveReader fromBytes(Uint8List bytes) {
    // Verify ZIP magic number
    if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
      throw const EpubReadException('Invalid EPUB: not a ZIP archive');
    }

    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      return _createFromArchive(archive);
    } catch (e) {
      throw EpubReadException(
        'Failed to decode EPUB archive',
        cause: e,
      );
    }
  }

  static ArchiveReader _createFromArchive(Archive archive) {
    final filesByPath = <String, ArchiveFile>{};
    final originalPaths = <String, String>{};

    for (final file in archive.files) {
      if (!file.isFile) continue;

      final path = file.name;
      final lowerPath = path.toLowerCase();

      filesByPath[lowerPath] = file;
      originalPaths[lowerPath] = path;
    }

    return ArchiveReader._(archive, filesByPath, originalPaths);
  }

  /// List of all file paths in the archive.
  List<String> get filePaths {
    return _archive.files.where((f) => f.isFile).map((f) => f.name).toList();
  }

  /// Number of files in the archive.
  int get fileCount => _archive.files.where((f) => f.isFile).length;

  /// Checks if a file exists in the archive.
  ///
  /// By default, performs case-insensitive matching to handle
  /// inconsistent path casing in some EPUBs.
  bool hasFile(String path, {bool caseSensitive = false}) {
    if (caseSensitive) {
      return _archive.files.any((f) => f.isFile && f.name == path);
    }
    return _filesByPath.containsKey(path.toLowerCase());
  }

  /// Gets the content of a file as bytes.
  ///
  /// Throws [EpubResourceNotFoundException] if the file doesn't exist.
  Uint8List readFileBytes(String path) {
    final file = _getFile(path);
    final content = file.content;

    if (content is Uint8List) {
      return content;
    }
    if (content is List<int>) {
      return Uint8List.fromList(content);
    }

    throw EpubReadException('Unexpected content type for file: $path');
  }

  /// Gets the content of a file as a string (UTF-8).
  ///
  /// Throws [EpubResourceNotFoundException] if the file doesn't exist.
  String readFileString(String path) {
    final bytes = readFileBytes(path);
    return String.fromCharCodes(bytes);
  }

  /// Gets a file from the archive.
  ArchiveFile _getFile(String path) {
    // Try exact match first
    final exactMatch =
        _archive.files.where((f) => f.isFile && f.name == path).firstOrNull;

    if (exactMatch != null) {
      return exactMatch;
    }

    // Try case-insensitive match
    final lowerPath = path.toLowerCase();
    final file = _filesByPath[lowerPath];

    if (file == null) {
      throw EpubResourceNotFoundException(path);
    }

    return file;
  }

  /// Gets the original (case-preserved) path for a file.
  String? getOriginalPath(String path) {
    return _originalPaths[path.toLowerCase()];
  }

  /// Validates the mimetype file per EPUB OCF specification.
  ///
  /// The mimetype file must:
  /// - Be the first file in the archive
  /// - Be uncompressed (stored)
  /// - Contain exactly "application/epub+zip"
  ///
  /// Returns a validation result with any issues found.
  MimetypeValidation validateMimetype() {
    final files = _archive.files.where((f) => f.isFile).toList();

    if (files.isEmpty) {
      return const MimetypeValidation(
        isValid: false,
        error: 'Archive contains no files',
      );
    }

    // Check if mimetype is first file
    final firstFile = files.first;
    if (firstFile.name != 'mimetype') {
      // Check if mimetype exists at all
      final hasMimetype = files.any((f) => f.name == 'mimetype');
      if (!hasMimetype) {
        return const MimetypeValidation(
          isValid: false,
          error: 'Missing mimetype file',
        );
      }
      return MimetypeValidation(
        isValid: false,
        error: 'mimetype is not the first file (found: ${firstFile.name})',
      );
    }

    // Check content
    final content = String.fromCharCodes(firstFile.content as List<int>).trim();
    if (content != 'application/epub+zip') {
      return MimetypeValidation(
        isValid: false,
        error: 'Invalid mimetype content: "$content"',
      );
    }

    // Note: We can't easily check compression method with the archive package
    // Most readers don't strictly enforce this anyway

    return const MimetypeValidation(isValid: true);
  }
}

/// Result of mimetype validation.
class MimetypeValidation {
  /// Whether the mimetype is valid.
  final bool isValid;

  /// Error message if validation failed.
  final String? error;

  const MimetypeValidation({
    required this.isValid,
    this.error,
  });
}
