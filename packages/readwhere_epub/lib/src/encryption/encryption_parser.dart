import 'package:xml/xml.dart';

import 'encryption_info.dart';

/// Parser for EPUB encryption.xml files.
class EncryptionParser {
  /// XML namespace for encryption.
  static const String encryptionNs = 'http://www.w3.org/2001/04/xmlenc#';

  /// XML namespace for digital signatures.
  static const String dsigNs = 'http://www.w3.org/2000/09/xmldsig#';

  /// Parses encryption.xml content into [EncryptionInfo].
  ///
  /// If the content is null or empty, returns [EncryptionInfo.none].
  static EncryptionInfo parse(
    String? encryptionXml, {
    bool hasRightsFile = false,
    bool hasLcpLicense = false,
  }) {
    if (encryptionXml == null || encryptionXml.trim().isEmpty) {
      return EncryptionInfo.none;
    }

    try {
      final document = XmlDocument.parse(encryptionXml);
      return _parseDocument(document, hasRightsFile, hasLcpLicense);
    } on XmlException {
      // If we can't parse, assume there's encryption but unknown type
      return EncryptionInfo(
        type: EncryptionType.unknown,
        hasRightsFile: hasRightsFile,
        hasLcpLicense: hasLcpLicense,
      );
    }
  }

  static EncryptionInfo _parseDocument(
    XmlDocument document,
    bool hasRightsFile,
    bool hasLcpLicense,
  ) {
    final root = document.rootElement;

    // Find all EncryptedData elements
    final encryptedDataElements = root.findAllElements(
      'EncryptedData',
      namespace: encryptionNs,
    );

    final resources = <EncryptedResource>[];
    final algorithms = <String>{};

    for (final encryptedData in encryptedDataElements) {
      final resource = _parseEncryptedData(encryptedData);
      if (resource != null) {
        resources.add(resource);
        algorithms.add(resource.algorithm);
      }
    }

    // Also check without namespace (some EPUBs don't use namespaces properly)
    if (resources.isEmpty) {
      final fallbackElements =
          root.descendantElements.where((e) => e.localName == 'EncryptedData');

      for (final encryptedData in fallbackElements) {
        final resource = _parseEncryptedData(encryptedData);
        if (resource != null) {
          resources.add(resource);
          algorithms.add(resource.algorithm);
        }
      }
    }

    // Determine encryption type
    final type =
        _detectEncryptionType(algorithms, hasRightsFile, hasLcpLicense);

    return EncryptionInfo(
      type: type,
      encryptedResources: resources,
      hasRightsFile: hasRightsFile,
      hasLcpLicense: hasLcpLicense,
      algorithms: algorithms,
    );
  }

  static EncryptedResource? _parseEncryptedData(XmlElement element) {
    // Get algorithm from EncryptionMethod
    String? algorithm;
    final encryptionMethod =
        element.findElements('EncryptionMethod').firstOrNull ??
            element
                .findElements('EncryptionMethod', namespace: encryptionNs)
                .firstOrNull;

    if (encryptionMethod != null) {
      algorithm = encryptionMethod.getAttribute('Algorithm');
    }

    // Get URI from CipherData/CipherReference
    String? uri;
    final cipherData = element.findElements('CipherData').firstOrNull ??
        element.findElements('CipherData', namespace: encryptionNs).firstOrNull;

    if (cipherData != null) {
      final cipherReference =
          cipherData.findElements('CipherReference').firstOrNull ??
              cipherData
                  .findElements('CipherReference', namespace: encryptionNs)
                  .firstOrNull;

      if (cipherReference != null) {
        uri = cipherReference.getAttribute('URI');
      }
    }

    // Get retrieval method if present
    String? retrievalMethod;
    final keyInfo = element.findElements('KeyInfo').firstOrNull ??
        element.findElements('KeyInfo', namespace: dsigNs).firstOrNull;

    if (keyInfo != null) {
      final retrievalMethodElement =
          keyInfo.findElements('RetrievalMethod').firstOrNull ??
              keyInfo
                  .findElements('RetrievalMethod', namespace: dsigNs)
                  .firstOrNull;

      if (retrievalMethodElement != null) {
        retrievalMethod = retrievalMethodElement.getAttribute('URI');
      }
    }

    if (uri == null || algorithm == null) {
      return null;
    }

    return EncryptedResource(
      uri: uri,
      algorithm: algorithm,
      retrievalMethod: retrievalMethod,
    );
  }

  static EncryptionType _detectEncryptionType(
    Set<String> algorithms,
    bool hasRightsFile,
    bool hasLcpLicense,
  ) {
    if (algorithms.isEmpty) {
      return EncryptionType.none;
    }

    // Check for LCP first (most modern)
    if (hasLcpLicense ||
        algorithms.any((a) => a.contains('lcp') || a.contains('readium'))) {
      return EncryptionType.lcp;
    }

    // Check for Adobe DRM
    if (hasRightsFile ||
        algorithms.any((a) =>
            a == 'http://www.idpf.org/2008/epub/algo/user_key' ||
            a.contains('adobe') ||
            a.contains('adept'))) {
      return EncryptionType.adobeDrm;
    }

    // Check for Apple FairPlay
    if (algorithms.any((a) => a.contains('fairplay') || a.contains('apple'))) {
      return EncryptionType.appleFairPlay;
    }

    // Check if it's only font obfuscation
    final nonFontAlgorithms = algorithms.where((a) =>
        !a.contains('obfuscation') &&
        a != 'http://www.idpf.org/2008/embedding' &&
        a != 'http://ns.adobe.com/pdf/enc#RC');

    if (nonFontAlgorithms.isEmpty) {
      return EncryptionType.fontObfuscation;
    }

    return EncryptionType.unknown;
  }
}
