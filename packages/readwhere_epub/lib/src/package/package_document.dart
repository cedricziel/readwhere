import 'package:equatable/equatable.dart';
import 'package:xml/xml.dart';

import '../errors/epub_exception.dart';
import '../utils/xml_utils.dart';
import 'manifest/manifest.dart';
import 'metadata/metadata.dart';
import 'spine/spine.dart';

/// Parses and represents the OPF package document.
class PackageDocument extends Equatable {
  /// Path to the OPF file within the EPUB.
  final String path;

  /// EPUB version (e.g., "3.0", "2.0").
  final EpubVersion version;

  /// Unique identifier for the publication.
  final String uniqueIdentifier;

  /// Publication metadata.
  final EpubMetadata metadata;

  /// Manifest of all resources.
  final EpubManifest manifest;

  /// Spine (reading order).
  final EpubSpine spine;

  /// Whether this is a fixed-layout publication.
  final bool isFixedLayout;

  const PackageDocument({
    required this.path,
    required this.version,
    required this.uniqueIdentifier,
    required this.metadata,
    required this.manifest,
    required this.spine,
    this.isFixedLayout = false,
  });

  /// Parses an OPF package document from XML.
  ///
  /// Throws [EpubParseException] if the XML is invalid or required
  /// elements are missing.
  factory PackageDocument.parse(String xml, String path) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(xml);
    } on XmlException catch (e) {
      throw EpubParseException(
        'Failed to parse package document: ${e.message}',
        documentPath: path,
        cause: e,
      );
    }

    final root = document.rootElement;

    // Validate root element
    if (root.localName != 'package') {
      throw EpubParseException(
        'Invalid package document: expected <package> root element',
        documentPath: path,
      );
    }

    // Get version
    final versionStr = root.getAttribute('version') ?? '3.0';
    final version = EpubVersion.parse(versionStr);

    // Get unique-identifier reference
    final uniqueIdRef = root.getAttribute('unique-identifier');

    // Parse metadata
    final metadataElement = XmlUtils.findChildByLocalNameOrNull(root, 'metadata');
    if (metadataElement == null) {
      throw EpubParseException(
        'Invalid package document: missing <metadata> element',
        documentPath: path,
      );
    }
    final metadata = _parseMetadata(metadataElement, uniqueIdRef, version, path);

    // Parse manifest
    final manifestElement = XmlUtils.findChildByLocalNameOrNull(root, 'manifest');
    if (manifestElement == null) {
      throw EpubParseException(
        'Invalid package document: missing <manifest> element',
        documentPath: path,
      );
    }
    final manifest = _parseManifest(manifestElement);

    // Parse spine
    final spineElement = XmlUtils.findChildByLocalNameOrNull(root, 'spine');
    if (spineElement == null) {
      throw EpubParseException(
        'Invalid package document: missing <spine> element',
        documentPath: path,
      );
    }
    final spine = _parseSpine(spineElement);

    // Check for fixed layout
    final isFixedLayout = _checkFixedLayout(metadataElement);

    return PackageDocument(
      path: path,
      version: version,
      uniqueIdentifier: metadata.identifier,
      metadata: metadata,
      manifest: manifest,
      spine: spine,
      isFixedLayout: isFixedLayout,
    );
  }

  static EpubMetadata _parseMetadata(
    XmlElement element,
    String? uniqueIdRef,
    EpubVersion version,
    String path,
  ) {
    // Parse identifiers
    final identifiers = <EpubIdentifier>[];
    String? primaryIdentifier;

    for (final dcId in XmlUtils.findAllElementsByNs(
      element,
      'identifier',
      EpubNamespaces.dc,
    )) {
      final value = dcId.innerText.trim();
      if (value.isEmpty) continue;

      final id = dcId.getAttribute('id');
      final scheme = dcId.getAttribute('scheme') ??
          dcId.getAttribute('scheme', namespace: EpubNamespaces.opf);

      final isPrimary = id != null && id == uniqueIdRef;
      if (isPrimary) {
        primaryIdentifier = value;
      }

      identifiers.add(EpubIdentifier(
        value: value,
        scheme: scheme,
        isPrimary: isPrimary,
        id: id,
      ));
    }

    // Use first identifier if no unique-identifier match
    if (primaryIdentifier == null && identifiers.isNotEmpty) {
      primaryIdentifier = identifiers.first.value;
    }
    primaryIdentifier ??= 'unknown';

    // Parse titles
    final titles = <EpubTitle>[];
    String? mainTitle;

    for (final dcTitle in XmlUtils.findAllElementsByNs(
      element,
      'title',
      EpubNamespaces.dc,
    )) {
      final value = dcTitle.innerText.trim();
      if (value.isEmpty) continue;

      final id = dcTitle.getAttribute('id');
      final lang = dcTitle.getAttribute('lang') ??
          dcTitle.getAttribute('lang', namespace: 'http://www.w3.org/XML/1998/namespace');

      // Look for title-type refinement
      TitleType? titleType;
      int? displaySeq;

      if (id != null) {
        for (final meta in XmlUtils.findAllChildrenByLocalName(element, 'meta')) {
          final refines = meta.getAttribute('refines');
          if (refines == '#$id') {
            final property = meta.getAttribute('property');
            if (property == 'title-type') {
              titleType = TitleType.fromString(meta.innerText.trim());
            } else if (property == 'display-seq') {
              displaySeq = int.tryParse(meta.innerText.trim());
            }
          }
        }
      }

      final title = EpubTitle(
        value: value,
        type: titleType,
        language: lang,
        displaySeq: displaySeq,
        id: id,
      );
      titles.add(title);

      if (mainTitle == null || titleType == TitleType.main) {
        mainTitle = value;
      }
    }

    mainTitle ??= 'Untitled';

    // Parse language
    String language = 'en';
    final dcLang = XmlUtils.findElementByNs(element, 'language', EpubNamespaces.dc);
    if (dcLang != null) {
      final langValue = dcLang.innerText.trim();
      if (langValue.isNotEmpty) {
        language = langValue;
      }
    }

    // Parse creators
    final creators = <EpubCreator>[];
    for (final dcCreator in XmlUtils.findAllElementsByNs(
      element,
      'creator',
      EpubNamespaces.dc,
    )) {
      final name = dcCreator.innerText.trim();
      if (name.isEmpty) continue;

      final id = dcCreator.getAttribute('id');
      final fileAs = dcCreator.getAttribute('file-as') ??
          dcCreator.getAttribute('file-as', namespace: EpubNamespaces.opf);
      var role = dcCreator.getAttribute('role') ??
          dcCreator.getAttribute('role', namespace: EpubNamespaces.opf);

      // Look for role refinement
      if (id != null && role == null) {
        for (final meta in XmlUtils.findAllChildrenByLocalName(element, 'meta')) {
          final refines = meta.getAttribute('refines');
          if (refines == '#$id') {
            final property = meta.getAttribute('property');
            if (property == 'role') {
              role = meta.innerText.trim();
              break;
            }
          }
        }
      }

      creators.add(EpubCreator(
        name: name,
        fileAs: fileAs,
        role: role,
        id: id,
      ));
    }

    // Parse contributors
    final contributors = <EpubCreator>[];
    for (final dcContrib in XmlUtils.findAllElementsByNs(
      element,
      'contributor',
      EpubNamespaces.dc,
    )) {
      final name = dcContrib.innerText.trim();
      if (name.isEmpty) continue;

      final id = dcContrib.getAttribute('id');
      final fileAs = dcContrib.getAttribute('file-as') ??
          dcContrib.getAttribute('file-as', namespace: EpubNamespaces.opf);
      final role = dcContrib.getAttribute('role') ??
          dcContrib.getAttribute('role', namespace: EpubNamespaces.opf);

      contributors.add(EpubCreator(
        name: name,
        fileAs: fileAs,
        role: role,
        id: id,
      ));
    }

    // Parse other Dublin Core elements
    final publisher = XmlUtils.getChildTextNs(element, 'publisher', EpubNamespaces.dc);
    final description = XmlUtils.getChildTextNs(element, 'description', EpubNamespaces.dc);
    final rights = XmlUtils.getChildTextNs(element, 'rights', EpubNamespaces.dc);
    final source = XmlUtils.getChildTextNs(element, 'source', EpubNamespaces.dc);
    final type = XmlUtils.getChildTextNs(element, 'type', EpubNamespaces.dc);
    final format = XmlUtils.getChildTextNs(element, 'format', EpubNamespaces.dc);
    final coverage = XmlUtils.getChildTextNs(element, 'coverage', EpubNamespaces.dc);

    // Parse subjects
    final subjects = <String>[];
    for (final dcSubject in XmlUtils.findAllElementsByNs(
      element,
      'subject',
      EpubNamespaces.dc,
    )) {
      final value = dcSubject.innerText.trim();
      if (value.isNotEmpty) {
        subjects.add(value);
      }
    }

    // Parse relations
    final relations = <String>[];
    for (final dcRelation in XmlUtils.findAllElementsByNs(
      element,
      'relation',
      EpubNamespaces.dc,
    )) {
      final value = dcRelation.innerText.trim();
      if (value.isNotEmpty) {
        relations.add(value);
      }
    }

    // Parse date
    DateTime? date;
    final dcDate = XmlUtils.getChildTextNs(element, 'date', EpubNamespaces.dc);
    if (dcDate != null) {
      date = _parseDate(dcDate);
    }

    // Parse modified date (EPUB 3)
    DateTime? modified;
    for (final meta in XmlUtils.findAllChildrenByLocalName(element, 'meta')) {
      final property = meta.getAttribute('property');
      if (property == 'dcterms:modified') {
        modified = _parseDate(meta.innerText.trim());
        break;
      }
    }

    // Parse cover image ID (EPUB 2 style)
    String? coverImageId;
    for (final meta in XmlUtils.findAllChildrenByLocalName(element, 'meta')) {
      final name = meta.getAttribute('name');
      if (name == 'cover') {
        coverImageId = meta.getAttribute('content');
        break;
      }
    }

    // Parse additional meta properties
    final metaMap = <String, String>{};
    for (final meta in XmlUtils.findAllChildrenByLocalName(element, 'meta')) {
      final property = meta.getAttribute('property');
      final refines = meta.getAttribute('refines');

      // Only include non-refinement meta elements
      if (property != null && refines == null) {
        metaMap[property] = meta.innerText.trim();
      }
    }

    return EpubMetadata(
      identifier: primaryIdentifier,
      title: mainTitle,
      language: language,
      creators: creators,
      contributors: contributors,
      publisher: publisher,
      description: description,
      subjects: subjects,
      date: date,
      rights: rights,
      source: source,
      type: type,
      format: format,
      relations: relations,
      coverage: coverage,
      modified: modified,
      coverImageId: coverImageId,
      identifiers: identifiers,
      titles: titles,
      meta: metaMap,
      version: version,
    );
  }

  static EpubManifest _parseManifest(XmlElement element) {
    final items = <ManifestItem>[];

    for (final item in XmlUtils.findAllChildrenByLocalName(element, 'item')) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      final mediaType = item.getAttribute('media-type');

      if (id == null || href == null || mediaType == null) {
        continue; // Skip invalid items
      }

      // Parse properties
      final propertiesStr = item.getAttribute('properties') ?? '';
      final properties = propertiesStr.isEmpty
          ? <String>{}
          : propertiesStr.split(' ').where((p) => p.isNotEmpty).toSet();

      final fallback = item.getAttribute('fallback');
      final mediaOverlay = item.getAttribute('media-overlay');

      items.add(ManifestItem(
        id: id,
        href: href,
        mediaType: mediaType,
        properties: properties,
        fallback: fallback,
        mediaOverlay: mediaOverlay,
      ));
    }

    return EpubManifest(items);
  }

  static EpubSpine _parseSpine(XmlElement element) {
    final items = <SpineItem>[];

    // Get toc attribute (NCX reference for EPUB 2)
    final toc = element.getAttribute('toc');

    // Get page progression direction
    final ppdStr = element.getAttribute('page-progression-direction');
    final pageProgression = switch (ppdStr?.toLowerCase()) {
      'ltr' => PageProgression.ltr,
      'rtl' => PageProgression.rtl,
      _ => PageProgression.defaultDirection,
    };

    for (final itemref in XmlUtils.findAllChildrenByLocalName(element, 'itemref')) {
      final idref = itemref.getAttribute('idref');
      if (idref == null) continue;

      // Parse linear attribute (default is true)
      final linearStr = itemref.getAttribute('linear');
      final linear = linearStr?.toLowerCase() != 'no';

      // Parse properties
      final propertiesStr = itemref.getAttribute('properties') ?? '';
      final properties = propertiesStr.isEmpty
          ? <String>{}
          : propertiesStr.split(' ').where((p) => p.isNotEmpty).toSet();

      items.add(SpineItem(
        idref: idref,
        linear: linear,
        properties: properties,
      ));
    }

    return EpubSpine(
      items: items,
      toc: toc,
      pageProgression: pageProgression,
    );
  }

  static bool _checkFixedLayout(XmlElement metadataElement) {
    // Check for rendition:layout property
    for (final meta in XmlUtils.findAllChildrenByLocalName(metadataElement, 'meta')) {
      final property = meta.getAttribute('property');
      if (property == 'rendition:layout') {
        return meta.innerText.trim() == 'pre-paginated';
      }
    }
    return false;
  }

  static DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    try {
      // Try ISO 8601 format first
      return DateTime.parse(dateStr);
    } catch (_) {
      // Try other common formats
      try {
        // Year only: "2024"
        if (dateStr.length == 4) {
          final year = int.tryParse(dateStr);
          if (year != null) {
            return DateTime(year);
          }
        }
        // Year-month: "2024-01"
        if (dateStr.length == 7 && dateStr.contains('-')) {
          final parts = dateStr.split('-');
          if (parts.length == 2) {
            final year = int.tryParse(parts[0]);
            final month = int.tryParse(parts[1]);
            if (year != null && month != null) {
              return DateTime(year, month);
            }
          }
        }
      } catch (_) {
        // Ignore parsing errors
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [
        path,
        version,
        uniqueIdentifier,
        metadata,
        manifest,
        spine,
        isFixedLayout,
      ];
}
