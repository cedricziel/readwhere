import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:path/path.dart' as p;

import '../config/sample_media_config.dart';
import '../downloader/media_downloader.dart';

/// Creates the sample media builder.
Builder sampleMediaBuilder(BuilderOptions options) {
  return SampleMediaBuilder(options);
}

/// A builder that downloads sample test media on build.
///
/// This builder watches a marker file (`sample_media_trigger.txt`) and
/// downloads sample media when triggered. It caches downloads by version
/// to avoid unnecessary re-downloads.
class SampleMediaBuilder implements Builder {
  /// Builder options from build.yaml.
  final BuilderOptions options;

  /// Creates a new [SampleMediaBuilder].
  SampleMediaBuilder(this.options);

  @override
  Map<String, List<String>> get buildExtensions => {
        'sample_media_trigger.txt': ['.sample_media_marker'],
      };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    // Find the workspace root (where .dart_tool should be)
    final workspaceRoot = _findWorkspaceRoot();
    if (workspaceRoot == null) {
      log.warning(
          'Could not find workspace root. Skipping sample media download.');
      return;
    }

    final cacheDir = Directory(
      p.join(workspaceRoot, '.dart_tool', SampleMediaConfig.cacheDirectoryName),
    );

    // Check if already downloaded with correct version
    if (await MediaDownloader.isAlreadyDownloaded(
      cacheDir,
      SampleMediaConfig.version,
    )) {
      log.fine(
        'Sample media already downloaded (${SampleMediaConfig.version})',
      );
      // Write marker file to satisfy build_runner
      await buildStep.writeAsString(
        buildStep.inputId.changeExtension('.sample_media_marker'),
        'Downloaded: ${SampleMediaConfig.version}',
      );
      return;
    }

    log.info(
        'Downloading sample media from ${SampleMediaConfig.downloadUrl}...');
    log.info('This may take a moment (~10 MB download)...');

    final downloader = MediaDownloader(
      url: SampleMediaConfig.downloadUrl,
      outputDirectory: cacheDir,
      version: SampleMediaConfig.version,
    );

    try {
      await downloader.downloadAndExtract();
      log.info('Sample media downloaded and extracted to ${cacheDir.path}');

      // Write marker file to satisfy build_runner
      await buildStep.writeAsString(
        buildStep.inputId.changeExtension('.sample_media_marker'),
        'Downloaded: ${SampleMediaConfig.version}',
      );
    } on MediaDownloadException catch (e) {
      log.severe('Failed to download sample media: $e');
      rethrow;
    }
  }

  /// Finds the workspace root by looking for pubspec.yaml with workspace key.
  String? _findWorkspaceRoot() {
    var current = Directory.current;
    while (current.path != current.parent.path) {
      final pubspec = File(p.join(current.path, 'pubspec.yaml'));
      if (pubspec.existsSync()) {
        final content = pubspec.readAsStringSync();
        if (content.contains('workspace:')) {
          return current.path;
        }
      }
      current = current.parent;
    }
    return null;
  }
}
