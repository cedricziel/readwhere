import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;

import '../config/sample_media_config.dart';

/// Downloads and extracts sample media archives.
class MediaDownloader {
  /// The URL to download from.
  final String url;

  /// The directory to extract files to.
  final Directory outputDirectory;

  /// The version string to write after successful download.
  final String version;

  /// Creates a new [MediaDownloader].
  MediaDownloader({
    required this.url,
    required this.outputDirectory,
    required this.version,
  });

  /// Downloads the ZIP and extracts it to the output directory.
  ///
  /// Clears the output directory before extraction if it exists.
  /// Writes a version file on successful completion.
  Future<void> downloadAndExtract() async {
    // Ensure output directory exists and is clean
    if (await outputDirectory.exists()) {
      await outputDirectory.delete(recursive: true);
    }
    await outputDirectory.create(recursive: true);

    // Download the ZIP
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw MediaDownloadException(
        'Failed to download sample media: HTTP ${response.statusCode}',
      );
    }

    final bytes = response.bodyBytes;

    // Extract ZIP contents
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final outputFile = File('${outputDirectory.path}/$filename');
        await outputFile.parent.create(recursive: true);
        await outputFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory('${outputDirectory.path}/$filename')
            .create(recursive: true);
      }
    }

    // Write version file
    final versionFile = File(
      '${outputDirectory.path}/${SampleMediaConfig.versionFileName}',
    );
    await versionFile.writeAsString(version);
  }

  /// Checks if the media is already downloaded with the correct version.
  static Future<bool> isAlreadyDownloaded(
    Directory cacheDir,
    String expectedVersion,
  ) async {
    final versionFile = File(
      '${cacheDir.path}/${SampleMediaConfig.versionFileName}',
    );
    if (!await versionFile.exists()) return false;

    final storedVersion = await versionFile.readAsString();
    return storedVersion.trim() == expectedVersion;
  }
}

/// Exception thrown when media download fails.
class MediaDownloadException implements Exception {
  /// The error message.
  final String message;

  /// Creates a new [MediaDownloadException].
  MediaDownloadException(this.message);

  @override
  String toString() => 'MediaDownloadException: $message';
}
