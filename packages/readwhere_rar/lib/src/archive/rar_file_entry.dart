import 'package:equatable/equatable.dart';
import 'package:path/path.dart' as p;

import 'rar_block.dart';

/// Represents a file entry in a RAR archive.
///
/// Provides a high-level view of a file's metadata and extraction status.
class RarFileEntry extends Equatable {
  /// The underlying file header block.
  final RarFileBlock block;

  /// Normalized path with forward slashes and no leading slash.
  final String path;

  /// Just the filename without directory path.
  final String fileName;

  /// File extension in lowercase with leading dot (e.g., ".jpg").
  final String extension;

  /// Creates a new [RarFileEntry] from a file block.
  RarFileEntry(this.block)
      : path = _normalizePath(block.fileName),
        fileName = _extractFileName(block.fileName),
        extension = _extractExtension(block.fileName);

  /// Unpacked (original) file size in bytes.
  int get size => block.unpackedSize;

  /// Packed (compressed) size in bytes.
  int get packedSize => block.packedSize;

  /// CRC32 checksum of the unpacked file.
  int get crc32 => block.fileCrc;

  /// Whether this file can be extracted (STORE method, not encrypted, not directory).
  bool get canExtract =>
      block.isStored && !block.isEncrypted && !block.isDirectory;

  /// Whether this file uses unsupported compression.
  bool get hasUnsupportedCompression =>
      block.isCompressed && !block.isDirectory;

  /// Whether this file's data is encrypted.
  bool get isEncrypted => block.isEncrypted;

  /// Whether this is a directory entry.
  bool get isDirectory => block.isDirectory;

  /// Whether the file is split across volumes.
  bool get isSplit => block.isSplitBefore || block.isSplitAfter;

  /// Position in archive where file data starts.
  int get dataOffset => block.dataOffset;

  /// File modification time.
  DateTime get modificationTime => block.modificationTime;

  /// Compression method code.
  int get compressionMethod => block.compressionMethod;

  /// Human-readable compression method name.
  String get compressionMethodName => block.compressionMethodName;

  /// Host operating system name.
  String get hostOsName => block.hostOsName;

  /// Normalizes a path to use forward slashes and no leading slash.
  static String _normalizePath(String path) {
    var normalized = path.replaceAll('\\', '/');
    while (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    return normalized;
  }

  /// Extracts just the filename from a path.
  static String _extractFileName(String path) {
    return p.basename(_normalizePath(path));
  }

  /// Extracts the file extension in lowercase.
  static String _extractExtension(String path) {
    return p.extension(_normalizePath(path)).toLowerCase();
  }

  @override
  List<Object?> get props => [path, size, crc32, compressionMethod];

  @override
  String toString() {
    return 'RarFileEntry('
        'path: $path, '
        'size: $size, '
        'method: $compressionMethodName, '
        'canExtract: $canExtract)';
  }
}
