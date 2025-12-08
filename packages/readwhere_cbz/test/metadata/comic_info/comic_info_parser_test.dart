import 'package:readwhere_cbz/src/errors/cbz_exception.dart';
import 'package:readwhere_cbz/src/metadata/age_rating.dart';
import 'package:readwhere_cbz/src/metadata/comic_info/comic_info_parser.dart';
import 'package:readwhere_cbz/src/metadata/reading_direction.dart';
import 'package:readwhere_cbz/src/pages/comic_page.dart';
import 'package:test/test.dart';

void main() {
  group('ComicInfoParser', () {
    test('parses minimal ComicInfo.xml', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <Title>Test Comic</Title>
</ComicInfo>''';

      final info = ComicInfoParser.parse(xml);
      expect(info.title, equals('Test Comic'));
    });

    test('parses bibliographic information', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <Title>Batman: Year One</Title>
  <Series>Batman</Series>
  <Number>404</Number>
  <Count>12</Count>
  <Volume>1</Volume>
  <AlternateSeries>Dark Knight Saga</AlternateSeries>
  <AlternateNumber>1</AlternateNumber>
  <AlternateCount>4</AlternateCount>
  <Summary>An origin story for Batman.</Summary>
  <Notes>First print edition</Notes>
</ComicInfo>''';

      final info = ComicInfoParser.parse(xml);
      expect(info.title, equals('Batman: Year One'));
      expect(info.series, equals('Batman'));
      expect(info.number, equals('404'));
      expect(info.count, equals(12));
      expect(info.volume, equals(1));
      expect(info.alternateSeries, equals('Dark Knight Saga'));
      expect(info.alternateNumber, equals('1'));
      expect(info.alternateCount, equals(4));
      expect(info.summary, equals('An origin story for Batman.'));
      expect(info.notes, equals('First print edition'));
    });

    test('parses dates', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <Year>1987</Year>
  <Month>2</Month>
  <Day>15</Day>
</ComicInfo>''';

      final info = ComicInfoParser.parse(xml);
      expect(info.year, equals(1987));
      expect(info.month, equals(2));
      expect(info.day, equals(15));
      expect(info.releaseDate, equals(DateTime(1987, 2, 15)));
    });

    test('parses comma-separated creators', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <Writer>Frank Miller, Brian Azzarello</Writer>
  <Penciller>David Mazzucchelli</Penciller>
  <Inker>Richmond Lewis</Inker>
  <Colorist>Richmond Lewis</Colorist>
  <Letterer>Todd Klein</Letterer>
  <CoverArtist>David Mazzucchelli, Frank Miller</CoverArtist>
  <Editor>Dennis O'Neil</Editor>
  <Translator>John Doe</Translator>
</ComicInfo>''';

      final info = ComicInfoParser.parse(xml);
      expect(info.writers, equals(['Frank Miller', 'Brian Azzarello']));
      expect(info.pencillers, equals(['David Mazzucchelli']));
      expect(info.inkers, equals(['Richmond Lewis']));
      expect(info.colorists, equals(['Richmond Lewis']));
      expect(info.letterers, equals(['Todd Klein']));
      expect(info.coverArtists, equals(['David Mazzucchelli', 'Frank Miller']));
      expect(info.editors, equals(["Dennis O'Neil"]));
      expect(info.translators, equals(['John Doe']));
    });

    test('parses publication information', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <Publisher>DC Comics</Publisher>
  <Imprint>Vertigo</Imprint>
  <Genre>Superhero, Crime, Noir</Genre>
  <Tags>batman, origin, year one</Tags>
  <Web>https://dc.com/batman</Web>
  <LanguageISO>en-US</LanguageISO>
  <Format>TBP</Format>
  <GTIN>978-1401207526</GTIN>
</ComicInfo>''';

      final info = ComicInfoParser.parse(xml);
      expect(info.publisher, equals('DC Comics'));
      expect(info.imprint, equals('Vertigo'));
      expect(info.genres, equals(['Superhero', 'Crime', 'Noir']));
      expect(info.tags, equals(['batman', 'origin', 'year one']));
      expect(info.web, equals('https://dc.com/batman'));
      expect(info.languageISO, equals('en-US'));
      expect(info.format, equals('TBP'));
      expect(info.gtin, equals('978-1401207526'));
    });

    test('parses manga settings', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <Manga>YesAndRightToLeft</Manga>
</ComicInfo>''';

      final info = ComicInfoParser.parse(xml);
      expect(info.manga, equals(MangaType.yesAndRightToLeft));
      expect(info.isManga, isTrue);
      expect(info.readingDirection, equals(ReadingDirection.rightToLeft));
    });

    test('parses reading information', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <BlackAndWhite>Yes</BlackAndWhite>
  <AgeRating>Mature 17+</AgeRating>
  <CommunityRating>4.5</CommunityRating>
</ComicInfo>''';

      final info = ComicInfoParser.parse(xml);
      expect(info.blackAndWhite, isTrue);
      expect(info.ageRating, equals(AgeRating.mature17));
      expect(info.communityRating, equals(4.5));
    });

    test('parses story information', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <Characters>Batman, James Gordon, Carmine Falcone</Characters>
  <Teams>Justice League</Teams>
  <Locations>Gotham City, Wayne Manor</Locations>
  <MainCharacterOrTeam>Batman</MainCharacterOrTeam>
  <StoryArc>Batman: Year One</StoryArc>
  <StoryArcNumber>1,2,3,4</StoryArcNumber>
  <SeriesGroup>Batman Main Series</SeriesGroup>
</ComicInfo>''';

      final info = ComicInfoParser.parse(xml);
      expect(info.characters,
          equals(['Batman', 'James Gordon', 'Carmine Falcone']));
      expect(info.teams, equals(['Justice League']));
      expect(info.locations, equals(['Gotham City', 'Wayne Manor']));
      expect(info.mainCharacterOrTeam, equals('Batman'));
      expect(info.storyArc, equals('Batman: Year One'));
      expect(info.storyArcNumbers, equals(['1', '2', '3', '4']));
      expect(info.seriesGroups, equals(['Batman Main Series']));
    });

    test('parses scanning information', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <ScanInformation>Scanned by user123 at 300dpi</ScanInformation>
  <Review>Excellent quality scan</Review>
</ComicInfo>''';

      final info = ComicInfoParser.parse(xml);
      expect(info.scanInformation, equals('Scanned by user123 at 300dpi'));
      expect(info.review, equals('Excellent quality scan'));
    });

    test('parses page metadata', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <PageCount>10</PageCount>
  <Pages>
    <Page Image="0" Type="FrontCover" ImageSize="512000" ImageWidth="1200" ImageHeight="1800" />
    <Page Image="1" Type="Story" DoublePage="false" />
    <Page Image="2" Type="Story" DoublePage="true" Bookmark="Chapter 1" />
    <Page Image="9" Type="BackCover" />
  </Pages>
</ComicInfo>''';

      final info = ComicInfoParser.parse(xml);
      expect(info.pageCount, equals(10));
      expect(info.pages.length, equals(4));

      final cover = info.pages[0];
      expect(cover.index, equals(0));
      expect(cover.type, equals(PageType.frontCover));
      expect(cover.imageSize, equals(512000));
      expect(cover.imageWidth, equals(1200));
      expect(cover.imageHeight, equals(1800));

      final page2 = info.pages[2];
      expect(page2.index, equals(2));
      expect(page2.doublePage, isTrue);
      expect(page2.bookmark, equals('Chapter 1'));

      final back = info.pages[3];
      expect(back.index, equals(9));
      expect(back.type, equals(PageType.backCover));
    });

    test('handles empty/missing elements gracefully', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <Title></Title>
  <Writer></Writer>
  <Genre></Genre>
</ComicInfo>''';

      final info = ComicInfoParser.parse(xml);
      expect(info.title, isNull);
      expect(info.writers, isEmpty);
      expect(info.genres, isEmpty);
    });

    test('throws CbzParseException for invalid root element', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<WrongRoot>
  <Title>Test</Title>
</WrongRoot>''';

      expect(
        () => ComicInfoParser.parse(xml),
        throwsA(isA<CbzParseException>()),
      );
    });

    test('throws CbzParseException for malformed XML', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <Title>Unclosed tag
</ComicInfo>''';

      expect(
        () => ComicInfoParser.parse(xml),
        throwsA(isA<CbzParseException>()),
      );
    });

    group('convenience properties', () {
      test('author returns first writer', () {
        const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <Writer>Frank Miller, Brian Azzarello</Writer>
</ComicInfo>''';

        final info = ComicInfoParser.parse(xml);
        expect(info.author, equals('Frank Miller'));
      });

      test('author returns first penciller if no writer', () {
        const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <Penciller>David Mazzucchelli</Penciller>
</ComicInfo>''';

        final info = ComicInfoParser.parse(xml);
        expect(info.author, equals('David Mazzucchelli'));
      });

      test('allCreators returns all creators with roles', () {
        const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <Writer>Frank Miller</Writer>
  <Penciller>David Mazzucchelli</Penciller>
</ComicInfo>''';

        final info = ComicInfoParser.parse(xml);
        final creators = info.allCreators;
        expect(creators.length, equals(2));
        expect(creators[0].name, equals('Frank Miller'));
        expect(creators[1].name, equals('David Mazzucchelli'));
      });

      test('effectivePageCount uses pageCount field', () {
        const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <PageCount>100</PageCount>
  <Pages>
    <Page Image="0" />
    <Page Image="1" />
  </Pages>
</ComicInfo>''';

        final info = ComicInfoParser.parse(xml);
        expect(info.effectivePageCount, equals(100));
        expect(info.pages.length, equals(2));
      });

      test('effectivePageCount falls back to pages.length', () {
        const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <Pages>
    <Page Image="0" />
    <Page Image="1" />
    <Page Image="2" />
  </Pages>
</ComicInfo>''';

        final info = ComicInfoParser.parse(xml);
        expect(info.effectivePageCount, equals(3));
      });
    });
  });
}
