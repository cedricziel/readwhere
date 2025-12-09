import 'package:readwhere_webdav/src/xml/propfind_parser.dart';
import 'package:test/test.dart';

void main() {
  group('PropfindParser', () {
    group('parse', () {
      test('parses single file response', () {
        const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/files/</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>files</d:displayname>
        <d:resourcetype><d:collection/></d:resourcetype>
      </d:prop>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/files/test.txt</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>test.txt</d:displayname>
        <d:getcontentlength>1024</d:getcontentlength>
        <d:getlastmodified>Mon, 15 Jan 2024 10:30:00 GMT</d:getlastmodified>
        <d:getcontenttype>text/plain</d:getcontenttype>
        <d:getetag>"abc123"</d:getetag>
        <d:resourcetype/>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>''';

        final files = PropfindParser.parse(xml, basePath: '/files/');

        expect(files.length, 1);
        expect(files[0].name, 'test.txt');
        expect(files[0].path, '/files/test.txt');
        expect(files[0].size, 1024);
        expect(files[0].isDirectory, false);
        expect(files[0].mimeType, 'text/plain');
        expect(files[0].etag, 'abc123');
      });

      test('parses directory response', () {
        const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/files/</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>files</d:displayname>
        <d:resourcetype><d:collection/></d:resourcetype>
      </d:prop>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/files/documents/</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>documents</d:displayname>
        <d:resourcetype><d:collection/></d:resourcetype>
      </d:prop>
    </d:propstat>
  </d:response>
</d:multistatus>''';

        final files = PropfindParser.parse(xml, basePath: '/files/');

        expect(files.length, 1);
        expect(files[0].name, 'documents');
        expect(files[0].isDirectory, true);
      });

      test('parses multiple files and directories', () {
        const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/files/</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>files</d:displayname>
        <d:resourcetype><d:collection/></d:resourcetype>
      </d:prop>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/files/doc.pdf</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>doc.pdf</d:displayname>
        <d:getcontentlength>2048</d:getcontentlength>
        <d:resourcetype/>
      </d:prop>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/files/folder/</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>folder</d:displayname>
        <d:resourcetype><d:collection/></d:resourcetype>
      </d:prop>
    </d:propstat>
  </d:response>
</d:multistatus>''';

        final files = PropfindParser.parse(xml, basePath: '/files/');

        // Should exclude the base path itself (first response)
        expect(files.length, 2);
        expect(files.any((f) => f.name == 'doc.pdf'), true);
        expect(files.any((f) => f.name == 'folder'), true);
      });

      test('handles URL-encoded paths', () {
        const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/files/</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>files</d:displayname>
        <d:resourcetype><d:collection/></d:resourcetype>
      </d:prop>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/files/my%20document.txt</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>my document.txt</d:displayname>
        <d:resourcetype/>
      </d:prop>
    </d:propstat>
  </d:response>
</d:multistatus>''';

        final files = PropfindParser.parse(xml, basePath: '/files/');

        expect(files.length, 1);
        expect(files[0].name, 'my document.txt');
        expect(files[0].path, '/files/my document.txt');
      });

      test('handles missing optional properties', () {
        const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/files/</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>files</d:displayname>
        <d:resourcetype><d:collection/></d:resourcetype>
      </d:prop>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/files/test.txt</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>test.txt</d:displayname>
        <d:resourcetype/>
      </d:prop>
    </d:propstat>
  </d:response>
</d:multistatus>''';

        final files = PropfindParser.parse(xml, basePath: '/files/');

        expect(files.length, 1);
        expect(files[0].name, 'test.txt');
        expect(files[0].size, isNull);
        expect(files[0].lastModified, isNull);
        expect(files[0].mimeType, isNull);
        expect(files[0].etag, isNull);
      });

      test('returns empty list when only base directory', () {
        const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/files/</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>files</d:displayname>
        <d:resourcetype><d:collection/></d:resourcetype>
      </d:prop>
    </d:propstat>
  </d:response>
</d:multistatus>''';

        final files = PropfindParser.parse(xml, basePath: '/files/');

        expect(files, isEmpty);
      });

      test('skipFirst=false includes base directory', () {
        const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/files/</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>files</d:displayname>
        <d:resourcetype><d:collection/></d:resourcetype>
      </d:prop>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/files/test.txt</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>test.txt</d:displayname>
        <d:resourcetype/>
      </d:prop>
    </d:propstat>
  </d:response>
</d:multistatus>''';

        final files =
            PropfindParser.parse(xml, basePath: '/files/', skipFirst: false);

        expect(files.length, 2);
      });

      test('sorts directories first, then by name', () {
        const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/files/</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>files</d:displayname>
        <d:resourcetype><d:collection/></d:resourcetype>
      </d:prop>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/files/zebra.txt</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>zebra.txt</d:displayname>
        <d:resourcetype/>
      </d:prop>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/files/alpha/</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>alpha</d:displayname>
        <d:resourcetype><d:collection/></d:resourcetype>
      </d:prop>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/files/apple.txt</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>apple.txt</d:displayname>
        <d:resourcetype/>
      </d:prop>
    </d:propstat>
  </d:response>
</d:multistatus>''';

        final files = PropfindParser.parse(xml, basePath: '/files/');

        expect(files.length, 3);
        // Directory first
        expect(files[0].name, 'alpha');
        expect(files[0].isDirectory, true);
        // Then files alphabetically
        expect(files[1].name, 'apple.txt');
        expect(files[2].name, 'zebra.txt');
      });

      test('uses custom pathExtractor when provided', () {
        const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/remote.php/dav/files/user/</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>user</d:displayname>
        <d:resourcetype><d:collection/></d:resourcetype>
      </d:prop>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/remote.php/dav/files/user/test.txt</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>test.txt</d:displayname>
        <d:resourcetype/>
      </d:prop>
    </d:propstat>
  </d:response>
</d:multistatus>''';

        final files = PropfindParser.parse(
          xml,
          pathExtractor: (href) {
            // Extract just the user-relative path
            const prefix = '/remote.php/dav/files/user';
            if (href.startsWith(prefix)) {
              final path = href.substring(prefix.length);
              return path.isEmpty ? '/' : path;
            }
            return href;
          },
        );

        expect(files.length, 1);
        expect(files[0].path, '/test.txt');
      });

      test('handles OwnCloud size extension', () {
        const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<d:multistatus xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns">
  <d:response>
    <d:href>/files/</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>files</d:displayname>
        <d:resourcetype><d:collection/></d:resourcetype>
      </d:prop>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/files/test.txt</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>test.txt</d:displayname>
        <oc:size>4096</oc:size>
        <d:resourcetype/>
      </d:prop>
    </d:propstat>
  </d:response>
</d:multistatus>''';

        final files = PropfindParser.parse(xml, basePath: '/files/');

        expect(files.length, 1);
        expect(files[0].size, 4096);
      });
    });
  });
}
