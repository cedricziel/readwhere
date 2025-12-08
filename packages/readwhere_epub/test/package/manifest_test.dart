import 'package:test/test.dart';
import 'package:readwhere_epub/src/package/manifest/manifest.dart';

void main() {
  group('ManifestItem', () {
    group('constructor', () {
      test('creates item with required fields', () {
        const item = ManifestItem(
          id: 'chapter1',
          href: 'chapter1.xhtml',
          mediaType: 'application/xhtml+xml',
        );

        expect(item.id, equals('chapter1'));
        expect(item.href, equals('chapter1.xhtml'));
        expect(item.mediaType, equals('application/xhtml+xml'));
        expect(item.properties, isEmpty);
        expect(item.fallback, isNull);
        expect(item.mediaOverlay, isNull);
      });

      test('creates item with all fields', () {
        const item = ManifestItem(
          id: 'chapter1',
          href: 'chapter1.xhtml',
          mediaType: 'application/xhtml+xml',
          properties: {'scripted', 'mathml'},
          fallback: 'fallback-id',
          mediaOverlay: 'overlay-id',
        );

        expect(item.properties, containsAll(['scripted', 'mathml']));
        expect(item.fallback, equals('fallback-id'));
        expect(item.mediaOverlay, equals('overlay-id'));
      });
    });

    group('isXhtml', () {
      test('returns true for application/xhtml+xml', () {
        const item = ManifestItem(
          id: 'ch1',
          href: 'ch1.xhtml',
          mediaType: 'application/xhtml+xml',
        );
        expect(item.isXhtml, isTrue);
      });

      test('returns true for text/html', () {
        const item = ManifestItem(
          id: 'ch1',
          href: 'ch1.html',
          mediaType: 'text/html',
        );
        expect(item.isXhtml, isTrue);
      });

      test('returns false for other types', () {
        const item = ManifestItem(
          id: 'style',
          href: 'style.css',
          mediaType: 'text/css',
        );
        expect(item.isXhtml, isFalse);
      });
    });

    group('isCss', () {
      test('returns true for text/css', () {
        const item = ManifestItem(
          id: 'style',
          href: 'style.css',
          mediaType: 'text/css',
        );
        expect(item.isCss, isTrue);
      });

      test('returns false for other types', () {
        const item = ManifestItem(
          id: 'ch1',
          href: 'ch1.xhtml',
          mediaType: 'application/xhtml+xml',
        );
        expect(item.isCss, isFalse);
      });
    });

    group('isImage', () {
      test('returns true for image/jpeg', () {
        const item = ManifestItem(
          id: 'img1',
          href: 'img1.jpg',
          mediaType: 'image/jpeg',
        );
        expect(item.isImage, isTrue);
      });

      test('returns true for image/png', () {
        const item = ManifestItem(
          id: 'img1',
          href: 'img1.png',
          mediaType: 'image/png',
        );
        expect(item.isImage, isTrue);
      });

      test('returns true for image/gif', () {
        const item = ManifestItem(
          id: 'img1',
          href: 'img1.gif',
          mediaType: 'image/gif',
        );
        expect(item.isImage, isTrue);
      });

      test('returns true for image/svg+xml', () {
        const item = ManifestItem(
          id: 'img1',
          href: 'img1.svg',
          mediaType: 'image/svg+xml',
        );
        expect(item.isImage, isTrue);
      });

      test('returns true for image/webp', () {
        const item = ManifestItem(
          id: 'img1',
          href: 'img1.webp',
          mediaType: 'image/webp',
        );
        expect(item.isImage, isTrue);
      });

      test('returns false for non-image types', () {
        const item = ManifestItem(
          id: 'ch1',
          href: 'ch1.xhtml',
          mediaType: 'application/xhtml+xml',
        );
        expect(item.isImage, isFalse);
      });
    });

    group('isFont', () {
      test('returns true for font/woff', () {
        const item = ManifestItem(
          id: 'font1',
          href: 'font.woff',
          mediaType: 'font/woff',
        );
        expect(item.isFont, isTrue);
      });

      test('returns true for font/woff2', () {
        const item = ManifestItem(
          id: 'font1',
          href: 'font.woff2',
          mediaType: 'font/woff2',
        );
        expect(item.isFont, isTrue);
      });

      test('returns true for font/ttf', () {
        const item = ManifestItem(
          id: 'font1',
          href: 'font.ttf',
          mediaType: 'font/ttf',
        );
        expect(item.isFont, isTrue);
      });

      test('returns true for font/otf', () {
        const item = ManifestItem(
          id: 'font1',
          href: 'font.otf',
          mediaType: 'font/otf',
        );
        expect(item.isFont, isTrue);
      });

      test('returns true for application/font-woff', () {
        const item = ManifestItem(
          id: 'font1',
          href: 'font.woff',
          mediaType: 'application/font-woff',
        );
        expect(item.isFont, isTrue);
      });

      test('returns true for application/font-woff2', () {
        const item = ManifestItem(
          id: 'font1',
          href: 'font.woff2',
          mediaType: 'application/font-woff2',
        );
        expect(item.isFont, isTrue);
      });

      test('returns true for application/vnd.ms-opentype', () {
        const item = ManifestItem(
          id: 'font1',
          href: 'font.otf',
          mediaType: 'application/vnd.ms-opentype',
        );
        expect(item.isFont, isTrue);
      });

      test('returns true for application/font-sfnt', () {
        const item = ManifestItem(
          id: 'font1',
          href: 'font.otf',
          mediaType: 'application/font-sfnt',
        );
        expect(item.isFont, isTrue);
      });

      test('returns false for non-font types', () {
        const item = ManifestItem(
          id: 'ch1',
          href: 'ch1.xhtml',
          mediaType: 'application/xhtml+xml',
        );
        expect(item.isFont, isFalse);
      });
    });

    group('isAudio', () {
      test('returns true for audio/mpeg', () {
        const item = ManifestItem(
          id: 'audio1',
          href: 'audio.mp3',
          mediaType: 'audio/mpeg',
        );
        expect(item.isAudio, isTrue);
      });

      test('returns true for audio/mp4', () {
        const item = ManifestItem(
          id: 'audio1',
          href: 'audio.m4a',
          mediaType: 'audio/mp4',
        );
        expect(item.isAudio, isTrue);
      });

      test('returns true for audio/ogg', () {
        const item = ManifestItem(
          id: 'audio1',
          href: 'audio.ogg',
          mediaType: 'audio/ogg',
        );
        expect(item.isAudio, isTrue);
      });

      test('returns false for non-audio types', () {
        const item = ManifestItem(
          id: 'video1',
          href: 'video.mp4',
          mediaType: 'video/mp4',
        );
        expect(item.isAudio, isFalse);
      });
    });

    group('isVideo', () {
      test('returns true for video/mp4', () {
        const item = ManifestItem(
          id: 'video1',
          href: 'video.mp4',
          mediaType: 'video/mp4',
        );
        expect(item.isVideo, isTrue);
      });

      test('returns true for video/webm', () {
        const item = ManifestItem(
          id: 'video1',
          href: 'video.webm',
          mediaType: 'video/webm',
        );
        expect(item.isVideo, isTrue);
      });

      test('returns false for non-video types', () {
        const item = ManifestItem(
          id: 'audio1',
          href: 'audio.mp3',
          mediaType: 'audio/mpeg',
        );
        expect(item.isVideo, isFalse);
      });
    });

    group('property checks', () {
      test('isNav returns true when nav property present', () {
        const item = ManifestItem(
          id: 'nav',
          href: 'nav.xhtml',
          mediaType: 'application/xhtml+xml',
          properties: {'nav'},
        );
        expect(item.isNav, isTrue);
      });

      test('isNav returns false when nav property absent', () {
        const item = ManifestItem(
          id: 'ch1',
          href: 'ch1.xhtml',
          mediaType: 'application/xhtml+xml',
        );
        expect(item.isNav, isFalse);
      });

      test('isCoverImage returns true when cover-image property present', () {
        const item = ManifestItem(
          id: 'cover',
          href: 'cover.jpg',
          mediaType: 'image/jpeg',
          properties: {'cover-image'},
        );
        expect(item.isCoverImage, isTrue);
      });

      test('isScripted returns true when scripted property present', () {
        const item = ManifestItem(
          id: 'interactive',
          href: 'interactive.xhtml',
          mediaType: 'application/xhtml+xml',
          properties: {'scripted'},
        );
        expect(item.isScripted, isTrue);
      });

      test('hasMathML returns true when mathml property present', () {
        const item = ManifestItem(
          id: 'math',
          href: 'math.xhtml',
          mediaType: 'application/xhtml+xml',
          properties: {'mathml'},
        );
        expect(item.hasMathML, isTrue);
      });

      test('hasSVG returns true when svg property present', () {
        const item = ManifestItem(
          id: 'vector',
          href: 'vector.xhtml',
          mediaType: 'application/xhtml+xml',
          properties: {'svg'},
        );
        expect(item.hasSVG, isTrue);
      });

      test('hasRemoteResources returns true when remote-resources present', () {
        const item = ManifestItem(
          id: 'remote',
          href: 'remote.xhtml',
          mediaType: 'application/xhtml+xml',
          properties: {'remote-resources'},
        );
        expect(item.hasRemoteResources, isTrue);
      });

      test('multiple properties can be checked', () {
        const item = ManifestItem(
          id: 'complex',
          href: 'complex.xhtml',
          mediaType: 'application/xhtml+xml',
          properties: {'scripted', 'mathml', 'svg'},
        );
        expect(item.isScripted, isTrue);
        expect(item.hasMathML, isTrue);
        expect(item.hasSVG, isTrue);
        expect(item.isNav, isFalse);
      });
    });

    group('isCoreMediaType', () {
      test('returns true for image/gif', () {
        const item = ManifestItem(
          id: 'img',
          href: 'img.gif',
          mediaType: 'image/gif',
        );
        expect(item.isCoreMediaType, isTrue);
      });

      test('returns true for image/jpeg', () {
        const item = ManifestItem(
          id: 'img',
          href: 'img.jpg',
          mediaType: 'image/jpeg',
        );
        expect(item.isCoreMediaType, isTrue);
      });

      test('returns true for image/png', () {
        const item = ManifestItem(
          id: 'img',
          href: 'img.png',
          mediaType: 'image/png',
        );
        expect(item.isCoreMediaType, isTrue);
      });

      test('returns true for image/svg+xml', () {
        const item = ManifestItem(
          id: 'img',
          href: 'img.svg',
          mediaType: 'image/svg+xml',
        );
        expect(item.isCoreMediaType, isTrue);
      });

      test('returns true for image/webp', () {
        const item = ManifestItem(
          id: 'img',
          href: 'img.webp',
          mediaType: 'image/webp',
        );
        expect(item.isCoreMediaType, isTrue);
      });

      test('returns true for audio/mpeg', () {
        const item = ManifestItem(
          id: 'audio',
          href: 'audio.mp3',
          mediaType: 'audio/mpeg',
        );
        expect(item.isCoreMediaType, isTrue);
      });

      test('returns true for application/xhtml+xml', () {
        const item = ManifestItem(
          id: 'ch1',
          href: 'ch1.xhtml',
          mediaType: 'application/xhtml+xml',
        );
        expect(item.isCoreMediaType, isTrue);
      });

      test('returns true for text/css', () {
        const item = ManifestItem(
          id: 'style',
          href: 'style.css',
          mediaType: 'text/css',
        );
        expect(item.isCoreMediaType, isTrue);
      });

      test('returns true for application/javascript', () {
        const item = ManifestItem(
          id: 'script',
          href: 'script.js',
          mediaType: 'application/javascript',
        );
        expect(item.isCoreMediaType, isTrue);
      });

      test('returns true for NCX (application/x-dtbncx+xml)', () {
        const item = ManifestItem(
          id: 'ncx',
          href: 'toc.ncx',
          mediaType: 'application/x-dtbncx+xml',
        );
        expect(item.isCoreMediaType, isTrue);
      });

      test('returns true for SMIL (application/smil+xml)', () {
        const item = ManifestItem(
          id: 'overlay',
          href: 'overlay.smil',
          mediaType: 'application/smil+xml',
        );
        expect(item.isCoreMediaType, isTrue);
      });

      test('returns false for non-core types', () {
        const item = ManifestItem(
          id: 'pdf',
          href: 'doc.pdf',
          mediaType: 'application/pdf',
        );
        expect(item.isCoreMediaType, isFalse);
      });

      test('returns false for text/html (not core, needs fallback)', () {
        const item = ManifestItem(
          id: 'ch1',
          href: 'ch1.html',
          mediaType: 'text/html',
        );
        expect(item.isCoreMediaType, isFalse);
      });
    });

    group('extension', () {
      test('extracts .xhtml extension', () {
        const item = ManifestItem(
          id: 'ch1',
          href: 'chapter1.xhtml',
          mediaType: 'application/xhtml+xml',
        );
        expect(item.extension, equals('.xhtml'));
      });

      test('extracts .jpg extension', () {
        const item = ManifestItem(
          id: 'img',
          href: 'image.jpg',
          mediaType: 'image/jpeg',
        );
        expect(item.extension, equals('.jpg'));
      });

      test('extracts extension from path with directories', () {
        const item = ManifestItem(
          id: 'ch1',
          href: 'OEBPS/text/chapter1.xhtml',
          mediaType: 'application/xhtml+xml',
        );
        expect(item.extension, equals('.xhtml'));
      });

      test('returns empty string when no extension', () {
        const item = ManifestItem(
          id: 'file',
          href: 'README',
          mediaType: 'text/plain',
        );
        expect(item.extension, equals(''));
      });

      test('returns empty string when ends with dot', () {
        const item = ManifestItem(
          id: 'file',
          href: 'file.',
          mediaType: 'text/plain',
        );
        expect(item.extension, equals(''));
      });

      test('handles multiple dots correctly', () {
        const item = ManifestItem(
          id: 'file',
          href: 'archive.tar.gz',
          mediaType: 'application/gzip',
        );
        expect(item.extension, equals('.gz'));
      });
    });

    group('Equatable', () {
      test('equal items have same hashCode', () {
        const item1 = ManifestItem(
          id: 'ch1',
          href: 'ch1.xhtml',
          mediaType: 'application/xhtml+xml',
        );
        const item2 = ManifestItem(
          id: 'ch1',
          href: 'ch1.xhtml',
          mediaType: 'application/xhtml+xml',
        );
        expect(item1, equals(item2));
        expect(item1.hashCode, equals(item2.hashCode));
      });

      test('different items are not equal', () {
        const item1 = ManifestItem(
          id: 'ch1',
          href: 'ch1.xhtml',
          mediaType: 'application/xhtml+xml',
        );
        const item2 = ManifestItem(
          id: 'ch2',
          href: 'ch2.xhtml',
          mediaType: 'application/xhtml+xml',
        );
        expect(item1, isNot(equals(item2)));
      });
    });

    group('toString', () {
      test('returns formatted string', () {
        const item = ManifestItem(
          id: 'ch1',
          href: 'chapter1.xhtml',
          mediaType: 'application/xhtml+xml',
        );
        expect(
          item.toString(),
          equals('ManifestItem(ch1: chapter1.xhtml [application/xhtml+xml])'),
        );
      });
    });
  });

  group('EpubManifest', () {
    late EpubManifest manifest;

    setUp(() {
      manifest = EpubManifest([
        const ManifestItem(
          id: 'nav',
          href: 'nav.xhtml',
          mediaType: 'application/xhtml+xml',
          properties: {'nav'},
        ),
        const ManifestItem(
          id: 'ch1',
          href: 'chapter1.xhtml',
          mediaType: 'application/xhtml+xml',
        ),
        const ManifestItem(
          id: 'ch2',
          href: 'chapter2.xhtml',
          mediaType: 'application/xhtml+xml',
        ),
        const ManifestItem(
          id: 'style',
          href: 'style.css',
          mediaType: 'text/css',
        ),
        const ManifestItem(
          id: 'cover',
          href: 'cover.jpg',
          mediaType: 'image/jpeg',
          properties: {'cover-image'},
        ),
        const ManifestItem(
          id: 'img1',
          href: 'image1.png',
          mediaType: 'image/png',
        ),
        const ManifestItem(
          id: 'font1',
          href: 'font.woff2',
          mediaType: 'font/woff2',
        ),
        const ManifestItem(
          id: 'ncx',
          href: 'toc.ncx',
          mediaType: 'application/x-dtbncx+xml',
        ),
      ]);
    });

    group('factory constructor', () {
      test('creates manifest from list of items', () {
        expect(manifest.length, equals(8));
      });

      test('creates empty manifest from empty list', () {
        final empty = EpubManifest([]);
        expect(empty.length, equals(0));
        expect(empty.items, isEmpty);
      });
    });

    group('items', () {
      test('returns all items', () {
        expect(manifest.items, hasLength(8));
      });
    });

    group('length', () {
      test('returns correct count', () {
        expect(manifest.length, equals(8));
      });
    });

    group('operator []', () {
      test('returns item by id', () {
        final item = manifest['ch1'];
        expect(item, isNotNull);
        expect(item!.id, equals('ch1'));
      });

      test('returns null for unknown id', () {
        final item = manifest['unknown'];
        expect(item, isNull);
      });
    });

    group('getById', () {
      test('returns item by id', () {
        final item = manifest.getById('ch1');
        expect(item, isNotNull);
        expect(item!.href, equals('chapter1.xhtml'));
      });

      test('returns null for unknown id', () {
        final item = manifest.getById('unknown');
        expect(item, isNull);
      });
    });

    group('getByHref', () {
      test('returns item by href', () {
        final item = manifest.getByHref('chapter1.xhtml');
        expect(item, isNotNull);
        expect(item!.id, equals('ch1'));
      });

      test('is case-insensitive', () {
        final item = manifest.getByHref('CHAPTER1.XHTML');
        expect(item, isNotNull);
        expect(item!.id, equals('ch1'));
      });

      test('returns null for unknown href', () {
        final item = manifest.getByHref('unknown.xhtml');
        expect(item, isNull);
      });
    });

    group('itemsByMediaType', () {
      test('returns items with matching media type', () {
        final xhtmlItems =
            manifest.itemsByMediaType('application/xhtml+xml').toList();
        expect(xhtmlItems, hasLength(3)); // nav, ch1, ch2
      });

      test('returns empty for non-existent media type', () {
        final pdfItems = manifest.itemsByMediaType('application/pdf').toList();
        expect(pdfItems, isEmpty);
      });
    });

    group('itemsByProperty', () {
      test('returns items with matching property', () {
        final navItems = manifest.itemsByProperty('nav').toList();
        expect(navItems, hasLength(1));
        expect(navItems.first.id, equals('nav'));
      });

      test('returns items with cover-image property', () {
        final coverItems = manifest.itemsByProperty('cover-image').toList();
        expect(coverItems, hasLength(1));
        expect(coverItems.first.id, equals('cover'));
      });

      test('returns empty for non-existent property', () {
        final scriptedItems = manifest.itemsByProperty('scripted').toList();
        expect(scriptedItems, isEmpty);
      });
    });

    group('contentDocuments', () {
      test('returns all XHTML documents', () {
        final docs = manifest.contentDocuments.toList();
        expect(docs, hasLength(3)); // nav, ch1, ch2
      });
    });

    group('stylesheets', () {
      test('returns all CSS files', () {
        final sheets = manifest.stylesheets.toList();
        expect(sheets, hasLength(1));
        expect(sheets.first.id, equals('style'));
      });
    });

    group('images', () {
      test('returns all image files', () {
        final imgs = manifest.images.toList();
        expect(imgs, hasLength(2)); // cover, img1
      });
    });

    group('fonts', () {
      test('returns all font files', () {
        final fnts = manifest.fonts.toList();
        expect(fnts, hasLength(1));
        expect(fnts.first.id, equals('font1'));
      });
    });

    group('navigationDocument', () {
      test('returns nav document when present', () {
        final nav = manifest.navigationDocument;
        expect(nav, isNotNull);
        expect(nav!.id, equals('nav'));
      });

      test('returns null when no nav document', () {
        final noNavManifest = EpubManifest([
          const ManifestItem(
            id: 'ch1',
            href: 'ch1.xhtml',
            mediaType: 'application/xhtml+xml',
          ),
        ]);
        expect(noNavManifest.navigationDocument, isNull);
      });
    });

    group('ncx', () {
      test('returns NCX document when present', () {
        final ncx = manifest.ncx;
        expect(ncx, isNotNull);
        expect(ncx!.id, equals('ncx'));
      });

      test('returns null when no NCX document', () {
        final noNcxManifest = EpubManifest([
          const ManifestItem(
            id: 'ch1',
            href: 'ch1.xhtml',
            mediaType: 'application/xhtml+xml',
          ),
        ]);
        expect(noNcxManifest.ncx, isNull);
      });
    });

    group('coverImage', () {
      test('returns cover image when present', () {
        final cover = manifest.coverImage;
        expect(cover, isNotNull);
        expect(cover!.id, equals('cover'));
      });

      test('returns null when no cover image', () {
        final noCoverManifest = EpubManifest([
          const ManifestItem(
            id: 'img1',
            href: 'img1.jpg',
            mediaType: 'image/jpeg',
          ),
        ]);
        expect(noCoverManifest.coverImage, isNull);
      });
    });

    group('containsId', () {
      test('returns true for existing id', () {
        expect(manifest.containsId('ch1'), isTrue);
      });

      test('returns false for non-existing id', () {
        expect(manifest.containsId('unknown'), isFalse);
      });
    });

    group('containsHref', () {
      test('returns true for existing href', () {
        expect(manifest.containsHref('chapter1.xhtml'), isTrue);
      });

      test('is case-insensitive', () {
        expect(manifest.containsHref('CHAPTER1.XHTML'), isTrue);
      });

      test('returns false for non-existing href', () {
        expect(manifest.containsHref('unknown.xhtml'), isFalse);
      });
    });

    group('Equatable', () {
      test('equal manifests are equal', () {
        final manifest2 = EpubManifest([
          const ManifestItem(
            id: 'nav',
            href: 'nav.xhtml',
            mediaType: 'application/xhtml+xml',
            properties: {'nav'},
          ),
          const ManifestItem(
            id: 'ch1',
            href: 'chapter1.xhtml',
            mediaType: 'application/xhtml+xml',
          ),
          const ManifestItem(
            id: 'ch2',
            href: 'chapter2.xhtml',
            mediaType: 'application/xhtml+xml',
          ),
          const ManifestItem(
            id: 'style',
            href: 'style.css',
            mediaType: 'text/css',
          ),
          const ManifestItem(
            id: 'cover',
            href: 'cover.jpg',
            mediaType: 'image/jpeg',
            properties: {'cover-image'},
          ),
          const ManifestItem(
            id: 'img1',
            href: 'image1.png',
            mediaType: 'image/png',
          ),
          const ManifestItem(
            id: 'font1',
            href: 'font.woff2',
            mediaType: 'font/woff2',
          ),
          const ManifestItem(
            id: 'ncx',
            href: 'toc.ncx',
            mediaType: 'application/x-dtbncx+xml',
          ),
        ]);
        expect(manifest, equals(manifest2));
      });

      test('different manifests are not equal', () {
        final manifest2 = EpubManifest([
          const ManifestItem(
            id: 'ch1',
            href: 'ch1.xhtml',
            mediaType: 'application/xhtml+xml',
          ),
        ]);
        expect(manifest, isNot(equals(manifest2)));
      });
    });
  });
}
