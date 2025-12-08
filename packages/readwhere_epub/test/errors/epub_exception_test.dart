import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_epub/src/errors/epub_exception.dart';

void main() {
  group('EpubReadException', () {
    test('creates with message only', () {
      const ex = EpubReadException('Cannot read file');
      expect(ex.message, equals('Cannot read file'));
      expect(ex.filePath, isNull);
      expect(ex.cause, isNull);
      expect(ex.stackTrace, isNull);
    });

    test('creates with all parameters', () {
      final cause = Exception('IO Error');
      final trace = StackTrace.current;
      final ex = EpubReadException(
        'Cannot read file',
        filePath: '/path/to/file.epub',
        cause: cause,
        stackTrace: trace,
      );
      expect(ex.message, equals('Cannot read file'));
      expect(ex.filePath, equals('/path/to/file.epub'));
      expect(ex.cause, equals(cause));
      expect(ex.stackTrace, equals(trace));
    });

    test('toString without filePath', () {
      const ex = EpubReadException('Cannot read file');
      expect(ex.toString(), equals('EpubReadException: Cannot read file'));
    });

    test('toString with filePath', () {
      const ex = EpubReadException(
        'Cannot read file',
        filePath: '/path/to/file.epub',
      );
      expect(
        ex.toString(),
        equals(
            'EpubReadException: Cannot read file (file: /path/to/file.epub)'),
      );
    });
  });

  group('EpubValidationException', () {
    test('creates with message and errors', () {
      const errors = [
        EpubValidationError(
          severity: EpubValidationSeverity.error,
          code: 'ERR001',
          message: 'Missing metadata',
        ),
      ];
      const ex = EpubValidationException('Validation failed', errors);
      expect(ex.message, equals('Validation failed'));
      expect(ex.errors, hasLength(1));
    });

    test('creates with empty errors list', () {
      const ex = EpubValidationException('No errors', []);
      expect(ex.errors, isEmpty);
    });

    test('toString formats error list', () {
      const errors = [
        EpubValidationError(
          severity: EpubValidationSeverity.error,
          code: 'ERR001',
          message: 'Missing title',
        ),
        EpubValidationError(
          severity: EpubValidationSeverity.warning,
          code: 'WARN001',
          message: 'Invalid date format',
        ),
      ];
      const ex = EpubValidationException('Validation failed', errors);
      final str = ex.toString();
      expect(str, contains('EpubValidationException: Validation failed'));
      expect(str, contains('Errors:'));
      expect(str, contains('Missing title'));
      expect(str, contains('Invalid date format'));
    });
  });

  group('EpubParseException', () {
    test('creates with message only', () {
      const ex = EpubParseException('Parse error');
      expect(ex.message, equals('Parse error'));
      expect(ex.documentPath, isNull);
      expect(ex.lineNumber, isNull);
      expect(ex.column, isNull);
    });

    test('creates with all parameters', () {
      const ex = EpubParseException(
        'Invalid XML',
        documentPath: 'content.opf',
        lineNumber: 42,
        column: 15,
      );
      expect(ex.documentPath, equals('content.opf'));
      expect(ex.lineNumber, equals(42));
      expect(ex.column, equals(15));
    });

    test('toString with message only', () {
      const ex = EpubParseException('Parse error');
      expect(ex.toString(), equals('EpubParseException: Parse error'));
    });

    test('toString with documentPath', () {
      const ex = EpubParseException(
        'Invalid XML',
        documentPath: 'content.opf',
      );
      expect(
        ex.toString(),
        equals('EpubParseException: Invalid XML in content.opf'),
      );
    });

    test('toString with line number', () {
      const ex = EpubParseException(
        'Invalid XML',
        lineNumber: 42,
      );
      expect(
        ex.toString(),
        equals('EpubParseException: Invalid XML at line 42'),
      );
    });

    test('toString with line and column', () {
      const ex = EpubParseException(
        'Invalid XML',
        lineNumber: 42,
        column: 15,
      );
      expect(
        ex.toString(),
        equals('EpubParseException: Invalid XML at line 42 column 15'),
      );
    });

    test('toString with all location info', () {
      const ex = EpubParseException(
        'Invalid XML',
        documentPath: 'content.opf',
        lineNumber: 42,
        column: 15,
      );
      expect(
        ex.toString(),
        equals(
          'EpubParseException: Invalid XML in content.opf at line 42 column 15',
        ),
      );
    });

    test('toString ignores column without line number', () {
      const ex = EpubParseException(
        'Invalid XML',
        column: 15,
      );
      expect(ex.toString(), equals('EpubParseException: Invalid XML'));
    });
  });

  group('EpubCfiParseException', () {
    test('creates with message and CFI string', () {
      const ex = EpubCfiParseException('Invalid CFI', 'epubcfi(/6/4)');
      expect(ex.message, equals('Invalid CFI'));
      expect(ex.cfiString, equals('epubcfi(/6/4)'));
    });

    test('toString includes CFI string', () {
      const ex =
          EpubCfiParseException('Invalid step', 'epubcfi(/6/4!/invalid)');
      expect(
        ex.toString(),
        equals(
          'EpubCfiParseException: Invalid step (CFI: epubcfi(/6/4!/invalid))',
        ),
      );
    });
  });

  group('EpubResourceNotFoundException', () {
    test('creates with resource path', () {
      const ex = EpubResourceNotFoundException('images/cover.jpg');
      expect(ex.resourcePath, equals('images/cover.jpg'));
      expect(ex.message, equals('Resource not found: images/cover.jpg'));
    });

    test('toString shows resource path', () {
      const ex = EpubResourceNotFoundException('chapter1.xhtml');
      expect(
        ex.toString(),
        equals('EpubResourceNotFoundException: chapter1.xhtml'),
      );
    });
  });

  group('EpubEncryptionException', () {
    test('creates with message only', () {
      const ex = EpubEncryptionException('Content is encrypted');
      expect(ex.message, equals('Content is encrypted'));
      expect(ex.encryptionType, isNull);
    });

    test('creates with encryption type', () {
      const ex = EpubEncryptionException(
        'Content is encrypted',
        encryptionType: 'Adobe DRM',
      );
      expect(ex.encryptionType, equals('Adobe DRM'));
    });

    test('toString without encryption type', () {
      const ex = EpubEncryptionException('Content is encrypted');
      expect(
        ex.toString(),
        equals('EpubEncryptionException: Content is encrypted'),
      );
    });

    test('toString with encryption type', () {
      const ex = EpubEncryptionException(
        'Content is encrypted',
        encryptionType: 'Adobe DRM',
      );
      expect(
        ex.toString(),
        equals(
          'EpubEncryptionException: Content is encrypted (type: Adobe DRM)',
        ),
      );
    });
  });

  group('EpubValidationSeverity', () {
    test('has error value', () {
      expect(EpubValidationSeverity.error, isNotNull);
    });

    test('has warning value', () {
      expect(EpubValidationSeverity.warning, isNotNull);
    });

    test('has info value', () {
      expect(EpubValidationSeverity.info, isNotNull);
    });

    test('has exactly 3 values', () {
      expect(EpubValidationSeverity.values, hasLength(3));
    });
  });

  group('EpubValidationError', () {
    test('creates with required fields', () {
      const error = EpubValidationError(
        severity: EpubValidationSeverity.error,
        code: 'ERR001',
        message: 'Missing title',
      );
      expect(error.severity, equals(EpubValidationSeverity.error));
      expect(error.code, equals('ERR001'));
      expect(error.message, equals('Missing title'));
      expect(error.location, isNull);
    });

    test('creates with location', () {
      const error = EpubValidationError(
        severity: EpubValidationSeverity.warning,
        code: 'WARN001',
        message: 'Invalid date',
        location: 'content.opf:line 25',
      );
      expect(error.location, equals('content.opf:line 25'));
    });

    test('toString without location', () {
      const error = EpubValidationError(
        severity: EpubValidationSeverity.error,
        code: 'ERR001',
        message: 'Missing title',
      );
      expect(error.toString(), equals('[ERROR] ERR001: Missing title'));
    });

    test('toString with location', () {
      const error = EpubValidationError(
        severity: EpubValidationSeverity.warning,
        code: 'WARN001',
        message: 'Invalid date',
        location: 'content.opf',
      );
      expect(
        error.toString(),
        equals('[WARNING] WARN001: Invalid date (at content.opf)'),
      );
    });

    test('toString with info severity', () {
      const error = EpubValidationError(
        severity: EpubValidationSeverity.info,
        code: 'INFO001',
        message: 'Consider adding description',
      );
      expect(
        error.toString(),
        equals('[INFO] INFO001: Consider adding description'),
      );
    });

    group('Equatable', () {
      test('equal errors are equal', () {
        const error1 = EpubValidationError(
          severity: EpubValidationSeverity.error,
          code: 'ERR001',
          message: 'Missing title',
        );
        const error2 = EpubValidationError(
          severity: EpubValidationSeverity.error,
          code: 'ERR001',
          message: 'Missing title',
        );
        expect(error1, equals(error2));
      });

      test('different severity are not equal', () {
        const error1 = EpubValidationError(
          severity: EpubValidationSeverity.error,
          code: 'ERR001',
          message: 'Issue',
        );
        const error2 = EpubValidationError(
          severity: EpubValidationSeverity.warning,
          code: 'ERR001',
          message: 'Issue',
        );
        expect(error1, isNot(equals(error2)));
      });

      test('different codes are not equal', () {
        const error1 = EpubValidationError(
          severity: EpubValidationSeverity.error,
          code: 'ERR001',
          message: 'Issue',
        );
        const error2 = EpubValidationError(
          severity: EpubValidationSeverity.error,
          code: 'ERR002',
          message: 'Issue',
        );
        expect(error1, isNot(equals(error2)));
      });
    });
  });

  group('EpubValidationResult', () {
    test('creates valid result', () {
      const result = EpubValidationResult(isValid: true);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
      expect(result.info, isEmpty);
      expect(result.detectedVersion, isNull);
    });

    test('creates invalid result with errors', () {
      const errors = [
        EpubValidationError(
          severity: EpubValidationSeverity.error,
          code: 'ERR001',
          message: 'Missing title',
        ),
      ];
      const result = EpubValidationResult(
        isValid: false,
        errors: errors,
      );
      expect(result.isValid, isFalse);
      expect(result.errors, hasLength(1));
    });

    test('creates result with all issue types', () {
      const errors = [
        EpubValidationError(
          severity: EpubValidationSeverity.error,
          code: 'ERR001',
          message: 'Error 1',
        ),
      ];
      const warnings = [
        EpubValidationError(
          severity: EpubValidationSeverity.warning,
          code: 'WARN001',
          message: 'Warning 1',
        ),
        EpubValidationError(
          severity: EpubValidationSeverity.warning,
          code: 'WARN002',
          message: 'Warning 2',
        ),
      ];
      const info = [
        EpubValidationError(
          severity: EpubValidationSeverity.info,
          code: 'INFO001',
          message: 'Info 1',
        ),
      ];
      const result = EpubValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
        info: info,
        detectedVersion: EpubVersion.epub33,
      );
      expect(result.errors, hasLength(1));
      expect(result.warnings, hasLength(2));
      expect(result.info, hasLength(1));
      expect(result.detectedVersion, equals(EpubVersion.epub33));
    });

    test('allIssues returns combined list', () {
      const result = EpubValidationResult(
        isValid: false,
        errors: [
          EpubValidationError(
            severity: EpubValidationSeverity.error,
            code: 'E1',
            message: 'Error',
          ),
        ],
        warnings: [
          EpubValidationError(
            severity: EpubValidationSeverity.warning,
            code: 'W1',
            message: 'Warning',
          ),
        ],
        info: [
          EpubValidationError(
            severity: EpubValidationSeverity.info,
            code: 'I1',
            message: 'Info',
          ),
        ],
      );
      expect(result.allIssues, hasLength(3));
    });

    test('totalIssues returns count', () {
      const result = EpubValidationResult(
        isValid: false,
        errors: [
          EpubValidationError(
            severity: EpubValidationSeverity.error,
            code: 'E1',
            message: 'Error',
          ),
        ],
        warnings: [
          EpubValidationError(
            severity: EpubValidationSeverity.warning,
            code: 'W1',
            message: 'Warning',
          ),
        ],
      );
      expect(result.totalIssues, equals(2));
    });

    group('Equatable', () {
      test('equal results are equal', () {
        const result1 = EpubValidationResult(isValid: true);
        const result2 = EpubValidationResult(isValid: true);
        expect(result1, equals(result2));
      });

      test('different isValid are not equal', () {
        const result1 = EpubValidationResult(isValid: true);
        const result2 = EpubValidationResult(isValid: false);
        expect(result1, isNot(equals(result2)));
      });
    });
  });

  group('EpubVersion', () {
    test('epub2 has value 2.0', () {
      expect(EpubVersion.epub2.value, equals('2.0'));
    });

    test('epub30 has value 3.0', () {
      expect(EpubVersion.epub30.value, equals('3.0'));
    });

    test('epub31 has value 3.1', () {
      expect(EpubVersion.epub31.value, equals('3.1'));
    });

    test('epub32 has value 3.2', () {
      expect(EpubVersion.epub32.value, equals('3.2'));
    });

    test('epub33 has value 3.3', () {
      expect(EpubVersion.epub33.value, equals('3.3'));
    });

    test('has exactly 5 versions', () {
      expect(EpubVersion.values, hasLength(5));
    });

    group('parse', () {
      test('parses 2.0 to epub2', () {
        expect(EpubVersion.parse('2.0'), equals(EpubVersion.epub2));
      });

      test('parses 3.0 to epub30', () {
        expect(EpubVersion.parse('3.0'), equals(EpubVersion.epub30));
      });

      test('parses 3.1 to epub31', () {
        expect(EpubVersion.parse('3.1'), equals(EpubVersion.epub31));
      });

      test('parses 3.2 to epub32', () {
        expect(EpubVersion.parse('3.2'), equals(EpubVersion.epub32));
      });

      test('parses 3.3 to epub33', () {
        expect(EpubVersion.parse('3.3'), equals(EpubVersion.epub33));
      });

      test('handles whitespace', () {
        expect(EpubVersion.parse('  3.0  '), equals(EpubVersion.epub30));
      });

      test('defaults 3.x variants to epub33', () {
        expect(EpubVersion.parse('3'), equals(EpubVersion.epub33));
        expect(EpubVersion.parse('3.4'), equals(EpubVersion.epub33));
        expect(EpubVersion.parse('3.99'), equals(EpubVersion.epub33));
      });

      test('defaults 2.x variants to epub2', () {
        expect(EpubVersion.parse('2'), equals(EpubVersion.epub2));
        expect(EpubVersion.parse('2.1'), equals(EpubVersion.epub2));
      });

      test('defaults unknown to epub33', () {
        expect(EpubVersion.parse('1.0'), equals(EpubVersion.epub33));
        expect(EpubVersion.parse('unknown'), equals(EpubVersion.epub33));
      });
    });

    group('isEpub3', () {
      test('returns true for EPUB 3.x versions', () {
        expect(EpubVersion.epub30.isEpub3, isTrue);
        expect(EpubVersion.epub31.isEpub3, isTrue);
        expect(EpubVersion.epub32.isEpub3, isTrue);
        expect(EpubVersion.epub33.isEpub3, isTrue);
      });

      test('returns false for EPUB 2.x', () {
        expect(EpubVersion.epub2.isEpub3, isFalse);
      });
    });

    group('isEpub2', () {
      test('returns true for EPUB 2.x', () {
        expect(EpubVersion.epub2.isEpub2, isTrue);
      });

      test('returns false for EPUB 3.x versions', () {
        expect(EpubVersion.epub30.isEpub2, isFalse);
        expect(EpubVersion.epub31.isEpub2, isFalse);
        expect(EpubVersion.epub32.isEpub2, isFalse);
        expect(EpubVersion.epub33.isEpub2, isFalse);
      });
    });

    group('toString', () {
      test('returns formatted string', () {
        expect(EpubVersion.epub2.toString(), equals('EPUB 2.0'));
        expect(EpubVersion.epub30.toString(), equals('EPUB 3.0'));
        expect(EpubVersion.epub33.toString(), equals('EPUB 3.3'));
      });
    });
  });
}
