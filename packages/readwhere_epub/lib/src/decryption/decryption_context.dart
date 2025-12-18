import 'dart:typed_data';

import '../encryption/encryption_info.dart';
import 'decryption_algorithm.dart';
import 'font_obfuscation.dart';
import 'lcp_decryptor.dart';
import 'lcp_license.dart';

/// Context for decrypting EPUB resources.
///
/// This class manages the decryption state for an EPUB, including:
/// - Font deobfuscation (IDPF and Adobe algorithms)
/// - Readium LCP decryption
///
/// The context is created based on the EPUB's encryption information
/// and any credentials provided by the user.
class DecryptionContext {
  /// The EPUB's unique identifier (used for font deobfuscation).
  final String uniqueIdentifier;

  /// Encryption information from encryption.xml.
  final EncryptionInfo encryptionInfo;

  /// LCP decryptor (if LCP license is present and unlocked).
  final LcpDecryptor? lcpDecryptor;

  /// Whether resources can be decrypted.
  final bool canDecrypt;

  DecryptionContext._({
    required this.uniqueIdentifier,
    required this.encryptionInfo,
    this.lcpDecryptor,
    required this.canDecrypt,
  });

  /// Creates a decryption context for an EPUB.
  ///
  /// [uniqueIdentifier] - The EPUB's unique identifier from metadata.
  /// [encryptionInfo] - Parsed encryption.xml information.
  /// [lcpLicenseJson] - Content of license.lcpl (if present).
  /// [lcpPassphrase] - User's passphrase for LCP (if applicable).
  ///
  /// Returns a context that can decrypt resources.
  factory DecryptionContext.create({
    required String uniqueIdentifier,
    required EncryptionInfo encryptionInfo,
    String? lcpLicenseJson,
    String? lcpPassphrase,
  }) {
    LcpDecryptor? lcpDecryptor;
    var canDecrypt = true;

    // Handle LCP encryption
    if (encryptionInfo.type == EncryptionType.lcp && lcpLicenseJson != null) {
      if (lcpPassphrase != null) {
        try {
          lcpDecryptor = LcpDecryptor.create(lcpLicenseJson, lcpPassphrase);
        } catch (e) {
          // Passphrase invalid - cannot decrypt
          canDecrypt = false;
        }
      } else {
        // LCP but no passphrase provided
        canDecrypt = false;
      }
    }

    // Font obfuscation is always decodable (no credentials needed)
    // Adobe DRM and Apple FairPlay cannot be decrypted
    if (encryptionInfo.type == EncryptionType.adobeDrm ||
        encryptionInfo.type == EncryptionType.appleFairPlay) {
      canDecrypt = false;
    }

    return DecryptionContext._(
      uniqueIdentifier: uniqueIdentifier,
      encryptionInfo: encryptionInfo,
      lcpDecryptor: lcpDecryptor,
      canDecrypt: canDecrypt,
    );
  }

  /// Creates a context for an unencrypted EPUB.
  factory DecryptionContext.none(String uniqueIdentifier) {
    return DecryptionContext._(
      uniqueIdentifier: uniqueIdentifier,
      encryptionInfo: EncryptionInfo.none,
      canDecrypt: true,
    );
  }

  /// Decrypts a resource if needed.
  ///
  /// [uri] - The resource path within the EPUB.
  /// [data] - The resource bytes.
  ///
  /// Returns the decrypted bytes, or the original bytes if not encrypted.
  /// Throws [DecryptionException] if decryption fails.
  Uint8List decryptResource(String uri, Uint8List data) {
    // Find encryption info for this resource
    final resource = _findEncryptedResource(uri);

    if (resource == null) {
      // Not encrypted
      return data;
    }

    // Handle font obfuscation
    if (resource.isFontObfuscation) {
      return FontObfuscation.deobfuscate(
        data,
        uniqueIdentifier,
        resource.algorithm,
      );
    }

    // Handle LCP encryption
    if (resource.isLcp && lcpDecryptor != null) {
      // Check if this resource should be compressed
      final isCompressed = _isLikelyCompressed(uri);
      return lcpDecryptor!.decrypt(data, isCompressed: isCompressed);
    }

    // Cannot decrypt (Adobe DRM, etc.)
    if (!canDecrypt) {
      throw DecryptionException(
        'Cannot decrypt resource: ${encryptionInfo.type.name}',
        uri: uri,
      );
    }

    return data;
  }

  /// Checks if a resource is encrypted.
  bool isResourceEncrypted(String uri) {
    return _findEncryptedResource(uri) != null;
  }

  /// Checks if a resource requires credentials to decrypt.
  bool resourceRequiresCredentials(String uri) {
    final resource = _findEncryptedResource(uri);
    if (resource == null) return false;

    // Font obfuscation doesn't require credentials
    if (resource.isFontObfuscation) return false;

    // LCP requires passphrase
    if (resource.isLcp) return lcpDecryptor == null;

    // Adobe/Apple require external DRM
    return true;
  }

  /// Finds the encrypted resource entry for a URI.
  EncryptedResource? _findEncryptedResource(String uri) {
    final normalizedUri = uri.toLowerCase();

    for (final resource in encryptionInfo.encryptedResources) {
      final resourceUri = resource.uri.toLowerCase();

      // Match exact or with leading path components
      if (resourceUri == normalizedUri ||
          resourceUri.endsWith('/$normalizedUri') ||
          normalizedUri.endsWith('/${resource.uri.toLowerCase()}')) {
        return resource;
      }
    }

    return null;
  }

  /// Determines if a resource is likely compressed.
  ///
  /// Per LCP spec, text-based content (HTML, CSS, etc.) is typically
  /// compressed before encryption, while binary content (images, audio)
  /// is not.
  bool _isLikelyCompressed(String uri) {
    final lower = uri.toLowerCase();

    // Text-based formats that are typically compressed
    if (lower.endsWith('.html') ||
        lower.endsWith('.xhtml') ||
        lower.endsWith('.htm') ||
        lower.endsWith('.css') ||
        lower.endsWith('.js') ||
        lower.endsWith('.xml') ||
        lower.endsWith('.svg') ||
        lower.endsWith('.ncx') ||
        lower.endsWith('.opf') ||
        lower.endsWith('.smil')) {
      return true;
    }

    // Binary formats are typically not compressed
    return false;
  }

  /// Gets the passphrase hint for LCP (if available).
  String? get lcpPassphraseHint => lcpDecryptor?.license.userKeyHint;

  /// Whether this context has an active LCP license.
  bool get hasLcpLicense => lcpDecryptor != null;

  /// Whether the content has any encryption that requires credentials.
  bool get requiresCredentials {
    if (encryptionInfo.type == EncryptionType.none) return false;
    if (encryptionInfo.type == EncryptionType.fontObfuscation) return false;
    if (encryptionInfo.type == EncryptionType.lcp) return lcpDecryptor == null;
    return true;
  }

  /// A human-readable description of the encryption status.
  String get description {
    if (!canDecrypt) {
      if (encryptionInfo.type == EncryptionType.lcp && lcpDecryptor == null) {
        return 'LCP protected - passphrase required';
      }
      return 'Protected with ${encryptionInfo.description}';
    }

    if (lcpDecryptor != null) {
      return 'LCP protected - unlocked';
    }

    if (encryptionInfo.isOnlyFontObfuscation) {
      return 'Contains obfuscated fonts';
    }

    return 'No protection';
  }
}

/// Exception thrown for decryption errors.
class DecryptionException implements Exception {
  final String message;
  final String? uri;

  const DecryptionException(this.message, {this.uri});

  @override
  String toString() {
    if (uri != null) {
      return 'DecryptionException: $message (resource: $uri)';
    }
    return 'DecryptionException: $message';
  }
}
