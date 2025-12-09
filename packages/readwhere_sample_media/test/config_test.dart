import 'package:readwhere_sample_media/readwhere_sample_media.dart';
import 'package:test/test.dart';

void main() {
  group('SampleMediaConfig', () {
    test('has valid download URL', () {
      expect(SampleMediaConfig.downloadUrl, isNotEmpty);
      expect(
        Uri.tryParse(SampleMediaConfig.downloadUrl),
        isNotNull,
        reason: 'URL should be valid',
      );
      expect(
        SampleMediaConfig.downloadUrl,
        startsWith('https://'),
        reason: 'URL should use HTTPS',
      );
    });

    test('has version', () {
      expect(SampleMediaConfig.version, isNotEmpty);
      expect(SampleMediaConfig.version, startsWith('v'));
    });

    test('has cache directory name', () {
      expect(SampleMediaConfig.cacheDirectoryName, isNotEmpty);
      expect(SampleMediaConfig.cacheDirectoryName, equals('sample_media'));
    });

    test('has version file name', () {
      expect(SampleMediaConfig.versionFileName, isNotEmpty);
      expect(SampleMediaConfig.versionFileName, startsWith('.'));
    });

    test('has known extensions for common formats', () {
      expect(SampleMediaConfig.knownExtensions, containsPair('epub', ['epub']));
      expect(SampleMediaConfig.knownExtensions, containsPair('cbz', ['cbz']));
      expect(SampleMediaConfig.knownExtensions, containsPair('cbr', ['cbr']));
      expect(SampleMediaConfig.knownExtensions, containsPair('pdf', ['pdf']));
    });
  });
}
