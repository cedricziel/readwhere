import 'package:xml/xml.dart';

import '../../errors/cbz_exception.dart';
import '../../pages/comic_page.dart';
import '../age_rating.dart';
import '../comic_page_info.dart';
import '../reading_direction.dart';
import 'comic_info.dart';

/// Parser for ComicInfo.xml files.
class ComicInfoParser {
  ComicInfoParser._();

  /// Parses ComicInfo.xml content into a [ComicInfo] object.
  ///
  /// Throws [CbzParseException] if the XML is malformed.
  static ComicInfo parse(String xmlContent) {
    try {
      final document = XmlDocument.parse(xmlContent);
      final root = document.rootElement;

      if (root.name.local != 'ComicInfo') {
        throw CbzParseException(
          'Invalid root element: expected "ComicInfo", got "${root.name.local}"',
          documentPath: 'ComicInfo.xml',
        );
      }

      return _parseComicInfo(root);
    } on XmlException catch (e, st) {
      throw CbzParseException(
        'Failed to parse ComicInfo.xml: $e',
        documentPath: 'ComicInfo.xml',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Parses the ComicInfo element.
  static ComicInfo _parseComicInfo(XmlElement root) {
    return ComicInfo(
      // Bibliographic
      title: _getText(root, 'Title'),
      series: _getText(root, 'Series'),
      number: _getText(root, 'Number'),
      count: _getInt(root, 'Count'),
      volume: _getInt(root, 'Volume'),
      alternateSeries: _getText(root, 'AlternateSeries'),
      alternateNumber: _getText(root, 'AlternateNumber'),
      alternateCount: _getInt(root, 'AlternateCount'),
      summary: _getText(root, 'Summary'),
      notes: _getText(root, 'Notes'),

      // Dates
      year: _getInt(root, 'Year'),
      month: _getInt(root, 'Month'),
      day: _getInt(root, 'Day'),

      // Creators
      writers: _getCommaSeparatedList(root, 'Writer'),
      pencillers: _getCommaSeparatedList(root, 'Penciller'),
      inkers: _getCommaSeparatedList(root, 'Inker'),
      colorists: _getCommaSeparatedList(root, 'Colorist'),
      letterers: _getCommaSeparatedList(root, 'Letterer'),
      coverArtists: _getCommaSeparatedList(root, 'CoverArtist'),
      editors: _getCommaSeparatedList(root, 'Editor'),
      translators: _getCommaSeparatedList(root, 'Translator'),

      // Publication
      publisher: _getText(root, 'Publisher'),
      imprint: _getText(root, 'Imprint'),
      genres: _getCommaSeparatedList(root, 'Genre'),
      tags: _getCommaSeparatedList(root, 'Tags'),
      web: _getText(root, 'Web'),
      languageISO: _getText(root, 'LanguageISO'),
      format: _getText(root, 'Format'),
      gtin: _getText(root, 'GTIN'),

      // Reading
      manga: MangaType.parse(_getText(root, 'Manga')),
      blackAndWhite: _getBool(root, 'BlackAndWhite'),
      ageRating: _getAgeRating(root),
      communityRating: _getDouble(root, 'CommunityRating'),

      // Story
      characters: _getCommaSeparatedList(root, 'Characters'),
      teams: _getCommaSeparatedList(root, 'Teams'),
      locations: _getCommaSeparatedList(root, 'Locations'),
      mainCharacterOrTeam: _getText(root, 'MainCharacterOrTeam'),
      storyArc: _getText(root, 'StoryArc'),
      storyArcNumbers: _getCommaSeparatedList(root, 'StoryArcNumber'),
      seriesGroups: _getCommaSeparatedList(root, 'SeriesGroup'),

      // Scanning
      scanInformation: _getText(root, 'ScanInformation'),
      review: _getText(root, 'Review'),

      // Pages
      pages: _parsePages(root),
      pageCount: _getInt(root, 'PageCount'),
    );
  }

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

  /// Gets double value of a child element.
  static double? _getDouble(XmlElement parent, String name) {
    final text = _getText(parent, name);
    if (text == null) return null;
    return double.tryParse(text);
  }

  /// Gets boolean value of a child element.
  ///
  /// Recognizes: "Yes", "True", "1" as true.
  static bool _getBool(XmlElement parent, String name) {
    final text = _getText(parent, name)?.toLowerCase();
    if (text == null) return false;
    return text == 'yes' || text == 'true' || text == '1';
  }

  /// Gets age rating from the AgeRating element.
  static AgeRating? _getAgeRating(XmlElement parent) {
    final text = _getText(parent, 'AgeRating');
    if (text == null) return null;
    return AgeRating.parse(text);
  }

  /// Parses a comma-separated list from an element.
  static List<String> _getCommaSeparatedList(XmlElement parent, String name) {
    final text = _getText(parent, name);
    if (text == null) return const [];

    return text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Parses the Pages element containing Page elements.
  static List<ComicPageInfo> _parsePages(XmlElement root) {
    final pagesElement = root.getElement('Pages');
    if (pagesElement == null) return const [];

    final pages = <ComicPageInfo>[];

    for (final pageElement in pagesElement.childElements) {
      if (pageElement.name.local != 'Page') continue;

      final pageInfo = _parsePage(pageElement);
      if (pageInfo != null) {
        pages.add(pageInfo);
      }
    }

    return pages;
  }

  /// Parses a single Page element.
  static ComicPageInfo? _parsePage(XmlElement element) {
    // Image attribute is required
    final imageAttr = element.getAttribute('Image');
    if (imageAttr == null) return null;

    final index = int.tryParse(imageAttr);
    if (index == null) return null;

    return ComicPageInfo(
      index: index,
      type: _parsePageType(element.getAttribute('Type')),
      doublePage: _parseAttrBool(element.getAttribute('DoublePage')),
      imageWidth: _parseAttrInt(element.getAttribute('ImageWidth')),
      imageHeight: _parseAttrInt(element.getAttribute('ImageHeight')),
      imageSize: _parseAttrInt(element.getAttribute('ImageSize')),
      bookmark: element.getAttribute('Bookmark'),
      key: element.getAttribute('Key'),
    );
  }

  /// Parses PageType from attribute value.
  static PageType? _parsePageType(String? value) {
    if (value == null || value.isEmpty) return null;
    return PageType.parse(value);
  }

  /// Parses integer from attribute value.
  static int? _parseAttrInt(String? value) {
    if (value == null) return null;
    return int.tryParse(value);
  }

  /// Parses boolean from attribute value.
  static bool? _parseAttrBool(String? value) {
    if (value == null) return null;
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == 'yes' || lower == '1') return true;
    if (lower == 'false' || lower == 'no' || lower == '0') return false;
    return null;
  }
}
