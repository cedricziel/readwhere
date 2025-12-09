/// Configuration for sample media downloads.
class SampleMediaConfig {
  SampleMediaConfig._();

  /// The URL to download sample media from.
  static const String downloadUrl =
      'https://github.com/clach04/sample_reading_media/releases/download/v0.2/sample_reading_media.zip';

  /// Expected version identifier (used to detect if re-download needed).
  static const String version = 'v0.2';

  /// Directory name within .dart_tool for storing media.
  static const String cacheDirectoryName = 'sample_media';

  /// File indicating download completion with version info.
  static const String versionFileName = '.version';

  /// Known file types in the sample media archive.
  static const Map<String, List<String>> knownExtensions = {
    'epub': ['epub'],
    'pdf': ['pdf'],
    'fb2': ['fb2'],
    'cbz': ['cbz'],
    'cbr': ['cbr'],
    'cb7': ['cb7'],
    'cbt': ['cbt'],
    'odt': ['odt'],
    'docx': ['docx'],
    'txt': ['txt'],
    'html': ['html', 'htm'],
    'rtf': ['rtf'],
    'md': ['md'],
    'zip': ['zip'],
  };
}
