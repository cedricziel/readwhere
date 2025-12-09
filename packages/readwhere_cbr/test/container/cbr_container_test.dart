import 'dart:io';

import 'package:readwhere_cbr/src/container/cbr_container.dart';
import 'package:readwhere_cbr/src/errors/cbr_exception.dart';
import 'package:test/test.dart';

void main() {
  group('CbrContainer', () {
    group('fromFile', () {
      test('throws CbrReadException for non-existent file', () async {
        expect(
          () => CbrContainer.fromFile('/non/existent/file.cbr'),
          throwsA(isA<CbrReadException>()),
        );
      });

      test('throws CbrReadException with file path', () async {
        try {
          await CbrContainer.fromFile('/non/existent/file.cbr');
          fail('Expected CbrReadException');
        } on CbrReadException catch (e) {
          expect(e.filePath, '/non/existent/file.cbr');
        }
      });
    });

    group('fromFileObject', () {
      test('throws CbrReadException for non-existent file', () async {
        final file = File('/non/existent/file.cbr');
        expect(
          () => CbrContainer.fromFileObject(file),
          throwsA(isA<CbrReadException>()),
        );
      });
    });

    group('kImageExtensions', () {
      test('contains expected extensions', () {
        expect(kImageExtensions, contains('.jpg'));
        expect(kImageExtensions, contains('.jpeg'));
        expect(kImageExtensions, contains('.png'));
        expect(kImageExtensions, contains('.gif'));
        expect(kImageExtensions, contains('.webp'));
      });

      test('does not contain non-image extensions', () {
        expect(kImageExtensions, isNot(contains('.txt')));
        expect(kImageExtensions, isNot(contains('.xml')));
        expect(kImageExtensions, isNot(contains('.cbr')));
      });
    });

    group('constants', () {
      test('ComicInfo filename is correct', () {
        expect(kComicInfoFilename, 'ComicInfo.xml');
      });

      test('MetronInfo filename is correct', () {
        expect(kMetronInfoFilename, 'MetronInfo.xml');
      });
    });
  });
}
