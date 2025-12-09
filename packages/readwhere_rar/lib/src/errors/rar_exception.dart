/// Exception classes for RAR archive operations.
///
/// Uses sealed class pattern for exhaustive handling of error cases.
library;

/// Base exception for all RAR-related errors.
sealed class RarException implements Exception {
  /// Human-readable error message.
  String get message;

  /// The underlying cause of the exception, if any.
  Object? get cause;

  /// Stack trace from the underlying cause, if any.
  StackTrace? get stackTrace;

  @override
  String toString() => 'RarException: $message';
}

/// Exception thrown when reading or parsing a RAR file fails.
///
/// This includes file I/O errors and general parsing failures.
class RarReadException extends RarException {
  @override
  final String message;

  @override
  final Object? cause;

  @override
  final StackTrace? stackTrace;

  /// The file path that failed to read, if known.
  final String? filePath;

  /// Creates a new [RarReadException].
  RarReadException(
    this.message, {
    this.filePath,
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('RarReadException: $message');
    if (filePath != null) {
      buffer.write(' (file: $filePath)');
    }
    return buffer.toString();
  }
}

/// Exception thrown when the archive format is invalid.
///
/// This includes missing or invalid magic signatures, corrupted block headers,
/// and other structural problems with the archive.
class RarFormatException extends RarException {
  @override
  final String message;

  @override
  final Object? cause;

  @override
  final StackTrace? stackTrace;

  /// Position in the file where the error was detected.
  final int? offset;

  /// Creates a new [RarFormatException].
  RarFormatException(
    this.message, {
    this.offset,
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('RarFormatException: $message');
    if (offset != null) {
      buffer.write(' (at offset $offset)');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a file in the archive uses unsupported compression.
///
/// This library only supports STORE (0x30) method. Files using compression
/// methods 0x31-0x35 cannot be extracted.
class RarUnsupportedCompressionException extends RarException {
  @override
  final String message;

  @override
  Object? get cause => null;

  @override
  StackTrace? get stackTrace => null;

  /// The name of the file that uses unsupported compression.
  final String fileName;

  /// The compression method used (0x31-0x35).
  final int compressionMethod;

  /// Creates a new [RarUnsupportedCompressionException].
  RarUnsupportedCompressionException(
    this.message, {
    required this.fileName,
    required this.compressionMethod,
  });

  @override
  String toString() => 'RarUnsupportedCompressionException: $message '
      '(file: $fileName, method: 0x${compressionMethod.toRadixString(16)})';
}

/// Exception thrown when the archive or file is encrypted.
///
/// Encrypted archives and files are not supported by this library.
class RarEncryptedArchiveException extends RarException {
  @override
  final String message;

  @override
  Object? get cause => null;

  @override
  StackTrace? get stackTrace => null;

  /// True if the archive headers are encrypted, false if just file data.
  final bool isHeaderEncrypted;

  /// Creates a new [RarEncryptedArchiveException].
  RarEncryptedArchiveException(
    this.message, {
    required this.isHeaderEncrypted,
  });

  @override
  String toString() {
    final type = isHeaderEncrypted ? 'header' : 'file';
    return 'RarEncryptedArchiveException: $message ($type encryption)';
  }
}

/// Exception thrown when a requested file is not found in the archive.
class RarFileNotFoundException extends RarException {
  @override
  String get message => 'File not found in archive: $fileName';

  @override
  Object? get cause => null;

  @override
  StackTrace? get stackTrace => null;

  /// The name of the file that was not found.
  final String fileName;

  /// Creates a new [RarFileNotFoundException].
  RarFileNotFoundException(this.fileName);

  @override
  String toString() => 'RarFileNotFoundException: $message';
}

/// Exception thrown when CRC verification fails.
///
/// This indicates data corruption in the archive.
class RarCrcException extends RarException {
  @override
  final String message;

  @override
  Object? get cause => null;

  @override
  StackTrace? get stackTrace => null;

  /// The file name where CRC mismatch occurred, if applicable.
  final String? fileName;

  /// Expected CRC value.
  final int expected;

  /// Actual CRC value.
  final int actual;

  /// Creates a new [RarCrcException].
  RarCrcException(
    this.message, {
    this.fileName,
    required this.expected,
    required this.actual,
  });

  @override
  String toString() {
    final buffer = StringBuffer('RarCrcException: $message');
    if (fileName != null) {
      buffer.write(' (file: $fileName)');
    }
    buffer.write(' expected: 0x${expected.toRadixString(16)},');
    buffer.write(' actual: 0x${actual.toRadixString(16)}');
    return buffer.toString();
  }
}

/// Exception thrown when the archive is a RAR 5.x format.
///
/// This library only supports RAR 4.x format.
class RarVersionException extends RarException {
  @override
  final String message;

  @override
  Object? get cause => null;

  @override
  StackTrace? get stackTrace => null;

  /// The detected RAR version.
  final int version;

  /// Creates a new [RarVersionException].
  RarVersionException(
    this.message, {
    required this.version,
  });

  @override
  String toString() => 'RarVersionException: $message (version: $version)';
}
