import 'dart:typed_data';

import 'package:readwhere_epub/src/decryption/decryption_context.dart';
import 'package:readwhere_epub/src/encryption/encryption_info.dart';
import 'package:test/test.dart';

void main() {
  group('DecryptionContext', () {
    test('creates context for unencrypted EPUB', () {
      final context = DecryptionContext.none('unique-id-12345');

      expect(context.canDecrypt, isTrue);
      expect(context.requiresCredentials, isFalse);
      expect(context.encryptionInfo.type, equals(EncryptionType.none));
    });

    test('creates context for font-obfuscated EPUB', () {
      final context = DecryptionContext.create(
        uniqueIdentifier: 'unique-id-12345',
        encryptionInfo: const EncryptionInfo(
          type: EncryptionType.fontObfuscation,
          encryptedResources: [
            EncryptedResource(
              uri: 'OEBPS/fonts/font.otf',
              algorithm: 'http://www.idpf.org/2008/embedding',
            ),
          ],
        ),
      );

      expect(context.canDecrypt, isTrue);
      expect(context.requiresCredentials, isFalse);
      expect(context.description, contains('font'));
    });

    test('creates context for Adobe DRM (unsupported)', () {
      final context = DecryptionContext.create(
        uniqueIdentifier: 'unique-id-12345',
        encryptionInfo: const EncryptionInfo(
          type: EncryptionType.adobeDrm,
          encryptedResources: [
            EncryptedResource(
              uri: 'OEBPS/chapter1.xhtml',
              algorithm: 'http://www.idpf.org/2008/epub/algo/user_key',
            ),
          ],
          hasRightsFile: true,
        ),
      );

      expect(context.canDecrypt, isFalse);
      expect(context.requiresCredentials, isTrue);
      expect(context.description, contains('Adobe'));
    });

    test('creates context for Apple FairPlay (unsupported)', () {
      final context = DecryptionContext.create(
        uniqueIdentifier: 'unique-id-12345',
        encryptionInfo: const EncryptionInfo(
          type: EncryptionType.appleFairPlay,
          encryptedResources: [
            EncryptedResource(
              uri: 'OEBPS/chapter1.xhtml',
              algorithm: 'http://apple.com/fairplay',
            ),
          ],
        ),
      );

      expect(context.canDecrypt, isFalse);
      expect(context.requiresCredentials, isTrue);
    });

    test('creates context for LCP without passphrase', () {
      final context = DecryptionContext.create(
        uniqueIdentifier: 'unique-id-12345',
        encryptionInfo: const EncryptionInfo(
          type: EncryptionType.lcp,
          encryptedResources: [
            EncryptedResource(
              uri: 'OEBPS/chapter1.xhtml',
              algorithm: 'http://www.w3.org/2001/04/xmlenc#aes256-cbc',
            ),
          ],
          hasLcpLicense: true,
        ),
        lcpLicenseJson: '{}', // Invalid but shows flow
      );

      expect(context.canDecrypt, isFalse);
      expect(context.requiresCredentials, isTrue);
      expect(context.hasLcpLicense, isFalse);
      expect(context.description, contains('passphrase required'));
    });

    group('isResourceEncrypted', () {
      test('returns true for encrypted resource', () {
        final context = DecryptionContext.create(
          uniqueIdentifier: 'unique-id',
          encryptionInfo: const EncryptionInfo(
            type: EncryptionType.fontObfuscation,
            encryptedResources: [
              EncryptedResource(
                uri: 'OEBPS/fonts/font.otf',
                algorithm: 'http://www.idpf.org/2008/embedding',
              ),
            ],
          ),
        );

        expect(context.isResourceEncrypted('OEBPS/fonts/font.otf'), isTrue);
      });

      test('returns false for unencrypted resource', () {
        final context = DecryptionContext.create(
          uniqueIdentifier: 'unique-id',
          encryptionInfo: const EncryptionInfo(
            type: EncryptionType.fontObfuscation,
            encryptedResources: [
              EncryptedResource(
                uri: 'OEBPS/fonts/font.otf',
                algorithm: 'http://www.idpf.org/2008/embedding',
              ),
            ],
          ),
        );

        expect(context.isResourceEncrypted('OEBPS/chapter1.xhtml'), isFalse);
      });

      test('matches case-insensitively', () {
        final context = DecryptionContext.create(
          uniqueIdentifier: 'unique-id',
          encryptionInfo: const EncryptionInfo(
            type: EncryptionType.fontObfuscation,
            encryptedResources: [
              EncryptedResource(
                uri: 'OEBPS/Fonts/Font.otf',
                algorithm: 'http://www.idpf.org/2008/embedding',
              ),
            ],
          ),
        );

        expect(context.isResourceEncrypted('oebps/fonts/font.otf'), isTrue);
      });
    });

    group('decryptResource', () {
      test('returns unchanged data for unencrypted resource', () {
        final context = DecryptionContext.none('unique-id');
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);

        final result = context.decryptResource('any/path.xhtml', data);

        expect(result, equals(data));
      });

      test('deobfuscates font with IDPF algorithm', () {
        final uniqueId = 'urn:uuid:12345678-1234-5678-1234-567812345678';

        final context = DecryptionContext.create(
          uniqueIdentifier: uniqueId,
          encryptionInfo: const EncryptionInfo(
            type: EncryptionType.fontObfuscation,
            encryptedResources: [
              EncryptedResource(
                uri: 'OEBPS/fonts/font.otf',
                algorithm: 'http://www.idpf.org/2008/embedding',
              ),
            ],
          ),
        );

        // Create "obfuscated" data
        final original = Uint8List.fromList(List.generate(100, (i) => i));

        // Obfuscate first (to simulate reading from EPUB)
        final obfuscated = context.decryptResource('OEBPS/fonts/font.otf', original);

        // Deobfuscate again (XOR is symmetric)
        final deobfuscated = context.decryptResource('OEBPS/fonts/font.otf', obfuscated);

        expect(deobfuscated, equals(original));
      });

      test('throws for unsupported DRM', () {
        final context = DecryptionContext.create(
          uniqueIdentifier: 'unique-id',
          encryptionInfo: const EncryptionInfo(
            type: EncryptionType.adobeDrm,
            encryptedResources: [
              EncryptedResource(
                uri: 'OEBPS/chapter1.xhtml',
                algorithm: 'http://www.idpf.org/2008/epub/algo/user_key',
              ),
            ],
            hasRightsFile: true,
          ),
        );

        final data = Uint8List.fromList([1, 2, 3, 4]);

        expect(
          () => context.decryptResource('OEBPS/chapter1.xhtml', data),
          throwsA(isA<DecryptionException>()),
        );
      });
    });

    group('resourceRequiresCredentials', () {
      test('returns false for unencrypted resource', () {
        final context = DecryptionContext.none('unique-id');

        expect(context.resourceRequiresCredentials('any/path.xhtml'), isFalse);
      });

      test('returns false for font obfuscation', () {
        final context = DecryptionContext.create(
          uniqueIdentifier: 'unique-id',
          encryptionInfo: const EncryptionInfo(
            type: EncryptionType.fontObfuscation,
            encryptedResources: [
              EncryptedResource(
                uri: 'OEBPS/fonts/font.otf',
                algorithm: 'http://www.idpf.org/2008/embedding',
              ),
            ],
          ),
        );

        expect(context.resourceRequiresCredentials('OEBPS/fonts/font.otf'), isFalse);
      });

      test('returns true for DRM-protected resource', () {
        final context = DecryptionContext.create(
          uniqueIdentifier: 'unique-id',
          encryptionInfo: const EncryptionInfo(
            type: EncryptionType.adobeDrm,
            encryptedResources: [
              EncryptedResource(
                uri: 'OEBPS/chapter1.xhtml',
                algorithm: 'http://www.idpf.org/2008/epub/algo/user_key',
              ),
            ],
            hasRightsFile: true,
          ),
        );

        expect(context.resourceRequiresCredentials('OEBPS/chapter1.xhtml'), isTrue);
      });
    });
  });
}
