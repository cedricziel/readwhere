import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:readwhere_cbz/readwhere_cbz.dart';
import 'package:test/test.dart';

void main() {
  group('CbzValidator', () {
    group('validate', () {
      test('returns error for invalid ZIP data', () {
        // Invalid ZIP data that can't be parsed
        // The archive library may treat some invalid data as empty archives
        final bytes = Uint8List.fromList([0, 1, 2, 3, 4, 5]);
        final result = CbzValidator.validate(bytes);

        // Result should be invalid (either INVALID_ZIP or EMPTY_ARCHIVE)
        expect(result.isValid, isFalse);
        expect(result.errors, hasLength(1));
        expect(
          result.errors.first.code,
          anyOf(CbzValidationCodes.invalidZip, CbzValidationCodes.emptyArchive),
        );
      });

      test('returns error for empty archive', () {
        final archive = Archive();
        final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
        final result = CbzValidator.validate(bytes);

        expect(result.isValid, isFalse);
        expect(result.errors, hasLength(1));
        expect(result.errors.first.code, CbzValidationCodes.emptyArchive);
      });

      test('returns error for archive with no images', () {
        final archive = Archive();
        archive.addFile(
          ArchiveFile('readme.txt', 5, [72, 101, 108, 108, 111]),
        );
        final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
        final result = CbzValidator.validate(bytes);

        expect(result.isValid, isFalse);
        expect(result.errors, hasLength(1));
        expect(result.errors.first.code, CbzValidationCodes.noImages);
      });

      test('returns valid result for archive with valid images', () {
        final archive = Archive();
        // Valid JPEG header
        final jpegBytes = Uint8List.fromList([
          0xFF,
          0xD8,
          0xFF,
          0xE0,
          0x00,
          0x10,
          0x4A,
          0x46,
          0x49,
          0x46,
          0x00,
          0x01,
          0x01,
          0x00,
          0x00,
          0x01,
          0x00,
          0x01,
          0x00,
          0x00,
        ]);
        archive
            .addFile(ArchiveFile('page001.jpg', jpegBytes.length, jpegBytes));
        final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
        final result = CbzValidator.validate(bytes);

        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('returns info message when no metadata present', () {
        final archive = Archive();
        final jpegBytes = Uint8List.fromList([
          0xFF,
          0xD8,
          0xFF,
          0xE0,
          0x00,
          0x10,
          0x4A,
          0x46,
          0x49,
          0x46,
          0x00,
          0x01,
          0x01,
          0x00,
          0x00,
          0x01,
          0x00,
          0x01,
          0x00,
          0x00,
        ]);
        archive
            .addFile(ArchiveFile('page001.jpg', jpegBytes.length, jpegBytes));
        final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
        final result = CbzValidator.validate(bytes);

        expect(result.info, hasLength(1));
        expect(result.info.first.code, CbzValidationCodes.noMetadata);
      });

      test('returns info message when __MACOSX directory present', () {
        final archive = Archive();
        final jpegBytes = Uint8List.fromList([
          0xFF,
          0xD8,
          0xFF,
          0xE0,
          0x00,
          0x10,
          0x4A,
          0x46,
          0x49,
          0x46,
          0x00,
          0x01,
          0x01,
          0x00,
          0x00,
          0x01,
          0x00,
          0x01,
          0x00,
          0x00,
        ]);
        archive
            .addFile(ArchiveFile('page001.jpg', jpegBytes.length, jpegBytes));
        archive.addFile(
          ArchiveFile('__MACOSX/.DS_Store', 5, [1, 2, 3, 4, 5]),
        );
        final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
        final result = CbzValidator.validate(bytes);

        expect(result.isValid, isTrue);
        expect(
          result.info,
          contains(
            predicate<CbzValidationError>(
              (e) => e.code == CbzValidationCodes.macOsxFiles,
            ),
          ),
        );
      });

      test('returns warning for unsupported image format', () {
        final archive = Archive();
        // Some random bytes that don't match any image format
        final unknownBytes = Uint8List.fromList([
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
        ]);
        archive.addFile(
            ArchiveFile('page001.jpg', unknownBytes.length, unknownBytes));
        final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
        final result = CbzValidator.validate(bytes);

        // Archive has an image file (by extension) but with unrecognized format
        expect(
          result.warnings,
          contains(
            predicate<CbzValidationError>(
              (e) => e.code == CbzValidationCodes.unsupportedFormat,
            ),
          ),
        );
      });
    });

    group('page ordering validation', () {
      test('returns warning for gap in page numbers', () {
        final archive = Archive();
        final jpegBytes = Uint8List.fromList([
          0xFF,
          0xD8,
          0xFF,
          0xE0,
          0x00,
          0x10,
          0x4A,
          0x46,
          0x49,
          0x46,
          0x00,
          0x01,
          0x01,
          0x00,
          0x00,
          0x01,
          0x00,
          0x01,
          0x00,
          0x00,
        ]);
        archive
            .addFile(ArchiveFile('page001.jpg', jpegBytes.length, jpegBytes));
        archive
            .addFile(ArchiveFile('page002.jpg', jpegBytes.length, jpegBytes));
        // Gap: missing page003
        archive
            .addFile(ArchiveFile('page004.jpg', jpegBytes.length, jpegBytes));
        final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
        final result = CbzValidator.validate(bytes);

        expect(
          result.warnings,
          contains(
            predicate<CbzValidationError>(
              (e) => e.code == CbzValidationCodes.gapInPageNumbers,
            ),
          ),
        );
      });

      test('returns warning for duplicate page numbers', () {
        final archive = Archive();
        final jpegBytes = Uint8List.fromList([
          0xFF,
          0xD8,
          0xFF,
          0xE0,
          0x00,
          0x10,
          0x4A,
          0x46,
          0x49,
          0x46,
          0x00,
          0x01,
          0x01,
          0x00,
          0x00,
          0x01,
          0x00,
          0x01,
          0x00,
          0x00,
        ]);
        archive
            .addFile(ArchiveFile('page001.jpg', jpegBytes.length, jpegBytes));
        archive.addFile(
            ArchiveFile('page001_alt.jpg', jpegBytes.length, jpegBytes));
        archive
            .addFile(ArchiveFile('page002.jpg', jpegBytes.length, jpegBytes));
        final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
        final result = CbzValidator.validate(bytes);

        expect(
          result.warnings,
          contains(
            predicate<CbzValidationError>(
              (e) => e.code == CbzValidationCodes.duplicatePageNumber,
            ),
          ),
        );
      });

      test('returns no warnings for sequential page numbers', () {
        final archive = Archive();
        final jpegBytes = Uint8List.fromList([
          0xFF,
          0xD8,
          0xFF,
          0xE0,
          0x00,
          0x10,
          0x4A,
          0x46,
          0x49,
          0x46,
          0x00,
          0x01,
          0x01,
          0x00,
          0x00,
          0x01,
          0x00,
          0x01,
          0x00,
          0x00,
        ]);
        archive
            .addFile(ArchiveFile('page001.jpg', jpegBytes.length, jpegBytes));
        archive
            .addFile(ArchiveFile('page002.jpg', jpegBytes.length, jpegBytes));
        archive
            .addFile(ArchiveFile('page003.jpg', jpegBytes.length, jpegBytes));
        final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
        final result = CbzValidator.validate(bytes);

        expect(
          result.warnings.where(
            (e) =>
                e.code == CbzValidationCodes.gapInPageNumbers ||
                e.code == CbzValidationCodes.duplicatePageNumber,
          ),
          isEmpty,
        );
      });
    });

    group('metadata validation', () {
      test('returns no warning for valid ComicInfo.xml', () {
        final archive = Archive();
        final jpegBytes = Uint8List.fromList([
          0xFF,
          0xD8,
          0xFF,
          0xE0,
          0x00,
          0x10,
          0x4A,
          0x46,
          0x49,
          0x46,
          0x00,
          0x01,
          0x01,
          0x00,
          0x00,
          0x01,
          0x00,
          0x01,
          0x00,
          0x00,
        ]);
        archive
            .addFile(ArchiveFile('page001.jpg', jpegBytes.length, jpegBytes));

        const comicInfoXml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <Title>Test Comic</Title>
</ComicInfo>''';
        final xmlBytes = Uint8List.fromList(comicInfoXml.codeUnits);
        archive
            .addFile(ArchiveFile('ComicInfo.xml', xmlBytes.length, xmlBytes));

        final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
        final result = CbzValidator.validate(bytes);

        expect(
          result.warnings.where(
            (e) => e.code == CbzValidationCodes.invalidComicInfo,
          ),
          isEmpty,
        );
        expect(
          result.info.where(
            (e) => e.code == CbzValidationCodes.noMetadata,
          ),
          isEmpty,
        );
      });

      test('returns warning for invalid ComicInfo.xml', () {
        final archive = Archive();
        final jpegBytes = Uint8List.fromList([
          0xFF,
          0xD8,
          0xFF,
          0xE0,
          0x00,
          0x10,
          0x4A,
          0x46,
          0x49,
          0x46,
          0x00,
          0x01,
          0x01,
          0x00,
          0x00,
          0x01,
          0x00,
          0x01,
          0x00,
          0x00,
        ]);
        archive
            .addFile(ArchiveFile('page001.jpg', jpegBytes.length, jpegBytes));

        // Invalid XML - wrong root element
        const invalidXml = '''<?xml version="1.0"?>
<NotComicInfo>
  <Title>Test</Title>
</NotComicInfo>''';
        final xmlBytes = Uint8List.fromList(invalidXml.codeUnits);
        archive
            .addFile(ArchiveFile('ComicInfo.xml', xmlBytes.length, xmlBytes));

        final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
        final result = CbzValidator.validate(bytes);

        expect(
          result.warnings,
          contains(
            predicate<CbzValidationError>(
              (e) => e.code == CbzValidationCodes.invalidComicInfo,
            ),
          ),
        );
      });

      test('returns no warning for valid MetronInfo.xml', () {
        final archive = Archive();
        final jpegBytes = Uint8List.fromList([
          0xFF,
          0xD8,
          0xFF,
          0xE0,
          0x00,
          0x10,
          0x4A,
          0x46,
          0x49,
          0x46,
          0x00,
          0x01,
          0x01,
          0x00,
          0x00,
          0x01,
          0x00,
          0x01,
          0x00,
          0x00,
        ]);
        archive
            .addFile(ArchiveFile('page001.jpg', jpegBytes.length, jpegBytes));

        const metronInfoXml = '''<?xml version="1.0" encoding="UTF-8"?>
<MetronInfo>
</MetronInfo>''';
        final xmlBytes = Uint8List.fromList(metronInfoXml.codeUnits);
        archive
            .addFile(ArchiveFile('MetronInfo.xml', xmlBytes.length, xmlBytes));

        final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
        final result = CbzValidator.validate(bytes);

        expect(
          result.warnings.where(
            (e) => e.code == CbzValidationCodes.invalidMetronInfo,
          ),
          isEmpty,
        );
      });

      test('returns warning for invalid MetronInfo.xml', () {
        final archive = Archive();
        final jpegBytes = Uint8List.fromList([
          0xFF,
          0xD8,
          0xFF,
          0xE0,
          0x00,
          0x10,
          0x4A,
          0x46,
          0x49,
          0x46,
          0x00,
          0x01,
          0x01,
          0x00,
          0x00,
          0x01,
          0x00,
          0x01,
          0x00,
          0x00,
        ]);
        archive
            .addFile(ArchiveFile('page001.jpg', jpegBytes.length, jpegBytes));

        // Invalid XML - wrong root element
        const invalidXml = '''<?xml version="1.0"?>
<NotMetronInfo>
</NotMetronInfo>''';
        final xmlBytes = Uint8List.fromList(invalidXml.codeUnits);
        archive
            .addFile(ArchiveFile('MetronInfo.xml', xmlBytes.length, xmlBytes));

        final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
        final result = CbzValidator.validate(bytes);

        expect(
          result.warnings,
          contains(
            predicate<CbzValidationError>(
              (e) => e.code == CbzValidationCodes.invalidMetronInfo,
            ),
          ),
        );
      });
    });
  });

  group('CbzValidationResult', () {
    test('isValid returns true when errors list is empty', () {
      const result = CbzValidationResult(
        isValid: true,
        errors: [],
        warnings: [
          CbzValidationError(
            severity: CbzValidationSeverity.warning,
            code: 'TEST',
            message: 'Test warning',
          ),
        ],
      );
      expect(result.isValid, isTrue);
    });

    test('isValid returns false when errors list is not empty', () {
      const result = CbzValidationResult(
        isValid: false,
        errors: [
          CbzValidationError(
            severity: CbzValidationSeverity.error,
            code: 'TEST',
            message: 'Test error',
          ),
        ],
      );
      expect(result.isValid, isFalse);
    });

    test('allIssues contains all errors, warnings, and info', () {
      const result = CbzValidationResult(
        isValid: true,
        errors: [
          CbzValidationError(
            severity: CbzValidationSeverity.error,
            code: 'E1',
            message: 'Error',
          ),
        ],
        warnings: [
          CbzValidationError(
            severity: CbzValidationSeverity.warning,
            code: 'W1',
            message: 'Warning',
          ),
        ],
        info: [
          CbzValidationError(
            severity: CbzValidationSeverity.info,
            code: 'I1',
            message: 'Info',
          ),
        ],
      );

      expect(result.allIssues, hasLength(3));
      expect(result.totalIssues, equals(3));
    });
  });

  group('CbzValidationError', () {
    test('toString includes severity, code, and message', () {
      const error = CbzValidationError(
        severity: CbzValidationSeverity.error,
        code: 'TEST_CODE',
        message: 'Test message',
      );

      final str = error.toString();
      expect(str, contains('ERROR'));
      expect(str, contains('TEST_CODE'));
      expect(str, contains('Test message'));
    });

    test('toString includes location when present', () {
      const error = CbzValidationError(
        severity: CbzValidationSeverity.warning,
        code: 'TEST_CODE',
        message: 'Test message',
        location: 'path/to/file.jpg',
      );

      final str = error.toString();
      expect(str, contains('path/to/file.jpg'));
    });
  });
}
