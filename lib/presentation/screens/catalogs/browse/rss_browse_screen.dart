import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:readwhere_rss/readwhere_rss.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../data/services/book_import_service.dart';
import '../../../../domain/entities/feed_item.dart';
import '../../../../domain/repositories/book_repository.dart';
import '../../../providers/catalogs_provider.dart';
import '../../../providers/feed_reader_provider.dart';
import '../../../providers/library_provider.dart';
import '../../../router/routes.dart';

/// Filter options for RSS feed items
enum FeedFilter { all, downloadable, unread }

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
  String? _catalogUrl;
  FeedFilter _filter = FeedFilter.all;
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
    final feedReaderProvider = sl<FeedReaderProvider>();

    try {
      final catalog = catalogsProvider.catalogs.firstWhere(
        (c) => c.id == widget.catalogId,
        orElse: () => throw Exception('Catalog not found'),
      );

      setState(() {
        _catalogName = catalog.name;
        _catalogUrl = catalog.url;
        _isLoading = true;
        _error = null;
      });

      // First load from database (cached items)
      await feedReaderProvider.loadFeedItems(widget.catalogId);

      // Then refresh from network
      await feedReaderProvider.refreshFeed(widget.catalogId, catalog.url);

      setState(() {
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
    if (_isRefreshing || _catalogUrl == null) return;

    setState(() => _isRefreshing = true);
    try {
      final feedReaderProvider = sl<FeedReaderProvider>();
      await feedReaderProvider.refreshFeed(widget.catalogId, _catalogUrl!);
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _handleItemTap(FeedItem item) {
    // Navigate to article screen
    context.push(AppRoutes.articlePath(widget.catalogId, item.id));
  }

  void _showDownloadSheet(FeedItem item) {
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

  Future<void> _handleDownload(FeedItem item, RssEnclosure enclosure) async {
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

  void _markAllAsRead() async {
    final feedReaderProvider = sl<FeedReaderProvider>();
    await feedReaderProvider.markAllAsRead(widget.catalogId);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Marked all as read')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<FeedReaderProvider>(
          builder: (context, provider, child) {
            final unreadCount = provider.getUnreadCount(widget.catalogId);
            final title = _catalogName ?? 'RSS Feed';
            if (unreadCount > 0) {
              return Text('$title ($unreadCount)');
            }
            return Text(title);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refresh,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'mark_all_read':
                  _markAllAsRead();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: ListTile(
                  leading: Icon(Icons.done_all),
                  title: Text('Mark all as read'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(),
          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            selected: _filter == FeedFilter.all,
            label: const Text('All'),
            onSelected: (selected) {
              if (selected) setState(() => _filter = FeedFilter.all);
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: _filter == FeedFilter.unread,
            label: const Text('Unread'),
            onSelected: (selected) {
              if (selected) setState(() => _filter = FeedFilter.unread);
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: _filter == FeedFilter.downloadable,
            label: const Text('Downloads'),
            onSelected: (selected) {
              if (selected) setState(() => _filter = FeedFilter.downloadable);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return Consumer<FeedReaderProvider>(
      builder: (context, provider, child) {
        var items = provider.getItems(widget.catalogId);

        // Apply filter
        switch (_filter) {
          case FeedFilter.unread:
            items = items.where((item) => !item.isRead).toList();
          case FeedFilter.downloadable:
            items = items.where((item) => item.hasSupportedEnclosures).toList();
          case FeedFilter.all:
            break;
        }

        if (items.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _FeedItemTile(
                item: item,
                isDownloading: _downloadProgress.containsKey(item.id),
                isDownloaded: _downloadedIds.contains(item.id),
                downloadProgress: _downloadProgress[item.id] ?? 0.0,
                onTap: () => _handleItemTap(item),
                onDownloadTap: item.hasSupportedEnclosures
                    ? () => _showDownloadSheet(item)
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String message;
    switch (_filter) {
      case FeedFilter.unread:
        message = 'All caught up! No unread items.';
      case FeedFilter.downloadable:
        message = 'No downloadable content in this feed (EPUB, PDF, CBZ, CBR).';
      case FeedFilter.all:
        message = 'This feed has no items.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _filter == FeedFilter.unread
                  ? Icons.check_circle_outline
                  : Icons.rss_feed,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            if (_filter != FeedFilter.all) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _filter = FeedFilter.all),
                child: const Text('Show all items'),
              ),
            ],
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

/// List tile for a feed item
class _FeedItemTile extends StatelessWidget {
  final FeedItem item;
  final bool isDownloading;
  final bool isDownloaded;
  final double downloadProgress;
  final VoidCallback onTap;
  final VoidCallback? onDownloadTap;

  const _FeedItemTile({
    required this.item,
    required this.isDownloading,
    required this.isDownloaded,
    required this.downloadProgress,
    required this.onTap,
    this.onDownloadTap,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m';
      }
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${date.day}/${date.month}';
    }
  }

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
      title: Text(
        item.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (item.author != null) ...[
                Flexible(
                  child: Text(
                    item.author!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (item.pubDate != null)
                Text(
                  _formatDate(item.pubDate),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
            ],
          ),
          if (formatChips.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: formatChips.map((String format) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
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
      child: Icon(
        item.hasSupportedEnclosures ? Icons.book : Icons.article,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }

  Widget? _buildTrailing(BuildContext context) {
    // Unread indicator
    final List<Widget> trailing = [];

    if (!item.isRead) {
      trailing.add(
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    // Download status/button
    if (item.hasSupportedEnclosures) {
      if (isDownloaded) {
        trailing.add(
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      } else if (isDownloading) {
        trailing.add(
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: downloadProgress,
              strokeWidth: 2,
            ),
          ),
        );
      } else {
        trailing.add(
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: onDownloadTap,
            tooltip: 'Download',
          ),
        );
      }
    }

    if (trailing.isEmpty) return null;

    return Row(mainAxisSize: MainAxisSize.min, children: trailing);
  }
}
