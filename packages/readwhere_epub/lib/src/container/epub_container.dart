import 'dart:typed_data';

import '../errors/epub_exception.dart';
import '../utils/path_utils.dart';
import 'archive_reader.dart';
import 'container_parser.dart';

/// Provides access to the EPUB OCF container.
///
/// The container is the ZIP archive that holds all EPUB content.
/// This class handles:
/// - Opening the archive
/// - Validating the mimetype
/// - Parsing container.xml
/// - Providing access to files within the EPUB
class EpubContainer {
  /// The underlying archive reader.
  final ArchiveReader _archive;

  /// The parsed container document.
  final ContainerDocument _container;

  /// The base directory of the OPF file.
  ///
  /// All relative paths in the OPF are resolved from this directory.
  final String _opfBasePath;

  EpubContainer._({
    required ArchiveReader archive,
    required ContainerDocument container,
  })  : _archive = archive,
        _container = container,
        _opfBasePath = PathUtils.dirname(container.primaryOpfPath);

  /// Opens an EPUB from a file path.
  ///
  /// Validates the EPUB structure and parses the container document.
  ///
  /// Throws [EpubReadException] if the file cannot be read.
  /// Throws [EpubValidationException] if the EPUB structure is invalid.
  static Future<EpubContainer> fromFile(String filePath) async {
    final archive = await ArchiveReader.fromFile(filePath);
    return _createFromArchive(archive);
  }

  /// Opens an EPUB from bytes.
  ///
  /// Validates the EPUB structure and parses the container document.
  ///
  /// Throws [EpubReadException] if the bytes are not a valid ZIP.
  /// Throws [EpubValidationException] if the EPUB structure is invalid.
  static EpubContainer fromBytes(Uint8List bytes) {
    final archive = ArchiveReader.fromBytes(bytes);
    return _createFromArchive(archive);
  }

  static EpubContainer _createFromArchive(ArchiveReader archive) {
    // Validate mimetype (warning only, don't fail)
    final mimetypeValidation = archive.validateMimetype();
    if (!mimetypeValidation.isValid) {
      // Log warning but continue - many EPUBs have mimetype issues
      // but still work fine
    }

    // Check for container.xml
    if (!archive.hasFile(ContainerParser.containerPath)) {
      throw EpubValidationException(
        'Invalid EPUB: missing ${ContainerParser.containerPath}',
        [
          const EpubValidationError(
            severity: EpubValidationSeverity.error,
            code: 'OCF-001',
            message: 'Missing container.xml',
            location: ContainerParser.containerPath,
          ),
        ],
      );
    }

    // Parse container.xml
    final containerXml = archive.readFileString(ContainerParser.containerPath);
    final container = ContainerParser.parse(containerXml);

    // Verify the OPF file exists
    if (!archive.hasFile(container.primaryOpfPath)) {
      throw EpubValidationException(
        'Invalid EPUB: missing package document at ${container.primaryOpfPath}',
        [
          EpubValidationError(
            severity: EpubValidationSeverity.error,
            code: 'OCF-002',
            message: 'Missing package document',
            location: container.primaryOpfPath,
          ),
        ],
      );
    }

    return EpubContainer._(
      archive: archive,
      container: container,
    );
  }

  /// The parsed container document.
  ContainerDocument get container => _container;

  /// Path to the primary package document (.opf file).
  String get opfPath => _container.primaryOpfPath;

  /// Base directory for resolving relative paths in the OPF.
  String get opfBasePath => _opfBasePath;

  /// List of all file paths in the EPUB.
  List<String> get filePaths => _archive.filePaths;

  /// Number of files in the EPUB.
  int get fileCount => _archive.fileCount;

  /// Checks if a file exists in the EPUB.
  bool hasFile(String path) {
    return _archive.hasFile(path);
  }

  /// Reads a file as bytes.
  ///
  /// The [path] should be relative to the EPUB root.
  ///
  /// Throws [EpubResourceNotFoundException] if the file doesn't exist.
  Uint8List readFileBytes(String path) {
    return _archive.readFileBytes(path);
  }

  /// Reads a file as a string (UTF-8).
  ///
  /// The [path] should be relative to the EPUB root.
  ///
  /// Throws [EpubResourceNotFoundException] if the file doesn't exist.
  String readFileString(String path) {
    return _archive.readFileString(path);
  }

  /// Reads the OPF package document content.
  String readOpf() {
    return _archive.readFileString(opfPath);
  }

  /// Resolves a path relative to the OPF directory.
  ///
  /// Given a relative path from a manifest item, returns the full path
  /// within the EPUB archive.
  String resolveOpfRelativePath(String relativePath) {
    if (relativePath.startsWith('/')) {
      // Absolute path within EPUB
      return PathUtils.normalize(relativePath);
    }
    return PathUtils.resolve(opfPath, relativePath);
  }

  /// Reads a file relative to the OPF directory.
  ///
  /// Throws [EpubResourceNotFoundException] if the file doesn't exist.
  Uint8List readOpfRelativeBytes(String relativePath) {
    final fullPath = resolveOpfRelativePath(relativePath);
    return readFileBytes(fullPath);
  }

  /// Reads a file relative to the OPF directory as a string.
  ///
  /// Throws [EpubResourceNotFoundException] if the file doesn't exist.
  String readOpfRelativeString(String relativePath) {
    final fullPath = resolveOpfRelativePath(relativePath);
    return readFileString(fullPath);
  }

  /// Resolves a path relative to a content document.
  ///
  /// Given a base path (e.g., "OEBPS/Text/chapter1.xhtml") and a relative
  /// path (e.g., "../Images/cover.jpg"), returns the resolved path
  /// (e.g., "OEBPS/Images/cover.jpg").
  String resolvePath(String basePath, String relativePath) {
    return PathUtils.resolve(basePath, relativePath);
  }

  /// Checks if the EPUB has encryption metadata.
  ///
  /// Note: This library does not support DRM decryption.
  bool hasEncryption() {
    return _archive.hasFile('META-INF/encryption.xml');
  }

  /// Validates the mimetype file.
  MimetypeValidation validateMimetype() {
    return _archive.validateMimetype();
  }
}
