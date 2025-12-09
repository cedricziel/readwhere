import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:readwhere_rss/readwhere_rss.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../data/services/book_import_service.dart';
import '../../../../domain/repositories/book_repository.dart';
import '../../../providers/catalogs_provider.dart';
import '../../../providers/library_provider.dart';
import '../../../router/routes.dart';

/// Extracts file extension from an enclosure URL
String? _getEnclosureExtension(RssEnclosure enclosure) {
  // Try to get extension from URL
  try {
    final uri = Uri.parse(enclosure.url);
    final path = uri.path;
    final lastDot = path.lastIndexOf('.');
    if (lastDot >= 0 && lastDot < path.length - 1) {
      return path.substring(lastDot + 1).toLowerCase();
    }
  } catch (_) {
    // Invalid URL
  }

  // Fall back to MIME type
  final type = enclosure.type;
  if (type != null) {
    if (type.contains('epub')) return 'epub';
    if (type.contains('pdf')) return 'pdf';
    if (type.contains('mobi') || type.contains('mobipocket')) return 'mobi';
    if (type.contains('cbz')) return 'cbz';
    if (type.contains('cbr')) return 'cbr';
  }

  return null;
}

/// Screen for browsing an RSS feed's contents
class RssBrowseScreen extends StatefulWidget {
  final String catalogId;

  const RssBrowseScreen({super.key, required this.catalogId});

  @override
  State<RssBrowseScreen> createState() => _RssBrowseScreenState();
}

class _RssBrowseScreenState extends State<RssBrowseScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  String? _catalogName;
  RssFeed? _feed;
  final Map<String, double> _downloadProgress = {};
  final Set<String> _downloadedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeed();
    });
  }

  Future<void> _loadFeed() async {
    final catalogsProvider = sl<CatalogsProvider>();

    try {
      final catalog = catalogsProvider.catalogs.firstWhere(
        (c) => c.id == widget.catalogId,
        orElse: () => throw Exception('Catalog not found'),
      );

      setState(() {
        _catalogName = catalog.name;
        _isLoading = true;
        _error = null;
      });

      final rssClient = sl<RssClient>();
      final feed = await rssClient.fetchFeed(catalog.url);

      setState(() {
        _feed = feed;
        _isLoading = false;
      });

      // Update last accessed
      await catalogsProvider.updateLastAccessed(catalog.id);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    try {
      await _loadFeed();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _handleItemTap(RssItem item) {
    if (item.hasSupportedEnclosures) {
      _showDownloadSheet(item);
    } else if (item.link != null) {
      // TODO: Open external link
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Opening: ${item.link}')));
    }
  }

  void _showDownloadSheet(RssItem item) {
    final theme = Theme.of(context);
    final enclosures = item.supportedEnclosures;
    final isDownloaded = _downloadedIds.contains(item.id);
    final isDownloading = _downloadProgress.containsKey(item.id);
    final progress = _downloadProgress[item.id] ?? 0.0;

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (item.author != null) ...[
              const SizedBox(height: 4),
              Text(
                item.author!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
            if (item.description != null) ...[
              const SizedBox(height: 12),
              Text(
                item.description!,
                style: theme.textTheme.bodyMedium,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            // Show available formats
            if (enclosures.isNotEmpty) ...[
              Text(
                'Available formats:',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: enclosures.map((e) {
                  final ext =
                      _getEnclosureExtension(e)?.toUpperCase() ?? 'FILE';
                  return Chip(
                    label: Text(ext),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
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
                    // TODO: Open the book
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
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleDownload(item, enclosures.first);
                  },
                  icon: const Icon(Icons.download),
                  label: Text(
                    'Download (${_getEnclosureExtension(enclosures.first)?.toUpperCase() ?? "FILE"})',
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

  Future<void> _handleDownload(RssItem item, RssEnclosure enclosure) async {
    setState(() {
      _downloadProgress[item.id] = 0.0;
    });

    try {
      // Get temp directory for download
      final tempDir = await getTemporaryDirectory();
      final ext = _getEnclosureExtension(enclosure) ?? 'epub';
      final filename = enclosure.filename ?? '${item.id}.$ext';
      final localPath = p.join(tempDir.path, filename);

      // Download the file
      final rssClient = sl<RssClient>();
      await rssClient.downloadEnclosure(
        enclosure.url,
        localPath,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress[item.id] = progress;
            });
          }
        },
      );

      // Import the book
      final importService = sl<BookImportService>();
      final bookRepository = sl<BookRepository>();

      final book = await importService.importBook(localPath);
      final savedBook = await bookRepository.insert(
        book.copyWith(sourceCatalogId: widget.catalogId),
      );

      // Clean up temp file
      try {
        await File(localPath).delete();
      } catch (_) {
        // Ignore cleanup errors
      }

      if (mounted) {
        setState(() {
          _downloadProgress.remove(item.id);
          _downloadedIds.add(item.id);
        });

        // Refresh library
        sl<LibraryProvider>().loadBooks();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded: ${savedBook.title}'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                context.push(AppRoutes.readerPath(savedBook.id));
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadProgress.remove(item.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_feed?.title ?? _catalogName ?? 'RSS Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refresh,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    final feed = _feed;
    if (feed == null || feed.items.isEmpty) {
      return _buildEmptyState();
    }

    // Filter to only show items with supported enclosures
    final items = feed.supportedItems;
    if (items.isEmpty) {
      return _buildNoSupportedItemsState(feed);
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _RssItemTile(
            item: item,
            isDownloading: _downloadProgress.containsKey(item.id),
            isDownloaded: _downloadedIds.contains(item.id),
            downloadProgress: _downloadProgress[item.id] ?? 0.0,
            onTap: () => _handleItemTap(item),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rss_feed,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text('Feed is empty', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'This feed has no items',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildNoSupportedItemsState(RssFeed feed) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No downloadable content',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This feed has ${feed.items.length} items, but none contain '
              'downloadable ebooks or comics (EPUB, PDF, CBZ, CBR).',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              'Error loading feed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadFeed,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// List tile for an RSS item
class _RssItemTile extends StatelessWidget {
  final RssItem item;
  final bool isDownloading;
  final bool isDownloaded;
  final double downloadProgress;
  final VoidCallback onTap;

  const _RssItemTile({
    required this.item,
    required this.isDownloading,
    required this.isDownloaded,
    required this.downloadProgress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enclosures = item.supportedEnclosures;
    final formatChips = enclosures
        .map((e) => _getEnclosureExtension(e)?.toUpperCase() ?? 'FILE')
        .toSet()
        .toList();

    return ListTile(
      leading: item.thumbnailUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                item.thumbnailUrl!,
                width: 48,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholder(context),
              ),
            )
          : _buildPlaceholder(context),
      title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.author != null)
            Text(
              item.author!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: formatChips.map((String format) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  format,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      trailing: _buildTrailing(context),
      onTap: onTap,
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: 48,
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.book, color: Theme.of(context).colorScheme.outline),
    );
  }

  Widget? _buildTrailing(BuildContext context) {
    if (isDownloaded) {
      return Icon(
        Icons.check_circle,
        color: Theme.of(context).colorScheme.primary,
      );
    }

    if (isDownloading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          value: downloadProgress,
          strokeWidth: 2,
        ),
      );
    }

    return const Icon(Icons.download_outlined);
  }
}
