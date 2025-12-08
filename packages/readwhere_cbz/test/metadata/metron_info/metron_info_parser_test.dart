import 'package:readwhere_cbz/src/errors/cbz_exception.dart';
import 'package:readwhere_cbz/src/metadata/age_rating.dart';
import 'package:readwhere_cbz/src/metadata/metron_info/metron_info_parser.dart';
import 'package:readwhere_cbz/src/metadata/metron_info/metron_models.dart';
import 'package:test/test.dart';

void main() {
  group('MetronInfoParser', () {
    test('parses minimal MetronInfo.xml', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <Series>
    <Name>Test Series</Name>
  </Series>
</MetronInfo>''';

      final info = MetronInfoParser.parse(xml);
      expect(info.series?.name, equals('Test Series'));
    });

    test('parses IDs', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <IDS>
    <ID source="Metron" primary="true">12345</ID>
    <ID source="Comic Vine">67890</ID>
  </IDS>
</MetronInfo>''';

      final info = MetronInfoParser.parse(xml);
      expect(info.ids.length, equals(2));
      expect(info.ids[0].source, equals(MetronIdSource.metron));
      expect(info.ids[0].value, equals('12345'));
      expect(info.ids[0].isPrimary, isTrue);
      expect(info.ids[1].source, equals(MetronIdSource.comicVine));
      expect(info.ids[1].isPrimary, isFalse);
      expect(info.primaryId?.value, equals('12345'));
    });

    test('parses publisher information', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <Publisher id="1">
    <Name>DC Comics</Name>
    <Imprint id="5">Vertigo</Imprint>
  </Publisher>
</MetronInfo>''';

      final info = MetronInfoParser.parse(xml);
      expect(info.publisher?.name, equals('DC Comics'));
      expect(info.publisher?.id, equals(1));
      expect(info.publisher?.imprint, equals('Vertigo'));
      expect(info.publisher?.imprintId, equals(5));
      expect(info.publisherName, equals('DC Comics'));
    });

    test('parses series information', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <Series lang="eng" id="100">
    <Name>Batman</Name>
    <SortName>Batman</SortName>
    <Volume>2</Volume>
    <IssueCount>52</IssueCount>
    <VolumeCount>3</VolumeCount>
    <Format>Single Issue</Format>
    <StartYear>2011</StartYear>
    <AlternativeNames>
      <AlternativeName>The Batman</AlternativeName>
      <AlternativeName>Batman (2011)</AlternativeName>
    </AlternativeNames>
  </Series>
</MetronInfo>''';

      final info = MetronInfoParser.parse(xml);
      expect(info.series?.name, equals('Batman'));
      expect(info.series?.sortName, equals('Batman'));
      expect(info.series?.volume, equals(2));
      expect(info.series?.issueCount, equals(52));
      expect(info.series?.volumeCount, equals(3));
      expect(info.series?.format, equals(SeriesFormat.singleIssue));
      expect(info.series?.startYear, equals(2011));
      expect(info.series?.language, equals('eng'));
      expect(info.series?.id, equals(100));
      expect(info.series?.alternativeNames, hasLength(2));
      expect(info.series?.alternativeNames[0], equals('The Batman'));
    });

    test('parses issue details', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <Series>
    <Name>Batman</Name>
  </Series>
  <MangaVolume>5</MangaVolume>
  <CollectionTitle>Batman: Year One</CollectionTitle>
  <Number>404</Number>
  <Stories>
    <Story>Year One, Part 1</Story>
    <Story>Year One, Part 2</Story>
  </Stories>
  <Summary>The origin of Batman.</Summary>
  <PageCount>128</PageCount>
  <Notes>First printing</Notes>
</MetronInfo>''';

      final info = MetronInfoParser.parse(xml);
      expect(info.mangaVolume, equals(5));
      expect(info.collectionTitle, equals('Batman: Year One'));
      expect(info.number, equals('404'));
      expect(info.stories.length, equals(2));
      expect(info.stories[0].title, equals('Year One, Part 1'));
      expect(info.summary, equals('The origin of Batman.'));
      expect(info.pageCount, equals(128));
      expect(info.notes, equals('First printing'));
      expect(info.title, equals('Batman: Year One'));
    });

    test('parses prices', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <Prices>
    <Price country="US">3.99</Price>
    <Price country="CA">4.99</Price>
  </Prices>
</MetronInfo>''';

      final info = MetronInfoParser.parse(xml);
      expect(info.prices.length, equals(2));
      expect(info.prices[0].value, equals(3.99));
      expect(info.prices[0].country, equals('US'));
      expect(info.prices[1].value, equals(4.99));
      expect(info.prices[1].country, equals('CA'));
    });

    test('parses dates', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <CoverDate>1987-02-01</CoverDate>
  <StoreDate>1987-01-15</StoreDate>
  <LastModified>2023-12-01T10:30:00</LastModified>
</MetronInfo>''';

      final info = MetronInfoParser.parse(xml);
      expect(info.coverDate, equals(DateTime(1987, 2, 1)));
      expect(info.storeDate, equals(DateTime(1987, 1, 15)));
      expect(info.releaseDate,
          equals(DateTime(1987, 1, 15))); // Prefers store date
      expect(info.lastModified?.year, equals(2023));
    });

    test('parses genres and tags', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <Genres>
    <Genre>Superhero</Genre>
    <Genre>Crime</Genre>
    <Genre>Noir</Genre>
  </Genres>
  <Tags>
    <Tag>batman</Tag>
    <Tag>origin</Tag>
    <Tag>year one</Tag>
  </Tags>
</MetronInfo>''';

      final info = MetronInfoParser.parse(xml);
      expect(info.genres, equals(['Superhero', 'Crime', 'Noir']));
      expect(info.tags, equals(['batman', 'origin', 'year one']));
    });

    test('parses age rating', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <AgeRating>Teen Plus</AgeRating>
</MetronInfo>''';

      final info = MetronInfoParser.parse(xml);
      expect(info.ageRating, equals(AgeRating.teenPlus));
    });

    test('parses story arcs', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <Arcs>
    <Arc id="50">
      <Name>Batman: Year One</Name>
      <Number>1</Number>
    </Arc>
    <Arc>
      <Name>Dark Knight Saga</Name>
      <Number>2</Number>
    </Arc>
  </Arcs>
</MetronInfo>''';

      final info = MetronInfoParser.parse(xml);
      expect(info.arcs.length, equals(2));
      expect(info.arcs[0].name, equals('Batman: Year One'));
      expect(info.arcs[0].number, equals(1));
      expect(info.arcs[0].id, equals(50));
      expect(info.storyArc, equals('Batman: Year One'));
    });

    test('parses characters, teams, and locations', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <Characters>
    <Character id="1">Batman</Character>
    <Character id="2">James Gordon</Character>
    <Character>Carmine Falcone</Character>
  </Characters>
  <Teams>
    <Team id="10">Justice League</Team>
  </Teams>
  <Locations>
    <Location>Gotham City</Location>
    <Location>Wayne Manor</Location>
  </Locations>
</MetronInfo>''';

      final info = MetronInfoParser.parse(xml);
      expect(info.characters.length, equals(3));
      expect(info.characters[0].name, equals('Batman'));
      expect(info.characters[0].id, equals(1));
      expect(info.characterNames,
          equals(['Batman', 'James Gordon', 'Carmine Falcone']));

      expect(info.teams.length, equals(1));
      expect(info.teams[0].name, equals('Justice League'));
      expect(info.teamNames, equals(['Justice League']));

      expect(info.locations.length, equals(2));
      expect(info.locationNames, equals(['Gotham City', 'Wayne Manor']));
    });

    test('parses universes', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <Universes>
    <Universe id="1">
      <Name>DC Universe</Name>
      <Designation>Earth-0</Designation>
    </Universe>
  </Universes>
</MetronInfo>''';

      final info = MetronInfoParser.parse(xml);
      expect(info.universes.length, equals(1));
      expect(info.universes[0].name, equals('DC Universe'));
      expect(info.universes[0].designation, equals('Earth-0'));
      expect(info.universes[0].id, equals(1));
    });

    test('parses GTIN', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <GTIN>
    <ISBN>978-1401207526</ISBN>
    <UPC>725274329901</UPC>
  </GTIN>
</MetronInfo>''';

      final info = MetronInfoParser.parse(xml);
      expect(info.gtin?.isbn, equals('978-1401207526'));
      expect(info.gtin?.upc, equals('725274329901'));
      expect(info.isbn, equals('978-1401207526'));
      expect(info.upc, equals('725274329901'));
    });

    test('parses URLs', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <URLs>
    <URL primary="true">https://metron.cloud/issue/12345</URL>
    <URL>https://comicvine.com/issue/67890</URL>
  </URLs>
</MetronInfo>''';

      final info = MetronInfoParser.parse(xml);
      expect(info.urls.length, equals(2));
      expect(info.urls[0].url, equals('https://metron.cloud/issue/12345'));
      expect(info.urls[0].isPrimary, isTrue);
      expect(info.primaryUrl, equals('https://metron.cloud/issue/12345'));
    });

    test('parses credits with roles', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <Credits>
    <Credit>
      <Creator id="100">Frank Miller</Creator>
      <Roles>
        <Role>Writer</Role>
        <Role>Penciller</Role>
      </Roles>
    </Credit>
    <Credit>
      <Creator id="101">David Mazzucchelli</Creator>
      <Roles>
        <Role>Artist</Role>
      </Roles>
    </Credit>
    <Credit>
      <Creator>Richmond Lewis</Creator>
      <Roles>
        <Role>Colorist</Role>
      </Roles>
    </Credit>
  </Credits>
</MetronInfo>''';

      final info = MetronInfoParser.parse(xml);
      expect(info.credits.length, equals(3));

      final miller = info.credits[0];
      expect(miller.name, equals('Frank Miller'));
      expect(miller.id, equals(100));
      expect(miller.roles, contains(MetronCreatorRole.writer));
      expect(miller.roles, contains(MetronCreatorRole.penciller));

      expect(info.writers.length, equals(1));
      expect(info.pencillers.length, equals(1));
      expect(info.artists.length,
          equals(2)); // Miller (penciller) + Mazzucchelli (artist)
      expect(info.colorists.length, equals(1));

      expect(info.author, equals('Frank Miller'));
    });

    test('parses pages', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <Pages>
    <Page Image="0" Type="FrontCover" ImageWidth="1200" ImageHeight="1800" ImageSize="512000" />
    <Page Image="1" Type="Story" DoublePage="false" />
    <Page Image="2" Type="Story" DoublePage="true" />
    <Page Image="9" Type="BackCover" />
  </Pages>
</MetronInfo>''';

      final info = MetronInfoParser.parse(xml);
      expect(info.pages.length, equals(4));

      expect(info.pages[0].index, equals(0));
      expect(info.pages[0].type, equals('FrontCover'));
      expect(info.pages[0].imageWidth, equals(1200));
      expect(info.pages[0].imageHeight, equals(1800));
      expect(info.pages[0].imageSize, equals(512000));

      expect(info.pages[2].doublePage, isTrue);
      expect(info.pages[3].index, equals(9));
    });

    test('handles empty/missing elements gracefully', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <Series>
    <Name></Name>
  </Series>
  <Genres></Genres>
  <Credits></Credits>
</MetronInfo>''';

      final info = MetronInfoParser.parse(xml);
      expect(info.series, isNull); // Empty name means no series
      expect(info.genres, isEmpty);
      expect(info.credits, isEmpty);
    });

    test('throws CbzParseException for invalid root element', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<WrongRoot>
  <Series>
    <Name>Test</Name>
  </Series>
</WrongRoot>''';

      expect(
        () => MetronInfoParser.parse(xml),
        throwsA(isA<CbzParseException>()),
      );
    });

    test('throws CbzParseException for malformed XML', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <Series>
    <Name>Unclosed tag
</MetronInfo>''';

      expect(
        () => MetronInfoParser.parse(xml),
        throwsA(isA<CbzParseException>()),
      );
    });

    group('convenience properties', () {
      test('title falls back to series name', () {
        const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <Series>
    <Name>Batman</Name>
  </Series>
</MetronInfo>''';

        final info = MetronInfoParser.parse(xml);
        expect(info.title, equals('Batman'));
      });

      test('releaseDate falls back to coverDate', () {
        const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <CoverDate>1987-02-01</CoverDate>
</MetronInfo>''';

        final info = MetronInfoParser.parse(xml);
        expect(info.releaseDate, equals(DateTime(1987, 2, 1)));
      });

      test('allCreators returns creators with mapped roles', () {
        const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <Credits>
    <Credit>
      <Creator>Frank Miller</Creator>
      <Roles>
        <Role>Writer</Role>
        <Role>Penciller</Role>
      </Roles>
    </Credit>
  </Credits>
</MetronInfo>''';

        final info = MetronInfoParser.parse(xml);
        final creators = info.allCreators;
        expect(creators.length, equals(2)); // One for each role
        expect(creators[0].name, equals('Frank Miller'));
      });

      test('isManga returns true for manga volumes', () {
        const xml = '''<?xml version="1.0" encoding="utf-8"?>
<MetronInfo>
  <MangaVolume>5</MangaVolume>
</MetronInfo>''';

        final info = MetronInfoParser.parse(xml);
        expect(info.isManga, isTrue);
      });
    });
  });

  group('MetronIdSource', () {
    test('parse handles various formats', () {
      expect(MetronIdSource.parse('Metron'), equals(MetronIdSource.metron));
      expect(
          MetronIdSource.parse('Comic Vine'), equals(MetronIdSource.comicVine));
      expect(
          MetronIdSource.parse('comicvine'), equals(MetronIdSource.comicVine));
      expect(MetronIdSource.parse('MyAnimeList'),
          equals(MetronIdSource.myAnimeList));
      expect(MetronIdSource.parse('unknown'), isNull);
    });
  });

  group('SeriesFormat', () {
    test('parse handles various formats', () {
      expect(
          SeriesFormat.parse('Single Issue'), equals(SeriesFormat.singleIssue));
      expect(
          SeriesFormat.parse('singleissue'), equals(SeriesFormat.singleIssue));
      expect(SeriesFormat.parse('Trade Paperback'),
          equals(SeriesFormat.tradePaperback));
      expect(SeriesFormat.parse('One-Shot'), equals(SeriesFormat.oneShot));
      expect(SeriesFormat.parse('unknown'), isNull);
    });
  });

  group('MetronCreatorRole', () {
    test('parse handles various formats', () {
      expect(
          MetronCreatorRole.parse('Writer'), equals(MetronCreatorRole.writer));
      expect(
          MetronCreatorRole.parse('writer'), equals(MetronCreatorRole.writer));
      expect(MetronCreatorRole.parse('Penciller'),
          equals(MetronCreatorRole.penciller));
      expect(MetronCreatorRole.parse('Cover'), equals(MetronCreatorRole.cover));
      expect(MetronCreatorRole.parse('Editor In Chief'),
          equals(MetronCreatorRole.editorInChief));
      expect(MetronCreatorRole.parse('unknown'), isNull);
    });
  });
}
