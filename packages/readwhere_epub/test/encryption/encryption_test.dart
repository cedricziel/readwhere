import 'package:readwhere_epub/src/encryption/encryption_info.dart';
import 'package:readwhere_epub/src/encryption/encryption_parser.dart';
import 'package:test/test.dart';

void main() {
  group('EncryptedResource', () {
    test('creates with required fields', () {
      const resource = EncryptedResource(
        uri: 'OEBPS/chapter1.xhtml',
        algorithm: 'http://www.idpf.org/2008/epub/algo/user_key',
      );

      expect(resource.uri, 'OEBPS/chapter1.xhtml');
      expect(resource.algorithm, 'http://www.idpf.org/2008/epub/algo/user_key');
      expect(resource.retrievalMethod, isNull);
    });

    test('creates with retrieval method', () {
      const resource = EncryptedResource(
        uri: 'OEBPS/chapter1.xhtml',
        algorithm: 'http://www.idpf.org/2008/epub/algo/user_key',
        retrievalMethod: 'META-INF/rights.xml#key',
      );

      expect(resource.retrievalMethod, 'META-INF/rights.xml#key');
    });

    group('isFontObfuscation', () {
      test('returns true for IDPF obfuscation', () {
        const resource = EncryptedResource(
          uri: 'OEBPS/fonts/font.otf',
          algorithm: 'http://www.idpf.org/2008/embedding',
        );

        expect(resource.isFontObfuscation, isTrue);
      });

      test('returns true for algorithm containing obfuscation', () {
        const resource = EncryptedResource(
          uri: 'OEBPS/fonts/font.otf',
          algorithm: 'http://example.com/font-obfuscation',
        );

        expect(resource.isFontObfuscation, isTrue);
      });

      test('returns false for Adobe DRM', () {
        const resource = EncryptedResource(
          uri: 'OEBPS/chapter1.xhtml',
          algorithm: 'http://www.idpf.org/2008/epub/algo/user_key',
        );

        expect(resource.isFontObfuscation, isFalse);
      });
    });

    group('isAdobeDrm', () {
      test('returns true for IDPF user key algorithm', () {
        const resource = EncryptedResource(
          uri: 'OEBPS/chapter1.xhtml',
          algorithm: 'http://www.idpf.org/2008/epub/algo/user_key',
        );

        expect(resource.isAdobeDrm, isTrue);
      });

      test('returns true for algorithm containing adobe', () {
        const resource = EncryptedResource(
          uri: 'OEBPS/chapter1.xhtml',
          algorithm: 'http://ns.adobe.com/adept/enc#AES128',
        );

        expect(resource.isAdobeDrm, isTrue);
      });
    });

    group('isLcp', () {
      test('returns true for algorithm containing lcp', () {
        const resource = EncryptedResource(
          uri: 'OEBPS/chapter1.xhtml',
          algorithm: 'http://readium.org/2014/01/lcp#encryption',
        );

        expect(resource.isLcp, isTrue);
      });
    });

    test('equality', () {
      const r1 = EncryptedResource(uri: 'a.xhtml', algorithm: 'algo');
      const r2 = EncryptedResource(uri: 'a.xhtml', algorithm: 'algo');
      const r3 = EncryptedResource(uri: 'b.xhtml', algorithm: 'algo');

      expect(r1, equals(r2));
      expect(r1, isNot(equals(r3)));
    });
  });

  group('EncryptionInfo', () {
    test('none constant', () {
      expect(EncryptionInfo.none.type, EncryptionType.none);
      expect(EncryptionInfo.none.encryptedResources, isEmpty);
      expect(EncryptionInfo.none.isEncrypted, isFalse);
    });

    test('creates with resources', () {
      const info = EncryptionInfo(
        type: EncryptionType.adobeDrm,
        encryptedResources: [
          EncryptedResource(
            uri: 'OEBPS/chapter1.xhtml',
            algorithm: 'http://www.idpf.org/2008/epub/algo/user_key',
          ),
        ],
        hasRightsFile: true,
      );

      expect(info.type, EncryptionType.adobeDrm);
      expect(info.encryptedResourceCount, 1);
      expect(info.isEncrypted, isTrue);
      expect(info.hasDrm, isTrue);
      expect(info.hasRightsFile, isTrue);
    });

    test('hasDrm returns false for font obfuscation', () {
      const info = EncryptionInfo(
        type: EncryptionType.fontObfuscation,
        encryptedResources: [
          EncryptedResource(
            uri: 'OEBPS/fonts/font.otf',
            algorithm: 'http://www.idpf.org/2008/embedding',
          ),
        ],
      );

      expect(info.hasDrm, isFalse);
      expect(info.isOnlyFontObfuscation, isTrue);
    });

    test('drmEncryptedResources excludes font obfuscation', () {
      const info = EncryptionInfo(
        type: EncryptionType.adobeDrm,
        encryptedResources: [
          EncryptedResource(
            uri: 'OEBPS/chapter1.xhtml',
            algorithm: 'http://www.idpf.org/2008/epub/algo/user_key',
          ),
          EncryptedResource(
            uri: 'OEBPS/fonts/font.otf',
            algorithm: 'http://www.idpf.org/2008/embedding',
          ),
        ],
      );

      expect(info.drmEncryptedResources.length, 1);
      expect(info.fontObfuscatedResources.length, 1);
    });

    test('description returns human-readable text', () {
      expect(
        const EncryptionInfo(type: EncryptionType.none).description,
        'No encryption',
      );
      expect(
        const EncryptionInfo(type: EncryptionType.adobeDrm).description,
        'Adobe DRM protected',
      );
      expect(
        const EncryptionInfo(type: EncryptionType.appleFairPlay).description,
        'Apple FairPlay protected',
      );
      expect(
        const EncryptionInfo(type: EncryptionType.lcp).description,
        'Readium LCP protected',
      );
      expect(
        const EncryptionInfo(type: EncryptionType.fontObfuscation).description,
        'Font obfuscation only',
      );
      expect(
        const EncryptionInfo(type: EncryptionType.unknown).description,
        'Unknown encryption',
      );
    });
  });

  group('EncryptionParser', () {
    test('returns none for null input', () {
      final info = EncryptionParser.parse(null);

      expect(info.type, EncryptionType.none);
      expect(info.encryptedResources, isEmpty);
    });

    test('returns none for empty input', () {
      final info = EncryptionParser.parse('');

      expect(info.type, EncryptionType.none);
    });

    test('returns none for whitespace-only input', () {
      final info = EncryptionParser.parse('   \n\t  ');

      expect(info.type, EncryptionType.none);
    });

    test('returns unknown for invalid XML', () {
      final info = EncryptionParser.parse('<not valid xml');

      expect(info.type, EncryptionType.unknown);
    });

    test('parses Adobe DRM encryption', () {
      const encryptionXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<encryption xmlns="http://www.w3.org/2001/04/xmlenc#">
  <EncryptedData>
    <EncryptionMethod Algorithm="http://www.idpf.org/2008/epub/algo/user_key"/>
    <CipherData>
      <CipherReference URI="OEBPS/chapter1.xhtml"/>
    </CipherData>
  </EncryptedData>
  <EncryptedData>
    <EncryptionMethod Algorithm="http://www.idpf.org/2008/epub/algo/user_key"/>
    <CipherData>
      <CipherReference URI="OEBPS/chapter2.xhtml"/>
    </CipherData>
  </EncryptedData>
</encryption>
''';

      final info = EncryptionParser.parse(encryptionXml, hasRightsFile: true);

      expect(info.type, EncryptionType.adobeDrm);
      expect(info.encryptedResources.length, 2);
      expect(info.encryptedResources[0].uri, 'OEBPS/chapter1.xhtml');
      expect(info.encryptedResources[1].uri, 'OEBPS/chapter2.xhtml');
      expect(info.hasRightsFile, isTrue);
    });

    test('parses font obfuscation only', () {
      const encryptionXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<encryption xmlns="http://www.w3.org/2001/04/xmlenc#">
  <EncryptedData>
    <EncryptionMethod Algorithm="http://www.idpf.org/2008/embedding"/>
    <CipherData>
      <CipherReference URI="OEBPS/fonts/myfont.otf"/>
    </CipherData>
  </EncryptedData>
</encryption>
''';

      final info = EncryptionParser.parse(encryptionXml);

      expect(info.type, EncryptionType.fontObfuscation);
      expect(info.isOnlyFontObfuscation, isTrue);
      expect(info.hasDrm, isFalse);
    });

    test('parses LCP encryption', () {
      const encryptionXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<encryption xmlns="http://www.w3.org/2001/04/xmlenc#">
  <EncryptedData>
    <EncryptionMethod Algorithm="http://readium.org/2014/01/lcp#AES256-CBC"/>
    <CipherData>
      <CipherReference URI="OEBPS/content.opf"/>
    </CipherData>
  </EncryptedData>
</encryption>
''';

      final info = EncryptionParser.parse(encryptionXml, hasLcpLicense: true);

      expect(info.type, EncryptionType.lcp);
      expect(info.hasLcpLicense, isTrue);
    });

    test('parses without namespace prefixes', () {
      const encryptionXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<encryption>
  <EncryptedData>
    <EncryptionMethod Algorithm="http://www.idpf.org/2008/epub/algo/user_key"/>
    <CipherData>
      <CipherReference URI="OEBPS/chapter1.xhtml"/>
    </CipherData>
  </EncryptedData>
</encryption>
''';

      final info = EncryptionParser.parse(encryptionXml, hasRightsFile: true);

      expect(info.type, EncryptionType.adobeDrm);
      expect(info.encryptedResources.length, 1);
    });

    test('handles mixed DRM and font obfuscation', () {
      const encryptionXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<encryption xmlns="http://www.w3.org/2001/04/xmlenc#">
  <EncryptedData>
    <EncryptionMethod Algorithm="http://www.idpf.org/2008/epub/algo/user_key"/>
    <CipherData>
      <CipherReference URI="OEBPS/chapter1.xhtml"/>
    </CipherData>
  </EncryptedData>
  <EncryptedData>
    <EncryptionMethod Algorithm="http://www.idpf.org/2008/embedding"/>
    <CipherData>
      <CipherReference URI="OEBPS/fonts/font.otf"/>
    </CipherData>
  </EncryptedData>
</encryption>
''';

      final info = EncryptionParser.parse(encryptionXml);

      expect(info.type, EncryptionType.adobeDrm);
      expect(info.encryptedResources.length, 2);
      expect(info.drmEncryptedResources.length, 1);
      expect(info.fontObfuscatedResources.length, 1);
    });

    test('skips incomplete EncryptedData elements', () {
      const encryptionXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<encryption xmlns="http://www.w3.org/2001/04/xmlenc#">
  <EncryptedData>
    <EncryptionMethod Algorithm="http://www.idpf.org/2008/epub/algo/user_key"/>
    <!-- Missing CipherData -->
  </EncryptedData>
  <EncryptedData>
    <!-- Missing EncryptionMethod -->
    <CipherData>
      <CipherReference URI="OEBPS/chapter2.xhtml"/>
    </CipherData>
  </EncryptedData>
  <EncryptedData>
    <EncryptionMethod Algorithm="http://www.idpf.org/2008/epub/algo/user_key"/>
    <CipherData>
      <CipherReference URI="OEBPS/chapter3.xhtml"/>
    </CipherData>
  </EncryptedData>
</encryption>
''';

      final info = EncryptionParser.parse(encryptionXml);

      // Only the complete entry should be parsed
      expect(info.encryptedResources.length, 1);
      expect(info.encryptedResources[0].uri, 'OEBPS/chapter3.xhtml');
    });

    test('collects all unique algorithms', () {
      const encryptionXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<encryption xmlns="http://www.w3.org/2001/04/xmlenc#">
  <EncryptedData>
    <EncryptionMethod Algorithm="http://www.idpf.org/2008/epub/algo/user_key"/>
    <CipherData>
      <CipherReference URI="OEBPS/chapter1.xhtml"/>
    </CipherData>
  </EncryptedData>
  <EncryptedData>
    <EncryptionMethod Algorithm="http://www.idpf.org/2008/embedding"/>
    <CipherData>
      <CipherReference URI="OEBPS/fonts/font.otf"/>
    </CipherData>
  </EncryptedData>
</encryption>
''';

      final info = EncryptionParser.parse(encryptionXml);

      expect(info.algorithms.length, 2);
      expect(
          info.algorithms,
          containsAll([
            'http://www.idpf.org/2008/epub/algo/user_key',
            'http://www.idpf.org/2008/embedding',
          ]));
    });

    test('detects unknown encryption type', () {
      const encryptionXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<encryption xmlns="http://www.w3.org/2001/04/xmlenc#">
  <EncryptedData>
    <EncryptionMethod Algorithm="http://example.com/custom-encryption"/>
    <CipherData>
      <CipherReference URI="OEBPS/chapter1.xhtml"/>
    </CipherData>
  </EncryptedData>
</encryption>
''';

      final info = EncryptionParser.parse(encryptionXml);

      expect(info.type, EncryptionType.unknown);
    });
  });

  group('EncryptionType enum', () {
    test('has all expected values', () {
      expect(EncryptionType.values, contains(EncryptionType.none));
      expect(EncryptionType.values, contains(EncryptionType.adobeDrm));
      expect(EncryptionType.values, contains(EncryptionType.appleFairPlay));
      expect(EncryptionType.values, contains(EncryptionType.lcp));
      expect(EncryptionType.values, contains(EncryptionType.fontObfuscation));
      expect(EncryptionType.values, contains(EncryptionType.unknown));
    });
  });
}
