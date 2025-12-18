import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'crypto_utils.dart';
import 'lcp_license.dart';

/// Decrypts Readium LCP protected EPUB resources.
///
/// LCP uses the following encryption scheme:
/// 1. User provides a passphrase
/// 2. Passphrase is hashed with SHA-256 to create User Key
/// 3. User Key decrypts the Content Key from the license
/// 4. Content Key decrypts individual resources using AES-256-CBC
///
/// Resources may also be compressed with Deflate before encryption.
class LcpDecryptor {
  /// The parsed LCP license.
  final LcpLicense license;

  /// The decrypted content key (32 bytes for AES-256).
  final Uint8List _contentKey;

  LcpDecryptor._({
    required this.license,
    required Uint8List contentKey,
  }) : _contentKey = contentKey;

  /// Creates an LCP decryptor from a license and user passphrase.
  ///
  /// [licenseJson] - The license.lcpl JSON content.
  /// [passphrase] - The user's passphrase.
  ///
  /// Throws [LcpDecryptionException] if decryption fails.
  factory LcpDecryptor.create(String licenseJson, String passphrase) {
    final license = LcpLicense.parse(licenseJson);
    return LcpDecryptor.fromLicense(license, passphrase);
  }

  /// Creates an LCP decryptor from a parsed license and user passphrase.
  ///
  /// Throws [LcpDecryptionException] if the content key cannot be decrypted.
  factory LcpDecryptor.fromLicense(LcpLicense license, String passphrase) {
    // Derive user key from passphrase using SHA-256
    final userKey = CryptoUtils.sha256String(passphrase);

    // Decode the encrypted content key
    final encryptedContentKey = base64Decode(license.encryptedContentKey);

    // Decrypt the content key using the user key
    try {
      final contentKey = CryptoUtils.decryptAes256Cbc(encryptedContentKey, userKey);

      if (contentKey.length != 32) {
        throw LcpDecryptionException(
          'Invalid content key length: ${contentKey.length} (expected 32)',
        );
      }

      return LcpDecryptor._(
        license: license,
        contentKey: contentKey,
      );
    } on CryptoException catch (e) {
      throw LcpDecryptionException('Failed to decrypt content key: ${e.message}');
    }
  }

  /// Decrypts an encrypted resource.
  ///
  /// [encryptedData] - The encrypted resource bytes.
  /// [isCompressed] - Whether the resource was compressed before encryption.
  ///
  /// Returns the decrypted (and decompressed if applicable) resource.
  /// Throws [LcpDecryptionException] if decryption fails.
  Uint8List decrypt(Uint8List encryptedData, {bool isCompressed = false}) {
    try {
      // Decrypt with AES-256-CBC
      final decrypted = CryptoUtils.decryptAes256Cbc(encryptedData, _contentKey);

      // Decompress if needed
      if (isCompressed) {
        return _inflate(decrypted);
      }

      return decrypted;
    } on CryptoException catch (e) {
      throw LcpDecryptionException('Decryption failed: ${e.message}');
    }
  }

  /// Decrypts a resource that may be compressed.
  ///
  /// Attempts decompression automatically if decrypted data appears compressed.
  Uint8List decryptAuto(Uint8List encryptedData) {
    try {
      final decrypted = CryptoUtils.decryptAes256Cbc(encryptedData, _contentKey);

      // Try to decompress - Deflate compressed data often starts with specific bytes
      // If decompression fails, return the raw decrypted data
      try {
        return _inflate(decrypted);
      } catch (_) {
        return decrypted;
      }
    } on CryptoException catch (e) {
      throw LcpDecryptionException('Decryption failed: ${e.message}');
    }
  }

  /// Inflates Deflate-compressed data.
  Uint8List _inflate(Uint8List compressed) {
    try {
      final decoder = ZLibDecoder(raw: true);
      return Uint8List.fromList(decoder.convert(compressed));
    } catch (_) {
      // Try with zlib header
      try {
        final decoder = ZLibDecoder();
        return Uint8List.fromList(decoder.convert(compressed));
      } catch (_) {
        // Not compressed, return as-is
        return compressed;
      }
    }
  }

  /// Verifies that the passphrase can decrypt the content key.
  ///
  /// This is a static method that can be used to validate a passphrase
  /// before fully initializing the decryptor.
  static bool verifyPassphrase(String licenseJson, String passphrase) {
    try {
      LcpDecryptor.create(licenseJson, passphrase);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Gets the passphrase hint from the license.
  static String? getPassphraseHint(String licenseJson) {
    try {
      final license = LcpLicense.parse(licenseJson);
      return license.userKeyHint;
    } catch (_) {
      return null;
    }
  }
}

/// Exception thrown for LCP decryption errors.
class LcpDecryptionException implements Exception {
  final String message;

  const LcpDecryptionException(this.message);

  @override
  String toString() => 'LcpDecryptionException: $message';
}
