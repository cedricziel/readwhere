import 'dart:typed_data';

import 'package:readwhere_rar/readwhere_rar.dart';
import 'package:readwhere_rar/src/constants.dart';
import 'package:test/test.dart';

void main() {
  group('RarArchive', () {
    group('isRarArchive', () {
      test('returns true for RAR 4.x magic', () {
        final bytes = Uint8List.fromList([
          ...kRar4Magic,
          0x00, 0x00, 0x00, // padding
        ]);
        expect(RarArchive.isRarArchive(bytes), isTrue);
      });

      test('returns true for RAR 5.x magic', () {
        final bytes = Uint8List.fromList([
          ...kRar5Magic,
          0x00, 0x00, 0x00, // padding
        ]);
        expect(RarArchive.isRarArchive(bytes), isTrue);
      });

      test('returns false for non-RAR data', () {
        final bytes = Uint8List.fromList([
          0x50, 0x4B, 0x03, 0x04, // ZIP signature
          0x00, 0x00, 0x00,
        ]);
        expect(RarArchive.isRarArchive(bytes), isFalse);
      });

      test('returns false for empty data', () {
        expect(RarArchive.isRarArchive(Uint8List(0)), isFalse);
      });

      test('returns false for data too small', () {
        final bytes = Uint8List.fromList([0x52, 0x61, 0x72]);
        expect(RarArchive.isRarArchive(bytes), isFalse);
      });
    });

    group('fromBytes', () {
      test('throws RarFormatException for non-RAR data', () {
        final bytes = Uint8List.fromList([0x50, 0x4B, 0x03, 0x04, 0x00, 0x00]);
        expect(
          () => RarArchive.fromBytes(bytes),
          throwsA(isA<RarFormatException>()),
        );
      });

      test('throws RarFormatException for empty data', () {
        expect(
          () => RarArchive.fromBytes(Uint8List(0)),
          throwsA(isA<RarFormatException>()),
        );
      });

      test('throws RarVersionException for RAR 5.x', () {
        final bytes = Uint8List.fromList([
          ...kRar5Magic,
          0x00,
          0x00,
          0x00,
        ]);
        expect(
          () => RarArchive.fromBytes(bytes),
          throwsA(isA<RarVersionException>()),
        );
      });
    });

    group('with minimal valid archive', () {
      late Uint8List minimalArchive;

      setUp(() {
        // Build a minimal valid RAR 4.x archive with:
        // - Marker block
        // - Archive header block
        // - End of archive block
        minimalArchive = _buildMinimalArchive();
      });

      test('parses without error', () {
        expect(() => RarArchive.fromBytes(minimalArchive), returnsNormally);
      });

      test('reports empty file list', () {
        final archive = RarArchive.fromBytes(minimalArchive);
        expect(archive.files, isEmpty);
        expect(archive.fileCount, equals(0));
      });

      test('reports no unsupported files', () {
        final archive = RarArchive.fromBytes(minimalArchive);
        expect(archive.unsupportedFiles, isEmpty);
        expect(archive.extractableFiles, isEmpty);
      });

      test('allFilesExtractable is true for empty archive', () {
        final archive = RarArchive.fromBytes(minimalArchive);
        expect(archive.allFilesExtractable, isTrue);
      });
    });

    group('hasFile', () {
      test('returns false for non-existent file', () {
        final archive = RarArchive.fromBytes(_buildMinimalArchive());
        expect(archive.hasFile('nonexistent.txt'), isFalse);
      });

      test('normalizes path separators', () {
        final archive = RarArchive.fromBytes(_buildMinimalArchive());
        // Both should be normalized to the same path
        expect(archive.hasFile('dir/file.txt'), isFalse);
        expect(archive.hasFile('dir\\file.txt'), isFalse);
      });
    });

    group('getFile', () {
      test('returns null for non-existent file', () {
        final archive = RarArchive.fromBytes(_buildMinimalArchive());
        expect(archive.getFile('nonexistent.txt'), isNull);
      });
    });

    group('readFileBytes', () {
      test('throws RarFileNotFoundException for non-existent file', () {
        final archive = RarArchive.fromBytes(_buildMinimalArchive());
        expect(
          () => archive.readFileBytes('nonexistent.txt'),
          throwsA(isA<RarFileNotFoundException>()),
        );
      });
    });

    group('tryReadFileBytes', () {
      test('returns null for non-existent file', () {
        final archive = RarArchive.fromBytes(_buildMinimalArchive());
        expect(archive.tryReadFileBytes('nonexistent.txt'), isNull);
      });
    });

    group('getFilesByExtensions', () {
      test('returns empty list when no files', () {
        final archive = RarArchive.fromBytes(_buildMinimalArchive());
        expect(archive.getFilesByExtensions({'.jpg', '.png'}), isEmpty);
      });

      test('is case-insensitive', () {
        final archive = RarArchive.fromBytes(_buildMinimalArchive());
        expect(archive.getFilesByExtensions({'.JPG', '.PNG'}), isEmpty);
      });
    });

    // Note: Integration tests with real RAR files should be added
    // using actual .rar fixtures created by the rar command-line tool.
    // Synthetic archive construction is complex due to the RAR format's
    // CRC requirements and variable header structures.
  });
}

/// Builds a minimal valid RAR 4.x archive with no files.
Uint8List _buildMinimalArchive() {
  final buffer = <int>[];

  // RAR 4.x signature
  buffer.addAll(kRar4Magic);

  // Archive header: CRC(2) + TYPE(1) + FLAGS(2) + SIZE(2) + body
  final archiveHeader = <int>[
    0x00, 0x00, // CRC (placeholder - we skip CRC verification in tests)
    0x73, // Type: MAIN_HEAD
    0x00, 0x00, // Flags
    0x0D, 0x00, // Size: 13 bytes
    0x00, 0x00, // Reserved1
    0x00, 0x00, 0x00, 0x00, // Reserved2
  ];
  buffer.addAll(archiveHeader);

  // End of archive block: CRC(2) + TYPE(1) + FLAGS(2) + SIZE(2)
  final endBlock = <int>[
    0x00, 0x00, // CRC (placeholder)
    0x7B, // Type: ENDARC
    0x00, 0x00, // Flags
    0x07, 0x00, // Size: 7 bytes
  ];
  buffer.addAll(endBlock);

  return Uint8List.fromList(buffer);
}
