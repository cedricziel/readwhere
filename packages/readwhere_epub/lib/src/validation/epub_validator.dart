import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../errors/epub_exception.dart';
import '../utils/xml_utils.dart';

/// Validation error codes for EPUB files.
class ValidationCodes {
  // Structure errors (STR-xxx)
  static const String strMissingMimetype = 'STR-001';
  static const String strInvalidMimetype = 'STR-002';
  static const String strMissingContainer = 'STR-003';
  static const String strInvalidContainer = 'STR-004';
  static const String strInvalidZip = 'STR-005';
  static const String strMissingOpf = 'STR-006';

  // Package errors (PKG-xxx)
  static const String pkgInvalidOpf = 'PKG-001';
  static const String pkgMissingMetadata = 'PKG-002';
  static const String pkgMissingManifest = 'PKG-003';
  static const String pkgMissingSpine = 'PKG-004';
  static const String pkgEmptySpine = 'PKG-005';
  static const String pkgMissingIdentifier = 'PKG-006';
  static const String pkgMissingTitle = 'PKG-007';
  static const String pkgMissingLanguage = 'PKG-008';

  // Resource errors (RES-xxx)
  static const String resMissingResource = 'RES-001';
  static const String resInvalidMediaType = 'RES-002';
  static const String resInvalidXhtml = 'RES-003';
  static const String resMissingNavDoc = 'RES-004';

  // Warnings (WRN-xxx)
  static const String wrnDeprecatedNcx = 'WRN-001';
  static const String wrnMissingCover = 'WRN-002';
  static const String wrnMissingDescription = 'WRN-003';
  static const String wrnLargeImage = 'WRN-004';
  static const String wrnNonStandardMediaType = 'WRN-005';
}

/// Validator for EPUB files.
///
/// Checks EPUB files for compliance with the EPUB specification and
/// reports errors, warnings, and recommendations.
class EpubValidator {
  /// Maximum image size before warning (5MB).
  static const int _maxImageSize = 5 * 1024 * 1024;

  /// Validates an EPUB file and returns the validation result.
  ///
  /// [filePath] Path to the EPUB file to validate.
  /// [checkResources] Whether to validate resource references (default: true).
  Future<EpubValidationResult> validate(
    String filePath, {
    bool checkResources = true,
  }) async {
    final errors = <EpubValidationError>[];
    final warnings = <EpubValidationError>[];
    final info = <EpubValidationError>[];
    EpubVersion? detectedVersion;

    try {
      // Read file
      final file = File(filePath);
      if (!await file.exists()) {
        errors.add(const EpubValidationError(
          severity: EpubValidationSeverity.error,
          code: ValidationCodes.strInvalidZip,
          message: 'File does not exist',
        ));
        return EpubValidationResult(
          isValid: false,
          errors: errors,
          warnings: warnings,
          info: info,
        );
      }

      final bytes = await file.readAsBytes();

      // Validate structure
      final structureResult = await _validateStructure(bytes);
      errors.addAll(structureResult.errors);
      warnings.addAll(structureResult.warnings);
      info.addAll(structureResult.info);

      if (structureResult.errors.isNotEmpty) {
        // Critical structure errors - can't continue
        return EpubValidationResult(
          isValid: false,
          errors: errors,
          warnings: warnings,
          info: info,
        );
      }

      // Parse the archive
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find and parse container.xml
      final containerFile = archive.findFile('META-INF/container.xml');
      final containerXml = XmlDocument.parse(
        String.fromCharCodes(containerFile!.content as Uint8List),
      );

      // Get OPF path
      final rootfiles = containerXml.findAllElements('rootfile');
      final opfPath = rootfiles.first.getAttribute('full-path');

      // Find and parse OPF
      final opfFile = archive.findFile(opfPath!);
      final opfXml = XmlDocument.parse(
        String.fromCharCodes(opfFile!.content as Uint8List),
      );

      // Validate package document
      final packageResult = _validatePackageDocument(opfXml, opfPath);
      errors.addAll(packageResult.errors);
      warnings.addAll(packageResult.warnings);
      info.addAll(packageResult.info);
      detectedVersion = packageResult.detectedVersion;

      // Validate resources if requested
      if (checkResources) {
        final resourceResult = _validateResources(archive, opfXml, opfPath);
        errors.addAll(resourceResult.errors);
        warnings.addAll(resourceResult.warnings);
        info.addAll(resourceResult.info);
      }

      return EpubValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        warnings: warnings,
        info: info,
        detectedVersion: detectedVersion,
      );
    } catch (e) {
      errors.add(EpubValidationError(
        severity: EpubValidationSeverity.error,
        code: ValidationCodes.strInvalidZip,
        message: 'Failed to parse EPUB: $e',
      ));
      return EpubValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
        info: info,
      );
    }
  }

  /// Performs quick structure-only validation.
  ///
  /// Checks mimetype, container.xml, and OPF existence without
  /// full content validation.
  Future<EpubValidationResult> validateStructure(String filePath) async {
    return validate(filePath, checkResources: false);
  }

  /// Validates the EPUB archive structure.
  Future<EpubValidationResult> _validateStructure(Uint8List bytes) async {
    final errors = <EpubValidationError>[];
    final warnings = <EpubValidationError>[];
    final info = <EpubValidationError>[];

    // Check ZIP signature
    if (bytes.length < 4 ||
        bytes[0] != 0x50 ||
        bytes[1] != 0x4B ||
        bytes[2] != 0x03 ||
        bytes[3] != 0x04) {
      errors.add(const EpubValidationError(
        severity: EpubValidationSeverity.error,
        code: ValidationCodes.strInvalidZip,
        message: 'File is not a valid ZIP archive',
      ));
      return EpubValidationResult(
        isValid: false,
        errors: errors,
      );
    }

    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      errors.add(EpubValidationError(
        severity: EpubValidationSeverity.error,
        code: ValidationCodes.strInvalidZip,
        message: 'Failed to decode ZIP archive: $e',
      ));
      return EpubValidationResult(
        isValid: false,
        errors: errors,
      );
    }

    // Check mimetype file
    final mimetypeFile = archive.findFile('mimetype');
    if (mimetypeFile == null) {
      errors.add(const EpubValidationError(
        severity: EpubValidationSeverity.error,
        code: ValidationCodes.strMissingMimetype,
        message: 'Missing mimetype file',
        location: 'mimetype',
      ));
    } else {
      final mimetypeContent =
          String.fromCharCodes(mimetypeFile.content as Uint8List).trim();
      if (mimetypeContent != 'application/epub+zip') {
        errors.add(EpubValidationError(
          severity: EpubValidationSeverity.error,
          code: ValidationCodes.strInvalidMimetype,
          message:
              'Invalid mimetype: expected "application/epub+zip", got "$mimetypeContent"',
          location: 'mimetype',
        ));
      }
    }

    // Check container.xml
    final containerFile = archive.findFile('META-INF/container.xml');
    if (containerFile == null) {
      errors.add(const EpubValidationError(
        severity: EpubValidationSeverity.error,
        code: ValidationCodes.strMissingContainer,
        message: 'Missing container.xml',
        location: 'META-INF/container.xml',
      ));
      return EpubValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
        info: info,
      );
    }

    // Parse container.xml
    XmlDocument containerXml;
    try {
      containerXml = XmlDocument.parse(
        String.fromCharCodes(containerFile.content as Uint8List),
      );
    } catch (e) {
      errors.add(EpubValidationError(
        severity: EpubValidationSeverity.error,
        code: ValidationCodes.strInvalidContainer,
        message: 'Invalid container.xml XML: $e',
        location: 'META-INF/container.xml',
      ));
      return EpubValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
        info: info,
      );
    }

    // Find rootfile
    final rootfiles = containerXml.findAllElements('rootfile');
    if (rootfiles.isEmpty) {
      errors.add(const EpubValidationError(
        severity: EpubValidationSeverity.error,
        code: ValidationCodes.strInvalidContainer,
        message: 'No rootfile element in container.xml',
        location: 'META-INF/container.xml',
      ));
      return EpubValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
        info: info,
      );
    }

    final opfPath = rootfiles.first.getAttribute('full-path');
    if (opfPath == null || opfPath.isEmpty) {
      errors.add(const EpubValidationError(
        severity: EpubValidationSeverity.error,
        code: ValidationCodes.strInvalidContainer,
        message: 'Missing full-path attribute in rootfile',
        location: 'META-INF/container.xml',
      ));
      return EpubValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
        info: info,
      );
    }

    // Check OPF file exists
    final opfFile = archive.findFile(opfPath);
    if (opfFile == null) {
      errors.add(EpubValidationError(
        severity: EpubValidationSeverity.error,
        code: ValidationCodes.strMissingOpf,
        message: 'Missing OPF file referenced in container.xml',
        location: opfPath,
      ));
    }

    return EpubValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      info: info,
    );
  }

  /// Validates the OPF package document.
  EpubValidationResult _validatePackageDocument(
    XmlDocument opfXml,
    String opfPath,
  ) {
    final errors = <EpubValidationError>[];
    final warnings = <EpubValidationError>[];
    final info = <EpubValidationError>[];
    EpubVersion? detectedVersion;

    // Get package element
    final packageElement = opfXml.rootElement;
    if (packageElement.name.local != 'package') {
      errors.add(EpubValidationError(
        severity: EpubValidationSeverity.error,
        code: ValidationCodes.pkgInvalidOpf,
        message: 'Root element is not <package>',
        location: opfPath,
      ));
      return EpubValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
        info: info,
      );
    }

    // Check version
    final versionStr = packageElement.getAttribute('version');
    if (versionStr != null) {
      detectedVersion = EpubVersion.parse(versionStr);
    }

    // Check metadata
    final metadataElement = XmlUtils.findChildByLocalNameOrNull(
      packageElement,
      'metadata',
    );
    if (metadataElement == null) {
      errors.add(EpubValidationError(
        severity: EpubValidationSeverity.error,
        code: ValidationCodes.pkgMissingMetadata,
        message: 'Missing <metadata> element',
        location: opfPath,
      ));
    } else {
      // Check required metadata
      final identifier =
          metadataElement.findAllElements('dc:identifier').toList();
      if (identifier.isEmpty) {
        // Try without namespace prefix
        final ids = XmlUtils.findAllChildrenByLocalName(
          metadataElement,
          'identifier',
        );
        if (ids.isEmpty) {
          errors.add(EpubValidationError(
            severity: EpubValidationSeverity.error,
            code: ValidationCodes.pkgMissingIdentifier,
            message: 'Missing dc:identifier',
            location: opfPath,
          ));
        }
      }

      final title =
          XmlUtils.findChildByLocalNameOrNull(metadataElement, 'title');
      if (title == null || title.innerText.trim().isEmpty) {
        errors.add(EpubValidationError(
          severity: EpubValidationSeverity.error,
          code: ValidationCodes.pkgMissingTitle,
          message: 'Missing dc:title',
          location: opfPath,
        ));
      }

      final language =
          XmlUtils.findChildByLocalNameOrNull(metadataElement, 'language');
      if (language == null || language.innerText.trim().isEmpty) {
        errors.add(EpubValidationError(
          severity: EpubValidationSeverity.error,
          code: ValidationCodes.pkgMissingLanguage,
          message: 'Missing dc:language',
          location: opfPath,
        ));
      }

      // Check recommended metadata
      final description =
          XmlUtils.findChildByLocalNameOrNull(metadataElement, 'description');
      if (description == null || description.innerText.trim().isEmpty) {
        warnings.add(EpubValidationError(
          severity: EpubValidationSeverity.warning,
          code: ValidationCodes.wrnMissingDescription,
          message: 'Missing dc:description (recommended)',
          location: opfPath,
        ));
      }

      // Check for cover
      final coverMeta = metadataElement
          .findAllElements('meta')
          .where((m) => m.getAttribute('name') == 'cover')
          .toList();
      if (coverMeta.isEmpty) {
        // Check EPUB 3 style cover
        final hasCoverImage = XmlUtils.findChildByLocalNameOrNull(
              packageElement,
              'manifest',
            )?.findAllElements('item').any(
                  (i) =>
                      i.getAttribute('properties')?.contains('cover-image') ??
                      false,
                ) ??
            false;
        if (!hasCoverImage) {
          warnings.add(EpubValidationError(
            severity: EpubValidationSeverity.warning,
            code: ValidationCodes.wrnMissingCover,
            message: 'No cover image defined',
            location: opfPath,
          ));
        }
      }
    }

    // Check manifest
    final manifestElement = XmlUtils.findChildByLocalNameOrNull(
      packageElement,
      'manifest',
    );
    if (manifestElement == null) {
      errors.add(EpubValidationError(
        severity: EpubValidationSeverity.error,
        code: ValidationCodes.pkgMissingManifest,
        message: 'Missing <manifest> element',
        location: opfPath,
      ));
    }

    // Check spine
    final spineElement =
        XmlUtils.findChildByLocalNameOrNull(packageElement, 'spine');
    if (spineElement == null) {
      errors.add(EpubValidationError(
        severity: EpubValidationSeverity.error,
        code: ValidationCodes.pkgMissingSpine,
        message: 'Missing <spine> element',
        location: opfPath,
      ));
    } else {
      final itemrefs =
          XmlUtils.findAllChildrenByLocalName(spineElement, 'itemref');
      if (itemrefs.isEmpty) {
        errors.add(EpubValidationError(
          severity: EpubValidationSeverity.error,
          code: ValidationCodes.pkgEmptySpine,
          message: 'Spine has no items',
          location: opfPath,
        ));
      }

      // Check for NCX (deprecated in EPUB 3)
      final toc = spineElement.getAttribute('toc');
      if (toc != null && detectedVersion?.isEpub3 == true) {
        warnings.add(EpubValidationError(
          severity: EpubValidationSeverity.warning,
          code: ValidationCodes.wrnDeprecatedNcx,
          message: 'NCX navigation is deprecated in EPUB 3',
          location: opfPath,
        ));
      }
    }

    return EpubValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      info: info,
      detectedVersion: detectedVersion,
    );
  }

  /// Validates resource references.
  EpubValidationResult _validateResources(
    Archive archive,
    XmlDocument opfXml,
    String opfPath,
  ) {
    final errors = <EpubValidationError>[];
    final warnings = <EpubValidationError>[];
    final info = <EpubValidationError>[];

    final opfDir = opfPath.contains('/')
        ? opfPath.substring(0, opfPath.lastIndexOf('/'))
        : '';

    // Get manifest items
    final packageElement = opfXml.rootElement;
    final manifestElement =
        XmlUtils.findChildByLocalNameOrNull(packageElement, 'manifest');
    if (manifestElement == null) {
      return EpubValidationResult(
        isValid: true,
        errors: errors,
        warnings: warnings,
        info: info,
      );
    }

    final items = XmlUtils.findAllChildrenByLocalName(manifestElement, 'item');
    var hasNavDoc = false;

    for (final item in items) {
      final href = item.getAttribute('href');
      final mediaType = item.getAttribute('media-type');
      final properties = item.getAttribute('properties') ?? '';

      if (href == null) continue;

      // Resolve href relative to OPF
      final fullPath = opfDir.isNotEmpty ? '$opfDir/$href' : href;
      final normalizedPath = _normalizePath(fullPath);

      // Check file exists
      final file = archive.findFile(normalizedPath);
      if (file == null) {
        errors.add(EpubValidationError(
          severity: EpubValidationSeverity.error,
          code: ValidationCodes.resMissingResource,
          message: 'Missing resource: $href',
          location: normalizedPath,
        ));
        continue;
      }

      // Check nav document
      if (properties.contains('nav')) {
        hasNavDoc = true;
      }

      // Check image sizes
      if (mediaType?.startsWith('image/') == true) {
        if (file.size > _maxImageSize) {
          warnings.add(EpubValidationError(
            severity: EpubValidationSeverity.warning,
            code: ValidationCodes.wrnLargeImage,
            message:
                'Large image (${(file.size / 1024 / 1024).toStringAsFixed(1)} MB)',
            location: normalizedPath,
          ));
        }
      }

      // Check XHTML validity
      if (mediaType == 'application/xhtml+xml') {
        try {
          XmlDocument.parse(
            String.fromCharCodes(file.content as Uint8List),
          );
        } catch (e) {
          errors.add(EpubValidationError(
            severity: EpubValidationSeverity.error,
            code: ValidationCodes.resInvalidXhtml,
            message: 'Invalid XHTML: $e',
            location: normalizedPath,
          ));
        }
      }
    }

    // Check for nav document in EPUB 3
    final versionStr = packageElement.getAttribute('version');
    final version = versionStr != null ? EpubVersion.parse(versionStr) : null;
    if (version?.isEpub3 == true && !hasNavDoc) {
      warnings.add(EpubValidationError(
        severity: EpubValidationSeverity.warning,
        code: ValidationCodes.resMissingNavDoc,
        message: 'EPUB 3 should have a nav document with properties="nav"',
        location: opfPath,
      ));
    }

    return EpubValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      info: info,
    );
  }

  /// Normalizes a file path (removes ./, resolves ..).
  String _normalizePath(String path) {
    final segments = path.split('/');
    final result = <String>[];

    for (final segment in segments) {
      if (segment == '.' || segment.isEmpty) {
        continue;
      } else if (segment == '..') {
        if (result.isNotEmpty) {
          result.removeLast();
        }
      } else {
        result.add(segment);
      }
    }

    return result.join('/');
  }
}
