import 'package:equatable/equatable.dart';

/// Type of encryption/DRM used in the EPUB.
enum EncryptionType {
  /// No encryption detected.
  none,

  /// Adobe Digital Editions DRM (ADEPT).
  adobeDrm,

  /// Apple FairPlay DRM (used by Apple Books).
  appleFairPlay,

  /// Readium LCP (Licensed Content Protection).
  lcp,

  /// IDPF font obfuscation (not DRM, just font protection).
  fontObfuscation,

  /// Unknown encryption type.
  unknown,
}

/// Information about an encrypted resource in the EPUB.
class EncryptedResource extends Equatable {
  /// Path to the encrypted resource within the EPUB.
  final String uri;

  /// Encryption algorithm URI.
  final String algorithm;

  /// How to retrieve the decryption key (optional).
  final String? retrievalMethod;

  const EncryptedResource({
    required this.uri,
    required this.algorithm,
    this.retrievalMethod,
  });

  /// Whether this is font obfuscation (not real DRM).
  bool get isFontObfuscation =>
      algorithm.contains('obfuscation') ||
      algorithm == 'http://www.idpf.org/2008/embedding' ||
      algorithm == 'http://ns.adobe.com/pdf/enc#RC';

  /// Whether this is Adobe DRM encryption.
  bool get isAdobeDrm =>
      algorithm.contains('adobe') ||
      algorithm == 'http://www.idpf.org/2008/epub/algo/user_key' ||
      algorithm == 'http://ns.adobe.com/adept/enc#RC';

  /// Whether this is Readium LCP encryption.
  bool get isLcp =>
      algorithm.contains('lcp') || algorithm.contains('readium.org');

  @override
  List<Object?> get props => [uri, algorithm, retrievalMethod];

  @override
  String toString() => 'EncryptedResource($uri, algorithm: $algorithm)';
}

/// Information about encryption in an EPUB.
class EncryptionInfo extends Equatable {
  /// The primary encryption type detected.
  final EncryptionType type;

  /// List of encrypted resources.
  final List<EncryptedResource> encryptedResources;

  /// Whether a rights file (e.g., rights.xml for Adobe DRM) exists.
  final bool hasRightsFile;

  /// Whether an LCP license file exists.
  final bool hasLcpLicense;

  /// Raw encryption algorithm URIs found.
  final Set<String> algorithms;

  const EncryptionInfo({
    this.type = EncryptionType.none,
    this.encryptedResources = const [],
    this.hasRightsFile = false,
    this.hasLcpLicense = false,
    this.algorithms = const {},
  });

  /// No encryption.
  static const EncryptionInfo none = EncryptionInfo();

  /// Whether the EPUB has any encryption.
  bool get isEncrypted => encryptedResources.isNotEmpty;

  /// Whether the EPUB has DRM (not just font obfuscation).
  bool get hasDrm =>
      type != EncryptionType.none && type != EncryptionType.fontObfuscation;

  /// Whether all encrypted resources are just font obfuscation.
  bool get isOnlyFontObfuscation =>
      encryptedResources.isNotEmpty &&
      encryptedResources.every((r) => r.isFontObfuscation);

  /// Number of encrypted resources.
  int get encryptedResourceCount => encryptedResources.length;

  /// Resources encrypted with actual DRM (excluding font obfuscation).
  List<EncryptedResource> get drmEncryptedResources =>
      encryptedResources.where((r) => !r.isFontObfuscation).toList();

  /// Resources with font obfuscation only.
  List<EncryptedResource> get fontObfuscatedResources =>
      encryptedResources.where((r) => r.isFontObfuscation).toList();

  /// A human-readable description of the encryption.
  String get description {
    switch (type) {
      case EncryptionType.none:
        return 'No encryption';
      case EncryptionType.adobeDrm:
        return 'Adobe DRM protected';
      case EncryptionType.appleFairPlay:
        return 'Apple FairPlay protected';
      case EncryptionType.lcp:
        return 'Readium LCP protected';
      case EncryptionType.fontObfuscation:
        return 'Font obfuscation only';
      case EncryptionType.unknown:
        return 'Unknown encryption';
    }
  }

  @override
  List<Object?> get props => [
        type,
        encryptedResources,
        hasRightsFile,
        hasLcpLicense,
        algorithms,
      ];

  @override
  String toString() =>
      'EncryptionInfo($type, ${encryptedResources.length} resources)';
}
