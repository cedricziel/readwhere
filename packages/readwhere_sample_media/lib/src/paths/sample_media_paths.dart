import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/sample_media_config.dart';

/// Provides paths to sample media files for tests.
class SampleMediaPaths {
  SampleMediaPaths._();

  static Directory? _cachedRootDirectory;

  /// Root directory containing extracted sample media.
  ///
  /// Locates the workspace root by searching upward for pubspec.yaml
  /// with a workspace key, then returns `.dart_tool/sample_media/`.
  static Directory get rootDirectory {
    if (_cachedRootDirectory != null) return _cachedRootDirectory!;

    // Find the workspace root by looking for pubspec.yaml with workspace key
    var current = Directory.current;
    while (current.path != current.parent.path) {
      final pubspec = File(p.join(current.path, 'pubspec.yaml'));
      if (pubspec.existsSync()) {
        final content = pubspec.readAsStringSync();
        if (content.contains('workspace:')) {
          _cachedRootDirectory = Directory(
            p.join(
              current.path,
              '.dart_tool',
              SampleMediaConfig.cacheDirectoryName,
            ),
          );
          return _cachedRootDirectory!;
        }
      }
      current = current.parent;
    }

    // Fallback: assume we're in a package within packages/
    _cachedRootDirectory = Directory(
      p.join(
        Directory.current.path,
        '..',
        '..',
        '.dart_tool',
        SampleMediaConfig.cacheDirectoryName,
      ),
    );
    return _cachedRootDirectory!;
  }

  /// Clears the cached root directory.
  ///
  /// Useful for testing when the working directory changes.
  static void clearCache() {
    _cachedRootDirectory = null;
  }

  /// Gets all files with a specific extension.
  ///
  /// [extension] can be with or without leading dot (e.g., 'epub' or '.epub').
  static List<File> getFilesByExtension(String extension) {
    final ext = extension.startsWith('.') ? extension : '.$extension';
    final files = <File>[];
    _collectFiles(rootDirectory, files, ext);
    return files;
  }

  static void _collectFiles(Directory dir, List<File> files, String ext) {
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File &&
          entity.path.toLowerCase().endsWith(ext.toLowerCase())) {
        files.add(entity);
      }
    }
  }

  /// Gets the first file with a specific extension, or null.
  static File? getFirstFileByExtension(String extension) {
    final files = getFilesByExtension(extension);
    return files.isNotEmpty ? files.first : null;
  }

  /// Checks if sample media has been downloaded.
  static bool get isDownloaded {
    final versionFile = File(
      p.join(rootDirectory.path, SampleMediaConfig.versionFileName),
    );
    return versionFile.existsSync();
  }

  /// Gets the downloaded version, or null if not downloaded.
  static String? get downloadedVersion {
    final versionFile = File(
      p.join(rootDirectory.path, SampleMediaConfig.versionFileName),
    );
    if (!versionFile.existsSync()) return null;
    return versionFile.readAsStringSync().trim();
  }

  /// EPUB sample files.
  static List<File> get epubFiles => getFilesByExtension('epub');

  /// CBZ sample files.
  static List<File> get cbzFiles => getFilesByExtension('cbz');

  /// CBR sample files.
  static List<File> get cbrFiles => getFilesByExtension('cbr');

  /// CB7 sample files.
  static List<File> get cb7Files => getFilesByExtension('cb7');

  /// CBT sample files.
  static List<File> get cbtFiles => getFilesByExtension('cbt');

  /// PDF sample files.
  static List<File> get pdfFiles => getFilesByExtension('pdf');

  /// FB2 (FictionBook) sample files.
  static List<File> get fb2Files => getFilesByExtension('fb2');

  /// HTML sample files.
  static List<File> get htmlFiles => getFilesByExtension('html');

  /// TXT sample files.
  static List<File> get txtFiles => getFilesByExtension('txt');

  /// Markdown sample files.
  static List<File> get mdFiles => getFilesByExtension('md');

  /// All sample files.
  static List<File> get allFiles {
    final files = <File>[];
    if (!rootDirectory.existsSync()) return files;
    for (final entity in rootDirectory.listSync(recursive: true)) {
      if (entity is File && !p.basename(entity.path).startsWith('.')) {
        files.add(entity);
      }
    }
    return files;
  }
}
