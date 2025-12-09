import 'package:readwhere_webdav/src/xml/propfind_builder.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  group('PropfindBuilder', () {
    test('build() creates valid PROPFIND XML with default properties', () {
      final xml = PropfindBuilder.build();

      // Parse to verify it's valid XML
      final document = XmlDocument.parse(xml);
      expect(document.rootElement.name.local, 'propfind');

      // Check for expected properties
      expect(xml, contains('displayname'));
      expect(xml, contains('getcontentlength'));
      expect(xml, contains('getlastmodified'));
      expect(xml, contains('getcontenttype'));
      expect(xml, contains('getetag'));
      expect(xml, contains('resourcetype'));
    });

    test('build() includes DAV namespace', () {
      final xml = PropfindBuilder.build();
      expect(xml, contains('xmlns:d="DAV:"'));
    });

    test('build() with custom properties', () {
      final xml = PropfindBuilder.build(
        properties: ['custom-prop', 'another-prop'],
      );

      final document = XmlDocument.parse(xml);
      expect(document.rootElement.name.local, 'propfind');

      expect(xml, contains('custom-prop'));
      expect(xml, contains('another-prop'));
    });

    test('build() with custom namespaces', () {
      final xml = PropfindBuilder.build(
        customNamespaces: {'oc': 'http://owncloud.org/ns'},
        customProperties: {
          'oc': ['size', 'permissions']
        },
      );

      expect(xml, contains('xmlns:oc="http://owncloud.org/ns"'));
      expect(xml, contains('<oc:size/>'));
      expect(xml, contains('<oc:permissions/>'));
    });

    test('standard() creates standard propfind request', () {
      final xml = PropfindBuilder.standard();

      final document = XmlDocument.parse(xml);
      expect(document.rootElement.name.local, 'propfind');

      // Should have standard DAV properties
      expect(xml, contains('displayname'));
      expect(xml, contains('resourcetype'));
    });

    test('withOwnCloudExtensions() includes OC and NC namespaces', () {
      final xml = PropfindBuilder.withOwnCloudExtensions();

      expect(xml, contains('xmlns:oc="http://owncloud.org/ns"'));
      expect(xml, contains('xmlns:nc="http://nextcloud.org/ns"'));
      expect(xml, contains('<oc:size/>'));
      expect(xml, contains('<oc:permissions/>'));
      expect(xml, contains('<oc:fileid/>'));
      expect(xml, contains('<nc:has-preview/>'));
      expect(xml, contains('<nc:mount-type/>'));
    });
  });
}
