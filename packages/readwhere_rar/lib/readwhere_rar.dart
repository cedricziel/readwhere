/// A pure Dart library for reading RAR 4.x archives (STORE method only).
///
/// This library provides read-only access to RAR 4.x archives containing
/// uncompressed (STORE) files. It does NOT support:
/// - RAR 5.x format
/// - Compressed files (methods 0x31-0x35)
/// - Encrypted archives
/// - Multi-volume archives
///
/// ## Basic Usage
///
/// ```dart
/// import 'package:readwhere_rar/readwhere_rar.dart';
///
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
/// // Read a file
/// final bytes = archive.readFileBytes('image.jpg');
/// ```
library;

// Core API
export 'src/archive/rar_archive.dart';
export 'src/archive/rar_file_entry.dart';

// Errors
export 'src/errors/rar_exception.dart';

// Constants (for advanced usage)
export 'src/constants.dart' show RarCompressionMethod, RarBlockType, RarHostOs;
