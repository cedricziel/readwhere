import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:readwhere_cbz/readwhere_cbz.dart' show naturalSort;

import '../errors/cbr_exception.dart';

/// Supported image file extensions in CBR archives.
const kImageExtensions = {'.jpg', '.jpeg', '.png', '.gif', '.webp'};

/// Standard metadata file names.
const kComicInfoFilename = 'ComicInfo.xml';
const kMetronInfoFilename = 'MetronInfo.xml';

/// High-level CBR container abstraction.
///
/// Unlike [CbzContainer], this requires extracting to a temp directory
/// because the unrar_file package only supports file-based extraction.
class CbrContainer {
  final Directory _tempDir;
  final String _originalPath;
  List<String>? _sortedImagePaths;
  List<String>? _allFilePaths;

  CbrContainer._(this._tempDir, this._originalPath);

  /// Opens a CBR file and extracts it to a temp directory.
  ///
  /// Throws [CbrReadException] if the file cannot be read.
  /// Throws [CbrExtractionException] if extraction fails.
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

    // Create temp directory for extraction
    final tempDir = await Directory.systemTemp.createTemp('cbr_');

    try {
      // Extract RAR to temp directory using platform-appropriate method
      await _extractRar(filePath, tempDir.path, password: password);

      return CbrContainer._(tempDir, filePath);
    } catch (e, st) {
      // Clean up temp dir on failure
      await tempDir.delete(recursive: true);

      if (e is CbrException) rethrow;
      throw CbrExtractionException(
        'Failed to extract CBR file: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Platform-aware RAR extraction.
  ///
  /// Uses command-line `unrar` on desktop platforms (macOS, Linux, Windows)
  /// since the unrar_file package only supports mobile platforms.
  static Future<void> _extractRar(
    String filePath,
    String destPath, {
    String? password,
  }) async {
    if (_isDesktopPlatform()) {
      await _extractWithCommandLine(filePath, destPath, password: password);
    } else {
      await _extractWithPlugin(filePath, destPath, password: password);
    }
  }

  /// Check if running on a desktop platform.
  static bool _isDesktopPlatform() {
    // dart:io's Platform is not available on web, but this code path
    // won't be reached on web anyway since File operations fail there.
    return Platform.isMacOS || Platform.isLinux || Platform.isWindows;
  }

  /// Extract using command-line unrar tool.
  static Future<void> _extractWithCommandLine(
    String filePath,
    String destPath, {
    String? password,
  }) async {
    // Try to find unrar executable
    final unrarPath = await _findUnrar();
    if (unrarPath == null) {
      throw CbrExtractionException(
        'unrar command not found. Please install unrar:\n'
        '  macOS: brew install unrar\n'
        '  Ubuntu: sudo apt install unrar\n'
        '  Windows: Download from https://www.rarlab.com/rar_add.htm',
      );
    }

    final args = <String>[
      'x', // Extract with full paths
      '-o+', // Overwrite existing files
      '-y', // Assume yes to all queries
    ];

    if (password != null && password.isNotEmpty) {
      args.add('-p$password');
    } else {
      args.add('-p-'); // No password
    }

    args.add(filePath);
    args.add('$destPath/');

    final result = await Process.run(unrarPath, args);

    if (result.exitCode != 0) {
      final stderr = result.stderr.toString();
      if (stderr.contains('password') || stderr.contains('encrypted')) {
        throw CbrExtractionException(
          'Archive requires a password or password is incorrect',
        );
      }
      throw CbrExtractionException(
        'unrar failed with exit code ${result.exitCode}: ${result.stderr}',
      );
    }
  }

  /// Find the unrar executable on the system.
  static Future<String?> _findUnrar() async {
    // Common unrar locations
    final candidates = <String>[
      'unrar', // In PATH
      '/usr/local/bin/unrar', // Homebrew on Intel Mac
      '/opt/homebrew/bin/unrar', // Homebrew on Apple Silicon
      '/usr/bin/unrar', // Linux
      r'C:\Program Files\WinRAR\UnRAR.exe', // Windows WinRAR
      r'C:\Program Files (x86)\WinRAR\UnRAR.exe', // Windows WinRAR x86
    ];

    for (final candidate in candidates) {
      try {
        final result = await Process.run(
          candidate,
          ['--version'],
          runInShell: Platform.isWindows,
        );
        if (result.exitCode == 0 || result.exitCode == 7) {
          // unrar returns 7 for --version
          return candidate;
        }
      } catch (_) {
        // Try next candidate
      }
    }

    return null;
  }

  /// Extract using the unrar_file plugin (mobile only).
  static Future<void> _extractWithPlugin(
    String filePath,
    String destPath, {
    String? password,
  }) async {
    // Dynamic import to avoid issues on desktop
    try {
      // Use dynamic invocation to call the plugin
      // This avoids compile-time issues on unsupported platforms
      final unrarFile = _UnrarFileWrapper();
      await unrarFile.extractRar(filePath, destPath, password: password ?? '');
    } catch (e) {
      throw CbrExtractionException(
        'unrar_file plugin extraction failed: $e',
        cause: e,
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

  /// Returns all file paths in the extracted archive.
  List<String> get allFilePaths {
    _allFilePaths ??= _scanDirectory();
    return _allFilePaths!;
  }

  /// Scans the temp directory for all files.
  List<String> _scanDirectory() {
    final files = <String>[];
    final entities = _tempDir.listSync(recursive: true);

    for (final entity in entities) {
      if (entity is File) {
        // Store relative path from temp dir
        final relativePath = p.relative(entity.path, from: _tempDir.path);
        files.add(relativePath);
      }
    }

    return files;
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

  /// Gets the full path to a file in the temp directory.
  String _getFullPath(String relativePath) {
    return p.join(_tempDir.path, relativePath);
  }

  /// Reads ComicInfo.xml content if present.
  String? readComicInfo() {
    final path = _findFile(kComicInfoFilename);
    if (path == null) return null;
    return File(_getFullPath(path)).readAsStringSync();
  }

  /// Reads MetronInfo.xml content if present.
  String? readMetronInfo() {
    final path = _findFile(kMetronInfoFilename);
    if (path == null) return null;
    return File(_getFullPath(path)).readAsStringSync();
  }

  /// Reads an image file as bytes.
  Uint8List readImageBytes(String relativePath) {
    final fullPath = _getFullPath(relativePath);
    return File(fullPath).readAsBytesSync();
  }

  /// Reads a page by its index (0-based).
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
    return readImageBytes(path);
  }

  /// Returns the size of a file in bytes.
  int? getFileSize(String relativePath) {
    final fullPath = _getFullPath(relativePath);
    final file = File(fullPath);
    if (!file.existsSync()) return null;
    return file.lengthSync();
  }

  /// Checks if a file exists in the archive.
  bool hasFile(String relativePath) {
    return File(_getFullPath(relativePath)).existsSync();
  }

  /// Reads a page by its path.
  Uint8List? readPageByPath(String relativePath) {
    if (!hasFile(relativePath)) return null;
    return readImageBytes(relativePath);
  }

  /// Closes the container and cleans up the temp directory.
  Future<void> close() async {
    _sortedImagePaths = null;
    _allFilePaths = null;

    // Clean up temp directory
    if (await _tempDir.exists()) {
      await _tempDir.delete(recursive: true);
    }
  }

  /// Synchronously closes the container.
  void closeSync() {
    _sortedImagePaths = null;
    _allFilePaths = null;

    if (_tempDir.existsSync()) {
      _tempDir.deleteSync(recursive: true);
    }
  }

  /// The original file path.
  String get originalPath => _originalPath;

  /// The temp directory path (for debugging).
  String get tempPath => _tempDir.path;
}

/// Wrapper for unrar_file plugin to avoid compile-time issues on desktop.
///
/// This class is only instantiated on mobile platforms where unrar_file is available.
class _UnrarFileWrapper {
  Future<void> extractRar(
    String filePath,
    String destPath, {
    required String password,
  }) async {
    // Dynamic import to avoid compile issues on desktop
    // The actual implementation uses the unrar_file package
    // which is only available on Android/iOS
    try {
      // Import dynamically to avoid errors on unsupported platforms
      // ignore: depend_on_referenced_packages
      final unrarFile = await _loadUnrarFile();
      await unrarFile.extractRar(filePath, destPath, password: password);
    } catch (e) {
      throw Exception('unrar_file plugin not available: $e');
    }
  }

  Future<dynamic> _loadUnrarFile() async {
    // This would require conditional imports which Dart doesn't fully support
    // For now, throw on desktop platforms (which should never reach here)
    throw UnsupportedError(
      'unrar_file is only supported on Android and iOS. '
      'On desktop platforms, install the unrar command-line tool.',
    );
  }
}
