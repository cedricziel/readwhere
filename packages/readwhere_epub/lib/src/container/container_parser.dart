import 'package:equatable/equatable.dart';
import 'package:xml/xml.dart';

import '../errors/epub_exception.dart';
import '../utils/xml_utils.dart';

/// Parses the META-INF/container.xml file.
///
/// The container.xml file is required per OCF specification and
/// contains the location of the package document(s).
class ContainerParser {
  ContainerParser._();

  /// The path to the container file within the EPUB.
  static const String containerPath = 'META-INF/container.xml';

  /// Parses container.xml content and returns a [ContainerDocument].
  ///
  /// Throws [EpubParseException] if the XML is invalid or required
  /// elements are missing.
  static ContainerDocument parse(String xml) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(xml);
    } on XmlException catch (e) {
      throw EpubParseException(
        'Failed to parse container.xml: ${e.message}',
        documentPath: containerPath,
        cause: e,
      );
    }

    final root = document.rootElement;

    // Validate root element
    if (root.localName != 'container') {
      throw EpubParseException(
        'Invalid container.xml: expected <container> root element, found <${root.localName}>',
        documentPath: containerPath,
      );
    }

    // Get version
    final version = root.getAttribute('version') ?? '1.0';

    // Find rootfiles element
    final rootfilesElement =
        XmlUtils.findChildByLocalNameOrNull(root, 'rootfiles');
    if (rootfilesElement == null) {
      throw const EpubParseException(
        'Invalid container.xml: missing <rootfiles> element',
        documentPath: containerPath,
      );
    }

    // Parse rootfile elements
    final rootfileElements =
        XmlUtils.findAllChildrenByLocalName(rootfilesElement, 'rootfile');

    if (rootfileElements.isEmpty) {
      throw const EpubParseException(
        'Invalid container.xml: no <rootfile> elements found',
        documentPath: containerPath,
      );
    }

    final rootfiles = <Rootfile>[];
    for (final element in rootfileElements) {
      final fullPath = element.getAttribute('full-path');
      if (fullPath == null || fullPath.isEmpty) {
        throw const EpubParseException(
          'Invalid container.xml: <rootfile> missing full-path attribute',
          documentPath: containerPath,
        );
      }

      final mediaType =
          element.getAttribute('media-type') ?? 'application/oebps-package+xml';

      rootfiles.add(Rootfile(
        fullPath: fullPath,
        mediaType: mediaType,
      ));
    }

    return ContainerDocument(
      version: version,
      rootfiles: rootfiles,
    );
  }
}

/// Represents the parsed container.xml document.
class ContainerDocument extends Equatable {
  /// Container version (typically "1.0").
  final String version;

  /// List of rootfiles (package documents).
  final List<Rootfile> rootfiles;

  const ContainerDocument({
    required this.version,
    required this.rootfiles,
  });

  /// The primary (first) rootfile.
  ///
  /// Per OCF spec, the first rootfile is the default rendition.
  Rootfile get primaryRootfile => rootfiles.first;

  /// The path to the primary package document (.opf file).
  String get primaryOpfPath => primaryRootfile.fullPath;

  /// Whether there are multiple renditions.
  bool get hasMultipleRenditions => rootfiles.length > 1;

  @override
  List<Object?> get props => [version, rootfiles];
}

/// A rootfile entry pointing to a package document.
class Rootfile extends Equatable {
  /// Full path to the package document within the EPUB.
  final String fullPath;

  /// Media type (should be "application/oebps-package+xml").
  final String mediaType;

  const Rootfile({
    required this.fullPath,
    required this.mediaType,
  });

  /// Whether this is a standard OPF package document.
  bool get isOpf => mediaType == 'application/oebps-package+xml';

  @override
  List<Object?> get props => [fullPath, mediaType];
}
