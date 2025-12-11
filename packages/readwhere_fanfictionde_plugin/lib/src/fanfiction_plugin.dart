import 'dart:io';

import 'package:logging/logging.dart';
import 'package:readwhere_fanfictionde/readwhere_fanfictionde.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

import 'adapters/fanfiction_adapters.dart';

/// Fanfiction.de catalog plugin using the readwhere_fanfictionde library.
///
/// This plugin provides catalog browsing with search and story download
/// support. Stories are converted to EPUB format on download.
///
/// Implements the unified plugin architecture with [PluginBase] and
/// [CatalogBrowsingCapability] mixin.
class FanfictionPlugin extends PluginBase with CatalogBrowsingCapability {
  late Logger _log;
  late FanfictionClient _client;
  late EpubGenerator _epubGenerator;

  @override
  String get id => 'com.readwhere.fanfiction';

  @override
  String get name => 'Fanfiction.de';

  @override
  String get description => 'Browse and download stories from fanfiction.de';

  @override
  String get version => '1.0.0';

  @override
  List<String> get capabilityNames => ['CatalogBrowsingCapability'];

  @override
  Set<PluginCatalogFeature> get catalogFeatures => {
        PluginCatalogFeature.browse,
        PluginCatalogFeature.search,
        PluginCatalogFeature.download,
        PluginCatalogFeature.pagination,
      };

  @override
  Future<void> initialize(PluginContext context) async {
    _log = context.logger;
    _client = FanfictionClient(httpClient: context.httpClient);
    _epubGenerator = EpubGenerator();
    _log.info('Fanfiction.de plugin initialized');
  }

  @override
  Future<void> dispose() async {
    _log.info('Fanfiction.de plugin disposed');
  }

  @override
  bool canHandleCatalog(CatalogInfo catalog) {
    return catalog.providerType == 'fanfiction';
  }

  @override
  Future<ValidationResult> validate(CatalogInfo catalog) async {
    try {
      _log.info('Validating Fanfiction.de catalog');

      // Try to fetch the homepage to verify connectivity
      final categories = await _client.fetchCategories();

      _log.info(
          'Fanfiction.de catalog validated: ${categories.length} categories found');

      return ValidationResult.success(
        serverName: 'Fanfiction.de',
        properties: {
          'categoryCount': categories.length,
          'baseUrl': FanfictionClient.baseUrl,
        },
      );
    } on FanfictionNetworkException catch (e) {
      _log.warning('Fanfiction.de validation failed: ${e.message}');
      return ValidationResult.failure(
        error: e.message,
        errorCode: e.statusCode == 401 ? 'auth_failed' : 'validation_failed',
      );
    } on FanfictionException catch (e) {
      _log.warning('Fanfiction.de validation failed: ${e.message}');
      return ValidationResult.failure(
        error: e.message,
        errorCode: 'validation_failed',
      );
    } catch (e) {
      _log.severe('Fanfiction.de validation error: $e');
      return ValidationResult.failure(
        error: e.toString(),
        errorCode: 'validation_failed',
      );
    }
  }

  @override
  Future<BrowseResult> browse(
    CatalogInfo catalog, {
    String? path,
    int? page,
  }) async {
    _log.info('Browsing Fanfiction.de: path=$path, page=$page');

    try {
      // Root browse - show categories
      if (path == null || path.isEmpty || path == '/') {
        return _browseRoot();
      }

      // Normalize path - handle full URLs by extracting the path portion
      var normalizedPath = path;
      if (path.startsWith('https://') || path.startsWith('http://')) {
        final uri = Uri.parse(path);
        normalizedPath = uri.path;
        _log.info('Normalized full URL to path: $normalizedPath');
      }

      // Parse the path to determine what to browse
      // Expected formats:
      // - /category/{categoryId} - show fandoms in a category
      // - /fandom/{fandomId} - show stories in a fandom
      // - /stories/{path} - show stories at a specific URL path
      // - /{Category}/c/{id} - direct category URL path from fanfiction.de

      if (normalizedPath.startsWith('/category/')) {
        final categoryId = normalizedPath.substring('/category/'.length);
        return _browseCategory(categoryId, page: page);
      }

      if (normalizedPath.startsWith('/fandom/')) {
        final fandomId = normalizedPath.substring('/fandom/'.length);
        return _browseFandom(fandomId, page: page);
      }

      if (normalizedPath.startsWith('/stories/')) {
        final urlPath = normalizedPath.substring('/stories/'.length);
        return _browseStories(urlPath, page: page);
      }

      // Handle direct fanfiction.de URL paths like /Anime-Manga/c/102000000
      // These contain /c/{id} which indicates a category/fandom page
      // Pass the full path to preserve the category name prefix
      final categoryMatch = RegExp(r'/c/(\d+)').firstMatch(normalizedPath);
      if (categoryMatch != null) {
        final categoryId = categoryMatch.group(1)!;
        _log.info('Detected category ID from URL path: $categoryId');
        // Use the full normalized path instead of just the ID
        return _browseCategoryByPath(normalizedPath, categoryId, page: page);
      }

      // Unknown path format - try as a direct URL path for stories
      return _browseStories(normalizedPath, page: page);
    } on FanfictionException catch (e) {
      _log.warning('Browse failed: ${e.message}');
      rethrow;
    }
  }

  Future<BrowseResult> _browseRoot() async {
    _log.info('Browsing root - fetching categories');
    final categories = await _client.fetchCategories();
    return categoriesToBrowseResult(categories);
  }

  Future<BrowseResult> _browseCategory(String categoryId, {int? page}) async {
    _log.info('Browsing category: $categoryId');

    // Fetch the category page to get fandoms
    // The URL path format is /c/{categoryId}
    final categoryUrl = '/c/$categoryId';
    final fandoms = await _client.fetchFandoms(categoryUrl, categoryId);

    if (fandoms.isNotEmpty) {
      // This category has fandoms - show them
      return fandomsToBrowseResult(fandoms);
    }

    // No fandoms - this might be a direct story listing
    // Build the URL path and fetch stories
    final stories =
        await _client.fetchStories('/c/$categoryId', page: page ?? 1);

    return storyListToBrowseResult(
      stories,
      baseUrl: '${FanfictionClient.baseUrl}/c/$categoryId',
    );
  }

  /// Browse a category using the full URL path.
  ///
  /// This is used when we have a full path like /Anime-Manga/c/102000000
  /// instead of just the category ID.
  Future<BrowseResult> _browseCategoryByPath(
    String categoryPath,
    String categoryId, {
    int? page,
  }) async {
    _log.info('Browsing category by path: $categoryPath');

    // Fetch the category page to get fandoms using the full path
    final fandoms = await _client.fetchFandoms(categoryPath, categoryId);

    if (fandoms.isNotEmpty) {
      // This category has fandoms - show them
      return fandomsToBrowseResult(fandoms);
    }

    // No fandoms - this might be a direct story listing
    final stories = await _client.fetchStories(categoryPath, page: page ?? 1);

    return storyListToBrowseResult(
      stories,
      baseUrl: '${FanfictionClient.baseUrl}$categoryPath',
    );
  }

  Future<BrowseResult> _browseFandom(String fandomId, {int? page}) async {
    _log.info('Browsing fandom: $fandomId, page: $page');

    // Fetch stories for this fandom
    // We need to reconstruct the URL - fandoms are under /Category/Fandom/c/{id}
    // For now, we'll use the generic story fetch with the fandom ID
    final stories = await _client.fetchStories('/c/$fandomId', page: page ?? 1);

    return storyListToBrowseResult(
      stories,
      baseUrl: '${FanfictionClient.baseUrl}/c/$fandomId',
    );
  }

  Future<BrowseResult> _browseStories(String urlPath, {int? page}) async {
    _log.info('Browsing stories at: $urlPath, page: $page');

    final stories = await _client.fetchStories(urlPath, page: page ?? 1);

    return storyListToBrowseResult(
      stories,
      baseUrl: '${FanfictionClient.baseUrl}$urlPath',
    );
  }

  @override
  Future<BrowseResult> search(
    CatalogInfo catalog,
    String query, {
    int? page,
  }) async {
    _log.info('Searching Fanfiction.de: $query, page: $page');

    final results = await _client.search(query, page: page ?? 1);

    _log.info('Search found ${results.stories.length} stories');

    return storyListToBrowseResult(
      results,
      title: 'Search: $query',
    );
  }

  @override
  Future<void> download(
    CatalogInfo catalog,
    CatalogFile file,
    String localPath, {
    PluginProgressCallback? onProgress,
  }) async {
    _log.info('Downloading story to EPUB: ${file.href} -> $localPath');

    // Extract story ID from file properties or href
    final storyId = file.properties['storyId'] as String? ??
        _extractStoryIdFromUrl(file.href);

    if (storyId == null) {
      throw FanfictionParseException(
        'Could not determine story ID from: ${file.href}',
      );
    }

    // Report initial progress
    onProgress?.call(0, 100);

    // Fetch full story details
    _log.info('Fetching story details for: $storyId');
    final story = await _client.fetchStoryDetails(storyId);
    onProgress?.call(10, 100);

    // Fetch all chapters
    _log.info('Fetching ${story.chapterCount} chapters');
    final chapters = <Chapter>[];

    for (var i = 1; i <= story.chapterCount; i++) {
      final chapter = await _client.fetchChapter(storyId, i);
      chapters.add(chapter);

      // Report progress (10-90% for chapter fetching)
      final chapterProgress = 10 + ((i / story.chapterCount) * 80).toInt();
      onProgress?.call(chapterProgress, 100);
    }

    // Generate EPUB
    _log.info('Generating EPUB');
    final epubBytes = await _epubGenerator.generateEpub(story, chapters);
    onProgress?.call(95, 100);

    // Determine save location
    File outputFile;
    if (localPath.endsWith('.epub')) {
      outputFile = File(localPath);
    } else {
      // localPath is a directory - create filename from story title
      final sanitizedTitle = _sanitizeFilename(story.title);
      outputFile = File('$localPath/$sanitizedTitle.epub');
    }

    // Ensure parent directory exists
    await outputFile.parent.create(recursive: true);

    // Write EPUB file
    await outputFile.writeAsBytes(epubBytes);
    onProgress?.call(100, 100);

    _log.info('Download complete: ${outputFile.path}');
  }

  /// Extracts story ID from a fanfiction.de URL.
  String? _extractStoryIdFromUrl(String url) {
    // URL format: /s/{hex_id}/{chapter}/{slug}
    final match = RegExp(r'/s/([a-f0-9]+)/').firstMatch(url);
    return match?.group(1);
  }

  /// Sanitizes a string for use as a filename.
  String _sanitizeFilename(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
