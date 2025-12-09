import 'package:readwhere_webdav/readwhere_webdav.dart';

/// Represents a file or directory on a Nextcloud server
///
/// Extends [WebDavFile] with Nextcloud-specific helper properties
/// for identifying supported book formats.
class NextcloudFile extends WebDavFile {
  const NextcloudFile({
    required super.path,
    required super.name,
    required super.isDirectory,
    super.size,
    super.lastModified,
    super.mimeType,
    super.etag,
  });

  /// Create from a generic WebDavFile
  factory NextcloudFile.fromWebDavFile(WebDavFile file) {
    return NextcloudFile(
      path: file.path,
      name: file.name,
      isDirectory: file.isDirectory,
      size: file.size,
      lastModified: file.lastModified,
      mimeType: file.mimeType,
      etag: file.etag,
    );
  }

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

  @override
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
}
