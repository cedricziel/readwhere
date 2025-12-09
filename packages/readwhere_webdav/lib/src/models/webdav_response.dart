import 'webdav_file.dart';

/// Response from a PROPFIND request
class PropfindResponse {
  /// List of files/directories returned
  final List<WebDavFile> files;

  /// The path that was queried
  final String requestPath;

  const PropfindResponse({
    required this.files,
    required this.requestPath,
  });
}

/// Response from a file download
class DownloadResponse {
  /// Path where the file was saved
  final String localPath;

  /// ETag of the downloaded file
  final String? etag;

  /// Content type of the downloaded file
  final String? contentType;

  /// Size in bytes
  final int? size;

  const DownloadResponse({
    required this.localPath,
    this.etag,
    this.contentType,
    this.size,
  });
}

/// Response from a HEAD request
class HeadResponse {
  /// ETag of the resource
  final String? etag;

  /// Content type
  final String? contentType;

  /// Content length in bytes
  final int? contentLength;

  /// Last modified date
  final DateTime? lastModified;

  const HeadResponse({
    this.etag,
    this.contentType,
    this.contentLength,
    this.lastModified,
  });
}
