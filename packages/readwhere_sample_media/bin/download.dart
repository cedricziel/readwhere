import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:readwhere_sample_media/readwhere_sample_media.dart';
import 'package:readwhere_sample_media/src/downloader/media_downloader.dart';

/// Downloads sample test media to .dart_tool/sample_media/.
///
/// Usage: dart run readwhere_sample_media:download
///
/// Add --force to re-download even if already present.
Future<void> main(List<String> args) async {
  final force = args.contains('--force') || args.contains('-f');

  print('Sample Media Downloader');
  print('=======================');
  print('');

  // Find workspace root
  final workspaceRoot = _findWorkspaceRoot();
  if (workspaceRoot == null) {
    print(
        'Error: Could not find workspace root (pubspec.yaml with workspace key)');
    exit(1);
  }

  final cacheDir = Directory(
    p.join(workspaceRoot, '.dart_tool', SampleMediaConfig.cacheDirectoryName),
  );

  print('Workspace root: $workspaceRoot');
  print('Cache directory: ${cacheDir.path}');
  print('');

  // Check if already downloaded
  if (!force &&
      await MediaDownloader.isAlreadyDownloaded(
          cacheDir, SampleMediaConfig.version)) {
    print('Sample media already downloaded (${SampleMediaConfig.version})');
    print('Use --force to re-download.');
    _printStats(cacheDir);
    exit(0);
  }

  print('Downloading from: ${SampleMediaConfig.downloadUrl}');
  print('Version: ${SampleMediaConfig.version}');
  print('');
  print('Downloading... (this may take a moment, ~10 MB)');

  final stopwatch = Stopwatch()..start();

  final downloader = MediaDownloader(
    url: SampleMediaConfig.downloadUrl,
    outputDirectory: cacheDir,
    version: SampleMediaConfig.version,
  );

  try {
    await downloader.downloadAndExtract();
    stopwatch.stop();

    print('');
    print('Download complete in ${stopwatch.elapsed.inSeconds}s');
    _printStats(cacheDir);
    exit(0);
  } on MediaDownloadException catch (e) {
    print('');
    print('Error: $e');
    exit(1);
  }
}

void _printStats(Directory cacheDir) {
  if (!cacheDir.existsSync()) return;

  print('');
  print('Available files:');

  final byExtension = <String, int>{};
  for (final entity in cacheDir.listSync(recursive: true)) {
    if (entity is File) {
      final ext = p.extension(entity.path).toLowerCase();
      if (ext.isNotEmpty && !p.basename(entity.path).startsWith('.')) {
        byExtension[ext] = (byExtension[ext] ?? 0) + 1;
      }
    }
  }

  final sorted = byExtension.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  for (final entry in sorted) {
    print('  ${entry.key}: ${entry.value} file(s)');
  }
}

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
