import 'package:readwhere_fanfictionde/readwhere_fanfictionde.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

/// Adapts Fanfiction.de entities to the plugin's catalog entity interfaces.

const _baseUrl = 'https://www.fanfiktion.de';

/// Converts a [Story] to a [CatalogEntry].
class StoryEntryAdapter implements CatalogEntry {
  /// Creates an adapter for the given story.
  const StoryEntryAdapter(this.story);

  /// The underlying story.
  final Story story;

  @override
  String get id => story.id;

  @override
  String get title => story.title;

  @override
  CatalogEntryType get type => CatalogEntryType.book;

  @override
  String? get subtitle => story.author.displayName ?? story.author.username;

  @override
  String? get summary => story.summary.isNotEmpty ? story.summary : null;

  @override
  String? get thumbnailUrl => null; // Fanfiction.de doesn't have cover images

  @override
  List<CatalogFile> get files {
    // Create a virtual EPUB file that will be generated on download
    return [
      CatalogFile(
        href: '$_baseUrl/s/${story.id}/1/',
        mimeType: 'application/epub+zip',
        title: '${story.title}.epub',
        isPrimary: true,
        properties: {
          'storyId': story.id,
          'chapterCount': story.chapterCount,
          'wordCount': story.wordCount,
          'isComplete': story.isComplete,
          'rating': story.rating.name,
          'genres': story.genres,
          if (story.fandomName != null) 'fandomName': story.fandomName,
        },
      ),
    ];
  }

  @override
  List<CatalogLink> get links {
    final result = <CatalogLink>[];

    // Link to story page
    if (story.url != null) {
      result.add(CatalogLink(
        href: story.url!,
        rel: 'alternate',
        type: 'text/html',
        title: 'View on Fanfiction.de',
      ));
    }

    // Link to author page
    result.add(CatalogLink(
      href: '$_baseUrl/u/${story.author.username}',
      rel: 'author',
      type: 'text/html',
      title: story.author.displayName ?? story.author.username,
    ));

    return result;
  }
}

/// Converts a [Category] to a [CatalogEntry].
class CategoryEntryAdapter implements CatalogEntry {
  /// Creates an adapter for the given category.
  const CategoryEntryAdapter(this.category);

  /// The underlying category.
  final Category category;

  @override
  String get id => category.id;

  @override
  String get title => category.name;

  @override
  CatalogEntryType get type => CatalogEntryType.navigation;

  @override
  String? get subtitle =>
      category.storyCount != null ? '${category.storyCount} stories' : null;

  @override
  String? get summary => null;

  @override
  String? get thumbnailUrl => null;

  @override
  List<CatalogFile> get files => const [];

  @override
  List<CatalogLink> get links {
    return [
      CatalogLink(
        href: category.url,
        rel: 'subsection',
        type: 'text/html',
        title: category.name,
        properties: {'categoryId': category.id},
      ),
    ];
  }
}

/// Converts a [Fandom] to a [CatalogEntry].
class FandomEntryAdapter implements CatalogEntry {
  /// Creates an adapter for the given fandom.
  const FandomEntryAdapter(this.fandom);

  /// The underlying fandom.
  final Fandom fandom;

  @override
  String get id => fandom.id;

  @override
  String get title => fandom.name;

  @override
  CatalogEntryType get type => CatalogEntryType.navigation;

  @override
  String? get subtitle =>
      fandom.storyCount != null ? '${fandom.storyCount} stories' : null;

  @override
  String? get summary => null;

  @override
  String? get thumbnailUrl => null;

  @override
  List<CatalogFile> get files => const [];

  @override
  List<CatalogLink> get links {
    return [
      CatalogLink(
        href: fandom.url,
        rel: 'subsection',
        type: 'text/html',
        title: fandom.name,
        properties: {
          'fandomId': fandom.id,
          'categoryId': fandom.categoryId,
        },
      ),
    ];
  }
}

/// Converts a [StoryListResult] to a [BrowseResult].
BrowseResult storyListToBrowseResult(
  StoryListResult result, {
  String? title,
  String? baseUrl,
}) {
  final entries = result.stories.map((s) => StoryEntryAdapter(s)).toList();

  String? nextPageUrl;
  String? previousPageUrl;

  if (baseUrl != null) {
    if (result.hasNextPage) {
      nextPageUrl = '$baseUrl/${result.currentPage + 1}/updatedate';
    }
    if (result.currentPage > 1) {
      previousPageUrl = '$baseUrl/${result.currentPage - 1}/updatedate';
    }
  }

  // Use provided title, or fall back to page title from HTML
  final displayTitle = title ?? result.pageTitle;

  return BrowseResult(
    entries: entries,
    title: displayTitle,
    page: result.currentPage,
    totalPages: result.totalPages,
    hasNextPage: result.hasNextPage,
    hasPreviousPage: result.currentPage > 1,
    nextPageUrl: nextPageUrl,
    previousPageUrl: previousPageUrl,
    properties: {
      'source': 'fanfiction.de',
      'storyCount': result.stories.length,
    },
  );
}

/// Converts a list of [Category] to a [BrowseResult].
BrowseResult categoriesToBrowseResult(List<Category> categories) {
  final entries = categories.map((c) => CategoryEntryAdapter(c)).toList();

  return BrowseResult(
    entries: entries,
    title: 'Categories',
    properties: {
      'source': 'fanfiction.de',
      'categoryCount': categories.length,
    },
  );
}

/// Converts a list of [Fandom] to a [BrowseResult].
BrowseResult fandomsToBrowseResult(
  List<Fandom> fandoms, {
  String? categoryName,
}) {
  final entries = fandoms.map((f) => FandomEntryAdapter(f)).toList();

  return BrowseResult(
    entries: entries,
    title: categoryName ?? 'Fandoms',
    properties: {
      'source': 'fanfiction.de',
      'fandomCount': fandoms.length,
    },
  );
}

/// Extension methods for easy conversion.
extension StoryToAdapter on Story {
  /// Converts this story to a [CatalogEntry] adapter.
  CatalogEntry toEntry() => StoryEntryAdapter(this);
}

extension CategoryToAdapter on Category {
  /// Converts this category to a [CatalogEntry] adapter.
  CatalogEntry toEntry() => CategoryEntryAdapter(this);
}

extension FandomToAdapter on Fandom {
  /// Converts this fandom to a [CatalogEntry] adapter.
  CatalogEntry toEntry() => FandomEntryAdapter(this);
}

extension StoryListToEntries on List<Story> {
  /// Converts this list of stories to [CatalogEntry] adapters.
  List<CatalogEntry> toEntries() => map((s) => StoryEntryAdapter(s)).toList();
}

extension CategoryListToEntries on List<Category> {
  /// Converts this list of categories to [CatalogEntry] adapters.
  List<CatalogEntry> toEntries() =>
      map((c) => CategoryEntryAdapter(c)).toList();
}

extension FandomListToEntries on List<Fandom> {
  /// Converts this list of fandoms to [CatalogEntry] adapters.
  List<CatalogEntry> toEntries() => map((f) => FandomEntryAdapter(f)).toList();
}
