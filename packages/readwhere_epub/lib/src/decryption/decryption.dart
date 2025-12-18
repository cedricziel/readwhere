/// Decryption support for encrypted EPUBs.
///
/// This module provides support for:
/// - IDPF font obfuscation (deobfuscation)
/// - Adobe font obfuscation (deobfuscation)
/// - Readium LCP decryption
///
/// Adobe DRM (ADEPT) and Apple FairPlay are detected but not supported
/// for decryption as they require proprietary licenses.
library;

export 'crypto_utils.dart' show CryptoException;
export 'decryption_algorithm.dart';
export 'decryption_context.dart';
export 'font_obfuscation.dart';
export 'lcp_decryptor.dart' show LcpDecryptor, LcpDecryptionException;
export 'lcp_license.dart';
