import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../entities/author.dart';
import '../entities/chapter.dart';
import '../entities/story.dart';
import '../entities/story_rating.dart';

/// Parses story information from fanfiction.de HTML pages.
class StoryParser {
  const StoryParser();

  static const _baseUrl = 'https://www.fanfiktion.de';

  /// Parse stories from a listing page (latest, category, search results).
  StoryListResult parseStoryList(String html) {
    final document = html_parser.parse(html);
    final stories = <Story>[];

    // Find story items in the latest stories list
    final storyItems = document.querySelectorAll('.lateststories-item');

    for (final item in storyItems) {
      final story = _parseStoryItem(item);
      if (story != null) {
        stories.add(story);
      }
    }

    // If no latest items found, try generic story list format
    if (stories.isEmpty) {
      final storyLinks = document.querySelectorAll('a[href^="/s/"]');
      for (final link in storyLinks) {
        final story = _parseStoryLink(link);
        if (story != null && !stories.any((s) => s.id == story.id)) {
          stories.add(story);
        }
      }
    }

    // Parse pagination
    final pagination = _parsePagination(document);

    return StoryListResult(
      stories: stories,
      currentPage: pagination.currentPage,
      totalPages: pagination.totalPages,
      hasNextPage: pagination.hasNext,
    );
  }

  /// Parse a story item from the latest stories list.
  Story? _parseStoryItem(Element item) {
    // Get story link
    final storyLink = item.querySelector('a[href^="/s/"]');
    if (storyLink == null) return null;

    final href = storyLink.attributes['href'];
    if (href == null) return null;

    // Extract story ID from URL: /s/{id}/{chapter}/{slug}
    final match = RegExp(r'/s/([a-f0-9]+)/').firstMatch(href);
    if (match == null) return null;

    final storyId = match.group(1)!;
    final title = storyLink.text.trim();

    // Get author
    final authorLink = item.querySelector('a[href^="/u/"]');
    final authorUsername =
        authorLink?.attributes['href']?.replaceFirst('/u/', '') ?? 'Unknown';
    final authorName = authorLink?.text.trim() ?? 'Unknown';

    // Get summary from aria-label
    final summary = storyLink.attributes['aria-label'] ?? '';

    // Get category/fandom path
    final categoryLinks = item.querySelectorAll('.tiny-font a[href*="/c/"]');
    String? fandomName;
    String? categoryName;
    if (categoryLinks.isNotEmpty) {
      categoryName = categoryLinks.first.text.trim();
      if (categoryLinks.length > 1) {
        fandomName = categoryLinks.last.text.trim();
      }
    }

    // Parse genre/rating info from tiny-font div
    final infoDiv = item.querySelectorAll('.tiny-font').lastOrNull;
    final infoText = infoDiv?.text ?? '';

    // Parse rating (P6, P12, P16, P18)
    final ratingMatch = RegExp(r'P\d+(-AVL)?').firstMatch(infoText);
    final rating = ratingMatch != null
        ? StoryRating.fromString(ratingMatch.group(0)!)
        : StoryRating.unknown;

    // Parse genres
    final genres = <String>[];
    final genreMatch =
        RegExp(r'Geschichte.*?/\s*([^/]+)\s*/').firstMatch(infoText);
    if (genreMatch != null) {
      genres.addAll(genreMatch.group(1)!.split(',').map((g) => g.trim()));
    }

    return Story(
      id: storyId,
      title: title,
      author: Author(
        username: authorUsername,
        displayName: authorName,
      ),
      summary: summary,
      rating: rating,
      genres: genres,
      chapterCount: 1, // Unknown from listing
      wordCount: 0, // Unknown from listing
      isComplete: !infoText.contains('In Arbeit'),
      fandomName: fandomName,
      categoryName: categoryName,
      url: '$_baseUrl$href',
    );
  }

  /// Parse story info from a story link element.
  Story? _parseStoryLink(Element link) {
    final href = link.attributes['href'];
    if (href == null) return null;

    final match = RegExp(r'/s/([a-f0-9]+)/').firstMatch(href);
    if (match == null) return null;

    final storyId = match.group(1)!;
    final title = link.text.trim();

    if (title.isEmpty) return null;

    // Get summary from aria-label if available
    final summary = link.attributes['aria-label'] ?? '';

    return Story(
      id: storyId,
      title: title,
      author: const Author(username: 'Unknown'),
      summary: summary,
      rating: StoryRating.unknown,
      chapterCount: 1,
      wordCount: 0,
      isComplete: false,
      url: '$_baseUrl$href',
    );
  }

  /// Parse full story details from a story page.
  Story parseStoryDetails(String html) {
    final document = html_parser.parse(html);

    // Get story ID from canonical URL
    final canonical = document.querySelector('link[rel="canonical"]');
    final canonicalHref = canonical?.attributes['href'] ?? '';
    final idMatch = RegExp(r'/s/([a-f0-9]+)/').firstMatch(canonicalHref);
    final storyId = idMatch?.group(1) ?? '';

    // Get title
    final titleElement = document.querySelector('.story-left h4');
    final title = titleElement?.text.trim() ?? 'Unknown Title';

    // Get author
    final authorLink = document.querySelector('.story-left a[href^="/u/"]');
    final authorUsername =
        authorLink?.attributes['href']?.replaceFirst('/u/', '') ?? 'Unknown';
    final authorName = authorLink?.text.trim() ?? 'Unknown';

    // Get summary
    final summaryElement = document.querySelector('#story-summary-inline');
    final summary = summaryElement?.text.trim() ?? '';

    // Get metadata line (genre, rating, etc.)
    final metaLine =
        document.querySelector('.story-left .small-font.block')?.text ?? '';

    // Parse rating
    final ratingMatch = RegExp(r'P\d+(-AVL)?').firstMatch(metaLine);
    final rating = ratingMatch != null
        ? StoryRating.fromString(ratingMatch.group(0)!)
        : StoryRating.unknown;

    // Parse genres from meta line
    final genres = <String>[];
    // Format: "Geschichte > Genre1, Genre2 / P16 / MaleSlash"
    final genreMatch = RegExp(r'Geschichte.*?>([^/]+)/').firstMatch(metaLine);
    if (genreMatch != null) {
      genres.addAll(genreMatch.group(1)!.split(',').map((g) => g.trim()));
    }

    // Get chapter count
    final chapterSelect = document.querySelector('select[name="k"]');
    final chapterCount = chapterSelect?.querySelectorAll('option').length ?? 1;

    // Get word count
    final wordCountElement =
        document.querySelector('.titled-icon[title*="Wörter"]');
    var wordCount = 0;
    if (wordCountElement != null) {
      final sibling = wordCountElement.nextElementSibling;
      if (sibling != null) {
        final text = sibling.text.replaceAll(RegExp(r'[^\d]'), '');
        wordCount = int.tryParse(text) ?? 0;
      }
    }

    // Check if complete
    final isComplete =
        document.querySelector('.titled-icon[title="abgeschlossen"]') != null;

    // Get dates
    DateTime? publishedAt;
    DateTime? updatedAt;
    final dateElements =
        document.querySelectorAll('.flexicon-container .titled-icon');
    for (final el in dateElements) {
      final title = el.attributes['title'] ?? '';
      // Get the next sibling element's text
      final nextSibling = el.nextElementSibling;
      final dateText = nextSibling?.text.trim() ?? '';
      final date = _parseGermanDate(dateText);
      if (title.contains('erstellt') && date != null) {
        publishedAt = date;
      } else if (title.contains('aktualisiert') && date != null) {
        updatedAt = date;
      }
    }

    // Get characters
    final characters = document
        .querySelectorAll('.badge-character')
        .map((e) => e.text.trim())
        .toList();

    // Get category/fandom from breadcrumb
    String? categoryName;
    String? fandomName;
    final breadcrumbs =
        document.querySelectorAll('.topic-title-big a[href*="/c/"]');
    if (breadcrumbs.length >= 2) {
      categoryName = breadcrumbs[0].text.trim();
      fandomName = breadcrumbs.length > 2
          ? breadcrumbs[breadcrumbs.length - 2].text.trim()
          : null;
    }

    // Parse chapter list
    final chapters = _parseChapterList(document);

    return Story(
      id: storyId,
      title: title,
      author: Author(
        username: authorUsername,
        displayName: authorName,
      ),
      summary: summary,
      rating: rating,
      genres: genres,
      characters: characters,
      chapterCount: chapterCount,
      wordCount: wordCount,
      isComplete: isComplete,
      publishedAt: publishedAt,
      updatedAt: updatedAt,
      fandomName: fandomName,
      categoryName: categoryName,
      url: canonicalHref.isNotEmpty ? canonicalHref : null,
      chapters: chapters,
    );
  }

  /// Parse chapter list from story page.
  List<ChapterInfo> _parseChapterList(Document document) {
    final chapters = <ChapterInfo>[];
    final chapterSelect = document.querySelector('select[name="k"]');

    if (chapterSelect == null) {
      // Single chapter story
      final title =
          document.querySelector('.story-left h4')?.text.trim() ?? 'Chapter 1';
      chapters.add(ChapterInfo(number: 1, title: title));
      return chapters;
    }

    final options = chapterSelect.querySelectorAll('option');
    for (final option in options) {
      final value = option.attributes['value'];
      final number = int.tryParse(value ?? '') ?? (chapters.length + 1);
      final title = option.text.trim();

      // Parse title - format is "1. Chapter Title"
      final titleMatch = RegExp(r'^\d+\.\s*(.+)$').firstMatch(title);
      final cleanTitle = titleMatch?.group(1) ?? title;

      chapters.add(ChapterInfo(
        number: number,
        title: cleanTitle,
      ));
    }

    return chapters;
  }

  /// Parse pagination info.
  ({int currentPage, int? totalPages, bool hasNext}) _parsePagination(
      Document document) {
    // Default values
    var currentPage = 1;
    int? totalPages;
    var hasNext = false;

    // Look for pagination in various formats
    final pagerLinks = document.querySelectorAll('.pager a, .pagination a');

    for (final link in pagerLinks) {
      final text = link.text.trim();
      if (text == '»' || text.toLowerCase().contains('weiter')) {
        hasNext = true;
      }

      // Try to extract page numbers
      final pageNum = int.tryParse(text);
      if (pageNum != null) {
        if (link.classes.contains('current') ||
            link.parent?.classes.contains('active') == true) {
          currentPage = pageNum;
        }
        if (totalPages == null || pageNum > totalPages) {
          totalPages = pageNum;
        }
      }
    }

    return (currentPage: currentPage, totalPages: totalPages, hasNext: hasNext);
  }

  /// Parse a German date string (DD.MM.YYYY).
  DateTime? _parseGermanDate(String text) {
    final match = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})').firstMatch(text);
    if (match == null) return null;

    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);

    return DateTime(year, month, day);
  }
}
