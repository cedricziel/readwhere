import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Information about an available app update.
class UpdateInfo {
  /// The latest version available (e.g., "1.2.0").
  final String version;

  /// The release notes/changelog for this version.
  final String? releaseNotes;

  /// URL to the GitHub releases page.
  final String releaseUrl;

  /// URL to download the APK (if available).
  final String? apkDownloadUrl;

  /// When the release was published.
  final DateTime? publishedAt;

  const UpdateInfo({
    required this.version,
    this.releaseNotes,
    required this.releaseUrl,
    this.apkDownloadUrl,
    this.publishedAt,
  });
}

/// Result of checking for updates.
class UpdateCheckResult {
  /// Whether an update is available.
  final bool updateAvailable;

  /// Information about the update (if available).
  final UpdateInfo? updateInfo;

  /// The current app version.
  final String currentVersion;

  /// Error message if the check failed.
  final String? error;

  const UpdateCheckResult({
    required this.updateAvailable,
    this.updateInfo,
    required this.currentVersion,
    this.error,
  });

  factory UpdateCheckResult.error(String currentVersion, String error) {
    return UpdateCheckResult(
      updateAvailable: false,
      currentVersion: currentVersion,
      error: error,
    );
  }

  factory UpdateCheckResult.noUpdate(String currentVersion) {
    return UpdateCheckResult(
      updateAvailable: false,
      currentVersion: currentVersion,
    );
  }

  factory UpdateCheckResult.available(
    String currentVersion,
    UpdateInfo updateInfo,
  ) {
    return UpdateCheckResult(
      updateAvailable: true,
      updateInfo: updateInfo,
      currentVersion: currentVersion,
    );
  }
}

/// Service for checking app updates via GitHub releases.
class UpdateService {
  final http.Client _httpClient;
  final String _owner;
  final String _repo;

  /// Creates an UpdateService.
  ///
  /// [httpClient] - HTTP client for making requests.
  /// [owner] - GitHub repository owner (e.g., "cedricziel").
  /// [repo] - GitHub repository name (e.g., "readwhere").
  UpdateService({
    required http.Client httpClient,
    String owner = 'cedricziel',
    String repo = 'readwhere',
  }) : _httpClient = httpClient,
       _owner = owner,
       _repo = repo;

  /// Checks for available updates.
  ///
  /// Compares the current app version with the latest GitHub release.
  /// Returns [UpdateCheckResult] with update information or error.
  Future<UpdateCheckResult> checkForUpdate() async {
    String currentVersion;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version;
    } catch (e) {
      return UpdateCheckResult.error(
        'unknown',
        'Failed to get app version: $e',
      );
    }

    try {
      final response = await _httpClient
          .get(
            Uri.parse(
              'https://api.github.com/repos/$_owner/$_repo/releases/latest',
            ),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        // No releases yet
        return UpdateCheckResult.noUpdate(currentVersion);
      }

      if (response.statusCode != 200) {
        return UpdateCheckResult.error(
          currentVersion,
          'GitHub API error: ${response.statusCode}',
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String?;

      if (tagName == null) {
        return UpdateCheckResult.noUpdate(currentVersion);
      }

      // Remove 'v' prefix if present (e.g., "v1.2.0" -> "1.2.0")
      final latestVersion = tagName.startsWith('v')
          ? tagName.substring(1)
          : tagName;

      // Compare versions
      if (!_isNewerVersion(latestVersion, currentVersion)) {
        return UpdateCheckResult.noUpdate(currentVersion);
      }

      // Find APK download URL if available
      String? apkDownloadUrl;
      final assets = data['assets'] as List<dynamic>?;
      if (assets != null) {
        for (final asset in assets) {
          final name = asset['name'] as String?;
          if (name != null && name.endsWith('.apk')) {
            apkDownloadUrl = asset['browser_download_url'] as String?;
            break;
          }
        }
      }

      // Parse published date
      DateTime? publishedAt;
      final publishedAtStr = data['published_at'] as String?;
      if (publishedAtStr != null) {
        publishedAt = DateTime.tryParse(publishedAtStr);
      }

      final updateInfo = UpdateInfo(
        version: latestVersion,
        releaseNotes: data['body'] as String?,
        releaseUrl:
            data['html_url'] as String? ??
            'https://github.com/$_owner/$_repo/releases/latest',
        apkDownloadUrl: apkDownloadUrl,
        publishedAt: publishedAt,
      );

      return UpdateCheckResult.available(currentVersion, updateInfo);
    } on SocketException {
      return UpdateCheckResult.error(currentVersion, 'No internet connection');
    } on TimeoutException {
      return UpdateCheckResult.error(currentVersion, 'Connection timed out');
    } on http.ClientException catch (e) {
      return UpdateCheckResult.error(
        currentVersion,
        'Network error: ${e.message}',
      );
    } catch (e) {
      return UpdateCheckResult.error(
        currentVersion,
        'Failed to check for updates: $e',
      );
    }
  }

  /// Compares two semantic versions.
  ///
  /// Returns true if [latest] is newer than [current].
  bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();

      // Pad with zeros to ensure same length
      while (latestParts.length < 3) {
        latestParts.add(0);
      }
      while (currentParts.length < 3) {
        currentParts.add(0);
      }

      // Compare major, minor, patch
      for (var i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) {
          return true;
        }
        if (latestParts[i] < currentParts[i]) {
          return false;
        }
      }

      return false; // Versions are equal
    } catch (e) {
      // If parsing fails, assume no update
      return false;
    }
  }

  /// Gets the URL to the releases page.
  String get releasesUrl => 'https://github.com/$_owner/$_repo/releases';
}
