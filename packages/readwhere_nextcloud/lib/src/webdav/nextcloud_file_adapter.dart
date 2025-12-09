import 'package:readwhere_plugin/readwhere_plugin.dart';

import 'nextcloud_file.dart';

/// Converts Nextcloud files to catalog entries.
///
/// This adapter bridges between the Nextcloud-specific file representation
/// and the generic [CatalogEntry] interface used by the plugin system.
class NextcloudFileAdapter {
  /// Creates the adapter with the given server URL and user ID.
  ///
  /// These are needed to construct full download URLs.
  NextcloudFileAdapter({
    required this.serverUrl,
    required this.userId,
  });

  /// The base server URL (normalized, no trailing slash).
  final String serverUrl;

  /// The user ID for WebDAV path construction.
  final String userId;

  /// Converts a [NextcloudFile] to a [CatalogEntry].
  CatalogEntry toEntry(NextcloudFile file) {
    if (file.isDirectory) {
      return _toNavigationEntry(file);
    } else if (file.isSupportedBook) {
      return _toBookEntry(file);
    } else {
      // Return as navigation entry for unsupported files
      return _toNavigationEntry(file);
    }
  }

  /// Converts a list of [NextcloudFile]s to [CatalogEntry]s.
  List<CatalogEntry> toEntries(List<NextcloudFile> files) {
    return files.map(toEntry).toList();
  }

  /// Converts a list of [NextcloudFile]s to a [BrowseResult].
  BrowseResult toBrowseResult(
    List<NextcloudFile> files, {
    String? title,
    String? parentPath,
  }) {
    // Filter out unsupported files, keep directories and supported books
    final filteredFiles = files.where((f) {
      if (f.isDirectory) return true;
      return f.isSupportedBook;
    }).toList();

    return BrowseResult(
      entries: toEntries(filteredFiles),
      title: title,
      properties: {
        if (parentPath != null) 'parentPath': parentPath,
      },
    );
  }

  DefaultCatalogEntry _toNavigationEntry(NextcloudFile file) {
    return DefaultCatalogEntry(
      id: file.path,
      title: file.name,
      type: CatalogEntryType.navigation,
      properties: {
        'path': file.path,
        'isDirectory': file.isDirectory,
        if (file.lastModified != null)
          'lastModified': file.lastModified!.toIso8601String(),
      },
    );
  }

  DefaultCatalogEntry _toBookEntry(NextcloudFile file) {
    final downloadUrl = _buildDownloadUrl(file.path);
    final mimeType = _getMimeType(file);

    return DefaultCatalogEntry(
      id: file.path,
      title: _extractBookTitle(file.name),
      type: CatalogEntryType.book,
      subtitle: _extractSubtitle(file),
      files: [
        CatalogFile(
          href: downloadUrl,
          mimeType: mimeType,
          size: file.size,
          isPrimary: true,
          properties: {
            'path': file.path,
            if (file.etag != null) 'etag': file.etag,
          },
        ),
      ],
      properties: {
        'path': file.path,
        if (file.lastModified != null)
          'lastModified': file.lastModified!.toIso8601String(),
        if (file.etag != null) 'etag': file.etag,
      },
    );
  }

  String _buildDownloadUrl(String path) {
    // Build full WebDAV URL for downloading
    return '$serverUrl/remote.php/dav/files/$userId$path';
  }

  String _getMimeType(NextcloudFile file) {
    // Use the file's MIME type if available, otherwise infer from extension
    if (file.mimeType != null && file.mimeType!.isNotEmpty) {
      return file.mimeType!;
    }

    final name = file.name.toLowerCase();
    if (name.endsWith('.epub')) return 'application/epub+zip';
    if (name.endsWith('.pdf')) return 'application/pdf';
    if (name.endsWith('.cbz')) return 'application/x-cbz';
    if (name.endsWith('.cbr')) return 'application/x-cbr';
    return 'application/octet-stream';
  }

  String _extractBookTitle(String filename) {
    // Remove file extension
    final lastDot = filename.lastIndexOf('.');
    if (lastDot > 0) {
      return filename.substring(0, lastDot);
    }
    return filename;
  }

  String? _extractSubtitle(NextcloudFile file) {
    // Could extract author from filename patterns like "Title - Author.epub"
    // For now, just return the file size as subtitle
    if (file.size != null) {
      return _formatFileSize(file.size!);
    }
    return null;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Extension methods for converting NextcloudFile lists to browse results.
extension NextcloudFilesToBrowseResult on List<NextcloudFile> {
  /// Converts this list to a [BrowseResult] using the given adapter.
  BrowseResult toBrowseResult(
    NextcloudFileAdapter adapter, {
    String? title,
    String? parentPath,
  }) {
    return adapter.toBrowseResult(this, title: title, parentPath: parentPath);
  }
}
