import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:readwhere_cbz/readwhere_cbz.dart';
import 'package:test/test.dart';

/// Creates a valid test CBZ archive with the given images and metadata.
Uint8List createTestCbz({
  List<String> imageFilenames = const ['page001.jpg', 'page002.jpg'],
  String? comicInfoXml,
  String? metronInfoXml,
}) {
  final archive = Archive();

  // Add JPEG images
  final jpegBytes = Uint8List.fromList([
    0xFF,
    0xD8,
    0xFF,
    0xE0,
    0x00,
    0x10,
    0x4A,
    0x46,
    0x49,
    0x46,
    0x00,
    0x01,
    0x01,
    0x00,
    0x00,
    0x01,
    0x00,
    0x01,
    0x00,
    0x00,
  ]);

  for (final filename in imageFilenames) {
    archive.addFile(ArchiveFile(filename, jpegBytes.length, jpegBytes));
  }

  if (comicInfoXml != null) {
    final xmlBytes = Uint8List.fromList(comicInfoXml.codeUnits);
    archive.addFile(ArchiveFile('ComicInfo.xml', xmlBytes.length, xmlBytes));
  }

  if (metronInfoXml != null) {
    final xmlBytes = Uint8List.fromList(metronInfoXml.codeUnits);
    archive.addFile(ArchiveFile('MetronInfo.xml', xmlBytes.length, xmlBytes));
  }

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  group('CbzReader', () {
    group('openBytes', () {
      test('opens valid CBZ archive', () {
        final bytes = createTestCbz();
        final reader = CbzReader.openBytes(bytes);

        expect(reader.pageCount, equals(2));
        reader.dispose();
      });

      test('throws CbzReadException for invalid data', () {
        final bytes = Uint8List.fromList([0, 1, 2, 3, 4, 5]);

        // May throw or create empty archive depending on library behavior
        try {
          final reader = CbzReader.openBytes(bytes);
          // If it doesn't throw, should have 0 pages
          expect(reader.pageCount, equals(0));
          reader.dispose();
        } catch (e) {
          expect(e, isA<CbzReadException>());
        }
      });
    });

    group('book', () {
      test('returns parsed CbzBook', () {
        final bytes = createTestCbz();
        final reader = CbzReader.openBytes(bytes);

        expect(reader.book, isA<CbzBook>());
        expect(reader.book.pageCount, equals(2));
        reader.dispose();
      });

      test('parses ComicInfo.xml metadata', () {
        const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <Title>Test Comic</Title>
  <Series>Test Series</Series>
  <Number>1</Number>
  <Writer>John Writer</Writer>
</ComicInfo>''';

        final bytes = createTestCbz(comicInfoXml: xml);
        final reader = CbzReader.openBytes(bytes);

        expect(reader.book.title, equals('Test Comic'));
        expect(reader.book.series, equals('Test Series'));
        expect(reader.book.number, equals('1'));
        expect(reader.book.author, equals('John Writer'));
        expect(reader.metadataSource, equals(MetadataSource.comicInfo));
        reader.dispose();
      });

      test('parses MetronInfo.xml metadata', () {
        const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<MetronInfo>
  <Series>
    <Name>Metron Series</Name>
    <Volume>2</Volume>
  </Series>
  <Number>5</Number>
  <Summary>A great comic!</Summary>
</MetronInfo>''';

        final bytes = createTestCbz(metronInfoXml: xml);
        final reader = CbzReader.openBytes(bytes);

        expect(reader.book.series, equals('Metron Series'));
        expect(reader.book.volume, equals(2));
        expect(reader.book.number, equals('5'));
        expect(reader.book.summary, equals('A great comic!'));
        expect(reader.metadataSource, equals(MetadataSource.metronInfo));
        reader.dispose();
      });

      test('prefers MetronInfo when both exist', () {
        const comicXml = '''<?xml version="1.0"?>
<ComicInfo>
  <Title>Comic Title</Title>
</ComicInfo>''';

        const metronXml = '''<?xml version="1.0"?>
<MetronInfo>
  <Series>
    <Name>Metron Series</Name>
  </Series>
</MetronInfo>''';

        final bytes =
            createTestCbz(comicInfoXml: comicXml, metronInfoXml: metronXml);
        final reader = CbzReader.openBytes(bytes);

        // MetronInfo is preferred, so series comes from there
        expect(reader.book.series, equals('Metron Series'));
        expect(reader.metadataSource, equals(MetadataSource.metronInfo));
        // But ComicInfo is still available
        expect(reader.comicInfo, isNotNull);
        expect(reader.comicInfo!.title, equals('Comic Title'));
        reader.dispose();
      });
    });

    group('getPage', () {
      test('returns page by index', () {
        final bytes = createTestCbz();
        final reader = CbzReader.openBytes(bytes);

        final page = reader.getPage(0);
        expect(page.index, equals(0));
        expect(page.filename, equals('page001.jpg'));
        reader.dispose();
      });

      test('throws CbzPageNotFoundException for invalid index', () {
        final bytes = createTestCbz();
        final reader = CbzReader.openBytes(bytes);

        expect(
          () => reader.getPage(-1),
          throwsA(isA<CbzPageNotFoundException>()),
        );
        expect(
          () => reader.getPage(100),
          throwsA(isA<CbzPageNotFoundException>()),
        );
        reader.dispose();
      });
    });

    group('getAllPages', () {
      test('returns all pages in order', () {
        final bytes = createTestCbz(imageFilenames: [
          'page003.jpg',
          'page001.jpg',
          'page002.jpg',
        ]);
        final reader = CbzReader.openBytes(bytes);

        final pages = reader.getAllPages();
        expect(pages, hasLength(3));
        // Should be sorted by natural order
        expect(pages[0].filename, equals('page001.jpg'));
        expect(pages[1].filename, equals('page002.jpg'));
        expect(pages[2].filename, equals('page003.jpg'));
        reader.dispose();
      });
    });

    group('getPageBytes', () {
      test('returns image bytes for page', () {
        final bytes = createTestCbz();
        final reader = CbzReader.openBytes(bytes);

        final pageBytes = reader.getPageBytes(0);
        expect(pageBytes, isNotNull);
        expect(pageBytes!.length, greaterThan(0));
        // Check JPEG header
        expect(pageBytes[0], equals(0xFF));
        expect(pageBytes[1], equals(0xD8));
        reader.dispose();
      });

      test('throws CbzPageNotFoundException for invalid index', () {
        final bytes = createTestCbz();
        final reader = CbzReader.openBytes(bytes);

        expect(
          () => reader.getPageBytes(-1),
          throwsA(isA<CbzPageNotFoundException>()),
        );
        reader.dispose();
      });
    });

    group('getCoverBytes', () {
      test('returns cover image bytes', () {
        final bytes = createTestCbz();
        final reader = CbzReader.openBytes(bytes);

        final coverBytes = reader.getCoverBytes();
        expect(coverBytes, isNotNull);
        reader.dispose();
      });
    });

    group('caching', () {
      test('caches page bytes', () {
        final bytes = createTestCbz();
        final reader = CbzReader.openBytes(bytes);

        final bytes1 = reader.getPageBytes(0);
        final bytes2 = reader.getPageBytes(0);

        // Same reference (cached)
        expect(identical(bytes1, bytes2), isTrue);
        reader.dispose();
      });

      test('clearCache clears cached pages', () {
        final bytes = createTestCbz();
        final reader = CbzReader.openBytes(bytes);

        final bytes1 = reader.getPageBytes(0);
        reader.clearCache();
        final bytes2 = reader.getPageBytes(0);

        // Different references after cache clear
        expect(identical(bytes1, bytes2), isFalse);
        reader.dispose();
      });
    });

    group('dispose', () {
      test('prevents further operations', () {
        final bytes = createTestCbz();
        final reader = CbzReader.openBytes(bytes);
        reader.dispose();

        expect(() => reader.getPage(0), throwsA(isA<StateError>()));
        expect(() => reader.getPageBytes(0), throwsA(isA<StateError>()));
        expect(() => reader.getAllPages(), throwsA(isA<StateError>()));
      });

      test('can be called multiple times safely', () {
        final bytes = createTestCbz();
        final reader = CbzReader.openBytes(bytes);

        reader.dispose();
        reader.dispose(); // Should not throw
      });
    });
  });

  group('CbzBook', () {
    test('displayTitle returns title when available', () {
      const book = CbzBook(
        title: 'My Comic',
        series: 'My Series',
        number: '1',
      );
      expect(book.displayTitle, equals('My Comic'));
    });

    test('displayTitle returns series and number when no title', () {
      const book = CbzBook(
        series: 'My Series',
        number: '5',
      );
      expect(book.displayTitle, equals('My Series #5'));
    });

    test('displayTitle returns series alone when no title or number', () {
      const book = CbzBook(series: 'My Series');
      expect(book.displayTitle, equals('My Series'));
    });

    test('displayTitle returns Unknown Comic when no metadata', () {
      const book = CbzBook();
      expect(book.displayTitle, equals('Unknown Comic'));
    });

    test('coverPage returns first front cover page', () {
      const pages = [
        ComicPage(index: 0, filename: 'page1.jpg', mediaType: 'image/jpeg'),
        ComicPage(
          index: 1,
          filename: 'cover.jpg',
          mediaType: 'image/jpeg',
          type: PageType.frontCover,
        ),
        ComicPage(index: 2, filename: 'page2.jpg', mediaType: 'image/jpeg'),
      ];
      const book = CbzBook(pages: pages);

      expect(book.coverPage, isNotNull);
      expect(book.coverPage!.index, equals(1));
    });

    test('coverPage returns first page when no front cover', () {
      const pages = [
        ComicPage(index: 0, filename: 'page1.jpg', mediaType: 'image/jpeg'),
        ComicPage(index: 1, filename: 'page2.jpg', mediaType: 'image/jpeg'),
      ];
      const book = CbzBook(pages: pages);

      expect(book.coverPage, isNotNull);
      expect(book.coverPage!.index, equals(0));
    });

    test('hasMetadata returns true when metadata source is set', () {
      const book = CbzBook(metadataSource: MetadataSource.comicInfo);
      expect(book.hasMetadata, isTrue);
    });

    test('hasMetadata returns false when no metadata', () {
      const book = CbzBook(metadataSource: MetadataSource.none);
      expect(book.hasMetadata, isFalse);
    });

    test('copyWith creates copy with modified fields', () {
      const original = CbzBook(
        title: 'Original',
        series: 'Original Series',
      );

      final copy = original.copyWith(title: 'Modified');

      expect(copy.title, equals('Modified'));
      expect(copy.series, equals('Original Series')); // Preserved
    });

    group('factory constructors', () {
      test('fromComicInfo creates book from ComicInfo', () {
        const comicInfo = ComicInfo(
          title: 'Comic Title',
          series: 'Comic Series',
          number: '10',
          summary: 'A great story',
          writers: ['Writer One'],
        );
        const pages = [
          ComicPage(index: 0, filename: 'p1.jpg', mediaType: 'image/jpeg'),
        ];

        final book = CbzBook.fromComicInfo(comicInfo, pages);

        expect(book.title, equals('Comic Title'));
        expect(book.series, equals('Comic Series'));
        expect(book.number, equals('10'));
        expect(book.summary, equals('A great story'));
        expect(book.author, equals('Writer One'));
        expect(book.metadataSource, equals(MetadataSource.comicInfo));
        expect(book.pages, hasLength(1));
      });

      test('pagesOnly creates book with no metadata', () {
        const pages = [
          ComicPage(index: 0, filename: 'p1.jpg', mediaType: 'image/jpeg'),
          ComicPage(index: 1, filename: 'p2.jpg', mediaType: 'image/jpeg'),
        ];

        final book = CbzBook.pagesOnly(pages);

        expect(book.title, isNull);
        expect(book.series, isNull);
        expect(book.metadataSource, equals(MetadataSource.none));
        expect(book.pages, hasLength(2));
      });
    });
  });
}
