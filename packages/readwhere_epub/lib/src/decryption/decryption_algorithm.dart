/// Algorithm URIs for EPUB encryption standards.
class DecryptionAlgorithm {
  DecryptionAlgorithm._();

  // IDPF Font Obfuscation
  /// IDPF standard font obfuscation algorithm.
  static const String idpfFontObfuscation = 'http://www.idpf.org/2008/embedding';

  /// Adobe font obfuscation algorithm (legacy).
  static const String adobeFontObfuscation = 'http://ns.adobe.com/pdf/enc#RC';

  // LCP Algorithms
  /// Readium LCP AES-256-CBC content encryption.
  static const String lcpAes256Cbc = 'http://www.w3.org/2001/04/xmlenc#aes256-cbc';

  /// SHA-256 hashing for LCP user key derivation.
  static const String sha256 = 'http://www.w3.org/2001/04/xmlenc#sha256';

  /// Checks if an algorithm is IDPF font obfuscation.
  static bool isIdpfFontObfuscation(String algorithm) {
    return algorithm == idpfFontObfuscation;
  }

  /// Checks if an algorithm is Adobe font obfuscation.
  static bool isAdobeFontObfuscation(String algorithm) {
    return algorithm == adobeFontObfuscation;
  }

  /// Checks if an algorithm is any font obfuscation.
  static bool isFontObfuscation(String algorithm) {
    return isIdpfFontObfuscation(algorithm) ||
        isAdobeFontObfuscation(algorithm) ||
        algorithm.contains('obfuscation');
  }

  /// Checks if an algorithm is LCP encryption.
  static bool isLcpEncryption(String algorithm) {
    return algorithm == lcpAes256Cbc ||
        algorithm.contains('lcp') ||
        algorithm.contains('readium.org');
  }
}
