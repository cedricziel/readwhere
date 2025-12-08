import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/domain/entities/book_metadata.dart';
import 'package:readwhere/domain/entities/toc_entry.dart';

void main() {
  group('BookMetadata', () {
    final testDate = DateTime(2024, 1, 1);
    final testCoverImage = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);

    BookMetadata createTestMetadata({
      String title = 'Test Book',
      String author = 'Test Author',
      String? description,
      String? publisher,
      String? language,
      DateTime? publishedDate,
      Uint8List? coverImage,
      List<TocEntry> tableOfContents = const [],
      EpubEncryptionType encryptionType = EpubEncryptionType.none,
      String? encryptionDescription,
      bool isFixedLayout = false,
      bool hasMediaOverlays = false,
    }) {
      return BookMetadata(
        title: title,
        author: author,
        description: description,
        publisher: publisher,
        language: language,
        publishedDate: publishedDate,
        coverImage: coverImage,
        tableOfContents: tableOfContents,
        encryptionType: encryptionType,
        encryptionDescription: encryptionDescription,
        isFixedLayout: isFixedLayout,
        hasMediaOverlays: hasMediaOverlays,
      );
    }

    group('constructor', () {
      test('creates metadata with required fields', () {
        final metadata = createTestMetadata();

        expect(metadata.title, equals('Test Book'));
        expect(metadata.author, equals('Test Author'));
      });

      test('applies default values for optional fields', () {
        final metadata = createTestMetadata();

        expect(metadata.description, isNull);
        expect(metadata.publisher, isNull);
        expect(metadata.language, isNull);
        expect(metadata.publishedDate, isNull);
        expect(metadata.coverImage, isNull);
        expect(metadata.tableOfContents, isEmpty);
        expect(metadata.encryptionType, equals(EpubEncryptionType.none));
        expect(metadata.encryptionDescription, isNull);
        expect(metadata.isFixedLayout, isFalse);
        expect(metadata.hasMediaOverlays, isFalse);
      });

      test('creates metadata with all optional fields', () {
        final toc = [
          const TocEntry(
            id: 'toc-1',
            title: 'Chapter 1',
            href: 'chapter1.html',
            level: 0,
          ),
        ];

        final metadata = BookMetadata(
          title: 'Full Book',
          author: 'Full Author',
          description: 'A great book',
          publisher: 'Test Publisher',
          language: 'en',
          publishedDate: testDate,
          coverImage: testCoverImage,
          tableOfContents: toc,
          encryptionType: EpubEncryptionType.fontObfuscation,
          encryptionDescription: 'Font obfuscation only',
          isFixedLayout: true,
          hasMediaOverlays: true,
        );

        expect(metadata.description, equals('A great book'));
        expect(metadata.publisher, equals('Test Publisher'));
        expect(metadata.language, equals('en'));
        expect(metadata.publishedDate, equals(testDate));
        expect(metadata.coverImage, equals(testCoverImage));
        expect(metadata.tableOfContents, equals(toc));
        expect(
          metadata.encryptionType,
          equals(EpubEncryptionType.fontObfuscation),
        );
        expect(metadata.encryptionDescription, equals('Font obfuscation only'));
        expect(metadata.isFixedLayout, isTrue);
        expect(metadata.hasMediaOverlays, isTrue);
      });
    });

    group('hasDrm', () {
      test('returns false for no encryption', () {
        final metadata = createTestMetadata(
          encryptionType: EpubEncryptionType.none,
        );
        expect(metadata.hasDrm, isFalse);
      });

      test('returns false for font obfuscation only', () {
        final metadata = createTestMetadata(
          encryptionType: EpubEncryptionType.fontObfuscation,
        );
        expect(metadata.hasDrm, isFalse);
      });

      test('returns true for Adobe DRM', () {
        final metadata = createTestMetadata(
          encryptionType: EpubEncryptionType.adobeDrm,
        );
        expect(metadata.hasDrm, isTrue);
      });

      test('returns true for Apple FairPlay', () {
        final metadata = createTestMetadata(
          encryptionType: EpubEncryptionType.appleFairPlay,
        );
        expect(metadata.hasDrm, isTrue);
      });

      test('returns true for LCP', () {
        final metadata = createTestMetadata(
          encryptionType: EpubEncryptionType.lcp,
        );
        expect(metadata.hasDrm, isTrue);
      });

      test('returns true for unknown encryption', () {
        final metadata = createTestMetadata(
          encryptionType: EpubEncryptionType.unknown,
        );
        expect(metadata.hasDrm, isTrue);
      });
    });

    group('copyWith', () {
      test('creates new instance with changed fields', () {
        final metadata = createTestMetadata();

        final updated = metadata.copyWith(
          title: 'New Title',
          author: 'New Author',
        );

        expect(updated.title, equals('New Title'));
        expect(updated.author, equals('New Author'));
      });

      test('preserves unchanged fields', () {
        final metadata = createTestMetadata(
          description: 'Description',
          publisher: 'Publisher',
        );

        final updated = metadata.copyWith(title: 'New Title');

        expect(updated.description, equals(metadata.description));
        expect(updated.publisher, equals(metadata.publisher));
      });

      test('can update all fields', () {
        final metadata = createTestMetadata();
        final newCover = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
        final newToc = [
          const TocEntry(
            id: 'toc-new',
            title: 'New Chapter',
            href: 'new.html',
            level: 0,
          ),
        ];

        final updated = metadata.copyWith(
          title: 'Updated Title',
          author: 'Updated Author',
          description: 'Updated Description',
          publisher: 'Updated Publisher',
          language: 'de',
          publishedDate: testDate,
          coverImage: newCover,
          tableOfContents: newToc,
          encryptionType: EpubEncryptionType.lcp,
          encryptionDescription: 'LCP protected',
          isFixedLayout: true,
          hasMediaOverlays: true,
        );

        expect(updated.title, equals('Updated Title'));
        expect(updated.author, equals('Updated Author'));
        expect(updated.description, equals('Updated Description'));
        expect(updated.publisher, equals('Updated Publisher'));
        expect(updated.language, equals('de'));
        expect(updated.publishedDate, equals(testDate));
        expect(updated.coverImage, equals(newCover));
        expect(updated.tableOfContents, equals(newToc));
        expect(updated.encryptionType, equals(EpubEncryptionType.lcp));
        expect(updated.encryptionDescription, equals('LCP protected'));
        expect(updated.isFixedLayout, isTrue);
        expect(updated.hasMediaOverlays, isTrue);
      });
    });

    group('equality', () {
      test('equals same metadata with identical properties', () {
        final metadata1 = createTestMetadata();
        final metadata2 = createTestMetadata();

        expect(metadata1, equals(metadata2));
      });

      test('not equals metadata with different title', () {
        final metadata1 = createTestMetadata(title: 'Title 1');
        final metadata2 = createTestMetadata(title: 'Title 2');

        expect(metadata1, isNot(equals(metadata2)));
      });

      test('hashCode is equal for equal metadata', () {
        final metadata1 = createTestMetadata();
        final metadata2 = createTestMetadata();

        expect(metadata1.hashCode, equals(metadata2.hashCode));
      });
    });

    group('toString', () {
      test('includes title, author, publisher, language', () {
        final metadata = createTestMetadata(
          publisher: 'Test Publisher',
          language: 'en',
        );
        final str = metadata.toString();

        expect(str, contains('title: Test Book'));
        expect(str, contains('author: Test Author'));
        expect(str, contains('publisher: Test Publisher'));
        expect(str, contains('language: en'));
      });

      test('shows hasCover status', () {
        final withCover = createTestMetadata(coverImage: testCoverImage);
        final withoutCover = createTestMetadata();

        expect(withCover.toString(), contains('hasCover: true'));
        expect(withoutCover.toString(), contains('hasCover: false'));
      });

      test('shows tocEntries count', () {
        final toc = [
          const TocEntry(id: '1', title: 'Ch1', href: 'ch1.html', level: 0),
          const TocEntry(id: '2', title: 'Ch2', href: 'ch2.html', level: 0),
        ];
        final metadata = createTestMetadata(tableOfContents: toc);

        expect(metadata.toString(), contains('tocEntries: 2'));
      });
    });
  });

  group('EpubEncryptionType', () {
    test('has none type', () {
      expect(EpubEncryptionType.values, contains(EpubEncryptionType.none));
    });

    test('has adobeDrm type', () {
      expect(EpubEncryptionType.values, contains(EpubEncryptionType.adobeDrm));
    });

    test('has appleFairPlay type', () {
      expect(
        EpubEncryptionType.values,
        contains(EpubEncryptionType.appleFairPlay),
      );
    });

    test('has lcp type', () {
      expect(EpubEncryptionType.values, contains(EpubEncryptionType.lcp));
    });

    test('has fontObfuscation type', () {
      expect(
        EpubEncryptionType.values,
        contains(EpubEncryptionType.fontObfuscation),
      );
    });

    test('has unknown type', () {
      expect(EpubEncryptionType.values, contains(EpubEncryptionType.unknown));
    });

    test('has exactly 6 types', () {
      expect(EpubEncryptionType.values.length, equals(6));
    });
  });
}
