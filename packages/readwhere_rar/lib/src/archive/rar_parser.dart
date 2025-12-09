import 'dart:typed_data';

import '../constants.dart';
import '../errors/rar_exception.dart';
import '../utils/binary_reader.dart';
import 'rar_block.dart';
import 'rar_file_entry.dart';

/// Parses RAR 4.x archive structure from bytes.
///
/// This parser reads the archive structure and extracts file metadata.
/// It does not decompress files - only STORE method files can be extracted.
class RarParser {
  final BinaryReader _reader;
  final Uint8List _bytes;
  RarArchiveBlock? _archiveHeader;
  final List<RarFileEntry> _files = [];
  bool _parsed = false;

  RarParser._(this._bytes) : _reader = BinaryReader(_bytes);

  /// Creates a parser from raw bytes.
  ///
  /// Throws [RarFormatException] if this is not a valid RAR 4.x archive.
  /// Throws [RarVersionException] if this is a RAR 5.x archive.
  factory RarParser.fromBytes(Uint8List bytes) {
    final parser = RarParser._(bytes);
    parser._validateMagic();
    return parser;
  }

  /// Validates the RAR magic signature.
  void _validateMagic() {
    if (_bytes.length < 7) {
      throw RarFormatException(
        'File too small to be a RAR archive',
        offset: 0,
      );
    }

    // Check for RAR5 first (8 bytes)
    if (_bytes.length >= 8) {
      var isRar5 = true;
      for (var i = 0; i < 8; i++) {
        if (_bytes[i] != kRar5Magic[i]) {
          isRar5 = false;
          break;
        }
      }
      if (isRar5) {
        throw RarVersionException(
          'RAR 5.x format is not supported. This library only supports RAR 4.x.',
          version: 5,
        );
      }
    }

    // Check for RAR4 (7 bytes)
    var isRar4 = true;
    for (var i = 0; i < 7; i++) {
      if (_bytes[i] != kRar4Magic[i]) {
        isRar4 = false;
        break;
      }
    }
    if (!isRar4) {
      throw RarFormatException(
        'Invalid RAR signature. Expected RAR 4.x magic bytes.',
        offset: 0,
      );
    }
  }

  /// Parses the entire archive structure.
  ///
  /// Throws [RarEncryptedArchiveException] if headers are encrypted.
  void parse() {
    if (_parsed) return;

    // Skip past the magic signature
    _reader.seek(7);

    while (_reader.hasRemaining) {
      final blockStartOffset = _reader.position;

      try {
        final block = _parseBlock(blockStartOffset);

        if (block is RarArchiveBlock) {
          _archiveHeader = block;
          if (block.hasEncryptedHeaders) {
            throw RarEncryptedArchiveException(
              'Archive has encrypted headers. Cannot read file list.',
              isHeaderEncrypted: true,
            );
          }
        } else if (block is RarFileBlock) {
          if (!block.isDirectory) {
            _files.add(RarFileEntry(block));
          }
        } else if (block is RarEndArchiveBlock) {
          break;
        }

        // Move to next block
        _reader.seek(block.nextBlockOffset);
      } catch (e) {
        if (e is RarException) rethrow;
        throw RarFormatException(
          'Failed to parse block at offset $blockStartOffset: $e',
          offset: blockStartOffset,
          cause: e,
        );
      }
    }

    _parsed = true;
  }

  /// Parses a single block header.
  RarBlock _parseBlock(int startOffset) {
    // Minimum block header: CRC(2) + Type(1) + Flags(2) + Size(2) = 7 bytes
    if (_reader.remaining < 7) {
      throw RarFormatException(
        'Incomplete block header',
        offset: startOffset,
      );
    }

    final headerCrc = _reader.readUint16();
    final blockType = _reader.readUint8();
    final flags = _reader.readUint16();
    final headerSize = _reader.readUint16();

    // Read optional ADD_SIZE for non-file blocks.
    // For FILE blocks (0x74), the flag 0x8000 means header size is complete,
    // and packed size comes from the file-specific fields, not ADD_SIZE.
    int? addSize;
    if ((flags & 0x8000) != 0 && blockType != RarBlockType.file) {
      if (_reader.remaining < 4) {
        throw RarFormatException(
          'Incomplete ADD_SIZE field',
          offset: _reader.position,
        );
      }
      addSize = _reader.readUint32();
    }

    switch (blockType) {
      case RarBlockType.marker:
        return RarMarkerBlock(
          headerCrc: headerCrc,
          blockType: blockType,
          flags: flags,
          headerSize: headerSize,
          addSize: addSize,
          fileOffset: startOffset,
        );

      case RarBlockType.archive:
        return _parseArchiveBlock(
          headerCrc: headerCrc,
          blockType: blockType,
          flags: flags,
          headerSize: headerSize,
          addSize: addSize,
          fileOffset: startOffset,
        );

      case RarBlockType.file:
        return _parseFileBlock(
          headerCrc: headerCrc,
          blockType: blockType,
          flags: flags,
          headerSize: headerSize,
          addSize: addSize,
          fileOffset: startOffset,
        );

      case RarBlockType.endArchive:
        return _parseEndArchiveBlock(
          headerCrc: headerCrc,
          blockType: blockType,
          flags: flags,
          headerSize: headerSize,
          addSize: addSize,
          fileOffset: startOffset,
        );

      default:
        // Unknown block type - just skip it
        return RarUnknownBlock(
          headerCrc: headerCrc,
          blockType: blockType,
          flags: flags,
          headerSize: headerSize,
          addSize: addSize,
          fileOffset: startOffset,
        );
    }
  }

  /// Parses the main archive header block.
  RarArchiveBlock _parseArchiveBlock({
    required int headerCrc,
    required int blockType,
    required int flags,
    required int headerSize,
    int? addSize,
    required int fileOffset,
  }) {
    // Archive header has: reserved1(2) + reserved2(4) + archiveFlags is in flags
    // Actually, the archive flags are already in the 'flags' field for this block
    // Reserved fields follow
    final reserved1 = _reader.remaining >= 2 ? _reader.readUint16() : 0;
    final reserved2 = _reader.remaining >= 4 ? _reader.readUint32() : 0;

    return RarArchiveBlock(
      headerCrc: headerCrc,
      blockType: blockType,
      flags: flags,
      headerSize: headerSize,
      addSize: addSize,
      fileOffset: fileOffset,
      archiveFlags: flags, // Archive flags are in the main flags field
      reserved1: reserved1,
      reserved2: reserved2,
    );
  }

  /// Parses a file header block.
  RarFileBlock _parseFileBlock({
    required int headerCrc,
    required int blockType,
    required int flags,
    required int headerSize,
    int? addSize,
    required int fileOffset,
  }) {
    // File header structure:
    // PackedSize(4) + UnpackedSize(4) + HostOS(1) + FileCRC(4) +
    // FileTime(4) + UnpackVersion(1) + Method(1) + NameSize(2) + Attr(4)
    // = 25 bytes minimum

    final packedSizeLow = _reader.readUint32();
    final unpackedSizeLow = _reader.readUint32();
    final hostOs = _reader.readUint8();
    final fileCrc = _reader.readUint32();
    final fileTime = _reader.readUint32();
    final unpackVersion = _reader.readUint8();
    final compressionMethod = _reader.readUint8();
    final nameSize = _reader.readUint16();
    final fileAttributes = _reader.readUint32();

    // High parts for large files
    int? packedSizeHigh;
    int? unpackedSizeHigh;
    if ((flags & RarFileFlags.largeFile) != 0) {
      packedSizeHigh = _reader.readUint32();
      unpackedSizeHigh = _reader.readUint32();
    }

    // Read filename
    final fileNameBytes = _reader.readBytes(nameSize);
    final fileName = _decodeFileName(fileNameBytes, flags);

    // Read salt if encrypted
    Uint8List? salt;
    if ((flags & RarFileFlags.salt) != 0) {
      salt = _reader.readBytes(8);
    }

    // Read extended time if present
    Uint8List? extTime;
    if ((flags & RarFileFlags.extTime) != 0) {
      // Extended time has variable length, calculate remaining header bytes
      final currentPos = _reader.position;
      final headerEnd = fileOffset + headerSize;
      if (currentPos < headerEnd) {
        final extTimeSize = headerEnd - currentPos;
        extTime = _reader.readBytes(extTimeSize);
      }
    }

    // For FILE blocks, addSize is the packed size (from file-specific fields)
    final computedAddSize = addSize ??
        (packedSizeHigh != null
            ? ((packedSizeHigh << 32) | packedSizeLow)
            : packedSizeLow);

    return RarFileBlock(
      headerCrc: headerCrc,
      blockType: blockType,
      flags: flags,
      headerSize: headerSize,
      addSize: computedAddSize,
      fileOffset: fileOffset,
      packedSizeLow: packedSizeLow,
      unpackedSizeLow: unpackedSizeLow,
      hostOs: hostOs,
      fileCrc: fileCrc,
      fileTime: fileTime,
      unpackVersion: unpackVersion,
      compressionMethod: compressionMethod,
      nameSize: nameSize,
      fileAttributes: fileAttributes,
      packedSizeHigh: packedSizeHigh,
      unpackedSizeHigh: unpackedSizeHigh,
      fileName: fileName,
      fileNameBytes: fileNameBytes,
      salt: salt,
      extTime: extTime,
    );
  }

  /// Parses end of archive block.
  RarEndArchiveBlock _parseEndArchiveBlock({
    required int headerCrc,
    required int blockType,
    required int flags,
    required int headerSize,
    int? addSize,
    required int fileOffset,
  }) {
    // End flags may be present
    var endFlags = 0;
    if (_reader.remaining >= 2) {
      // Check if we're still within the header
      final headerEnd = fileOffset + headerSize;
      if (_reader.position < headerEnd) {
        endFlags = flags; // End flags are in the main flags
      }
    }

    return RarEndArchiveBlock(
      headerCrc: headerCrc,
      blockType: blockType,
      flags: flags,
      headerSize: headerSize,
      addSize: addSize,
      fileOffset: fileOffset,
      endFlags: endFlags,
    );
  }

  /// Decodes a filename from bytes, handling unicode if present.
  String _decodeFileName(Uint8List bytes, int flags) {
    if ((flags & RarFileFlags.unicode) == 0) {
      // Simple ASCII/CP437 name
      return String.fromCharCodes(bytes);
    }

    // Unicode name follows a zero byte after the base name
    final zeroIndex = bytes.indexOf(0);
    if (zeroIndex == -1 || zeroIndex == bytes.length - 1) {
      // No unicode data or no base name
      return String.fromCharCodes(bytes);
    }

    // Decode the Unicode portion
    // RAR uses a custom delta encoding for Unicode names
    return _decodeRarUnicode(bytes, zeroIndex);
  }

  /// Decodes RAR's custom unicode filename encoding.
  ///
  /// RAR stores Unicode names as a base ASCII name followed by delta-encoded
  /// Unicode characters.
  String _decodeRarUnicode(Uint8List bytes, int baseNameEnd) {
    // Get the base name (before the null)
    final baseName = String.fromCharCodes(bytes.sublist(0, baseNameEnd));

    // Unicode data starts after the null byte
    final unicodeStart = baseNameEnd + 1;
    if (unicodeStart >= bytes.length) {
      return baseName;
    }

    // Build the unicode name
    final result = StringBuffer();
    var highByte = 0;
    var flagByte = 0;
    var flagBits = 0;
    var pos = unicodeStart;
    var namePos = 0;

    while (pos < bytes.length && namePos < baseName.length * 2) {
      if (flagBits == 0) {
        flagByte = bytes[pos++];
        flagBits = 8;
      }

      flagBits -= 2;
      final mode = (flagByte >> flagBits) & 3;

      switch (mode) {
        case 0:
          // Use base name character
          if (namePos < baseName.length) {
            result.write(baseName[namePos++]);
          }
          break;

        case 1:
          // Use base name character with high byte
          if (namePos < baseName.length && pos < bytes.length) {
            final code = (highByte << 8) | baseName.codeUnitAt(namePos++);
            result.writeCharCode(code);
          }
          break;

        case 2:
          // Read 2-byte Unicode character
          if (pos + 1 < bytes.length) {
            final low = bytes[pos++];
            final high = bytes[pos++];
            result.writeCharCode((high << 8) | low);
          }
          namePos++;
          break;

        case 3:
          // Read new high byte and use base name character
          if (pos < bytes.length) {
            highByte = bytes[pos++];
            if (namePos < baseName.length) {
              final code = (highByte << 8) | baseName.codeUnitAt(namePos++);
              result.writeCharCode(code);
            }
          }
          break;
      }
    }

    return result.toString();
  }

  /// Archive header information.
  RarArchiveBlock? get archiveHeader => _archiveHeader;

  /// All file entries in the archive.
  List<RarFileEntry> get files => List.unmodifiable(_files);

  /// File entries that can be extracted (STORE, not encrypted).
  List<RarFileEntry> get extractableFiles =>
      _files.where((f) => f.canExtract).toList();

  /// File entries with unsupported compression.
  List<RarFileEntry> get unsupportedFiles =>
      _files.where((f) => f.hasUnsupportedCompression).toList();

  /// File entries that are encrypted.
  List<RarFileEntry> get encryptedFiles =>
      _files.where((f) => f.isEncrypted).toList();

  /// Whether the archive is a solid archive.
  bool get isSolid => _archiveHeader?.isSolid ?? false;

  /// Whether the archive is part of a multi-volume set.
  bool get isMultiVolume => _archiveHeader?.isVolume ?? false;
}
