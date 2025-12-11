import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../entities/category.dart';
import '../entities/fandom.dart';

/// Parses category and fandom information from fanfiction.de HTML pages.
class CategoryParser {
  const CategoryParser();

  static const _baseUrl = 'https://www.fanfiktion.de';

  /// Parse main categories from the homepage HTML.
  ///
  /// Extracts both Fanfiction categories and Free Works (Freie Arbeiten).
  List<Category> parseCategories(String html) {
    final document = html_parser.parse(html);
    final categories = <Category>[];

    // Find category links in the ffcbox sections
    // Categories have format: /CategoryName/c/ID
    final categoryLinks = document.querySelectorAll('a[href*="/c/"]');

    for (final link in categoryLinks) {
      final href = link.attributes['href'];
      if (href == null) continue;

      // Match pattern like /Anime-Manga/c/102000000
      final match = RegExp(r'^/([^/]+)/c/(\d+)$').firstMatch(href);
      if (match == null) continue;

      final categoryId = match.group(2)!;
      final name = _extractTextContent(link);
      if (name.isEmpty) continue;

      // Extract story count from sibling badge
      int? storyCount;
      final badge = link.parent?.querySelector('.badge');
      if (badge != null) {
        final countText = badge.text.replaceAll(RegExp(r'[^\d]'), '');
        storyCount = int.tryParse(countText);
      }

      // Avoid duplicates
      if (categories.any((c) => c.id == categoryId)) continue;

      categories.add(Category(
        id: categoryId,
        name: name,
        url: '$_baseUrl$href',
        storyCount: storyCount,
      ));
    }

    return categories;
  }

  /// Parse fandoms within a category page.
  ///
  /// [html] The HTML content of the category page.
  /// [categoryId] The parent category ID.
  List<Fandom> parseFandoms(String html, String categoryId) {
    final document = html_parser.parse(html);
    final fandoms = <Fandom>[];

    // Fandom links have format: /FandomName/c/ID/1/updatedate
    // They MUST have the /1/updatedate suffix to distinguish from breadcrumb links
    // Breadcrumb links like /Fanfiction/c/100000000 don't have this suffix
    final fandomLinks = document.querySelectorAll('a[href*="/c/"]');

    for (final link in fandomLinks) {
      final href = link.attributes['href'];
      if (href == null) continue;

      // Only match links with /updatedate suffix (actual fandom links)
      // This excludes breadcrumb navigation links like /Fanfiction/c/100000000
      if (!href.contains('/updatedate')) continue;

      // Extract the fandom ID which comes after /c/
      final match = RegExp(r'/c/(\d+)').firstMatch(href);
      if (match == null) continue;

      final fandomId = match.group(1)!;

      // Skip if it's the parent category itself
      if (fandomId == categoryId) continue;

      final name = _extractTextContent(link);
      if (name.isEmpty) continue;

      // Extract story count from sibling badge
      int? storyCount;
      final badge = link.parent?.querySelector('.badge');
      if (badge != null) {
        final countText = badge.text.replaceAll(RegExp(r'[^\d]'), '');
        storyCount = int.tryParse(countText);
      }

      // Avoid duplicates
      if (fandoms.any((f) => f.id == fandomId)) continue;

      // Keep the full href including /1/updatedate suffix
      // The site requires this suffix and returns 301 redirects without it
      fandoms.add(Fandom(
        id: fandomId,
        name: name,
        url: '$_baseUrl$href',
        categoryId: categoryId,
        storyCount: storyCount,
      ));
    }

    return fandoms;
  }

  /// Parse the current category/fandom name from a page.
  String? parseCurrentCategoryName(String html) {
    final document = html_parser.parse(html);

    // Try to find the title in the topic header
    final topicTitle = document.querySelector('.topic-title-big');
    if (topicTitle != null) {
      // Get the last link in the breadcrumb
      final links = topicTitle.querySelectorAll('a');
      if (links.isNotEmpty) {
        return _extractTextContent(links.last);
      }
    }

    return null;
  }

  /// Parse pagination info from a category/fandom page.
  ({int currentPage, int? totalPages, bool hasNext}) parsePagination(
      String html) {
    final document = html_parser.parse(html);

    // Look for pagination controls
    final paginationLinks =
        document.querySelectorAll('.pager a, .pagination a');

    var currentPage = 1;
    int? totalPages;
    var hasNext = false;

    for (final link in paginationLinks) {
      final href = link.attributes['href'] ?? '';
      final pageMatch = RegExp(r'/(\d+)/updatedate').firstMatch(href);
      if (pageMatch != null) {
        final page = int.tryParse(pageMatch.group(1)!) ?? 1;
        if (link.classes.contains('current') ||
            link.classes.contains('active')) {
          currentPage = page;
        }
        if (totalPages == null || page > totalPages) {
          totalPages = page;
        }
      }

      // Check for "next" link
      if (link.text.contains('»') ||
          link.text.contains('Weiter') ||
          link.classes.contains('next')) {
        hasNext = true;
      }
    }

    return (currentPage: currentPage, totalPages: totalPages, hasNext: hasNext);
  }

  /// Extract clean text content from an element.
  String _extractTextContent(Element element) {
    // Get text, removing icon elements
    final clone = element.clone(true);
    clone.querySelectorAll('span[class*="fa-"]').forEach((e) => e.remove());
    return clone.text.trim();
  }
}
