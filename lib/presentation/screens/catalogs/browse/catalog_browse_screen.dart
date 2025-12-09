import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../domain/entities/opds_entry.dart';
import '../../../../domain/entities/opds_link.dart';
import '../../../providers/catalogs_provider.dart';
import '../../../router/routes.dart';
import '../../../widgets/common/cache_status_indicator.dart';
import 'widgets/feed_breadcrumbs.dart';
import 'widgets/opds_entry_card.dart';

/// Screen for browsing an OPDS catalog's contents
class CatalogBrowseScreen extends StatefulWidget {
  final String catalogId;

  const CatalogBrowseScreen({super.key, required this.catalogId});

  @override
  State<CatalogBrowseScreen> createState() => _CatalogBrowseScreenState();
}

class _CatalogBrowseScreenState extends State<CatalogBrowseScreen> {
  final _searchController = TextEditingController();
  bool _isGridView = true;
  bool _showSearch = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCatalog();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    final provider = sl<CatalogsProvider>();
    final catalog = provider.catalogs.firstWhere(
      (c) => c.id == widget.catalogId,
      orElse: () => throw Exception('Catalog not found'),
    );
    await provider.openCatalog(catalog);
  }

  Future<void> _refreshFeed() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    try {
      final provider = sl<CatalogsProvider>();
      await provider.refreshCurrentFeed();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _handleEntryTap(CatalogsProvider provider, OpdsEntry entry) {
    if (entry.isNavigation) {
      // Navigate to subfeed
      final navLink = entry.links.firstWhere(
        (l) =>
            l.rel == OpdsLinkRel.subsection ||
            l.type.contains('atom') ||
            l.type.contains('opds'),
        orElse: () => entry.links.first,
      );
      provider.navigateToFeed(navLink);
    } else {
      // Show book details or download options
      _showBookOptionsSheet(context, provider, entry);
    }
  }

  Future<void> _handleDownload(
    CatalogsProvider provider,
    OpdsEntry entry,
  ) async {
    final book = await provider.downloadAndImportBook(entry);
    if (book != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded "${book.title}"'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => context.push(AppRoutes.readerPath(book.id)),
          ),
        ),
      );
    } else if (provider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _handleOpenBook(CatalogsProvider provider, String entryId) {
    final bookId = provider.getBookIdForEntry(entryId);
    if (bookId != null) {
      context.push(AppRoutes.readerPath(bookId));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Book not found in library'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showBookOptionsSheet(
    BuildContext context,
    CatalogsProvider provider,
    OpdsEntry entry,
  ) {
    final theme = Theme.of(context);
    final isDownloaded = provider.isBookInLibrary(entry.id);
    final isDownloading = provider.isDownloading(entry.id);
    final progress = provider.getDownloadProgress(entry.id);
    final isUnsupported = entry.hasOnlyUnsupportedFormats;

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              entry.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (entry.author != null) ...[
              const SizedBox(height: 4),
              Text(
                entry.author!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
            if (entry.summary != null) ...[
              const SizedBox(height: 12),
              Text(
                entry.summary!,
                style: theme.textTheme.bodyMedium,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // Unsupported format warning
            if (isUnsupported) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Format not supported',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'This book is only available as ${entry.preferredFormat?.toUpperCase() ?? "unknown format"}. '
                            'Supported formats: EPUB, PDF, MOBI.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Actions
            if (isDownloaded)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Navigate to downloaded book in library
                  },
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Open in Reader'),
                ),
              )
            else if (isDownloading)
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Downloading... ${(progress * 100).toInt()}%'),
                    ],
                  ),
                ),
              )
            else if (isUnsupported)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.block),
                  label: Text(
                    'Cannot Download (${entry.preferredFormat?.toUpperCase() ?? "Unknown"})',
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleDownload(provider, entry);
                  },
                  icon: const Icon(Icons.download),
                  label: Text(
                    'Download${entry.preferredFormat != null ? ' (${entry.preferredFormat!.toUpperCase()})' : ''}',
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSearch(CatalogsProvider provider) {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      provider.search(query);
    }
  }

  void _handleBreadcrumbTap(CatalogsProvider provider, int index) {
    // Navigate back to the selected breadcrumb level
    final depth = provider.breadcrumbs.length - index - 1;
    for (var i = 0; i < depth; i++) {
      provider.navigateBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: sl<CatalogsProvider>(),
      child: Consumer<CatalogsProvider>(
        builder: (context, provider, child) {
          final feed = provider.currentFeed;
          final catalog = provider.selectedCatalog;

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (provider.canNavigateBack) {
                    provider.navigateBack();
                  } else {
                    provider.closeCatalog();
                    context.pop();
                  }
                },
              ),
              title: Text(feed?.title ?? catalog?.name ?? 'Catalog'),
              actions: [
                if (feed?.hasSearch == true)
                  IconButton(
                    icon: Icon(_showSearch ? Icons.close : Icons.search),
                    onPressed: () {
                      setState(() {
                        _showSearch = !_showSearch;
                        if (!_showSearch) {
                          _searchController.clear();
                          if (provider.searchQuery.isNotEmpty) {
                            provider.clearSearch();
                          }
                        }
                      });
                    },
                  ),
                IconButton(
                  icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                // Search bar
                if (_showSearch)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.clearSearch();
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _handleSearch(provider),
                    ),
                  ),

                // Breadcrumbs
                if (provider.breadcrumbs.length > 1)
                  FeedBreadcrumbs(
                    breadcrumbs: provider.breadcrumbs,
                    onTap: (index) => _handleBreadcrumbTap(provider, index),
                  ),

                // Cache status indicator
                CacheStatusIndicator(
                  isFromCache: provider.isFromCache,
                  isFresh: provider.isCacheFresh,
                  cacheAgeText: provider.cacheAgeText,
                  onRefresh: _refreshFeed,
                  isRefreshing: _isRefreshing,
                ),

                // Content
                Expanded(child: _buildContent(provider)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(CatalogsProvider provider) {
    if (provider.isLoading && provider.currentFeed == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.currentFeed == null) {
      return _buildErrorState(provider);
    }

    final feed = provider.currentFeed;
    if (feed == null || feed.entries.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshFeed,
      child: _isGridView
          ? _buildGridView(provider, feed.entries)
          : _buildListView(provider, feed.entries),
    );
  }

  Widget _buildGridView(CatalogsProvider provider, List<OpdsEntry> entries) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        childAspectRatio: 0.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final coverUrl = _resolveCoverUrl(provider, entry);

        return OpdsEntryCard(
          entry: entry,
          coverUrl: coverUrl,
          isDownloading: provider.isDownloading(entry.id),
          isDownloaded: provider.isBookInLibrary(entry.id),
          downloadProgress: provider.getDownloadProgress(entry.id),
          onTap: () => _handleEntryTap(provider, entry),
          onDownload: () => _handleDownload(provider, entry),
          onOpen: provider.isBookInLibrary(entry.id)
              ? () => _handleOpenBook(provider, entry.id)
              : null,
        );
      },
    );
  }

  Widget _buildListView(CatalogsProvider provider, List<OpdsEntry> entries) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: entries.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final coverUrl = _resolveCoverUrl(provider, entry);

        return OpdsEntryListTile(
          entry: entry,
          coverUrl: coverUrl,
          isDownloading: provider.isDownloading(entry.id),
          isDownloaded: provider.isBookInLibrary(entry.id),
          downloadProgress: provider.getDownloadProgress(entry.id),
          onTap: () => _handleEntryTap(provider, entry),
          onDownload: () => _handleDownload(provider, entry),
          onOpen: provider.isBookInLibrary(entry.id)
              ? () => _handleOpenBook(provider, entry.id)
              : null,
        );
      },
    );
  }

  String? _resolveCoverUrl(CatalogsProvider provider, OpdsEntry entry) {
    final coverLink = entry.coverLink;
    if (coverLink == null) return null;

    final baseUrl = provider.selectedCatalog?.opdsUrl ?? '';
    // Simple URL resolution
    if (coverLink.href.startsWith('http')) {
      return coverLink.href;
    }
    // Resolve relative URL
    final uri = Uri.parse(baseUrl);
    return uri.resolve(coverLink.href).toString();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Items Found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'This feed appears to be empty.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(CatalogsProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: _loadCatalog,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
