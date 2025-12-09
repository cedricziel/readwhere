import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/catalog.dart';
import '../../providers/catalogs_provider.dart';
import '../../providers/feed_reader_provider.dart';
import '../../router/routes.dart';
import '../catalogs/widgets/add_catalog_dialog.dart';
import 'widgets/feed_card.dart';

/// The feeds screen for managing RSS/Atom feeds.
///
/// This screen allows users to:
/// - View subscribed RSS/Atom feeds
/// - Subscribe to new feeds
/// - Browse feed contents to download books
class FeedsScreen extends StatefulWidget {
  const FeedsScreen({super.key});

  @override
  State<FeedsScreen> createState() => _FeedsScreenState();
}

class _FeedsScreenState extends State<FeedsScreen> {
  @override
  void initState() {
    super.initState();
    // Load catalogs and unread counts when screen is first shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catalogsProvider = Provider.of<CatalogsProvider>(
        context,
        listen: false,
      );
      catalogsProvider.loadCatalogs();

      // Load unread counts for badge display
      final feedReaderProvider = Provider.of<FeedReaderProvider>(
        context,
        listen: false,
      );
      feedReaderProvider.loadAllUnreadCounts();
    });
  }

  Future<void> _showAddFeedDialog() async {
    final result = await showDialog<Catalog>(
      context: context,
      builder: (context) => const AddCatalogDialog(
        initialType: CatalogType.rss,
        showTypeSelector: false,
      ),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subscribed to "${result.name}"'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => _openFeed(result),
          ),
        ),
      );
    }
  }

  void _openFeed(Catalog feed) {
    context.push(AppRoutes.rssBrowsePath(feed.id));
  }

  Future<void> _confirmUnsubscribe(Catalog feed) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsubscribe'),
        content: Text(
          'Unsubscribe from "${feed.name}"?\n\n'
          'Books you\'ve downloaded will remain in your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unsubscribe'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<CatalogsProvider>(context, listen: false);
      final success = await provider.removeCatalog(feed.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Unsubscribed from "${feed.name}"'
                  : 'Failed to unsubscribe',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CatalogsProvider>(
      builder: (context, provider, child) {
        // Filter to only RSS feeds
        final feeds = provider.catalogs.where((c) => c.isRss).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Feeds')),
          body: _buildBody(provider, feeds),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showAddFeedDialog,
            icon: const Icon(Icons.add),
            label: const Text('Subscribe'),
          ),
        );
      },
    );
  }

  Widget _buildBody(CatalogsProvider provider, List<Catalog> feeds) {
    if (provider.isLoading && feeds.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && feeds.isEmpty) {
      return _buildErrorState(provider);
    }

    if (feeds.isEmpty) {
      return _buildEmptyState();
    }

    return _buildFeedList(provider, feeds);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rss_feed,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'No Feed Subscriptions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Subscribe to RSS feeds to discover and download ebooks and comics.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _showAddFeedDialog,
              icon: const Icon(Icons.add),
              label: const Text('Subscribe to Feed'),
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
              'Error Loading Feeds',
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
              onPressed: () => provider.loadCatalogs(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedList(CatalogsProvider provider, List<Catalog> feeds) {
    return RefreshIndicator(
      onRefresh: () => provider.loadCatalogs(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: feeds.length,
        itemBuilder: (context, index) {
          final feed = feeds[index];
          return FeedCard(
            feed: feed,
            onTap: () => _openFeed(feed),
            onDelete: () => _confirmUnsubscribe(feed),
          );
        },
      ),
    );
  }
}
