import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:readwhere_cbz/readwhere_cbz.dart' show naturalSort;
import 'package:readwhere_rar/readwhere_rar.dart';

import '../errors/cbr_exception.dart';

/// Supported image file extensions in CBR archives.
const kImageExtensions = {'.jpg', '.jpeg', '.png', '.gif', '.webp'};

/// Standard metadata file names.
const kComicInfoFilename = 'ComicInfo.xml';
const kMetronInfoFilename = 'MetronInfo.xml';

/// High-level CBR container abstraction using pure Dart RAR parsing.
///
/// This implementation uses the readwhere_rar package for pure Dart
/// RAR 4.x archive reading. No external tools are required.
class CbrContainer {
  final RarArchive _archive;
  final String _originalPath;
  List<String>? _sortedImagePaths;
  List<String>? _allFilePaths;

  CbrContainer._(this._archive, this._originalPath);

  /// Opens a CBR file.
  ///
  /// Throws [CbrReadException] if the file cannot be read.
  /// Throws [CbrFormatException] if the file is not a valid RAR archive.
  static Future<CbrContainer> fromFile(
    String filePath, {
    String? password,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw CbrReadException(
        'File not found: $filePath',
        filePath: filePath,
      );
    }

    // Password-protected archives are not supported in pure Dart mode
    if (password != null) {
      throw CbrExtractionException(
        'Password-protected archives are not supported. '
        'Pure Dart RAR parsing does not support encryption.',
      );
    }

    try {
      final archive = await RarArchive.fromFile(filePath);
      return CbrContainer._(archive, filePath);
    } on RarVersionException catch (e) {
      throw CbrFormatException(
        'RAR 5.x format is not supported: ${e.message}',
      );
    } on RarEncryptedArchiveException catch (e) {
      throw CbrExtractionException(
        'Encrypted archives are not supported: ${e.message}',
      );
    } on RarException catch (e, st) {
      throw CbrExtractionException(
        'Failed to parse CBR file: ${e.message}',
        cause: e,
        stackTrace: st,
      );
    } catch (e, st) {
      throw CbrExtractionException(
        'Failed to open CBR file: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Opens a CBR file from a [File] object.
  static Future<CbrContainer> fromFileObject(
    File file, {
    String? password,
  }) async {
    return fromFile(file.path, password: password);
  }

  /// Returns all file paths in the archive.
  List<String> get allFilePaths {
    _allFilePaths ??= _archive.filePaths;
    return _allFilePaths!;
  }

  /// Returns all image file paths in natural sort order.
  List<String> get imagePaths {
    _sortedImagePaths ??= _computeSortedImagePaths();
    return _sortedImagePaths!;
  }

  /// Computes and sorts image paths.
  List<String> _computeSortedImagePaths() {
    final images = allFilePaths.where((path) {
      final ext = p.extension(path).toLowerCase();
      return kImageExtensions.contains(ext);
    }).toList();

    // Filter out images in metadata/system directories
    final filtered = images.where((path) {
      final lower = path.toLowerCase();
      // Skip macOS resource fork files
      if (lower.contains('__macosx')) return false;
      // Skip hidden files
      if (p.basename(path).startsWith('.')) return false;
      return true;
    }).toList();

    // Sort using natural sort for proper page ordering
    naturalSort(filtered);

    return filtered;
  }

  /// Returns the number of image pages.
  int get pageCount => imagePaths.length;

  /// Returns the total number of files in the archive.
  int get fileCount => allFilePaths.length;

  /// Whether all files can be extracted (STORE method, not encrypted).
  bool get allFilesExtractable => _archive.allFilesExtractable;

  /// Files that use unsupported compression.
  List<RarFileEntry> get unsupportedFiles => _archive.unsupportedFiles;

  /// Checks if the archive contains ComicInfo.xml.
  bool get hasComicInfo => _findFile(kComicInfoFilename) != null;

  /// Checks if the archive contains MetronInfo.xml.
  bool get hasMetronInfo => _findFile(kMetronInfoFilename) != null;

  /// Finds a file by name (case-insensitive).
  String? _findFile(String filename) {
    final lower = filename.toLowerCase();
    for (final path in allFilePaths) {
      if (p.basename(path).toLowerCase() == lower) {
        return path;
      }
    }
    return null;
  }

  /// Reads ComicInfo.xml content if present.
  String? readComicInfo() {
    final path = _findFile(kComicInfoFilename);
    if (path == null) return null;
    try {
      return _archive.readFileString(path);
    } catch (_) {
      return null;
    }
  }

  /// Reads MetronInfo.xml content if present.
  String? readMetronInfo() {
    final path = _findFile(kMetronInfoFilename);
    if (path == null) return null;
    try {
      return _archive.readFileString(path);
    } catch (_) {
      return null;
    }
  }

  /// Reads an image file as bytes.
  ///
  /// Throws [CbrExtractionException] if the file uses compression.
  Uint8List readImageBytes(String relativePath) {
    try {
      return _archive.readFileBytes(relativePath);
    } on RarUnsupportedCompressionException catch (e) {
      throw CbrExtractionException(
        'File uses unsupported compression: ${e.fileName}. '
        'This archive requires decompression which is not supported in pure Dart.',
      );
    } on RarException catch (e) {
      throw CbrExtractionException(
        'Failed to read file $relativePath: ${e.message}',
      );
    }
  }

  /// Reads a page by its index (0-based).
  ///
  /// Throws [CbrPageNotFoundException] if the index is out of bounds.
  Uint8List readPageBytes(int index) {
    if (index < 0 || index >= pageCount) {
      throw CbrPageNotFoundException(index);
    }
    return readImageBytes(imagePaths[index]);
  }

  /// Returns the path of the cover image.
  String? get coverImagePath {
    if (imagePaths.isEmpty) return null;
    return imagePaths.first;
  }

  /// Reads the cover image bytes.
  Uint8List? readCoverBytes() {
    final path = coverImagePath;
    if (path == null) return null;
    try {
      return readImageBytes(path);
    } catch (_) {
      return null;
    }
  }

  /// Returns the size of a file in bytes.
  int? getFileSize(String relativePath) {
    return _archive.getFileSize(relativePath);
  }

  /// Checks if a file exists in the archive.
  bool hasFile(String relativePath) {
    return _archive.hasFile(relativePath);
  }

  /// Reads a page by its path.
  Uint8List? readPageByPath(String relativePath) {
    return _archive.tryReadFileBytes(relativePath);
  }

  /// Closes the container and releases resources.
  ///
  /// For pure Dart mode, this is a no-op as no temp files are created.
  Future<void> close() async {
    _sortedImagePaths = null;
    _allFilePaths = null;
  }

  /// Synchronously closes the container.
  void closeSync() {
    _sortedImagePaths = null;
    _allFilePaths = null;
  }

  /// The original file path.
  String get originalPath => _originalPath;
}
