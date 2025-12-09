import 'dart:typed_data';

import '../constants.dart';

/// Base class for RAR 4.x block headers.
///
/// All RAR blocks share a common header structure:
/// - CRC16 (2 bytes): Checksum of header data after CRC field
/// - Type (1 byte): Block type identifier
/// - Flags (2 bytes): Block-specific flags
/// - Size (2 bytes): Header size in bytes
/// - AddSize (4 bytes, optional): Additional data size if flag 0x8000 set
sealed class RarBlock {
  /// CRC16 checksum of header data (from type field to end of header).
  final int headerCrc;

  /// Block type identifier.
  final int blockType;

  /// Block flags.
  final int flags;

  /// Header size in bytes (includes CRC, type, flags, size, and optional fields).
  final int headerSize;

  /// Additional data size following the header (if flag 0x8000 is set).
  final int? addSize;

  /// Position in the archive file where this block starts.
  final int fileOffset;

  const RarBlock({
    required this.headerCrc,
    required this.blockType,
    required this.flags,
    required this.headerSize,
    this.addSize,
    required this.fileOffset,
  });

  /// Whether the block has additional data following the header.
  bool get hasAddSize => (flags & 0x8000) != 0;

  /// Total size of the block (header + additional data).
  int get totalSize => headerSize + (addSize ?? 0);

  /// Position where the next block starts.
  int get nextBlockOffset => fileOffset + totalSize;

  /// Human-readable block type name.
  String get typeName => RarBlockType.nameOf(blockType);
}

/// Marker block (archive signature).
///
/// This is always the first block in a RAR archive and contains the
/// magic signature bytes.
class RarMarkerBlock extends RarBlock {
  const RarMarkerBlock({
    required super.headerCrc,
    required super.blockType,
    required super.flags,
    required super.headerSize,
    super.addSize,
    required super.fileOffset,
  });
}

/// Main archive header block.
///
/// Contains archive-level information and flags.
class RarArchiveBlock extends RarBlock {
  /// Archive flags (multivolume, solid, encrypted headers, etc.).
  final int archiveFlags;

  /// Reserved bytes (usually 0).
  final int reserved1;
  final int reserved2;

  const RarArchiveBlock({
    required super.headerCrc,
    required super.blockType,
    required super.flags,
    required super.headerSize,
    super.addSize,
    required super.fileOffset,
    required this.archiveFlags,
    this.reserved1 = 0,
    this.reserved2 = 0,
  });

  /// Whether this is part of a multi-volume archive.
  bool get isVolume => (archiveFlags & RarArchiveFlags.isVolume) != 0;

  /// Whether the archive has a comment.
  bool get hasComment => (archiveFlags & RarArchiveFlags.hasComment) != 0;

  /// Whether the archive is locked.
  bool get isLocked => (archiveFlags & RarArchiveFlags.isLocked) != 0;

  /// Whether this is a solid archive.
  bool get isSolid => (archiveFlags & RarArchiveFlags.isSolid) != 0;

  /// Whether the archive uses new volume naming scheme.
  bool get hasNewNaming => (archiveFlags & RarArchiveFlags.hasNewNaming) != 0;

  /// Whether authenticity information is present.
  bool get hasAuthInfo => (archiveFlags & RarArchiveFlags.hasAuthInfo) != 0;

  /// Whether a recovery record is present.
  bool get hasRecovery => (archiveFlags & RarArchiveFlags.hasRecovery) != 0;

  /// Whether block headers are encrypted.
  bool get hasEncryptedHeaders =>
      (archiveFlags & RarArchiveFlags.hasEncryptedHeaders) != 0;

  /// Whether this is the first volume.
  bool get isFirstVolume => (archiveFlags & RarArchiveFlags.isFirstVolume) != 0;
}

/// File header block.
///
/// Contains information about a file stored in the archive.
class RarFileBlock extends RarBlock {
  /// Packed (compressed) size - lower 32 bits.
  final int packedSizeLow;

  /// Unpacked (original) size - lower 32 bits.
  final int unpackedSizeLow;

  /// Host operating system.
  final int hostOs;

  /// CRC32 of unpacked file data.
  final int fileCrc;

  /// File modification time in DOS format.
  final int fileTime;

  /// RAR version needed to extract.
  final int unpackVersion;

  /// Compression method (0x30 = store, 0x31-0x35 = compressed).
  final int compressionMethod;

  /// Filename size in bytes.
  final int nameSize;

  /// File attributes.
  final int fileAttributes;

  /// Packed size - high 32 bits (for files > 4GB).
  final int? packedSizeHigh;

  /// Unpacked size - high 32 bits (for files > 4GB).
  final int? unpackedSizeHigh;

  /// Filename (may be in various encodings).
  final String fileName;

  /// Raw filename bytes (for unicode decoding).
  final Uint8List fileNameBytes;

  /// Salt for encryption (if encrypted).
  final Uint8List? salt;

  /// Extended time information.
  final Uint8List? extTime;

  const RarFileBlock({
    required super.headerCrc,
    required super.blockType,
    required super.flags,
    required super.headerSize,
    super.addSize,
    required super.fileOffset,
    required this.packedSizeLow,
    required this.unpackedSizeLow,
    required this.hostOs,
    required this.fileCrc,
    required this.fileTime,
    required this.unpackVersion,
    required this.compressionMethod,
    required this.nameSize,
    required this.fileAttributes,
    this.packedSizeHigh,
    this.unpackedSizeHigh,
    required this.fileName,
    required this.fileNameBytes,
    this.salt,
    this.extTime,
  });

  /// Full packed size (combining high and low parts).
  int get packedSize {
    if (packedSizeHigh != null) {
      return (packedSizeHigh! << 32) | packedSizeLow;
    }
    return packedSizeLow;
  }

  /// Full unpacked size (combining high and low parts).
  int get unpackedSize {
    if (unpackedSizeHigh != null) {
      return (unpackedSizeHigh! << 32) | unpackedSizeLow;
    }
    return unpackedSizeLow;
  }

  /// Whether this file is stored without compression.
  bool get isStored => compressionMethod == RarCompressionMethod.store;

  /// Whether this file uses compression.
  bool get isCompressed => RarCompressionMethod.isCompressed(compressionMethod);

  /// Whether this file's data is encrypted.
  bool get isEncrypted => (flags & RarFileFlags.encrypted) != 0;

  /// Whether this is a directory entry.
  bool get isDirectory =>
      (flags & RarFileFlags.directory) == RarFileFlags.directory;

  /// Whether the file continues from the previous volume.
  bool get isSplitBefore => (flags & RarFileFlags.splitBefore) != 0;

  /// Whether the file continues in the next volume.
  bool get isSplitAfter => (flags & RarFileFlags.splitAfter) != 0;

  /// Whether this is a large file (> 4GB).
  bool get isLargeFile => (flags & RarFileFlags.largeFile) != 0;

  /// Whether the filename is unicode.
  bool get hasUnicode => (flags & RarFileFlags.unicode) != 0;

  /// Whether encryption salt is present.
  bool get hasSalt => (flags & RarFileFlags.salt) != 0;

  /// Whether extended time is present.
  bool get hasExtTime => (flags & RarFileFlags.extTime) != 0;

  /// Position in archive where file data starts.
  int get dataOffset => fileOffset + headerSize;

  /// Host OS name.
  String get hostOsName => RarHostOs.nameOf(hostOs);

  /// Compression method name.
  String get compressionMethodName =>
      RarCompressionMethod.nameOf(compressionMethod);

  /// File modification time as DateTime.
  DateTime get modificationTime => _dosTimeToDateTime(fileTime);

  /// Converts DOS time format to DateTime.
  static DateTime _dosTimeToDateTime(int dosTime) {
    final second = (dosTime & 0x1F) * 2;
    final minute = (dosTime >> 5) & 0x3F;
    final hour = (dosTime >> 11) & 0x1F;
    final day = (dosTime >> 16) & 0x1F;
    final month = (dosTime >> 21) & 0x0F;
    final year = ((dosTime >> 25) & 0x7F) + 1980;

    // Validate and clamp values
    final clampedMonth = month.clamp(1, 12);
    final clampedDay = day.clamp(1, 31);
    final clampedHour = hour.clamp(0, 23);
    final clampedMinute = minute.clamp(0, 59);
    final clampedSecond = second.clamp(0, 59);

    return DateTime(
      year,
      clampedMonth,
      clampedDay,
      clampedHour,
      clampedMinute,
      clampedSecond,
    );
  }
}

/// End of archive block.
///
/// Marks the end of the archive. May contain information about
/// subsequent volumes in multi-volume archives.
class RarEndArchiveBlock extends RarBlock {
  /// End of archive flags.
  final int endFlags;

  const RarEndArchiveBlock({
    required super.headerCrc,
    required super.blockType,
    required super.flags,
    required super.headerSize,
    super.addSize,
    required super.fileOffset,
    this.endFlags = 0,
  });

  /// Whether there is a next volume.
  bool get hasNextVolume => (endFlags & RarEndFlags.hasNextVolume) != 0;

  /// Whether data CRC is present.
  bool get hasDataCrc => (endFlags & RarEndFlags.hasDataCrc) != 0;
}

/// Unknown or unsupported block type.
///
/// Used for blocks that we don't need to parse but need to skip over.
class RarUnknownBlock extends RarBlock {
  const RarUnknownBlock({
    required super.headerCrc,
    required super.blockType,
    required super.flags,
    required super.headerSize,
    super.addSize,
    required super.fileOffset,
  });
}
