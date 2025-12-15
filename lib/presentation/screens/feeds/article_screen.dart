import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../domain/entities/feed_item.dart';
import '../../providers/feed_reader_provider.dart';
import '../../widgets/adaptive/adaptive_action_sheet.dart';
import '../../widgets/adaptive/adaptive_button.dart';
import '../../widgets/adaptive/adaptive_navigation_bar.dart';
import '../../widgets/adaptive/adaptive_page_scaffold.dart';
import '../../widgets/adaptive/adaptive_snackbar.dart';

/// Screen for reading a feed article/item content.
///
/// Displays the full content of an RSS/Atom feed item with:
/// - Title and metadata (author, date)
/// - HTML content rendering
/// - Star/bookmark functionality
/// - Open in browser option
/// - Download enclosures if available
class ArticleScreen extends StatefulWidget {
  final String feedId;
  final String itemId;

  const ArticleScreen({super.key, required this.feedId, required this.itemId});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  FeedItem? _item;
  bool _isLoading = true;
  bool _isScraping = false;
  bool _scrapingFailed = false;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    final provider = Provider.of<FeedReaderProvider>(context, listen: false);
    final item = await provider.getItem(widget.itemId);

    if (item != null && mounted) {
      // Mark as read when opened
      await provider.markAsRead(widget.itemId);
    }

    if (mounted) {
      setState(() {
        _item = item;
        _isLoading = false;
      });

      // If item needs scraping, fetch full content automatically
      if (item != null && item.needsScraping) {
        _fetchFullContent();
      }
    }
  }

  Future<void> _fetchFullContent() async {
    if (_item == null || _isScraping) return;

    setState(() {
      _isScraping = true;
      _scrapingFailed = false;
    });

    final provider = Provider.of<FeedReaderProvider>(context, listen: false);
    final updatedItem = await provider.fetchFullContent(
      widget.feedId,
      widget.itemId,
    );

    if (mounted) {
      setState(() {
        _isScraping = false;
        if (updatedItem != null) {
          _item = updatedItem;
        } else {
          _scrapingFailed = true;
        }
      });
    }
  }

  Future<void> _openInBrowser() async {
    final link = _item?.link;
    if (link == null) return;

    final uri = Uri.tryParse(link);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      showAdaptiveSnackBar(context, message: 'Could not open link');
    }
  }

  void _toggleStarred() {
    final provider = Provider.of<FeedReaderProvider>(context, listen: false);
    provider.toggleStarred(widget.itemId);
    setState(() {
      _item = _item?.copyWith(isStarred: !(_item?.isStarred ?? false));
    });
  }

  void _toggleReadState() {
    final provider = Provider.of<FeedReaderProvider>(context, listen: false);
    if (_item?.isRead ?? false) {
      provider.markAsUnread(widget.itemId);
      setState(() {
        _item = _item?.copyWith(isRead: false);
      });
    } else {
      provider.markAsRead(widget.itemId);
      setState(() {
        _item = _item?.copyWith(isRead: true);
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} min ago';
      }
      return '${diff.inHours} hours ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final useCupertino = context.useCupertino;

    return AdaptivePageScaffold(
      navigationBar: AdaptiveNavigationBar(
        title: 'Article',
        trailing: [
          if (_item != null) ...[
            AdaptiveIconButton(
              icon: _item!.isStarred
                  ? (useCupertino ? CupertinoIcons.star_fill : Icons.star)
                  : (useCupertino ? CupertinoIcons.star : Icons.star_outline),
              tooltip: _item!.isStarred ? 'Unstar' : 'Star',
              onPressed: _toggleStarred,
            ),
            AdaptiveIconButton(
              icon: useCupertino ? CupertinoIcons.ellipsis : Icons.more_vert,
              tooltip: 'More',
              onPressed: () {
                AdaptiveActionSheet.show(
                  context: context,
                  actions: [
                    if (_item?.link != null)
                      AdaptiveActionSheetAction(
                        label: 'Open in browser',
                        icon: Icons.open_in_browser,
                        onPressed: _openInBrowser,
                      ),
                    AdaptiveActionSheetAction(
                      label: _item?.isRead ?? false
                          ? 'Mark as unread'
                          : 'Mark as read',
                      icon: _item?.isRead ?? false
                          ? Icons.mark_email_unread
                          : Icons.mark_email_read,
                      onPressed: _toggleReadState,
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_item == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Article not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'The article may have been deleted.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            _item!.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Metadata row
          Row(
            children: [
              if (_item!.author != null && _item!.author!.isNotEmpty) ...[
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  _item!.author!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              if (_item!.pubDate != null) ...[
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(_item!.pubDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),

          // Enclosures section (downloads)
          if (_item!.hasSupportedEnclosures) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.download,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Downloads Available',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _item!.supportedEnclosures.map((enclosure) {
                        return ActionChip(
                          avatar: const Icon(Icons.file_download, size: 18),
                          label: Text(_getEnclosureLabel(enclosure.url)),
                          onPressed: () => _downloadEnclosure(enclosure),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Article content
          if (_isScraping)
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading full article...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          else if (_item!.hasContent)
            HtmlWidget(
              _item!.displayContent,
              textStyle: Theme.of(context).textTheme.bodyLarge,
              onTapUrl: (url) async {
                final uri = Uri.tryParse(url);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                return true;
              },
            )
          else if (_scrapingFailed)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Could not load article',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _fetchFullContent,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                      const SizedBox(width: 12),
                      if (_item?.link != null)
                        FilledButton.icon(
                          onPressed: _openInBrowser,
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text('Open in browser'),
                        ),
                    ],
                  ),
                ],
              ),
            )
          else
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No content available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  if (_item?.link != null) ...[
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _openInBrowser,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Read in browser'),
                    ),
                  ],
                ],
              ),
            ),

          // Bottom padding
          const SizedBox(height: 32),

          // Open in browser button at bottom
          if (_item?.link != null) ...[
            const Divider(),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                onPressed: _openInBrowser,
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Read full article in browser'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getEnclosureLabel(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return 'Download';

    final path = uri.path.toLowerCase();
    if (path.endsWith('.epub')) return 'EPUB';
    if (path.endsWith('.pdf')) return 'PDF';
    if (path.endsWith('.cbz')) return 'CBZ';
    if (path.endsWith('.cbr')) return 'CBR';
    if (path.endsWith('.mobi')) return 'MOBI';

    // Try to get filename
    final segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      final filename = segments.last;
      if (filename.length <= 20) return filename;
      return '${filename.substring(0, 17)}...';
    }

    return 'Download';
  }

  Future<void> _downloadEnclosure(dynamic enclosure) async {
    // Navigate to RSS browse screen which handles downloads
    // For now, show a snackbar indicating the feature
    if (mounted) {
      showAdaptiveSnackBar(
        context,
        message: 'Downloading: ${_getEnclosureLabel(enclosure.url)}',
        action: AdaptiveSnackBarAction(
          label: 'View',
          onPressed: () {
            // Could navigate to library after download
          },
        ),
      );

      // TODO: Integrate with actual download service
      // The RssBrowseScreen has download logic we could reuse
    }
  }
}
