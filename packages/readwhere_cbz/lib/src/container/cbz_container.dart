import 'dart:io';
import 'dart:typed_data';

import '../errors/cbz_exception.dart';
import '../utils/natural_sort.dart';
import 'archive_reader.dart';

/// Supported image file extensions in CBZ archives.
const kImageExtensions = {'.jpg', '.jpeg', '.png', '.gif', '.webp'};

/// Standard metadata file names.
const kComicInfoFilename = 'ComicInfo.xml';
const kMetronInfoFilename = 'MetronInfo.xml';

/// High-level CBZ container abstraction.
///
/// Provides CBZ-specific operations on top of [ArchiveReader]:
/// - Image file enumeration with natural sorting
/// - Metadata file detection
/// - Cover image detection
class CbzContainer {
  final ArchiveReader _reader;
  List<String>? _sortedImagePaths;

  CbzContainer._(this._reader);

  /// Opens a CBZ file from a file path.
  ///
  /// Throws [CbzReadException] if the file cannot be read.
  static Future<CbzContainer> fromFile(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      return fromBytes(bytes);
    } catch (e, st) {
      if (e is CbzException) rethrow;
      throw CbzReadException(
        'Failed to read CBZ file: $e',
        filePath: filePath,
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Opens a CBZ from a [File] object.
  ///
  /// Throws [CbzReadException] if the file cannot be read.
  static Future<CbzContainer> fromFileObject(File file) async {
    return fromFile(file.path);
  }

  /// Opens a CBZ from raw bytes.
  ///
  /// Throws [CbzReadException] if the bytes are not a valid ZIP.
  static CbzContainer fromBytes(Uint8List bytes) {
    final reader = ArchiveReader.fromBytes(bytes);
    return CbzContainer._(reader);
  }

  /// Returns all image file paths in natural sort order.
  ///
  /// The result is cached after the first call.
  List<String> get imagePaths {
    _sortedImagePaths ??= _computeSortedImagePaths();
    return _sortedImagePaths!;
  }

  /// Computes and sorts image paths.
  List<String> _computeSortedImagePaths() {
    final images = _reader.getFilesByExtensions(kImageExtensions);

    // Filter out images in metadata/system directories
    final filtered = images.where((path) {
      final lower = path.toLowerCase();
      // Skip macOS resource fork files
      if (lower.contains('__macosx')) return false;
      // Skip hidden files
      if (_getFilename(path).startsWith('.')) return false;
      return true;
    }).toList();

    // Sort using natural sort for proper page ordering
    naturalSort(filtered);

    return filtered;
  }

  /// Returns the number of image pages.
  int get pageCount => imagePaths.length;

  /// Returns all file paths in the archive.
  List<String> get allFilePaths => _reader.filePaths;

  /// Returns the total number of files in the archive.
  int get fileCount => _reader.fileCount;

  /// Checks if the archive contains ComicInfo.xml.
  bool get hasComicInfo => _reader.hasFile(kComicInfoFilename);

  /// Checks if the archive contains MetronInfo.xml.
  bool get hasMetronInfo => _reader.hasFile(kMetronInfoFilename);

  /// Reads ComicInfo.xml content if present.
  ///
  /// Returns null if the file doesn't exist.
  /// Throws [CbzReadException] if the file exists but cannot be read.
  String? readComicInfo() {
    if (!hasComicInfo) return null;
    return _reader.readFileString(kComicInfoFilename);
  }

  /// Reads MetronInfo.xml content if present.
  ///
  /// Returns null if the file doesn't exist.
  /// Throws [CbzReadException] if the file exists but cannot be read.
  String? readMetronInfo() {
    if (!hasMetronInfo) return null;
    return _reader.readFileString(kMetronInfoFilename);
  }

  /// Reads an image file as bytes.
  ///
  /// Throws [CbzReadException] if the file cannot be read.
  Uint8List readImageBytes(String path) {
    return _reader.readFileBytes(path);
  }

  /// Reads a page by its index (0-based).
  ///
  /// Throws [CbzPageNotFoundException] if the index is out of range.
  Uint8List readPageBytes(int index) {
    if (index < 0 || index >= pageCount) {
      throw CbzPageNotFoundException(index);
    }
    return readImageBytes(imagePaths[index]);
  }

  /// Returns the path of the cover image.
  ///
  /// This is typically the first image in natural sort order.
  /// Returns null if there are no images.
  String? get coverImagePath {
    if (imagePaths.isEmpty) return null;
    return imagePaths.first;
  }

  /// Reads the cover image bytes.
  ///
  /// Returns null if there are no images.
  Uint8List? readCoverBytes() {
    final path = coverImagePath;
    if (path == null) return null;
    return readImageBytes(path);
  }

  /// Returns the size of a file in bytes.
  ///
  /// Returns null if the file doesn't exist.
  int? getFileSize(String path) => _reader.getFileSize(path);

  /// Checks if a file exists in the archive.
  bool hasFile(String path) => _reader.hasFile(path);

  /// Extracts just the filename from a path.
  static String _getFilename(String path) {
    final lastSlash = path.lastIndexOf('/');
    if (lastSlash == -1) return path;
    return path.substring(lastSlash + 1);
  }
}
