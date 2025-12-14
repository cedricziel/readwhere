import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

import '../../../../domain/entities/catalog.dart';
import '../../../providers/library_provider.dart';
import '../../../providers/unified_catalog_browsing_provider.dart';
import '../../../router/routes.dart';
import '../../../widgets/adaptive/adaptive_text_field.dart';
import '../../../widgets/facets/facet_filter_bar.dart';
import '../../../widgets/facets/facet_selection_sheet.dart';
import 'widgets/mosaic_preview_card.dart';

/// Unified browse screen for all catalog types.
///
/// This screen uses [UnifiedCatalogBrowsingProvider] to provide a consistent
/// browsing experience across OPDS, Kavita, RSS, and other catalog types.
///
/// The screen automatically handles:
/// - Loading and error states
/// - Navigation stack with back button
/// - Search (if supported by the catalog)
/// - Download progress
/// - Pagination
class UnifiedBrowseScreen extends StatefulWidget {
  const UnifiedBrowseScreen({super.key, required this.catalog});

  /// The catalog to browse.
  final Catalog catalog;

  @override
  State<UnifiedBrowseScreen> createState() => _UnifiedBrowseScreenState();
}

class _UnifiedBrowseScreenState extends State<UnifiedBrowseScreen> {
  late final UnifiedCatalogBrowsingProvider _provider;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _provider = GetIt.I<UnifiedCatalogBrowsingProvider>();
    _provider.addListener(_onProviderChanged);
    _scrollController.addListener(_onScroll);

    // Open the catalog
    _provider.openCatalog(widget.catalog);
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    _provider.closeBrowser();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    // Load more when near the bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_provider.isLoading && _provider.hasNextPage) {
        _provider.loadNextPage();
      }
    }
  }

  Future<void> _onRefresh() async {
    await _provider.refresh();
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      _provider.clearSearch();
    } else {
      _provider.search(query);
    }
  }

  void _onEntryTap(CatalogEntry entry) {
    if (entry.type == CatalogEntryType.book) {
      // Row tap: download and open
      _downloadAndOpen(entry);
    } else {
      // Navigate to the entry (collection/navigation)
      _provider.navigateToEntry(entry);
    }
  }

  /// Download only (button tap) - doesn't open after download
  void _onDownloadOnly(CatalogEntry entry) {
    _showDownloadOptions(entry, openAfterDownload: false);
  }

  /// Download and open (row tap)
  void _downloadAndOpen(CatalogEntry entry) {
    // If already downloaded, just open it
    if (_provider.isDownloaded(entry.id)) {
      final bookId = _provider.getBookIdForEntry(entry.id);
      if (bookId != null) {
        context.push(AppRoutes.readerPath(bookId));
      }
      return;
    }
    _showDownloadOptions(entry, openAfterDownload: true);
  }

  void _showDownloadOptions(
    CatalogEntry entry, {
    required bool openAfterDownload,
  }) {
    if (entry.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No downloadable files available')),
      );
      return;
    }

    if (entry.files.length == 1) {
      // Download directly
      _downloadFile(entry, entry.files.first, openAfterDownload);
      return;
    }

    // Show format selection
    showModalBottomSheet(
      context: context,
      builder: (context) => _DownloadOptionsSheet(
        entry: entry,
        onDownload: (file) {
          Navigator.pop(context);
          _downloadFile(entry, file, openAfterDownload);
        },
      ),
    );
  }

  Future<void> _downloadFile(
    CatalogEntry entry,
    CatalogFile file,
    bool openAfterDownload,
  ) async {
    final bookId = await _provider.downloadAndImportEntry(entry, file);
    if (mounted) {
      if (bookId != null) {
        if (openAfterDownload) {
          // Refresh library so the reader can find the newly imported book
          await context.read<LibraryProvider>().loadBooks();
          if (mounted) {
            // Navigate to reader
            context.push(AppRoutes.readerPath(bookId));
          }
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Downloaded: ${entry.title}')));
        }
      } else if (_provider.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_provider.error!)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  PreferredSizeWidget _buildAppBar() {
    final canGoBack = _provider.canNavigateBack;
    final isSearching = _provider.isSearching;

    return AppBar(
      leading: canGoBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                final navigated = await _provider.navigateBack();
                if (!navigated && mounted) {
                  Navigator.of(context).pop();
                }
              },
            )
          : null,
      title: isSearching
          ? AdaptiveSearchField(
              controller: _searchController,
              autofocus: true,
              placeholder: 'Search...',
              onSubmitted: _onSearch,
              onClear: () {
                _searchController.clear();
                _provider.clearSearch();
              },
            )
          : Text(_provider.currentResult?.title ?? widget.catalog.name),
      actions: [
        if (_provider.hasSearch && !isSearching)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _searchController.clear();
              });
              _onSearch(''); // Trigger search mode
            },
          ),
        if (_provider.isFromCache)
          Tooltip(
            message: 'Cached ${_provider.cacheAgeText}',
            child: const Icon(Icons.offline_bolt, size: 20),
          ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _provider.isLoading ? null : _onRefresh,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_provider.isLoading && _provider.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_provider.error != null && _provider.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _provider.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _onRefresh, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_provider.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _provider.isSearching
                  ? 'No results found'
                  : 'This catalog is empty',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final hasFacets = _provider.currentResult?.hasFacets ?? false;

    return Column(
      children: [
        // Facet filter bar
        if (hasFacets) _buildFacetFilterBar(),

        // Content
        Expanded(
          child: RefreshIndicator.adaptive(
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              itemCount:
                  _provider.entries.length + (_provider.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _provider.entries.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final entry = _provider.entries[index];

                // Use mosaic tile for navigation entries
                if (entry.type == CatalogEntryType.navigation ||
                    entry.type == CatalogEntryType.collection) {
                  return _buildMosaicTile(entry);
                }

                return _CatalogEntryTile(
                  entry: entry,
                  downloadProgress: _provider.getDownloadProgress(entry.id),
                  isDownloaded: _provider.isDownloaded(entry.id),
                  onTap: () => _onEntryTap(entry),
                  onDownload: () => _onDownloadOnly(entry),
                  onOpen: () => _downloadAndOpen(entry),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the facet filter bar for catalog facets
  Widget _buildFacetFilterBar() {
    final facetGroups = _provider.currentResult?.facetGroups ?? [];

    return FacetFilterBar(
      facetGroups: facetGroups,
      isCatalogMode: true,
      onFacetTap: (facet, group) {
        // Navigate to facet URL
        _provider.navigateToPath(facet.href);
      },
      onShowFilters: () => _showFacetSelectionSheet(),
      onClearAll: null, // Catalog facets are server-side
    );
  }

  /// Shows the facet selection bottom sheet
  void _showFacetSelectionSheet() {
    final facetGroups = _provider.currentResult?.facetGroups ?? [];

    showFacetSelectionSheet(
      context: context,
      facetGroups: facetGroups,
      onFacetSelected: (facet, group) {
        // Navigate to facet URL (immediate action in catalog mode)
        _provider.navigateToPath(facet.href);
      },
      isCatalogMode: true,
    );
  }

  Widget _buildMosaicTile(CatalogEntry entry) {
    final cachedUrls = _provider.getCachedChildCoverUrls(entry.id);
    final isFetching = _provider.isFetchingChildCovers(entry.id);

    // Trigger fetch if no cached data and not already fetching
    if (cachedUrls.isEmpty && !isFetching) {
      // Schedule fetch after build to avoid calling notifyListeners during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _provider.fetchChildCoverUrls(entry).then((_) {
          if (mounted) setState(() {});
        });
      });
    }

    return MosaicPreviewListTile(
      entry: entry,
      childCoverUrls: cachedUrls,
      isLoading: isFetching,
      onTap: () => _onEntryTap(entry),
    );
  }
}

/// Tile widget for displaying a catalog entry.
class _CatalogEntryTile extends StatelessWidget {
  const _CatalogEntryTile({
    required this.entry,
    required this.onTap,
    this.onDownload,
    this.onOpen,
    this.downloadProgress,
    this.isDownloaded = false,
  });

  final CatalogEntry entry;

  /// Called when the row is tapped (navigates or downloads+opens)
  final VoidCallback onTap;

  /// Called when the download button is tapped (download only)
  final VoidCallback? onDownload;

  /// Called when the open button is tapped (opens downloaded book)
  final VoidCallback? onOpen;

  final double? downloadProgress;
  final bool isDownloaded;

  @override
  Widget build(BuildContext context) {
    final isDownloading = downloadProgress != null;

    return ListTile(
      leading: _buildLeading(),
      title: Text(entry.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: entry.subtitle != null
          ? Text(entry.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: _buildTrailing(context, isDownloading),
      onTap: isDownloading ? null : onTap,
    );
  }

  Widget _buildLeading() {
    if (entry.thumbnailUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          entry.thumbnailUrl!,
          width: 48,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, error, stackTrace) => _buildDefaultIcon(),
        ),
      );
    }
    return _buildDefaultIcon();
  }

  Widget _buildDefaultIcon() {
    IconData icon;
    switch (entry.type) {
      case CatalogEntryType.book:
        icon = Icons.book;
      case CatalogEntryType.collection:
        icon = Icons.folder;
      case CatalogEntryType.navigation:
        icon = Icons.chevron_right;
    }
    return Container(
      width: 48,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: Colors.grey[600]),
    );
  }

  Widget? _buildTrailing(BuildContext context, bool isDownloading) {
    final theme = Theme.of(context);

    if (isDownloading) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(value: downloadProgress, strokeWidth: 2),
            Text(
              '${((downloadProgress ?? 0) * 100).toInt()}',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      );
    }

    if (isDownloaded) {
      return IconButton(
        icon: const Icon(Icons.menu_book),
        color: theme.colorScheme.primary,
        tooltip: 'Open in reader',
        onPressed: onOpen,
      );
    }

    if (entry.type == CatalogEntryType.book && entry.files.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.download),
        tooltip: 'Download',
        onPressed: onDownload,
      );
    }

    if (entry.type != CatalogEntryType.book) {
      return const Icon(Icons.chevron_right);
    }

    return null;
  }
}

/// Bottom sheet for selecting download format.
class _DownloadOptionsSheet extends StatelessWidget {
  const _DownloadOptionsSheet({required this.entry, required this.onDownload});

  final CatalogEntry entry;
  final void Function(CatalogFile) onDownload;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Choose format',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),
          ...entry.files.map(
            (file) => ListTile(
              leading: Icon(_getFormatIcon(file)),
              title: Text(file.title ?? _getFormatName(file)),
              subtitle: file.size != null
                  ? Text(_formatSize(file.size!))
                  : null,
              onTap: () => onDownload(file),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  IconData _getFormatIcon(CatalogFile file) {
    if (file.isEpub) return Icons.book;
    if (file.isPdf) return Icons.picture_as_pdf;
    if (file.isComic) return Icons.photo_library;
    return Icons.insert_drive_file;
  }

  String _getFormatName(CatalogFile file) {
    final ext = file.extension?.toUpperCase();
    if (ext != null) return ext;
    if (file.isEpub) return 'EPUB';
    if (file.isPdf) return 'PDF';
    if (file.isComic) return 'Comic';
    return file.mimeType;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
