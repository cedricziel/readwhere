/// Sample test media provider for ReadWhere packages.
///
/// This package downloads sample EPUB, CBZ, CBR, PDF, and other format files
/// for use in integration tests across ReadWhere packages.
///
/// ## Setup
///
/// Add as a dev_dependency:
///
/// ```yaml
/// dev_dependencies:
///   readwhere_sample_media:
///     path: ../readwhere_sample_media
/// ```
///
/// Create a `build.yaml` in your package to enable the builder:
///
/// ```yaml
/// targets:
///   $default:
///     builders:
///       readwhere_sample_media:sample_media_downloader:
///         enabled: true
/// ```
///
/// ## Downloading Sample Media
///
/// Run `dart run build_runner build` to download the media.
/// Files are cached in `.dart_tool/sample_media/` and won't re-download
/// unless the version changes.
///
/// ## Usage in Tests
///
/// ```dart
/// import 'package:readwhere_sample_media/readwhere_sample_media.dart';
/// import 'package:test/test.dart';
///
/// void main() {
///   setUpAll(() {
///     if (!SampleMediaPaths.isDownloaded) {
///       throw StateError(
///         'Sample media not downloaded. Run: dart run build_runner build',
///       );
///     }
///   });
///
///   test('reads sample EPUB', () {
///     final epubs = SampleMediaPaths.epubFiles;
///     expect(epubs, isNotEmpty);
///   });
/// }
/// ```
///
/// ## Available File Types
///
/// - [SampleMediaPaths.epubFiles] - EPUB e-books
/// - [SampleMediaPaths.cbzFiles] - CBZ comic archives
/// - [SampleMediaPaths.cbrFiles] - CBR comic archives
/// - [SampleMediaPaths.pdfFiles] - PDF documents
/// - [SampleMediaPaths.fb2Files] - FictionBook files
/// - [SampleMediaPaths.htmlFiles] - HTML files
/// - [SampleMediaPaths.txtFiles] - Plain text files
/// - [SampleMediaPaths.allFiles] - All sample files
library;

export 'src/config/sample_media_config.dart';
export 'src/paths/sample_media_paths.dart';
