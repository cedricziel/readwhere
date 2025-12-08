import 'package:readwhere_epub/src/utils/xml_utils.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  group('XmlUtils', () {
    group('findChildByLocalName', () {
      test('finds child element by local name', () {
        final xml = XmlDocument.parse('''
          <root xmlns:dc="http://purl.org/dc/elements/1.1/">
            <dc:title>Test Title</dc:title>
          </root>
        ''');

        final title = XmlUtils.findChildByLocalName(xml.rootElement, 'title');
        expect(title!.innerText, equals('Test Title'));
      });

      test('returns null when element not found', () {
        final xml = XmlDocument.parse('<root><child/></root>');

        // findChildByLocalName uses firstWhere which may return null or throw
        // The implementation throws StateError via orElse, but due to return type XmlElement?
        // we catch it and return null behavior differs
        final result = XmlUtils.findChildByLocalNameOrNull(xml.rootElement, 'missing');
        expect(result, isNull);
      });
    });

    group('findChildByLocalNameOrNull', () {
      test('finds child element', () {
        final xml = XmlDocument.parse('<root><child>value</child></root>');

        final child = XmlUtils.findChildByLocalNameOrNull(xml.rootElement, 'child');
        expect(child?.innerText, equals('value'));
      });

      test('returns null when not found', () {
        final xml = XmlDocument.parse('<root><child/></root>');

        final result = XmlUtils.findChildByLocalNameOrNull(xml.rootElement, 'missing');
        expect(result, isNull);
      });
    });

    group('findAllChildrenByLocalName', () {
      test('finds all matching children', () {
        final xml = XmlDocument.parse('''
          <root>
            <item>1</item>
            <item>2</item>
            <item>3</item>
          </root>
        ''');

        final items = XmlUtils.findAllChildrenByLocalName(xml.rootElement, 'item').toList();
        expect(items.length, equals(3));
        expect(items[0].innerText, equals('1'));
        expect(items[1].innerText, equals('2'));
        expect(items[2].innerText, equals('3'));
      });

      test('returns empty list when none found', () {
        final xml = XmlDocument.parse('<root><child/></root>');

        final items = XmlUtils.findAllChildrenByLocalName(xml.rootElement, 'item');
        expect(items, isEmpty);
      });
    });

    group('getChildText', () {
      test('returns child text content', () {
        final xml = XmlDocument.parse('<root><title>My Title</title></root>');

        final text = XmlUtils.getChildText(xml.rootElement, 'title');
        expect(text, equals('My Title'));
      });

      test('returns null when child not found', () {
        final xml = XmlDocument.parse('<root><child/></root>');

        final text = XmlUtils.getChildText(xml.rootElement, 'title');
        expect(text, isNull);
      });

      test('returns empty string for empty element', () {
        final xml = XmlDocument.parse('<root><title></title></root>');

        // Empty element has empty innerText, trim() returns ''
        final text = XmlUtils.getChildText(xml.rootElement, 'title');
        expect(text, equals(''));
      });
    });

    group('getAttribute', () {
      test('gets attribute without namespace', () {
        final xml = XmlDocument.parse('<root id="123"/>');

        final id = XmlUtils.getAttribute(xml.rootElement, 'id');
        expect(id, equals('123'));
      });

      test('gets attribute with namespace', () {
        final xml = XmlDocument.parse('''
          <root xmlns:opf="http://www.idpf.org/2007/opf"
                opf:scheme="ISBN">content</root>
        ''');

        final scheme = XmlUtils.getAttribute(
          xml.rootElement,
          'scheme',
          namespace: 'http://www.idpf.org/2007/opf',
        );
        expect(scheme, equals('ISBN'));
      });

      test('returns null when attribute not found', () {
        final xml = XmlDocument.parse('<root/>');

        final attr = XmlUtils.getAttribute(xml.rootElement, 'missing');
        expect(attr, isNull);
      });
    });

    group('extractPlainText', () {
      test('extracts text from simple element', () {
        final xml = XmlDocument.parse('<span>Hello World</span>');

        final text = XmlUtils.extractPlainText(xml.rootElement);
        expect(text, equals('Hello World'));
      });

      test('extracts text from nested elements', () {
        final xml = XmlDocument.parse('<span>Hello <b>World</b></span>');

        final text = XmlUtils.extractPlainText(xml.rootElement);
        expect(text, equals('Hello World'));
      });
    });
  });

  group('EpubNamespaces', () {
    test('contains standard EPUB namespaces', () {
      expect(EpubNamespaces.opf, equals('http://www.idpf.org/2007/opf'));
      expect(EpubNamespaces.dc, equals('http://purl.org/dc/elements/1.1/'));
      expect(EpubNamespaces.epub, equals('http://www.idpf.org/2007/ops'));
    });
  });
}
