/// RAR archive format constants.
///
/// This file contains constants for parsing RAR 4.x archives including
/// magic signatures, block types, compression methods, and flags.
library;

import 'dart:typed_data';

/// RAR 4.x magic signature (7 bytes): "Rar!" + 0x1A 0x07 0x00
const List<int> kRar4Magic = [0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x00];

/// RAR 4.x magic as Uint8List for comparison.
final Uint8List kRar4MagicBytes = Uint8List.fromList(kRar4Magic);

/// RAR 5.x magic signature (8 bytes): "Rar!" + 0x1A 0x07 0x01 0x00
/// Used for detection and rejection with clear error message.
const List<int> kRar5Magic = [0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x01, 0x00];

/// RAR 5.x magic as Uint8List for comparison.
final Uint8List kRar5MagicBytes = Uint8List.fromList(kRar5Magic);

/// Block type constants for RAR 4.x archives.
abstract class RarBlockType {
  /// Marker block (archive signature).
  static const int marker = 0x72;

  /// Main archive header.
  static const int archive = 0x73;

  /// File header.
  static const int file = 0x74;

  /// Old-style comment header.
  static const int comment = 0x75;

  /// Old-style authenticity verification.
  static const int extra = 0x76;

  /// Old-style subblock.
  static const int subBlock = 0x77;

  /// Recovery record.
  static const int protect = 0x78;

  /// Old-style signature block.
  static const int sign = 0x79;

  /// New-style subblock (service header).
  static const int newSub = 0x7A;

  /// End of archive.
  static const int endArchive = 0x7B;

  /// Returns human-readable name for a block type.
  static String nameOf(int type) {
    return switch (type) {
      marker => 'MARKER',
      archive => 'ARCHIVE',
      file => 'FILE',
      comment => 'COMMENT',
      extra => 'EXTRA',
      subBlock => 'SUBBLOCK',
      protect => 'PROTECT',
      sign => 'SIGN',
      newSub => 'NEWSUB',
      endArchive => 'ENDARC',
      _ => 'UNKNOWN(0x${type.toRadixString(16)})',
    };
  }
}

/// Compression method constants.
abstract class RarCompressionMethod {
  /// Store (no compression) - the only method we support.
  static const int store = 0x30;

  /// Fastest compression.
  static const int fastest = 0x31;

  /// Fast compression.
  static const int fast = 0x32;

  /// Normal compression.
  static const int normal = 0x33;

  /// Good compression.
  static const int good = 0x34;

  /// Best compression.
  static const int best = 0x35;

  /// Returns true if the method is STORE (uncompressed).
  static bool isStore(int method) => method == store;

  /// Returns true if the method uses compression.
  static bool isCompressed(int method) => method >= fastest && method <= best;

  /// Returns human-readable name for a compression method.
  static String nameOf(int method) {
    return switch (method) {
      store => 'STORE',
      fastest => 'FASTEST',
      fast => 'FAST',
      normal => 'NORMAL',
      good => 'GOOD',
      best => 'BEST',
      _ => 'UNKNOWN(0x${method.toRadixString(16)})',
    };
  }
}

/// File header flags.
abstract class RarFileFlags {
  /// File continued from previous volume.
  static const int splitBefore = 0x0001;

  /// File continued in next volume.
  static const int splitAfter = 0x0002;

  /// File is encrypted.
  static const int encrypted = 0x0004;

  /// File comment present.
  static const int comment = 0x0008;

  /// Information from previous files is used (solid).
  static const int solid = 0x0010;

  /// Directory entry.
  static const int directory = 0x00E0;

  /// High 32 bits of file size present.
  static const int largeFile = 0x0100;

  /// Unicode filename present.
  static const int unicode = 0x0200;

  /// Salt for encryption present.
  static const int salt = 0x0400;

  /// Version number appended to filename.
  static const int version = 0x0800;

  /// Extended time field present.
  static const int extTime = 0x1000;

  /// Reserved for internal use.
  static const int reserved = 0x2000;

  /// ADD_SIZE field is present.
  static const int hasAddSize = 0x8000;
}

/// Archive header flags.
abstract class RarArchiveFlags {
  /// Volume attribute (archive is part of a multi-volume set).
  static const int isVolume = 0x0001;

  /// Archive comment present.
  static const int hasComment = 0x0002;

  /// Archive lock attribute.
  static const int isLocked = 0x0004;

  /// Solid attribute (all files use single dictionary).
  static const int isSolid = 0x0008;

  /// New volume naming scheme ('volname.partN.rar').
  static const int hasNewNaming = 0x0010;

  /// Authenticity information present.
  static const int hasAuthInfo = 0x0020;

  /// Recovery record present.
  static const int hasRecovery = 0x0040;

  /// Block headers are encrypted.
  static const int hasEncryptedHeaders = 0x0080;

  /// First volume.
  static const int isFirstVolume = 0x0100;

  /// ADD_SIZE field is present.
  static const int hasAddSize = 0x8000;
}

/// Host operating system constants.
abstract class RarHostOs {
  /// MS-DOS.
  static const int msDos = 0;

  /// OS/2.
  static const int os2 = 1;

  /// Windows.
  static const int windows = 2;

  /// Unix.
  static const int unix = 3;

  /// Mac OS (classic).
  static const int macOs = 4;

  /// BeOS.
  static const int beOs = 5;

  /// Returns human-readable name for a host OS.
  static String nameOf(int os) {
    return switch (os) {
      msDos => 'MS-DOS',
      os2 => 'OS/2',
      windows => 'Windows',
      unix => 'Unix',
      macOs => 'Mac OS',
      beOs => 'BeOS',
      _ => 'Unknown($os)',
    };
  }
}

/// End of archive flags.
abstract class RarEndFlags {
  /// Next volume exists.
  static const int hasNextVolume = 0x0001;

  /// Data CRC present.
  static const int hasDataCrc = 0x0002;

  /// Reserved for future use.
  static const int hasRevSpace = 0x0004;

  /// ADD_SIZE field is present.
  static const int hasAddSize = 0x8000;
}
