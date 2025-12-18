import 'dart:convert';
import 'dart:typed_data';

import 'decryption_algorithm.dart';

/// Deobfuscates fonts encrypted with IDPF or Adobe font obfuscation.
///
/// Font obfuscation is NOT DRM - it's a simple XOR-based scheme designed
/// to prevent casual extraction of embedded fonts while allowing
/// legitimate reading of the book.
///
/// See EPUB OCF specification:
/// https://idpf.org/epub/31/spec/epub-ocf.html#sec-resource-obfuscation
class FontObfuscation {
  FontObfuscation._();

  /// Number of bytes to obfuscate (per IDPF spec).
  static const int _obfuscationLength = 1040;

  /// Key length for IDPF obfuscation (SHA-1 hash = 20 bytes).
  static const int _idpfKeyLength = 20;

  /// Key length for Adobe obfuscation (16 bytes).
  static const int _adobeKeyLength = 16;

  /// Deobfuscates font data using the IDPF algorithm.
  ///
  /// The key is derived from the EPUB's unique identifier by:
  /// 1. Removing all whitespace (U+0020, U+0009, U+000D, U+000A)
  /// 2. Computing SHA-1 hash of the UTF-8 encoded string
  ///
  /// The first 1040 bytes are XORed with the 20-byte key (repeating).
  ///
  /// [fontBytes] - The obfuscated font data.
  /// [uniqueIdentifier] - The EPUB's unique identifier from metadata.
  ///
  /// Returns the deobfuscated font data.
  static Uint8List deobfuscateIdpf(Uint8List fontBytes, String uniqueIdentifier) {
    final key = _deriveIdpfKey(uniqueIdentifier);
    return _deobfuscate(fontBytes, key, _idpfKeyLength);
  }

  /// Deobfuscates font data using the Adobe algorithm.
  ///
  /// Similar to IDPF but uses a 16-byte key derived differently:
  /// The unique identifier is expected to be a UUID in URN format
  /// (urn:uuid:XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX), and the key
  /// is the raw UUID bytes (hex decoded, no dashes).
  ///
  /// [fontBytes] - The obfuscated font data.
  /// [uniqueIdentifier] - The EPUB's unique identifier (UUID).
  ///
  /// Returns the deobfuscated font data.
  static Uint8List deobfuscateAdobe(Uint8List fontBytes, String uniqueIdentifier) {
    final key = _deriveAdobeKey(uniqueIdentifier);
    return _deobfuscate(fontBytes, key, _adobeKeyLength);
  }

  /// Deobfuscates font data using the appropriate algorithm.
  ///
  /// [fontBytes] - The obfuscated font data.
  /// [uniqueIdentifier] - The EPUB's unique identifier.
  /// [algorithm] - The obfuscation algorithm URI.
  ///
  /// Returns the deobfuscated font data.
  static Uint8List deobfuscate(
    Uint8List fontBytes,
    String uniqueIdentifier,
    String algorithm,
  ) {
    if (DecryptionAlgorithm.isIdpfFontObfuscation(algorithm)) {
      return deobfuscateIdpf(fontBytes, uniqueIdentifier);
    } else if (DecryptionAlgorithm.isAdobeFontObfuscation(algorithm)) {
      return deobfuscateAdobe(fontBytes, uniqueIdentifier);
    }

    // Unknown algorithm, return as-is
    return fontBytes;
  }

  /// Derives the IDPF obfuscation key from the unique identifier.
  ///
  /// Per the spec:
  /// 1. Remove whitespace characters (U+0020, U+0009, U+000D, U+000A)
  /// 2. Compute SHA-1 hash of UTF-8 representation
  static Uint8List _deriveIdpfKey(String uniqueIdentifier) {
    // Remove whitespace as specified in XML 1.0 section 2.3
    final cleaned = uniqueIdentifier.replaceAll(RegExp(r'[\u0020\u0009\u000D\u000A]'), '');

    // Compute SHA-1 hash
    final bytes = utf8.encode(cleaned);
    return _sha1(Uint8List.fromList(bytes));
  }

  /// Derives the Adobe obfuscation key from a UUID identifier.
  ///
  /// Extracts the raw UUID bytes from formats like:
  /// - urn:uuid:XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
  /// - XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
  static Uint8List _deriveAdobeKey(String uniqueIdentifier) {
    // Extract UUID, removing urn:uuid: prefix and dashes
    var uuid = uniqueIdentifier.toLowerCase();
    if (uuid.startsWith('urn:uuid:')) {
      uuid = uuid.substring(9);
    }
    uuid = uuid.replaceAll('-', '');

    // Validate UUID length (should be 32 hex chars = 16 bytes)
    if (uuid.length != 32) {
      // Fallback to IDPF-style key derivation
      return _deriveIdpfKey(uniqueIdentifier).sublist(0, _adobeKeyLength);
    }

    // Convert hex string to bytes
    final key = Uint8List(_adobeKeyLength);
    for (var i = 0; i < _adobeKeyLength; i++) {
      key[i] = int.parse(uuid.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return key;
  }

  /// Performs XOR deobfuscation on the data.
  static Uint8List _deobfuscate(Uint8List data, Uint8List key, int keyLength) {
    if (data.isEmpty) return data;

    // Create output buffer
    final output = Uint8List.fromList(data);
    final obfuscationBytes = data.length < _obfuscationLength ? data.length : _obfuscationLength;

    // XOR the first obfuscationLength bytes with the key (repeating)
    for (var i = 0; i < obfuscationBytes; i++) {
      output[i] = data[i] ^ key[i % keyLength];
    }

    return output;
  }

  /// Simple SHA-1 implementation.
  ///
  /// Note: For a production library, consider using a crypto package.
  /// This implementation follows the FIPS 180-4 specification.
  static Uint8List _sha1(Uint8List message) {
    // Initialize hash values (big-endian)
    var h0 = 0x67452301;
    var h1 = 0xEFCDAB89;
    var h2 = 0x98BADCFE;
    var h3 = 0x10325476;
    var h4 = 0xC3D2E1F0;

    // Pre-processing: add padding
    final originalLength = message.length;
    final bitLength = originalLength * 8;

    // Message + 1 byte (0x80) + padding + 8 bytes (length)
    // Padded length must be ≡ 56 (mod 64)
    final paddingLength = (56 - (originalLength + 1) % 64) % 64;
    final paddedLength = originalLength + 1 + paddingLength + 8;
    final padded = Uint8List(paddedLength);

    // Copy original message
    padded.setRange(0, originalLength, message);

    // Add 0x80 byte
    padded[originalLength] = 0x80;

    // Add original length in bits as 64-bit big-endian
    padded[paddedLength - 8] = (bitLength >> 56) & 0xFF;
    padded[paddedLength - 7] = (bitLength >> 48) & 0xFF;
    padded[paddedLength - 6] = (bitLength >> 40) & 0xFF;
    padded[paddedLength - 5] = (bitLength >> 32) & 0xFF;
    padded[paddedLength - 4] = (bitLength >> 24) & 0xFF;
    padded[paddedLength - 3] = (bitLength >> 16) & 0xFF;
    padded[paddedLength - 2] = (bitLength >> 8) & 0xFF;
    padded[paddedLength - 1] = bitLength & 0xFF;

    // Process in 512-bit (64-byte) chunks
    for (var chunkStart = 0; chunkStart < paddedLength; chunkStart += 64) {
      // Break chunk into sixteen 32-bit big-endian words
      final w = List<int>.filled(80, 0);
      for (var i = 0; i < 16; i++) {
        final byteOffset = chunkStart + i * 4;
        w[i] = (padded[byteOffset] << 24) |
            (padded[byteOffset + 1] << 16) |
            (padded[byteOffset + 2] << 8) |
            padded[byteOffset + 3];
      }

      // Extend to 80 words
      for (var i = 16; i < 80; i++) {
        w[i] = _rotateLeft32(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
      }

      // Initialize working variables
      var a = h0;
      var b = h1;
      var c = h2;
      var d = h3;
      var e = h4;

      // Main loop
      for (var i = 0; i < 80; i++) {
        int f, k;
        if (i < 20) {
          f = (b & c) | ((~b) & d);
          k = 0x5A827999;
        } else if (i < 40) {
          f = b ^ c ^ d;
          k = 0x6ED9EBA1;
        } else if (i < 60) {
          f = (b & c) | (b & d) | (c & d);
          k = 0x8F1BBCDC;
        } else {
          f = b ^ c ^ d;
          k = 0xCA62C1D6;
        }

        final temp = (_rotateLeft32(a, 5) + f + e + k + w[i]) & 0xFFFFFFFF;
        e = d;
        d = c;
        c = _rotateLeft32(b, 30);
        b = a;
        a = temp;
      }

      // Add to hash
      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
    }

    // Produce final hash (big-endian)
    final hash = Uint8List(20);
    hash[0] = (h0 >> 24) & 0xFF;
    hash[1] = (h0 >> 16) & 0xFF;
    hash[2] = (h0 >> 8) & 0xFF;
    hash[3] = h0 & 0xFF;
    hash[4] = (h1 >> 24) & 0xFF;
    hash[5] = (h1 >> 16) & 0xFF;
    hash[6] = (h1 >> 8) & 0xFF;
    hash[7] = h1 & 0xFF;
    hash[8] = (h2 >> 24) & 0xFF;
    hash[9] = (h2 >> 16) & 0xFF;
    hash[10] = (h2 >> 8) & 0xFF;
    hash[11] = h2 & 0xFF;
    hash[12] = (h3 >> 24) & 0xFF;
    hash[13] = (h3 >> 16) & 0xFF;
    hash[14] = (h3 >> 8) & 0xFF;
    hash[15] = h3 & 0xFF;
    hash[16] = (h4 >> 24) & 0xFF;
    hash[17] = (h4 >> 16) & 0xFF;
    hash[18] = (h4 >> 8) & 0xFF;
    hash[19] = h4 & 0xFF;

    return hash;
  }

  /// Rotates a 32-bit integer left by n bits.
  static int _rotateLeft32(int x, int n) {
    return ((x << n) | (x >> (32 - n))) & 0xFFFFFFFF;
  }
}
