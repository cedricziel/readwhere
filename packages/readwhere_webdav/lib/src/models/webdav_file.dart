import 'package:equatable/equatable.dart';

/// Represents a file or directory on a WebDAV server
///
/// This is a generic representation that works with any WebDAV server.
/// Server-specific extensions can be added via subclassing.
class WebDavFile extends Equatable {
  /// Full path on the WebDAV server (relative to the WebDAV root)
  final String path;

  /// Display name of the file/directory
  final String name;

  /// Whether this is a directory (collection in WebDAV terms)
  final bool isDirectory;

  /// File size in bytes (null for directories)
  final int? size;

  /// Last modification timestamp
  final DateTime? lastModified;

  /// MIME type / content type (null for directories)
  final String? mimeType;

  /// ETag for change detection and caching
  final String? etag;

  const WebDavFile({
    required this.path,
    required this.name,
    required this.isDirectory,
    this.size,
    this.lastModified,
    this.mimeType,
    this.etag,
  });

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
  WebDavFile copyWith({
    String? path,
    String? name,
    bool? isDirectory,
    int? size,
    DateTime? lastModified,
    String? mimeType,
    String? etag,
  }) {
    return WebDavFile(
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
    return 'WebDavFile(path: $path, name: $name, isDirectory: $isDirectory)';
  }
}
