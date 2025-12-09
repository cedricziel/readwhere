import 'package:equatable/equatable.dart';

/// Represents a file or directory on a Nextcloud server
///
/// Used for WebDAV directory listings and file operations.
class NextcloudFile extends Equatable {
  /// Full path on the Nextcloud server (relative to WebDAV root)
  final String path;

  /// Display name of the file/directory
  final String name;

  /// Whether this is a directory
  final bool isDirectory;

  /// File size in bytes (null for directories)
  final int? size;

  /// Last modification timestamp
  final DateTime? lastModified;

  /// MIME type (null for directories)
  final String? mimeType;

  /// ETag for change detection
  final String? etag;

  const NextcloudFile({
    required this.path,
    required this.name,
    required this.isDirectory,
    this.size,
    this.lastModified,
    this.mimeType,
    this.etag,
  });

  /// Whether this file is an EPUB ebook
  bool get isEpub =>
      mimeType == 'application/epub+zip' ||
      name.toLowerCase().endsWith('.epub');

  /// Whether this file is a PDF document
  bool get isPdf =>
      mimeType == 'application/pdf' || name.toLowerCase().endsWith('.pdf');

  /// Whether this file is a CBZ/CBR comic archive
  bool get isComic =>
      name.toLowerCase().endsWith('.cbz') ||
      name.toLowerCase().endsWith('.cbr');

  /// Whether this is a supported book format
  bool get isSupportedBook => isEpub || isPdf || isComic;

  /// Get the file extension (lowercase, without dot)
  String? get extension {
    final lastDot = name.lastIndexOf('.');
    if (lastDot == -1 || lastDot == name.length - 1) return null;
    return name.substring(lastDot + 1).toLowerCase();
  }

  /// Get the parent directory path
  String get parentPath {
    final lastSlash = path.lastIndexOf('/');
    if (lastSlash <= 0) return '/';
    return path.substring(0, lastSlash);
  }

  /// Create a copy with updated fields
  NextcloudFile copyWith({
    String? path,
    String? name,
    bool? isDirectory,
    int? size,
    DateTime? lastModified,
    String? mimeType,
    String? etag,
  }) {
    return NextcloudFile(
      path: path ?? this.path,
      name: name ?? this.name,
      isDirectory: isDirectory ?? this.isDirectory,
      size: size ?? this.size,
      lastModified: lastModified ?? this.lastModified,
      mimeType: mimeType ?? this.mimeType,
      etag: etag ?? this.etag,
    );
  }

  @override
  List<Object?> get props => [
    path,
    name,
    isDirectory,
    size,
    lastModified,
    mimeType,
    etag,
  ];

  @override
  String toString() {
    return 'NextcloudFile(path: $path, name: $name, isDirectory: $isDirectory)';
  }
}
