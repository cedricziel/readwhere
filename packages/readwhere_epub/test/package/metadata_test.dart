import 'package:test/test.dart';
import 'package:readwhere_epub/src/errors/epub_exception.dart';
import 'package:readwhere_epub/src/package/metadata/metadata.dart';

void main() {
  group('EpubCreator', () {
    group('constructor', () {
      test('creates with required name', () {
        const creator = EpubCreator(name: 'John Doe');

        expect(creator.name, equals('John Doe'));
        expect(creator.fileAs, isNull);
        expect(creator.role, isNull);
        expect(creator.id, isNull);
      });

      test('creates with all parameters', () {
        const creator = EpubCreator(
          name: 'John Doe',
          fileAs: 'Doe, John',
          role: 'aut',
          id: 'creator-1',
        );

        expect(creator.name, equals('John Doe'));
        expect(creator.fileAs, equals('Doe, John'));
        expect(creator.role, equals('aut'));
        expect(creator.id, equals('creator-1'));
      });
    });

    group('roleEnum', () {
      test('returns CreatorRole for valid role code', () {
        const creator = EpubCreator(name: 'John Doe', role: 'aut');
        expect(creator.roleEnum, equals(CreatorRole.author));
      });

      test('returns null for null role', () {
        const creator = EpubCreator(name: 'John Doe');
        expect(creator.roleEnum, isNull);
      });

      test('returns null for unrecognized role', () {
        const creator = EpubCreator(name: 'John Doe', role: 'xyz');
        expect(creator.roleEnum, isNull);
      });
    });

    group('toString', () {
      test('returns name', () {
        const creator = EpubCreator(name: 'John Doe');
        expect(creator.toString(), equals('John Doe'));
      });
    });

    group('Equatable', () {
      test('equal creators are equal', () {
        const c1 = EpubCreator(name: 'John', role: 'aut');
        const c2 = EpubCreator(name: 'John', role: 'aut');
        expect(c1, equals(c2));
        expect(c1.hashCode, equals(c2.hashCode));
      });

      test('different creators are not equal', () {
        const c1 = EpubCreator(name: 'John');
        const c2 = EpubCreator(name: 'Jane');
        expect(c1, isNot(equals(c2)));
      });
    });
  });

  group('CreatorRole', () {
    test('has all expected values', () {
      expect(CreatorRole.values, contains(CreatorRole.author));
      expect(CreatorRole.values, contains(CreatorRole.editor));
      expect(CreatorRole.values, contains(CreatorRole.illustrator));
      expect(CreatorRole.values, contains(CreatorRole.translator));
      expect(CreatorRole.values, contains(CreatorRole.narrator));
      expect(CreatorRole.values, contains(CreatorRole.publisher));
      expect(CreatorRole.values, contains(CreatorRole.contributor));
      expect(CreatorRole.values, contains(CreatorRole.adapter));
      expect(CreatorRole.values, contains(CreatorRole.artist));
      expect(CreatorRole.values, contains(CreatorRole.composer));
      expect(CreatorRole.values, contains(CreatorRole.compiler));
      expect(CreatorRole.values, contains(CreatorRole.designer));
      expect(CreatorRole.values, contains(CreatorRole.photographer));
      expect(CreatorRole.values, contains(CreatorRole.other));
    });

    test('has correct MARC codes', () {
      expect(CreatorRole.author.code, equals('aut'));
      expect(CreatorRole.editor.code, equals('edt'));
      expect(CreatorRole.illustrator.code, equals('ill'));
      expect(CreatorRole.translator.code, equals('trl'));
      expect(CreatorRole.narrator.code, equals('nrt'));
    });

    group('fromCode', () {
      test('returns role for valid code', () {
        expect(CreatorRole.fromCode('aut'), equals(CreatorRole.author));
        expect(CreatorRole.fromCode('edt'), equals(CreatorRole.editor));
        expect(CreatorRole.fromCode('ill'), equals(CreatorRole.illustrator));
      });

      test('returns null for null code', () {
        expect(CreatorRole.fromCode(null), isNull);
      });

      test('returns null for unrecognized code', () {
        expect(CreatorRole.fromCode('xyz'), isNull);
      });

      test('is case insensitive', () {
        expect(CreatorRole.fromCode('AUT'), equals(CreatorRole.author));
        expect(CreatorRole.fromCode('Aut'), equals(CreatorRole.author));
      });
    });
  });

  group('EpubIdentifier', () {
    group('constructor', () {
      test('creates with required value', () {
        const id = EpubIdentifier(value: 'urn:uuid:12345');

        expect(id.value, equals('urn:uuid:12345'));
        expect(id.scheme, isNull);
        expect(id.isPrimary, isFalse);
        expect(id.id, isNull);
      });

      test('creates with all parameters', () {
        const id = EpubIdentifier(
          value: '978-0-13-468599-1',
          scheme: 'ISBN',
          isPrimary: true,
          id: 'pub-id',
        );

        expect(id.value, equals('978-0-13-468599-1'));
        expect(id.scheme, equals('ISBN'));
        expect(id.isPrimary, isTrue);
        expect(id.id, equals('pub-id'));
      });
    });

    group('toString', () {
      test('returns scheme: value when scheme present', () {
        const id = EpubIdentifier(value: '978-0-13-468599-1', scheme: 'ISBN');
        expect(id.toString(), equals('ISBN: 978-0-13-468599-1'));
      });

      test('returns value only when no scheme', () {
        const id = EpubIdentifier(value: 'urn:uuid:12345');
        expect(id.toString(), equals('urn:uuid:12345'));
      });
    });

    group('Equatable', () {
      test('equal identifiers are equal', () {
        const id1 = EpubIdentifier(value: '123', scheme: 'ISBN');
        const id2 = EpubIdentifier(value: '123', scheme: 'ISBN');
        expect(id1, equals(id2));
        expect(id1.hashCode, equals(id2.hashCode));
      });

      test('different identifiers are not equal', () {
        const id1 = EpubIdentifier(value: '123');
        const id2 = EpubIdentifier(value: '456');
        expect(id1, isNot(equals(id2)));
      });

      test('different isPrimary values are not equal', () {
        const id1 = EpubIdentifier(value: '123', isPrimary: true);
        const id2 = EpubIdentifier(value: '123', isPrimary: false);
        expect(id1, isNot(equals(id2)));
      });
    });
  });

  group('EpubTitle', () {
    group('constructor', () {
      test('creates with required value', () {
        const title = EpubTitle(value: 'My Book');

        expect(title.value, equals('My Book'));
        expect(title.type, isNull);
        expect(title.language, isNull);
        expect(title.displaySeq, isNull);
        expect(title.id, isNull);
      });

      test('creates with all parameters', () {
        const title = EpubTitle(
          value: 'My Book',
          type: TitleType.main,
          language: 'en',
          displaySeq: 1,
          id: 'title-1',
        );

        expect(title.value, equals('My Book'));
        expect(title.type, equals(TitleType.main));
        expect(title.language, equals('en'));
        expect(title.displaySeq, equals(1));
        expect(title.id, equals('title-1'));
      });
    });

    group('toString', () {
      test('returns value', () {
        const title = EpubTitle(value: 'My Book');
        expect(title.toString(), equals('My Book'));
      });
    });

    group('Equatable', () {
      test('equal titles are equal', () {
        const t1 = EpubTitle(value: 'Book', type: TitleType.main);
        const t2 = EpubTitle(value: 'Book', type: TitleType.main);
        expect(t1, equals(t2));
        expect(t1.hashCode, equals(t2.hashCode));
      });

      test('different titles are not equal', () {
        const t1 = EpubTitle(value: 'Book 1');
        const t2 = EpubTitle(value: 'Book 2');
        expect(t1, isNot(equals(t2)));
      });
    });
  });

  group('TitleType', () {
    test('has all expected values', () {
      expect(TitleType.values, contains(TitleType.main));
      expect(TitleType.values, contains(TitleType.subtitle));
      expect(TitleType.values, contains(TitleType.short));
      expect(TitleType.values, contains(TitleType.collection));
      expect(TitleType.values, contains(TitleType.edition));
      expect(TitleType.values, contains(TitleType.expanded));
    });

    group('fromString', () {
      test('parses valid type strings', () {
        expect(TitleType.fromString('main'), equals(TitleType.main));
        expect(TitleType.fromString('subtitle'), equals(TitleType.subtitle));
        expect(TitleType.fromString('short'), equals(TitleType.short));
        expect(
            TitleType.fromString('collection'), equals(TitleType.collection));
      });

      test('returns null for null input', () {
        expect(TitleType.fromString(null), isNull);
      });

      test('returns null for unrecognized type', () {
        expect(TitleType.fromString('unknown'), isNull);
      });

      test('is case insensitive', () {
        expect(TitleType.fromString('MAIN'), equals(TitleType.main));
        expect(TitleType.fromString('Main'), equals(TitleType.main));
      });
    });
  });

  group('EpubMetadata', () {
    group('constructor', () {
      test('creates with required fields', () {
        const metadata = EpubMetadata(
          identifier: 'urn:uuid:12345',
          title: 'My Book',
          language: 'en',
        );

        expect(metadata.identifier, equals('urn:uuid:12345'));
        expect(metadata.title, equals('My Book'));
        expect(metadata.language, equals('en'));
        expect(metadata.creators, isEmpty);
        expect(metadata.contributors, isEmpty);
        expect(metadata.publisher, isNull);
        expect(metadata.subjects, isEmpty);
        expect(metadata.version, equals(EpubVersion.epub33));
      });

      test('creates with all fields', () {
        final date = DateTime(2024, 1, 15);
        final modified = DateTime(2024, 6, 1);
        final metadata = EpubMetadata(
          identifier: 'urn:uuid:12345',
          title: 'My Book',
          language: 'en',
          creators: const [EpubCreator(name: 'John Doe', role: 'aut')],
          contributors: const [EpubCreator(name: 'Jane Editor', role: 'edt')],
          publisher: 'Example Press',
          description: 'A test book',
          subjects: const ['Fiction', 'Adventure'],
          date: date,
          rights: 'Copyright 2024',
          source: 'Original Source',
          type: 'Text',
          format: 'application/epub+zip',
          relations: const ['Related Work'],
          coverage: '21st Century',
          modified: modified,
          coverImageId: 'cover-image',
          identifiers: const [
            EpubIdentifier(value: '978-0-13-468599-1', scheme: 'ISBN'),
          ],
          titles: const [
            EpubTitle(value: 'My Book', type: TitleType.main),
            EpubTitle(value: 'A Subtitle', type: TitleType.subtitle),
          ],
          meta: const {'calibre:series': 'My Series'},
          version: EpubVersion.epub30,
        );

        expect(metadata.creators, hasLength(1));
        expect(metadata.contributors, hasLength(1));
        expect(metadata.publisher, equals('Example Press'));
        expect(metadata.description, equals('A test book'));
        expect(metadata.subjects, hasLength(2));
        expect(metadata.date, equals(date));
        expect(metadata.rights, equals('Copyright 2024'));
        expect(metadata.modified, equals(modified));
        expect(metadata.coverImageId, equals('cover-image'));
        expect(metadata.identifiers, hasLength(1));
        expect(metadata.titles, hasLength(2));
        expect(metadata.meta, hasLength(1));
        expect(metadata.version, equals(EpubVersion.epub30));
      });
    });

    group('author', () {
      test('returns first author name', () {
        const metadata = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
          creators: [
            EpubCreator(name: 'John Doe', role: 'aut'),
            EpubCreator(name: 'Jane Doe', role: 'aut'),
          ],
        );

        expect(metadata.author, equals('John Doe'));
      });

      test('returns creator with null role as author', () {
        const metadata = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
          creators: [EpubCreator(name: 'John Doe')],
        );

        expect(metadata.author, equals('John Doe'));
      });

      test('returns null when no authors', () {
        const metadata = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
          creators: [EpubCreator(name: 'Editor', role: 'edt')],
        );

        expect(metadata.author, isNull);
      });

      test('returns null for empty creators', () {
        const metadata = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
        );

        expect(metadata.author, isNull);
      });
    });

    group('authors', () {
      test('returns all author names', () {
        const metadata = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
          creators: [
            EpubCreator(name: 'John Doe', role: 'aut'),
            EpubCreator(name: 'Jane Doe', role: 'aut'),
            EpubCreator(name: 'Editor', role: 'edt'),
          ],
        );

        expect(metadata.authors, hasLength(2));
        expect(metadata.authors, contains('John Doe'));
        expect(metadata.authors, contains('Jane Doe'));
        expect(metadata.authors, isNot(contains('Editor')));
      });

      test('includes creators with null role', () {
        const metadata = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
          creators: [
            EpubCreator(name: 'John Doe'),
            EpubCreator(name: 'Editor', role: 'edt'),
          ],
        );

        expect(metadata.authors, hasLength(1));
        expect(metadata.authors, contains('John Doe'));
      });

      test('returns empty list when no authors', () {
        const metadata = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
        );

        expect(metadata.authors, isEmpty);
      });
    });

    group('creatorNames', () {
      test('returns all creator names regardless of role', () {
        const metadata = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
          creators: [
            EpubCreator(name: 'Author', role: 'aut'),
            EpubCreator(name: 'Editor', role: 'edt'),
          ],
        );

        expect(metadata.creatorNames, hasLength(2));
        expect(metadata.creatorNames, contains('Author'));
        expect(metadata.creatorNames, contains('Editor'));
      });
    });

    group('contributorNames', () {
      test('returns all contributor names', () {
        const metadata = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
          contributors: [
            EpubCreator(name: 'Contributor 1'),
            EpubCreator(name: 'Contributor 2'),
          ],
        );

        expect(metadata.contributorNames, hasLength(2));
      });
    });

    group('mainTitle', () {
      test('returns title with type=main', () {
        const metadata = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
          titles: [
            EpubTitle(value: 'Subtitle', type: TitleType.subtitle),
            EpubTitle(value: 'Main Title', type: TitleType.main),
          ],
        );

        expect(metadata.mainTitle?.value, equals('Main Title'));
      });

      test('returns first title when no main type', () {
        const metadata = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
          titles: [
            EpubTitle(value: 'First Title'),
            EpubTitle(value: 'Second Title'),
          ],
        );

        expect(metadata.mainTitle?.value, equals('First Title'));
      });

      test('returns null when no titles', () {
        const metadata = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
        );

        expect(metadata.mainTitle, isNull);
      });
    });

    group('subtitle', () {
      test('returns title with type=subtitle', () {
        const metadata = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
          titles: [
            EpubTitle(value: 'Main Title', type: TitleType.main),
            EpubTitle(value: 'The Subtitle', type: TitleType.subtitle),
          ],
        );

        expect(metadata.subtitle?.value, equals('The Subtitle'));
      });

      test('returns null when no subtitle', () {
        const metadata = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
          titles: [EpubTitle(value: 'Main Title', type: TitleType.main)],
        );

        expect(metadata.subtitle, isNull);
      });
    });

    group('getMeta', () {
      test('returns meta value for existing key', () {
        const metadata = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
          meta: {'calibre:series': 'My Series', 'calibre:series_index': '1'},
        );

        expect(metadata.getMeta('calibre:series'), equals('My Series'));
        expect(metadata.getMeta('calibre:series_index'), equals('1'));
      });

      test('returns null for non-existing key', () {
        const metadata = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
        );

        expect(metadata.getMeta('nonexistent'), isNull);
      });
    });

    group('isEpub3', () {
      test('returns true for EPUB 3.x versions', () {
        const metadata30 = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
          version: EpubVersion.epub30,
        );
        const metadata33 = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
          version: EpubVersion.epub33,
        );

        expect(metadata30.isEpub3, isTrue);
        expect(metadata33.isEpub3, isTrue);
      });

      test('returns false for EPUB 2.x', () {
        const metadata = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
          version: EpubVersion.epub2,
        );

        expect(metadata.isEpub3, isFalse);
      });
    });

    group('isEpub2', () {
      test('returns true for EPUB 2.x', () {
        const metadata = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
          version: EpubVersion.epub2,
        );

        expect(metadata.isEpub2, isTrue);
      });

      test('returns false for EPUB 3.x', () {
        const metadata = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
          version: EpubVersion.epub33,
        );

        expect(metadata.isEpub2, isFalse);
      });
    });

    group('copyWith', () {
      test('copies with modified fields', () {
        const original = EpubMetadata(
          identifier: 'id',
          title: 'Original Title',
          language: 'en',
          publisher: 'Publisher A',
        );

        final copy = original.copyWith(
          title: 'New Title',
          description: 'New Description',
        );

        expect(copy.identifier, equals('id'));
        expect(copy.title, equals('New Title'));
        expect(copy.language, equals('en'));
        expect(copy.publisher, equals('Publisher A'));
        expect(copy.description, equals('New Description'));
      });

      test('preserves original when no changes', () {
        const original = EpubMetadata(
          identifier: 'id',
          title: 'Title',
          language: 'en',
          creators: [EpubCreator(name: 'Author')],
        );

        final copy = original.copyWith();

        expect(copy, equals(original));
      });

      test('allows updating all fields', () {
        const original = EpubMetadata(
          identifier: 'id',
          title: 'Title',
          language: 'en',
        );

        final modified = DateTime(2024, 6, 1);
        final copy = original.copyWith(
          identifier: 'new-id',
          title: 'New Title',
          language: 'de',
          publisher: 'New Publisher',
          description: 'New Description',
          subjects: ['Subject'],
          rights: 'New Rights',
          modified: modified,
          coverImageId: 'new-cover',
          version: EpubVersion.epub30,
        );

        expect(copy.identifier, equals('new-id'));
        expect(copy.title, equals('New Title'));
        expect(copy.language, equals('de'));
        expect(copy.publisher, equals('New Publisher'));
        expect(copy.description, equals('New Description'));
        expect(copy.subjects, equals(['Subject']));
        expect(copy.rights, equals('New Rights'));
        expect(copy.modified, equals(modified));
        expect(copy.coverImageId, equals('new-cover'));
        expect(copy.version, equals(EpubVersion.epub30));
      });
    });

    group('Equatable', () {
      test('equal metadata are equal', () {
        const m1 = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
        );
        const m2 = EpubMetadata(
          identifier: 'id',
          title: 'Book',
          language: 'en',
        );

        expect(m1, equals(m2));
        expect(m1.hashCode, equals(m2.hashCode));
      });

      test('different metadata are not equal', () {
        const m1 = EpubMetadata(
          identifier: 'id1',
          title: 'Book',
          language: 'en',
        );
        const m2 = EpubMetadata(
          identifier: 'id2',
          title: 'Book',
          language: 'en',
        );

        expect(m1, isNot(equals(m2)));
      });
    });
  });
}
