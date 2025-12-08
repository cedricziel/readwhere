import 'dart:io';
import 'dart:typed_data';

import '../container/cbz_container.dart';
import '../errors/cbz_exception.dart';
import '../metadata/comic_info/comic_info_parser.dart';
import '../metadata/metron_info/metron_info_parser.dart';
import '../utils/image_utils.dart';

/// Validation error codes.
abstract class CbzValidationCodes {
  // Structure errors
  static const invalidZip = 'INVALID_ZIP';
  static const emptyArchive = 'EMPTY_ARCHIVE';
  static const noImages = 'NO_IMAGES';

  // Image errors
  static const invalidImage = 'INVALID_IMAGE';
  static const unsupportedFormat = 'UNSUPPORTED_FORMAT';
  static const corruptImage = 'CORRUPT_IMAGE';

  // Page ordering warnings
  static const gapInPageNumbers = 'GAP_IN_PAGE_NUMBERS';
  static const duplicatePageNumber = 'DUPLICATE_PAGE_NUMBER';
  static const nonSequentialPages = 'NON_SEQUENTIAL_PAGES';

  // Metadata warnings
  static const invalidComicInfo = 'INVALID_COMIC_INFO';
  static const invalidMetronInfo = 'INVALID_METRON_INFO';

  // Info
  static const noMetadata = 'NO_METADATA';
  static const macOsxFiles = 'MACOSX_FILES';
}

/// Validates CBZ comic book archives.
class CbzValidator {
  CbzValidator._();

  /// Validates a CBZ file from a file path.
  ///
  /// Returns a [CbzValidationResult] containing any issues found.
  static Future<CbzValidationResult> validateFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return CbzValidationResult(
          isValid: false,
          errors: [
            CbzValidationError(
              severity: CbzValidationSeverity.error,
              code: CbzValidationCodes.invalidZip,
              message: 'File not found: $filePath',
            ),
          ],
        );
      }
      final bytes = await file.readAsBytes();
      return validate(bytes);
    } catch (e) {
      return CbzValidationResult(
        isValid: false,
        errors: [
          CbzValidationError(
            severity: CbzValidationSeverity.error,
            code: CbzValidationCodes.invalidZip,
            message: 'Failed to read file: $e',
          ),
        ],
      );
    }
  }

  /// Validates a CBZ file from raw bytes.
  ///
  /// Returns a [CbzValidationResult] containing any issues found.
  static CbzValidationResult validate(Uint8List bytes) {
    final errors = <CbzValidationError>[];
    final warnings = <CbzValidationError>[];
    final info = <CbzValidationError>[];

    // Try to open as ZIP
    CbzContainer container;
    try {
      container = CbzContainer.fromBytes(bytes);
    } catch (e) {
      return CbzValidationResult(
        isValid: false,
        errors: [
          CbzValidationError(
            severity: CbzValidationSeverity.error,
            code: CbzValidationCodes.invalidZip,
            message: 'Invalid ZIP archive: $e',
          ),
        ],
      );
    }

    // Check for empty archive
    if (container.fileCount == 0) {
      return CbzValidationResult(
        isValid: false,
        errors: [
          CbzValidationError(
            severity: CbzValidationSeverity.error,
            code: CbzValidationCodes.emptyArchive,
            message: 'Archive contains no files',
          ),
        ],
      );
    }

    // Validate structure
    final structureIssues = _validateStructure(container);
    _categorizeIssues(structureIssues, errors, warnings, info);

    // Validate images
    final imageIssues = _validateImages(container);
    _categorizeIssues(imageIssues, errors, warnings, info);

    // Validate page ordering
    final orderingIssues = _validatePageOrdering(container);
    _categorizeIssues(orderingIssues, errors, warnings, info);

    // Validate metadata
    final metadataIssues = _validateMetadata(container);
    _categorizeIssues(metadataIssues, errors, warnings, info);

    container.close();

    return CbzValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      info: info,
    );
  }

  /// Categorizes issues by severity into separate lists.
  static void _categorizeIssues(
    List<CbzValidationError> issues,
    List<CbzValidationError> errors,
    List<CbzValidationError> warnings,
    List<CbzValidationError> info,
  ) {
    for (final issue in issues) {
      switch (issue.severity) {
        case CbzValidationSeverity.error:
          errors.add(issue);
        case CbzValidationSeverity.warning:
          warnings.add(issue);
        case CbzValidationSeverity.info:
          info.add(issue);
      }
    }
  }

  /// Validates the overall structure of the archive.
  static List<CbzValidationError> _validateStructure(CbzContainer container) {
    final issues = <CbzValidationError>[];

    // Check for images
    if (container.pageCount == 0) {
      issues.add(
        CbzValidationError(
          severity: CbzValidationSeverity.error,
          code: CbzValidationCodes.noImages,
          message: 'Archive contains no image files',
        ),
      );
    }

    // Check for __MACOSX directory (info only)
    final hasMacOsx = container.allFilePaths.any((p) => p.contains('__MACOSX'));
    if (hasMacOsx) {
      issues.add(
        CbzValidationError(
          severity: CbzValidationSeverity.info,
          code: CbzValidationCodes.macOsxFiles,
          message: 'Archive contains macOS metadata files (__MACOSX)',
        ),
      );
    }

    return issues;
  }

  /// Validates image files in the archive.
  static List<CbzValidationError> _validateImages(CbzContainer container) {
    final issues = <CbzValidationError>[];
    final imagePaths = container.imagePaths;

    for (final path in imagePaths) {
      try {
        final bytes = container.readImageBytes(path);
        final format = ImageUtils.detectFormat(bytes);

        if (format == ImageFormat.unknown) {
          issues.add(
            CbzValidationError(
              severity: CbzValidationSeverity.warning,
              code: CbzValidationCodes.unsupportedFormat,
              message: 'Unsupported or unrecognized image format',
              location: path,
            ),
          );
        }
      } catch (e) {
        issues.add(
          CbzValidationError(
            severity: CbzValidationSeverity.error,
            code: CbzValidationCodes.corruptImage,
            message: 'Failed to read image: $e',
            location: path,
          ),
        );
      }
    }

    return issues;
  }

  /// Validates page ordering and numbering.
  static List<CbzValidationError> _validatePageOrdering(
    CbzContainer container,
  ) {
    final issues = <CbzValidationError>[];
    final imagePaths = container.imagePaths;

    if (imagePaths.length < 2) {
      return issues;
    }

    // Extract numeric portions from filenames to detect gaps
    final numbers = <int>[];
    final numberPattern = RegExp(r'(\d+)');

    for (final path in imagePaths) {
      final filename = _getFilename(path);
      final matches = numberPattern.allMatches(filename);
      if (matches.isNotEmpty) {
        // Use the last number found in the filename
        final lastMatch = matches.last;
        final number = int.tryParse(lastMatch.group(1)!);
        if (number != null) {
          numbers.add(number);
        }
      }
    }

    // Check for gaps in sequential numbering
    if (numbers.length == imagePaths.length) {
      numbers.sort();

      // Check for duplicates
      final seen = <int>{};
      for (final num in numbers) {
        if (seen.contains(num)) {
          issues.add(
            CbzValidationError(
              severity: CbzValidationSeverity.warning,
              code: CbzValidationCodes.duplicatePageNumber,
              message: 'Duplicate page number detected: $num',
            ),
          );
        }
        seen.add(num);
      }

      // Check for large gaps
      for (var i = 1; i < numbers.length; i++) {
        final gap = numbers[i] - numbers[i - 1];
        if (gap > 1) {
          issues.add(
            CbzValidationError(
              severity: CbzValidationSeverity.warning,
              code: CbzValidationCodes.gapInPageNumbers,
              message:
                  'Gap in page numbers: ${numbers[i - 1]} to ${numbers[i]} (missing ${gap - 1} pages)',
            ),
          );
        }
      }
    }

    return issues;
  }

  /// Validates metadata files.
  static List<CbzValidationError> _validateMetadata(CbzContainer container) {
    final issues = <CbzValidationError>[];
    var hasValidMetadata = false;

    // Validate ComicInfo.xml
    if (container.hasComicInfo) {
      try {
        final xml = container.readComicInfo();
        if (xml != null) {
          ComicInfoParser.parse(xml);
          hasValidMetadata = true;
        }
      } catch (e) {
        issues.add(
          CbzValidationError(
            severity: CbzValidationSeverity.warning,
            code: CbzValidationCodes.invalidComicInfo,
            message: 'Invalid ComicInfo.xml: $e',
            location: 'ComicInfo.xml',
          ),
        );
      }
    }

    // Validate MetronInfo.xml
    if (container.hasMetronInfo) {
      try {
        final xml = container.readMetronInfo();
        if (xml != null) {
          MetronInfoParser.parse(xml);
          hasValidMetadata = true;
        }
      } catch (e) {
        issues.add(
          CbzValidationError(
            severity: CbzValidationSeverity.warning,
            code: CbzValidationCodes.invalidMetronInfo,
            message: 'Invalid MetronInfo.xml: $e',
            location: 'MetronInfo.xml',
          ),
        );
      }
    }

    // Info if no metadata present
    if (!container.hasComicInfo && !container.hasMetronInfo) {
      issues.add(
        CbzValidationError(
          severity: CbzValidationSeverity.info,
          code: CbzValidationCodes.noMetadata,
          message: 'No metadata files found (ComicInfo.xml or MetronInfo.xml)',
        ),
      );
    } else if (!hasValidMetadata) {
      // Metadata exists but couldn't be parsed - already logged as warning
    }

    return issues;
  }

  /// Extracts the filename from a path.
  static String _getFilename(String path) {
    final lastSlash = path.lastIndexOf('/');
    if (lastSlash == -1) return path;
    return path.substring(lastSlash + 1);
  }
}
