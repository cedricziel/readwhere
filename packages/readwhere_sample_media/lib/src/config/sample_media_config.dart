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

/// Configuration for encrypted EPUB test samples.
///
/// These samples are not automatically downloaded but can be obtained
/// from EDRLab for testing Readium LCP decryption.
class EncryptedSampleConfig {
  EncryptedSampleConfig._();

  /// OPDS feed URL for EDRLab LCP test samples.
  ///
  /// Use this URL in an OPDS-compatible client to browse available
  /// LCP-protected test EPUBs.
  static const String edrlabOpdsFeed =
      'https://edrlab.org/public/feed/opds-lcp.json';

  /// Test passphrase for EDRLab LCP samples.
  ///
  /// All EDRLab test EPUBs use this passphrase.
  static const String edrlabPassphrase = 'edrlab rocks';

  /// Passphrase hint shown in EDRLab LCP licenses.
  static const String edrlabPassphraseHint = 'What do you think about EDRLab?';

  /// Individual LCP license URLs for test EPUBs.
  ///
  /// Download these `.lcpl` files, then use an LCP-compatible reader
  /// to acquire the actual encrypted EPUB.
  static const Map<String, String> edrlabLicenses = {
    'Moby-Dick': 'https://edrlab.org/public/feed/moby-dick/moby-dick.lcpl',
    'The Waste Land':
        'https://edrlab.org/public/feed/the-waste-land/the-waste-land.lcpl',
    'Accessible EPUB 3':
        'https://edrlab.org/public/feed/accessible-epub-3/accessible-epub-3.lcpl',
  };

  /// Environment variable name for setting the encrypted samples path.
  ///
  /// Set this to the directory containing downloaded LCP-protected EPUBs
  /// to enable integration tests with real encrypted content.
  static const String envSamplesPath = 'EDRLAB_LCP_SAMPLES_PATH';
}
