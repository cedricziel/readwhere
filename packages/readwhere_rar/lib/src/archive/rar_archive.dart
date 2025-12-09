import 'dart:io';
import 'dart:typed_data';

import '../constants.dart';
import '../decompress/rar_decompressor.dart';
import '../errors/rar_exception.dart';
import '../utils/crc.dart';
import 'rar_file_entry.dart';
import 'rar_parser.dart';

/// High-level RAR 4.x archive reader with decompression support.
///
/// This is a pure Dart implementation that reads RAR 4.x archives.
/// Both uncompressed (STORE) and compressed files can be extracted.
/// Compressed files are decompressed using the Rar29 algorithm.
///
/// ## Example
///
/// ```dart
/// final archive = await RarArchive.fromFile('archive.rar');
///
/// // List all files
/// for (final file in archive.files) {
///   print('${file.path}: ${file.size} bytes');
/// }
///
/// // Check for unsupported files
/// if (archive.unsupportedFiles.isNotEmpty) {
///   print('Warning: ${archive.unsupportedFiles.length} files use compression');
/// }
///
/// // Read a file (only works for STORE files)
/// if (archive.files.first.canExtract) {
///   final bytes = archive.readFileBytes(archive.files.first.path);
/// }
/// ```
class RarArchive {
  final Uint8List _bytes;
  final RarParser _parser;
  Map<String, RarFileEntry>? _fileIndex;

  RarArchive._(this._bytes, this._parser);

  /// Opens a RAR archive from a file path.
  ///
  /// Throws [RarReadException] if the file cannot be read.
  /// Throws [RarFormatException] if the file is not a valid RAR 4.x archive.
  /// Throws [RarVersionException] if the file is a RAR 5.x archive.
  /// Throws [RarEncryptedArchiveException] if the archive has encrypted headers.
  static Future<RarArchive> fromFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw RarReadException('File not found: $path', filePath: path);
    }

    try {
      final bytes = await file.readAsBytes();
      return fromBytes(bytes, filePath: path);
    } catch (e, st) {
      if (e is RarException) rethrow;
      throw RarReadException(
        'Failed to read file: $e',
        filePath: path,
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Opens a RAR archive from a [File] object.
  ///
  /// Throws [RarReadException] if the file cannot be read.
  /// Throws [RarFormatException] if the file is not a valid RAR 4.x archive.
  static Future<RarArchive> fromFileObject(File file) async {
    return fromFile(file.path);
  }

  /// Opens a RAR archive from raw bytes.
  ///
  /// Throws [RarFormatException] if the bytes are not a valid RAR 4.x archive.
  /// Throws [RarVersionException] if this is a RAR 5.x archive.
  /// Throws [RarEncryptedArchiveException] if the archive has encrypted headers.
  static RarArchive fromBytes(Uint8List bytes, {String? filePath}) {
    try {
      final parser = RarParser.fromBytes(bytes);
      parser.parse();
      return RarArchive._(bytes, parser);
    } on RarException {
      rethrow;
    } catch (e, st) {
      throw RarReadException(
        'Failed to parse RAR archive: $e',
        filePath: filePath,
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Quick check if bytes appear to be a RAR archive.
  ///
  /// This only checks the magic signature, not the full validity.
  static bool isRarArchive(Uint8List bytes) {
    if (bytes.length < 7) return false;

    // Check RAR 4.x signature
    for (var i = 0; i < 7; i++) {
      if (bytes[i] != kRar4Magic[i]) {
        // Also check RAR 5.x
        if (bytes.length >= 8) {
          var isRar5 = true;
          for (var j = 0; j < 8; j++) {
            if (bytes[j] != kRar5Magic[j]) {
              isRar5 = false;
              break;
            }
          }
          return isRar5;
        }
        return false;
      }
    }
    return true;
  }

  /// Index for fast file lookups by path.
  Map<String, RarFileEntry> get _index {
    _fileIndex ??= {for (final file in _parser.files) file.path: file};
    return _fileIndex!;
  }

  /// All file entries in the archive.
  List<RarFileEntry> get files => _parser.files;

  /// All file paths in the archive.
  List<String> get filePaths => _parser.files.map((f) => f.path).toList();

  /// Number of files in the archive.
  int get fileCount => _parser.files.length;

  /// Files that can be extracted (STORE method, not encrypted).
  List<RarFileEntry> get extractableFiles => _parser.extractableFiles;

  /// Number of extractable files.
  int get extractableCount => extractableFiles.length;

  /// Files that use unsupported compression methods.
  List<RarFileEntry> get unsupportedFiles => _parser.unsupportedFiles;

  /// Files that are encrypted.
  List<RarFileEntry> get encryptedFiles => _parser.encryptedFiles;

  /// Whether all files in the archive can be extracted.
  bool get allFilesExtractable =>
      unsupportedFiles.isEmpty && encryptedFiles.isEmpty;

  /// Whether this is a solid archive.
  bool get isSolid => _parser.isSolid;

  /// Whether this is part of a multi-volume archive.
  bool get isMultiVolume => _parser.isMultiVolume;

  /// Gets files with specific extensions (case-insensitive).
  ///
  /// Extensions should include the dot (e.g., ".jpg", ".png").
  List<RarFileEntry> getFilesByExtensions(Set<String> extensions) {
    final lowerExt = extensions.map((e) => e.toLowerCase()).toSet();
    return files.where((f) => lowerExt.contains(f.extension)).toList();
  }

  /// Gets files matching a predicate.
  List<RarFileEntry> getFilesWhere(bool Function(RarFileEntry) test) {
    return files.where(test).toList();
  }

  /// Checks if a file exists in the archive.
  bool hasFile(String path) {
    final normalized = _normalizePath(path);
    return _index.containsKey(normalized);
  }

  /// Gets a file entry by path.
  ///
  /// Returns null if the file doesn't exist.
  RarFileEntry? getFile(String path) {
    final normalized = _normalizePath(path);
    return _index[normalized];
  }

  /// Gets the uncompressed size of a file.
  ///
  /// Returns null if the file doesn't exist.
  int? getFileSize(String path) => getFile(path)?.size;

  /// Reads file bytes from the archive.
  ///
  /// Only works for STORE (uncompressed) files.
  ///
  /// Throws [RarFileNotFoundException] if the file doesn't exist.
  /// Throws [RarUnsupportedCompressionException] if the file uses compression.
  /// Throws [RarEncryptedArchiveException] if the file is encrypted.
  /// Throws [RarCrcException] if CRC verification fails.
  Uint8List readFileBytes(String path) {
    final entry = getFile(path);
    if (entry == null) {
      throw RarFileNotFoundException(path);
    }

    return readFileBytesFromEntry(entry);
  }

  /// Reads file bytes from a file entry.
  ///
  /// Works for both STORE (uncompressed) and compressed files.
  /// Compressed files are decompressed using the Rar29 algorithm.
  ///
  /// Throws [RarEncryptedArchiveException] if the file is encrypted.
  /// Throws [RarCrcException] if CRC verification fails.
  Uint8List readFileBytesFromEntry(RarFileEntry entry) {
    if (entry.isEncrypted) {
      throw RarEncryptedArchiveException(
        'File is encrypted: ${entry.path}',
        isHeaderEncrypted: false,
      );
    }

    if (!entry.canExtract) {
      throw RarReadException(
        'Cannot extract file: ${entry.path}',
        filePath: entry.path,
      );
    }

    // Read compressed/raw data from archive
    final dataOffset = entry.dataOffset;
    final dataSize = entry.packedSize;

    if (dataOffset + dataSize > _bytes.length) {
      throw RarReadException(
        'File data extends beyond archive bounds: ${entry.path}',
        filePath: entry.path,
      );
    }

    final packedData = Uint8List.sublistView(
      _bytes,
      dataOffset,
      dataOffset + dataSize,
    );

    Uint8List fileBytes;

    if (entry.needsDecompression) {
      // Decompress the data
      try {
        final decompressor = Rar29Decompressor(packedData, entry.size);
        fileBytes = decompressor.decompress();
      } catch (e) {
        throw RarReadException(
          'Decompression failed for ${entry.path}: $e',
          filePath: entry.path,
          cause: e,
        );
      }
    } else {
      // STORE - use raw bytes
      fileBytes = packedData;
    }

    // Verify CRC32
    final actualCrc = Crc32.calculate(fileBytes);
    if (actualCrc != entry.crc32) {
      throw RarCrcException(
        'CRC32 verification failed for file: ${entry.path}',
        fileName: entry.path,
        expected: entry.crc32,
        actual: actualCrc,
      );
    }

    return fileBytes;
  }

  /// Reads file as UTF-8 string.
  ///
  /// Only works for STORE (uncompressed) files.
  ///
  /// Throws the same exceptions as [readFileBytes].
  String readFileString(String path) {
    final bytes = readFileBytes(path);
    return String.fromCharCodes(bytes);
  }

  /// Tries to read file bytes, returning null on failure.
  ///
  /// This is a convenience method that catches all exceptions and returns null.
  /// Use [readFileBytes] if you need to handle specific error cases.
  Uint8List? tryReadFileBytes(String path) {
    try {
      return readFileBytes(path);
    } catch (_) {
      return null;
    }
  }

  /// Normalizes a path for index lookup.
  static String _normalizePath(String path) {
    var normalized = path.replaceAll('\\', '/');
    while (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    return normalized;
  }
}
