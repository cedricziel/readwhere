import 'package:equatable/equatable.dart';

/// Represents a file or directory in Synology Drive.
class SynologyFile extends Equatable {
  /// Creates a new [SynologyFile].
  const SynologyFile({
    required this.fileId,
    required this.name,
    required this.path,
    required this.displayPath,
    required this.type,
    this.contentType,
    this.size,
    this.modifiedTime,
    this.createdTime,
    this.hash,
    this.parentId,
    this.permanentLink,
    this.isStarred = false,
    this.isShared = false,
    this.isEncrypted = false,
  });

  /// Creates a [SynologyFile] from a JSON response.
  factory SynologyFile.fromJson(Map<String, dynamic> json) {
    return SynologyFile(
      fileId: json['file_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      displayPath: json['display_path'] as String? ?? '',
      type: json['type'] as String? ?? 'file',
      contentType: json['content_type'] as String?,
      size: json['size'] as int?,
      modifiedTime: _parseTimestamp(json['modified_time']),
      createdTime: _parseTimestamp(json['created_time']),
      hash: json['hash'] as String?,
      parentId: json['parent_id'] as String?,
      permanentLink: json['permanent_link'] as String?,
      isStarred: json['starred'] as bool? ?? false,
      isShared: json['shared'] as bool? ?? false,
      isEncrypted: json['encrypted'] as bool? ?? false,
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      // Unix timestamp in seconds
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    return null;
  }

  /// The unique file ID.
  final String fileId;

  /// The file or directory name.
  final String name;

  /// The full path to the file.
  final String path;

  /// The display path for the user.
  final String displayPath;

  /// The file type ('file' or 'dir').
  final String type;

  /// The content type ('document', 'image', 'audio', 'video', 'file', 'dir').
  final String? contentType;

  /// The file size in bytes.
  final int? size;

  /// The last modification time.
  final DateTime? modifiedTime;

  /// The creation time.
  final DateTime? createdTime;

  /// Hash of the file content for change detection.
  final String? hash;

  /// The parent folder ID.
  final String? parentId;

  /// Permanent link UUID for this file.
  final String? permanentLink;

  /// Whether the file is starred.
  final bool isStarred;

  /// Whether the file is shared with others.
  final bool isShared;

  /// Whether the file is encrypted.
  final bool isEncrypted;

  /// Whether this is a directory.
  bool get isDirectory => type == 'dir' || contentType == 'dir';

  /// The file extension (lowercase, without dot).
  String get extension {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) return '';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  /// Whether this is an EPUB file.
  bool get isEpub => extension == 'epub';

  /// Whether this is a PDF file.
  bool get isPdf => extension == 'pdf';

  /// Whether this is a CBZ comic file.
  bool get isCbz => extension == 'cbz';

  /// Whether this is a CBR comic file.
  bool get isCbr => extension == 'cbr';

  /// Whether this is a comic file (CBZ or CBR).
  bool get isComic => isCbz || isCbr;

  /// Whether this is a supported book format.
  bool get isSupportedBook => isEpub || isPdf || isComic;

  /// The MIME type based on file extension.
  String get mimeType {
    if (isDirectory) return 'inode/directory';
    switch (extension) {
      case 'epub':
        return 'application/epub+zip';
      case 'pdf':
        return 'application/pdf';
      case 'cbz':
        return 'application/vnd.comicbook+zip';
      case 'cbr':
        return 'application/vnd.comicbook-rar';
      default:
        return 'application/octet-stream';
    }
  }

  /// Formats the file size for display.
  String get formattedSize {
    if (size == null) return '';
    final bytes = size!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  List<Object?> get props => [
        fileId,
        name,
        path,
        displayPath,
        type,
        contentType,
        size,
        modifiedTime,
        createdTime,
        hash,
        parentId,
        permanentLink,
        isStarred,
        isShared,
        isEncrypted,
      ];

  @override
  String toString() {
    return 'SynologyFile(name: $name, type: $type, path: $path)';
  }
}
