import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../errors/cbz_exception.dart';

/// Low-level ZIP archive reader for CBZ files.
///
/// This class provides raw access to the ZIP archive contents without
/// any CBZ-specific logic. It handles the underlying archive operations
/// and provides a clean interface for the higher-level [CbzContainer].
class ArchiveReader {
  final Map<String, ArchiveFile> _fileIndex;

  ArchiveReader._(this._fileIndex);

  /// Creates an [ArchiveReader] from raw bytes.
  ///
  /// Throws [CbzReadException] if the bytes do not represent a valid ZIP.
  factory ArchiveReader.fromBytes(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final fileIndex = <String, ArchiveFile>{};

      for (final file in archive) {
        if (!file.isFile) continue;
        // Normalize path separators and remove leading slashes
        final normalizedPath = _normalizePath(file.name);
        fileIndex[normalizedPath] = file;
      }

      return ArchiveReader._(fileIndex);
    } catch (e, st) {
      throw CbzReadException(
        'Failed to read ZIP archive: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Normalizes a file path from the archive.
  ///
  /// - Converts backslashes to forward slashes
  /// - Removes leading slashes
  /// - Handles Windows-style paths
  static String _normalizePath(String path) {
    var normalized = path.replaceAll('\\', '/');
    while (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    return normalized;
  }

  /// Returns all file paths in the archive.
  List<String> get filePaths => _fileIndex.keys.toList();

  /// Returns the number of files in the archive.
  int get fileCount => _fileIndex.length;

  /// Checks if a file exists in the archive.
  bool hasFile(String path) {
    final normalized = _normalizePath(path);
    return _fileIndex.containsKey(normalized);
  }

  /// Reads a file from the archive as bytes.
  ///
  /// Throws [CbzReadException] if the file is not found or cannot be read.
  Uint8List readFileBytes(String path) {
    final normalized = _normalizePath(path);
    final file = _fileIndex[normalized];

    if (file == null) {
      throw CbzReadException(
        'File not found in archive: $path',
        filePath: path,
      );
    }

    try {
      final content = file.content;
      return Uint8List.fromList(content);
    } catch (e, st) {
      throw CbzReadException(
        'Failed to read file from archive: $path',
        filePath: path,
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Reads a file from the archive as a UTF-8 string.
  ///
  /// Throws [CbzReadException] if the file is not found or cannot be read.
  String readFileString(String path) {
    final bytes = readFileBytes(path);
    try {
      return String.fromCharCodes(bytes);
    } catch (e, st) {
      throw CbzReadException(
        'Failed to decode file as string: $path',
        filePath: path,
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Returns the size of a file in bytes.
  ///
  /// Returns null if the file is not found.
  int? getFileSize(String path) {
    final normalized = _normalizePath(path);
    final file = _fileIndex[normalized];
    return file?.size;
  }

  /// Returns files matching a predicate.
  List<String> getFilesWhere(bool Function(String path) predicate) {
    return _fileIndex.keys.where(predicate).toList();
  }

  /// Returns files with specific extensions.
  ///
  /// Extensions should include the dot (e.g., '.jpg', '.png').
  List<String> getFilesByExtensions(Set<String> extensions) {
    final lowerExtensions = extensions.map((e) => e.toLowerCase()).toSet();
    return getFilesWhere((path) {
      final dotIndex = path.lastIndexOf('.');
      if (dotIndex == -1) return false;
      final ext = path.substring(dotIndex).toLowerCase();
      return lowerExtensions.contains(ext);
    });
  }
}
