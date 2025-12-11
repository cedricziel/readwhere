import 'package:http/http.dart' as http;

import '../entities/category.dart';
import '../entities/chapter.dart';
import '../entities/fandom.dart';
import '../entities/story.dart';
import '../parser/category_parser.dart';
import '../parser/chapter_parser.dart';
import '../parser/story_parser.dart';
import 'fanfiction_exception.dart';

/// Client for interacting with fanfiction.de.
///
/// Provides methods to fetch categories, stories, chapters, and search.
class FanfictionClient {
  /// Creates a new [FanfictionClient].
  ///
  /// [httpClient] Optional HTTP client for making requests.
  /// [userAgent] User agent string to identify requests.
  /// [timeout] Request timeout duration.
  FanfictionClient({
    http.Client? httpClient,
    this.userAgent = 'ReadWhere/1.0 (Fanfiction Client)',
    this.timeout = const Duration(seconds: 30),
  }) : _httpClient = httpClient ?? http.Client();

  /// Base URL for fanfiction.de.
  static const String baseUrl = 'https://www.fanfiktion.de';

  final http.Client _httpClient;

  /// User agent string for requests.
  final String userAgent;

  /// Request timeout duration.
  final Duration timeout;

  final _categoryParser = const CategoryParser();
  final _storyParser = const StoryParser();
  final _chapterParser = const ChapterParser();

  /// Fetch all main categories from the homepage.
  Future<List<Category>> fetchCategories() async {
    final html = await _fetch(baseUrl);
    return _categoryParser.parseCategories(html);
  }

  /// Fetch fandoms within a category.
  ///
  /// [categoryUrl] The full URL or path to the category page.
  /// [categoryId] The category ID for reference.
  Future<List<Fandom>> fetchFandoms(
      String categoryUrl, String categoryId) async {
    final url = _resolveUrl(categoryUrl);
    final html = await _fetch(url);
    return _categoryParser.parseFandoms(html, categoryId);
  }

  /// Fetch stories from a category, fandom, or listing page.
  ///
  /// [path] The URL path (e.g., '/Anime-Manga/c/102000000').
  /// [page] Page number for pagination (1-indexed).
  Future<StoryListResult> fetchStories(String path, {int page = 1}) async {
    var url = _resolveUrl(path);

    // Add pagination if needed
    if (page > 1) {
      // URL format: /Category/c/ID/PAGE/updatedate
      if (!url.contains('/updatedate')) {
        url = '$url/$page/updatedate';
      } else {
        // Replace existing page number
        url = url.replaceFirst(
          RegExp(r'/\d+/updatedate'),
          '/$page/updatedate',
        );
      }
    }

    final html = await _fetch(url);
    return _storyParser.parseStoryList(html);
  }

  /// Fetch the latest stories.
  Future<StoryListResult> fetchLatestStories() async {
    final html = await _fetch('$baseUrl/latest');
    return _storyParser.parseStoryList(html);
  }

  /// Fetch full story details including chapter list.
  ///
  /// [storyId] The story's hex ID.
  Future<Story> fetchStoryDetails(String storyId) async {
    final url = '$baseUrl/s/$storyId/1/story';
    final html = await _fetch(url);
    return _storyParser.parseStoryDetails(html);
  }

  /// Fetch a specific chapter's content.
  ///
  /// [storyId] The story's hex ID.
  /// [chapterNumber] The chapter number (1-indexed).
  Future<Chapter> fetchChapter(String storyId, int chapterNumber) async {
    final url = '$baseUrl/s/$storyId/$chapterNumber/chapter';
    final html = await _fetch(url);
    return _chapterParser.parseChapter(html, chapterNumber);
  }

  /// Fetch all chapters for a story.
  ///
  /// [storyId] The story's hex ID.
  /// [chapterCount] Total number of chapters.
  /// [onProgress] Optional callback for progress updates.
  Future<List<Chapter>> fetchAllChapters(
    String storyId,
    int chapterCount, {
    void Function(int current, int total)? onProgress,
  }) async {
    final chapters = <Chapter>[];

    for (var i = 1; i <= chapterCount; i++) {
      final chapter = await fetchChapter(storyId, i);
      chapters.add(chapter);
      onProgress?.call(i, chapterCount);
    }

    return chapters;
  }

  /// Search for stories.
  ///
  /// [query] Search query string.
  /// [page] Page number for results (1-indexed).
  Future<StoryListResult> search(String query, {int page = 1}) async {
    final encodedQuery = Uri.encodeQueryComponent(query);
    var url = '$baseUrl/?a=G&searchterms=$encodedQuery';

    if (page > 1) {
      url = '$url&seession_list_page=$page';
    }

    final html = await _fetch(url);
    return _storyParser.parseStoryList(html);
  }

  /// Fetch the Atom feed for latest stories.
  Future<String> fetchLatestFeed() async {
    return _fetch('$baseUrl/feed/latest/atom.xml');
  }

  /// Fetch an author's story Atom feed.
  ///
  /// [username] The author's username.
  Future<String> fetchAuthorFeed(String username) async {
    final encodedUsername = Uri.encodeComponent(username);
    return _fetch('$baseUrl/feed/author/$encodedUsername/stories/atom.xml');
  }

  /// Clean chapter HTML content for EPUB generation.
  String cleanChapterHtml(String rawHtml) {
    return _chapterParser.cleanChapterHtml(rawHtml);
  }

  /// Resolve a URL path to a full URL.
  String _resolveUrl(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    if (pathOrUrl.startsWith('/')) {
      return '$baseUrl$pathOrUrl';
    }
    return '$baseUrl/$pathOrUrl';
  }

  /// Fetch HTML content from a URL.
  Future<String> _fetch(String url) async {
    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'User-Agent': userAgent,
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'de-DE,de;q=0.9,en;q=0.8',
        },
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return response.body;
      } else if (response.statusCode == 404) {
        throw FanfictionNotFoundException(
          'Page not found: $url',
        );
      } else if (response.statusCode == 403) {
        throw FanfictionAccessDeniedException(
          'Access denied to: $url',
          reason: 'HTTP 403',
        );
      } else {
        throw FanfictionNetworkException(
          'Failed to fetch page',
          statusCode: response.statusCode,
          url: url,
        );
      }
    } on FanfictionException {
      rethrow;
    } catch (e) {
      throw FanfictionNetworkException(
        'Network error: $e',
        url: url,
      );
    }
  }

  /// Close the HTTP client.
  void close() {
    _httpClient.close();
  }
}
