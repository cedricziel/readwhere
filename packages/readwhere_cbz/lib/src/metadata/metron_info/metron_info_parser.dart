import 'package:xml/xml.dart';

import '../../errors/cbz_exception.dart';
import '../age_rating.dart';
import 'metron_info.dart';
import 'metron_models.dart';

/// Parser for MetronInfo.xml files.
class MetronInfoParser {
  MetronInfoParser._();

  /// Parses MetronInfo.xml content into a [MetronInfo] object.
  ///
  /// Throws [CbzParseException] if the XML is malformed.
  static MetronInfo parse(String xmlContent) {
    try {
      final document = XmlDocument.parse(xmlContent);
      final root = document.rootElement;

      if (root.name.local != 'MetronInfo') {
        throw CbzParseException(
          'Invalid root element: expected "MetronInfo", got "${root.name.local}"',
          documentPath: 'MetronInfo.xml',
        );
      }

      return _parseMetronInfo(root);
    } on XmlException catch (e, st) {
      throw CbzParseException(
        'Failed to parse MetronInfo.xml: $e',
        documentPath: 'MetronInfo.xml',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Parses the MetronInfo element.
  static MetronInfo _parseMetronInfo(XmlElement root) {
    return MetronInfo(
      // IDs
      ids: _parseIds(root),

      // Publisher
      publisher: _parsePublisher(root),

      // Series
      series: _parseSeries(root),

      // Issue details
      mangaVolume: _getInt(root, 'MangaVolume'),
      collectionTitle: _getText(root, 'CollectionTitle'),
      number: _getText(root, 'Number'),
      stories: _parseStories(root),
      summary: _getText(root, 'Summary'),
      pageCount: _getInt(root, 'PageCount'),
      notes: _getText(root, 'Notes'),

      // Prices
      prices: _parsePrices(root),

      // Dates
      coverDate: _getDate(root, 'CoverDate'),
      storeDate: _getDate(root, 'StoreDate'),

      // Classification
      genres: _parseGenres(root),
      tags: _parseTags(root),
      ageRating: _getAgeRating(root),

      // Story elements
      arcs: _parseArcs(root),
      characters: _parseResources(root, 'Characters', 'Character'),
      teams: _parseResources(root, 'Teams', 'Team'),
      locations: _parseResources(root, 'Locations', 'Location'),
      universes: _parseUniverses(root),
      reprints: _parseReprints(root),

      // Identifiers
      gtin: _parseGtin(root),

      // URLs
      urls: _parseUrls(root),

      // Credits
      credits: _parseCredits(root),

      // Pages
      pages: _parsePages(root),

      // Administrative
      lastModified: _getDate(root, 'LastModified'),

      // Display
      blackAndWhite: _getBool(root, 'BlackAndWhite'),
    );
  }

  // ============================================================
  // Text/Value extraction helpers
  // ============================================================

  /// Gets text content of a child element.
  static String? _getText(XmlElement parent, String name) {
    final element = parent.getElement(name);
    if (element == null) return null;
    final text = element.innerText.trim();
    return text.isEmpty ? null : text;
  }

  /// Gets integer value of a child element.
  static int? _getInt(XmlElement parent, String name) {
    final text = _getText(parent, name);
    if (text == null) return null;
    return int.tryParse(text);
  }

  /// Gets boolean value of a child element.
  static bool _getBool(XmlElement parent, String name) {
    final text = _getText(parent, name)?.toLowerCase();
    if (text == null) return false;
    return text == 'yes' || text == 'true' || text == '1';
  }

  /// Gets date value of a child element.
  static DateTime? _getDate(XmlElement parent, String name) {
    final text = _getText(parent, name);
    if (text == null) return null;
    return DateTime.tryParse(text);
  }

  /// Gets age rating from the AgeRating element.
  static AgeRating? _getAgeRating(XmlElement parent) {
    final text = _getText(parent, 'AgeRating');
    if (text == null) return null;
    return AgeRating.parse(text);
  }

  // ============================================================
  // Complex element parsing
  // ============================================================

  /// Parses IDs element.
  static List<MetronId> _parseIds(XmlElement root) {
    final idsElement = root.getElement('IDS') ?? root.getElement('Ids');
    if (idsElement == null) return const [];

    final ids = <MetronId>[];
    for (final idElement in idsElement.childElements) {
      if (idElement.name.local != 'ID' && idElement.name.local != 'Id') {
        continue;
      }

      final sourceAttr = idElement.getAttribute('source');
      final source = MetronIdSource.parse(sourceAttr);
      if (source == null) continue;

      final value = idElement.innerText.trim();
      if (value.isEmpty) continue;

      ids.add(MetronId(
        source: source,
        value: value,
        isPrimary: _parseAttrBool(idElement.getAttribute('primary')),
      ));
    }

    return ids;
  }

  /// Parses Publisher element.
  static MetronPublisher? _parsePublisher(XmlElement root) {
    final pubElement = root.getElement('Publisher');
    if (pubElement == null) return null;

    final nameElement = pubElement.getElement('Name');
    if (nameElement == null) return null;

    final name = nameElement.innerText.trim();
    if (name.isEmpty) return null;

    final imprintElement = pubElement.getElement('Imprint');
    String? imprint;
    int? imprintId;
    if (imprintElement != null) {
      imprint = imprintElement.innerText.trim();
      if (imprint.isEmpty) imprint = null;
      imprintId = _parseAttrInt(imprintElement.getAttribute('id'));
    }

    return MetronPublisher(
      name: name,
      id: _parseAttrInt(pubElement.getAttribute('id')),
      imprint: imprint,
      imprintId: imprintId,
    );
  }

  /// Parses Series element.
  static MetronSeries? _parseSeries(XmlElement root) {
    final seriesElement = root.getElement('Series');
    if (seriesElement == null) return null;

    final nameElement = seriesElement.getElement('Name');
    if (nameElement == null) return null;

    final name = nameElement.innerText.trim();
    if (name.isEmpty) return null;

    // Parse alternative names
    final altNamesElement = seriesElement.getElement('AlternativeNames');
    final alternativeNames = <String>[];
    if (altNamesElement != null) {
      for (final altElement in altNamesElement.childElements) {
        if (altElement.name.local == 'AlternativeName' ||
            altElement.name.local == 'Name') {
          final altName = altElement.innerText.trim();
          if (altName.isNotEmpty) {
            alternativeNames.add(altName);
          }
        }
      }
    }

    return MetronSeries(
      name: name,
      sortName: _getText(seriesElement, 'SortName'),
      volume: _getInt(seriesElement, 'Volume'),
      issueCount: _getInt(seriesElement, 'IssueCount'),
      volumeCount: _getInt(seriesElement, 'VolumeCount'),
      format: SeriesFormat.parse(_getText(seriesElement, 'Format')),
      startYear: _getInt(seriesElement, 'StartYear'),
      language: seriesElement.getAttribute('lang'),
      id: _parseAttrInt(seriesElement.getAttribute('id')),
      alternativeNames: alternativeNames,
    );
  }

  /// Parses Stories element.
  static List<MetronStory> _parseStories(XmlElement root) {
    final storiesElement = root.getElement('Stories');
    if (storiesElement == null) return const [];

    final stories = <MetronStory>[];
    for (final storyElement in storiesElement.childElements) {
      if (storyElement.name.local != 'Story') continue;

      final title = storyElement.innerText.trim();
      if (title.isEmpty) continue;

      stories.add(MetronStory(title: title));
    }

    return stories;
  }

  /// Parses Prices element.
  static List<MetronPrice> _parsePrices(XmlElement root) {
    final pricesElement = root.getElement('Prices');
    if (pricesElement == null) return const [];

    final prices = <MetronPrice>[];
    for (final priceElement in pricesElement.childElements) {
      if (priceElement.name.local != 'Price') continue;

      final country = priceElement.getAttribute('country');
      if (country == null || country.isEmpty) continue;

      final value = double.tryParse(priceElement.innerText.trim());
      if (value == null) continue;

      prices.add(MetronPrice(value: value, country: country));
    }

    return prices;
  }

  /// Parses Genres element.
  static List<String> _parseGenres(XmlElement root) {
    final genresElement = root.getElement('Genres');
    if (genresElement == null) return const [];

    final genres = <String>[];
    for (final genreElement in genresElement.childElements) {
      if (genreElement.name.local != 'Genre') continue;

      final genre = genreElement.innerText.trim();
      if (genre.isNotEmpty) {
        genres.add(genre);
      }
    }

    return genres;
  }

  /// Parses Tags element.
  static List<String> _parseTags(XmlElement root) {
    final tagsElement = root.getElement('Tags');
    if (tagsElement == null) return const [];

    final tags = <String>[];
    for (final tagElement in tagsElement.childElements) {
      if (tagElement.name.local != 'Tag') continue;

      final tag = tagElement.innerText.trim();
      if (tag.isNotEmpty) {
        tags.add(tag);
      }
    }

    return tags;
  }

  /// Parses Arcs element.
  static List<MetronArc> _parseArcs(XmlElement root) {
    final arcsElement = root.getElement('Arcs');
    if (arcsElement == null) return const [];

    final arcs = <MetronArc>[];
    for (final arcElement in arcsElement.childElements) {
      if (arcElement.name.local != 'Arc') continue;

      final nameElement = arcElement.getElement('Name');
      if (nameElement == null) continue;

      final name = nameElement.innerText.trim();
      if (name.isEmpty) continue;

      arcs.add(MetronArc(
        name: name,
        number: _getInt(arcElement, 'Number'),
        id: _parseAttrInt(arcElement.getAttribute('id')),
      ));
    }

    return arcs;
  }

  /// Parses resource lists (Characters, Teams, Locations).
  static List<MetronResource> _parseResources(
    XmlElement root,
    String containerName,
    String itemName,
  ) {
    final containerElement = root.getElement(containerName);
    if (containerElement == null) return const [];

    final resources = <MetronResource>[];
    for (final itemElement in containerElement.childElements) {
      if (itemElement.name.local != itemName) continue;

      final name = itemElement.innerText.trim();
      if (name.isEmpty) continue;

      resources.add(MetronResource(
        name: name,
        id: _parseAttrInt(itemElement.getAttribute('id')),
      ));
    }

    return resources;
  }

  /// Parses Universes element.
  static List<MetronUniverse> _parseUniverses(XmlElement root) {
    final universesElement = root.getElement('Universes');
    if (universesElement == null) return const [];

    final universes = <MetronUniverse>[];
    for (final universeElement in universesElement.childElements) {
      if (universeElement.name.local != 'Universe') continue;

      final nameElement = universeElement.getElement('Name');
      if (nameElement == null) continue;

      final name = nameElement.innerText.trim();
      if (name.isEmpty) continue;

      universes.add(MetronUniverse(
        name: name,
        designation: _getText(universeElement, 'Designation'),
        id: _parseAttrInt(universeElement.getAttribute('id')),
      ));
    }

    return universes;
  }

  /// Parses Reprints element.
  static List<MetronReprint> _parseReprints(XmlElement root) {
    final reprintsElement = root.getElement('Reprints');
    if (reprintsElement == null) return const [];

    final reprints = <MetronReprint>[];
    for (final reprintElement in reprintsElement.childElements) {
      if (reprintElement.name.local != 'Reprint') continue;

      reprints.add(MetronReprint(
        id: _parseAttrInt(reprintElement.getAttribute('id')),
        name: reprintElement.innerText.trim().isEmpty
            ? null
            : reprintElement.innerText.trim(),
      ));
    }

    return reprints;
  }

  /// Parses GTIN element.
  static MetronGtin? _parseGtin(XmlElement root) {
    final gtinElement = root.getElement('GTIN');
    if (gtinElement == null) return null;

    final isbn = _getText(gtinElement, 'ISBN');
    final upc = _getText(gtinElement, 'UPC');

    if (isbn == null && upc == null) return null;

    return MetronGtin(isbn: isbn, upc: upc);
  }

  /// Parses URLs element.
  static List<MetronUrl> _parseUrls(XmlElement root) {
    final urlsElement = root.getElement('URLs') ?? root.getElement('Urls');
    if (urlsElement == null) return const [];

    final urls = <MetronUrl>[];
    for (final urlElement in urlsElement.childElements) {
      if (urlElement.name.local != 'URL' && urlElement.name.local != 'Url') {
        continue;
      }

      final url = urlElement.innerText.trim();
      if (url.isEmpty) continue;

      urls.add(MetronUrl(
        url: url,
        isPrimary: _parseAttrBool(urlElement.getAttribute('primary')),
      ));
    }

    return urls;
  }

  /// Parses Credits element.
  static List<MetronCreator> _parseCredits(XmlElement root) {
    final creditsElement = root.getElement('Credits');
    if (creditsElement == null) return const [];

    final credits = <MetronCreator>[];
    for (final creditElement in creditsElement.childElements) {
      if (creditElement.name.local != 'Credit') continue;

      final creator = creditElement.getElement('Creator');
      if (creator == null) continue;

      final name = creator.innerText.trim();
      if (name.isEmpty) continue;

      // Parse roles
      final rolesElement = creditElement.getElement('Roles');
      final roles = <MetronCreatorRole>[];
      if (rolesElement != null) {
        for (final roleElement in rolesElement.childElements) {
          if (roleElement.name.local != 'Role') continue;
          final role = MetronCreatorRole.parse(roleElement.innerText.trim());
          if (role != null) {
            roles.add(role);
          }
        }
      }

      // If no roles found, check for single Role element
      if (roles.isEmpty) {
        final singleRole =
            MetronCreatorRole.parse(_getText(creditElement, 'Role'));
        if (singleRole != null) {
          roles.add(singleRole);
        }
      }

      credits.add(MetronCreator(
        name: name,
        roles: roles,
        id: _parseAttrInt(creator.getAttribute('id')),
      ));
    }

    return credits;
  }

  /// Parses Pages element.
  static List<MetronPageInfo> _parsePages(XmlElement root) {
    final pagesElement = root.getElement('Pages');
    if (pagesElement == null) return const [];

    final pages = <MetronPageInfo>[];
    var index = 0;

    for (final pageElement in pagesElement.childElements) {
      if (pageElement.name.local != 'Page') continue;

      // Try to get index from Image attribute, otherwise use sequential index
      final imageAttr = pageElement.getAttribute('Image');
      final pageIndex = imageAttr != null ? int.tryParse(imageAttr) : index;

      pages.add(MetronPageInfo(
        index: pageIndex ?? index,
        filename: pageElement.getAttribute('Filename'),
        type: pageElement.getAttribute('Type'),
        doublePage: _parseAttrBool(pageElement.getAttribute('DoublePage')),
        imageWidth: _parseAttrInt(pageElement.getAttribute('ImageWidth')),
        imageHeight: _parseAttrInt(pageElement.getAttribute('ImageHeight')),
        imageSize: _parseAttrInt(pageElement.getAttribute('ImageSize')),
      ));

      index++;
    }

    return pages;
  }

  // ============================================================
  // Attribute parsing helpers
  // ============================================================

  /// Parses integer from attribute value.
  static int? _parseAttrInt(String? value) {
    if (value == null) return null;
    return int.tryParse(value);
  }

  /// Parses boolean from attribute value.
  static bool _parseAttrBool(String? value) {
    if (value == null) return false;
    final lower = value.toLowerCase();
    return lower == 'true' || lower == 'yes' || lower == '1';
  }
}
