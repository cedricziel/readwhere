import 'dart:typed_data';

import 'package:readwhere_rar/src/archive/rar_block.dart';
import 'package:readwhere_rar/src/archive/rar_file_entry.dart';
import 'package:readwhere_rar/src/constants.dart';
import 'package:test/test.dart';

void main() {
  group('RarFileEntry', () {
    RarFileBlock createFileBlock({
      String fileName = 'test.txt',
      int compressionMethod = RarCompressionMethod.store,
      int flags = 0,
      int unpackedSize = 100,
      int packedSize = 100,
      int fileCrc = 0x12345678,
    }) {
      return RarFileBlock(
        headerCrc: 0,
        blockType: RarBlockType.file,
        flags: flags,
        headerSize: 32,
        addSize: packedSize,
        fileOffset: 0,
        packedSizeLow: packedSize,
        unpackedSizeLow: unpackedSize,
        hostOs: RarHostOs.windows,
        fileCrc: fileCrc,
        fileTime: 0,
        unpackVersion: 20,
        compressionMethod: compressionMethod,
        nameSize: fileName.length,
        fileAttributes: 0x20,
        fileName: fileName,
        fileNameBytes: Uint8List.fromList(fileName.codeUnits),
      );
    }

    group('path normalization', () {
      test('normalizes backslashes to forward slashes', () {
        final block = createFileBlock(fileName: 'dir\\subdir\\file.txt');
        final entry = RarFileEntry(block);
        expect(entry.path, equals('dir/subdir/file.txt'));
      });

      test('removes leading slashes', () {
        final block = createFileBlock(fileName: '/dir/file.txt');
        final entry = RarFileEntry(block);
        expect(entry.path, equals('dir/file.txt'));
      });

      test('removes multiple leading slashes', () {
        final block = createFileBlock(fileName: '///file.txt');
        final entry = RarFileEntry(block);
        expect(entry.path, equals('file.txt'));
      });
    });

    group('fileName', () {
      test('extracts filename from path', () {
        final block = createFileBlock(fileName: 'dir/subdir/file.txt');
        final entry = RarFileEntry(block);
        expect(entry.fileName, equals('file.txt'));
      });

      test('handles filename without path', () {
        final block = createFileBlock(fileName: 'file.txt');
        final entry = RarFileEntry(block);
        expect(entry.fileName, equals('file.txt'));
      });
    });

    group('extension', () {
      test('extracts extension in lowercase', () {
        final block = createFileBlock(fileName: 'file.TXT');
        final entry = RarFileEntry(block);
        expect(entry.extension, equals('.txt'));
      });

      test('handles multiple dots', () {
        final block = createFileBlock(fileName: 'file.backup.txt');
        final entry = RarFileEntry(block);
        expect(entry.extension, equals('.txt'));
      });

      test('handles no extension', () {
        final block = createFileBlock(fileName: 'README');
        final entry = RarFileEntry(block);
        expect(entry.extension, equals(''));
      });
    });

    group('canExtract', () {
      test('returns true for STORE files', () {
        final block = createFileBlock(
          compressionMethod: RarCompressionMethod.store,
        );
        final entry = RarFileEntry(block);
        expect(entry.canExtract, isTrue);
      });

      test('returns false for compressed files', () {
        final block = createFileBlock(
          compressionMethod: RarCompressionMethod.normal,
        );
        final entry = RarFileEntry(block);
        expect(entry.canExtract, isFalse);
      });

      test('returns false for encrypted files', () {
        final block = createFileBlock(
          compressionMethod: RarCompressionMethod.store,
          flags: RarFileFlags.encrypted,
        );
        final entry = RarFileEntry(block);
        expect(entry.canExtract, isFalse);
      });

      test('returns false for directories', () {
        final block = createFileBlock(
          compressionMethod: RarCompressionMethod.store,
          flags: RarFileFlags.directory,
        );
        final entry = RarFileEntry(block);
        expect(entry.canExtract, isFalse);
      });
    });

    group('hasUnsupportedCompression', () {
      test('returns false for STORE', () {
        final block = createFileBlock(
          compressionMethod: RarCompressionMethod.store,
        );
        final entry = RarFileEntry(block);
        expect(entry.hasUnsupportedCompression, isFalse);
      });

      test('returns true for FASTEST', () {
        final block = createFileBlock(
          compressionMethod: RarCompressionMethod.fastest,
        );
        final entry = RarFileEntry(block);
        expect(entry.hasUnsupportedCompression, isTrue);
      });

      test('returns true for NORMAL', () {
        final block = createFileBlock(
          compressionMethod: RarCompressionMethod.normal,
        );
        final entry = RarFileEntry(block);
        expect(entry.hasUnsupportedCompression, isTrue);
      });

      test('returns true for BEST', () {
        final block = createFileBlock(
          compressionMethod: RarCompressionMethod.best,
        );
        final entry = RarFileEntry(block);
        expect(entry.hasUnsupportedCompression, isTrue);
      });

      test('returns false for directories', () {
        final block = createFileBlock(
          compressionMethod: RarCompressionMethod.normal,
          flags: RarFileFlags.directory,
        );
        final entry = RarFileEntry(block);
        expect(entry.hasUnsupportedCompression, isFalse);
      });
    });

    group('size', () {
      test('returns unpacked size', () {
        final block = createFileBlock(unpackedSize: 12345);
        final entry = RarFileEntry(block);
        expect(entry.size, equals(12345));
      });
    });

    group('packedSize', () {
      test('returns packed size', () {
        final block = createFileBlock(packedSize: 9999);
        final entry = RarFileEntry(block);
        expect(entry.packedSize, equals(9999));
      });
    });

    group('crc32', () {
      test('returns file CRC', () {
        final block = createFileBlock(fileCrc: 0xABCDEF12);
        final entry = RarFileEntry(block);
        expect(entry.crc32, equals(0xABCDEF12));
      });
    });

    group('compressionMethodName', () {
      test('returns STORE for store method', () {
        final block = createFileBlock(
          compressionMethod: RarCompressionMethod.store,
        );
        final entry = RarFileEntry(block);
        expect(entry.compressionMethodName, equals('STORE'));
      });

      test('returns NORMAL for normal method', () {
        final block = createFileBlock(
          compressionMethod: RarCompressionMethod.normal,
        );
        final entry = RarFileEntry(block);
        expect(entry.compressionMethodName, equals('NORMAL'));
      });
    });

    group('equality', () {
      test('equal entries are equal', () {
        final block1 = createFileBlock(fileName: 'file.txt', fileCrc: 123);
        final block2 = createFileBlock(fileName: 'file.txt', fileCrc: 123);
        final entry1 = RarFileEntry(block1);
        final entry2 = RarFileEntry(block2);
        expect(entry1, equals(entry2));
      });

      test('different files are not equal', () {
        final block1 = createFileBlock(fileName: 'file1.txt');
        final block2 = createFileBlock(fileName: 'file2.txt');
        final entry1 = RarFileEntry(block1);
        final entry2 = RarFileEntry(block2);
        expect(entry1, isNot(equals(entry2)));
      });
    });

    group('toString', () {
      test('contains useful information', () {
        final block = createFileBlock(
          fileName: 'test.txt',
          unpackedSize: 1000,
          compressionMethod: RarCompressionMethod.store,
        );
        final entry = RarFileEntry(block);
        final str = entry.toString();

        expect(str, contains('test.txt'));
        expect(str, contains('1000'));
        expect(str, contains('STORE'));
        expect(str, contains('canExtract'));
      });
    });
  });
}
