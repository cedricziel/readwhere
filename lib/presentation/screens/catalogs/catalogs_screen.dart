import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../domain/entities/catalog.dart';
import '../../providers/catalogs_provider.dart';
import '../../router/routes.dart';
import '../../widgets/adaptive/adaptive_button.dart';
import '../../widgets/adaptive/adaptive_navigation_bar.dart';
import '../../widgets/adaptive/adaptive_page_scaffold.dart';
import '../../widgets/adaptive/adaptive_snackbar.dart';
import '../../widgets/adaptive/responsive_layout.dart';
import 'widgets/add_catalog_dialog.dart';
import 'widgets/catalog_card.dart';
import 'widgets/nextcloud_catalog_settings_dialog.dart';

/// The catalogs screen for browsing OPDS catalogs and online book sources.
///
/// This screen allows users to:
/// - View saved Kavita/OPDS server connections
/// - Add new server connections
/// - Browse catalogs to download books
class CatalogsScreen extends StatefulWidget {
  const CatalogsScreen({super.key});

  @override
  State<CatalogsScreen> createState() => _CatalogsScreenState();
}

class _CatalogsScreenState extends State<CatalogsScreen> {
  @override
  void initState() {
    super.initState();
    // Load catalogs when screen is first shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sl<CatalogsProvider>().loadCatalogs();
    });
  }

  Future<void> _showAddCatalogDialog() async {
    final result = await showDialog<Catalog>(
      context: context,
      builder: (context) => const AddCatalogDialog(),
    );

    if (result != null && mounted) {
      showAdaptiveSnackBar(
        context,
        message: 'Added "${result.name}"',
        duration: const Duration(seconds: 3),
        action: AdaptiveSnackBarAction(
          label: 'Open',
          onPressed: () => _openCatalog(result),
        ),
      );
    }
  }

  void _openCatalog(Catalog catalog) {
    final router = GoRouter.of(context);
    if (catalog.isNextcloud) {
      router.push(AppRoutes.nextcloudBrowsePath(catalog.id));
    } else if (catalog.isRss) {
      router.push(AppRoutes.rssBrowsePath(catalog.id));
    } else if (catalog.isFanfiction) {
      router.push(AppRoutes.fanfictionBrowsePath(catalog.id));
    } else {
      router.push(AppRoutes.catalogBrowsePath(catalog.id));
    }
  }

  Future<void> _confirmDeleteCatalog(Catalog catalog) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Remove Server'),
        content: Text(
          'Remove "${catalog.name}" from your servers?\n\n'
          'Books you\'ve downloaded will remain in your library.',
        ),
        actions: [
          AdaptiveTextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          AdaptiveTextButton(
            onPressed: () => Navigator.pop(context, true),
            isDestructive: true,
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = sl<CatalogsProvider>();
      final success = await provider.removeCatalog(catalog.id);
      if (mounted) {
        showAdaptiveSnackBar(
          context,
          message: success
              ? 'Removed "${catalog.name}"'
              : 'Failed to remove catalog',
        );
      }
    }
  }

  Future<void> _openSettings(Catalog catalog) async {
    final result = await NextcloudCatalogSettingsDialog.show(
      context: context,
      catalog: catalog,
    );

    if (result != null && mounted) {
      showAdaptiveSnackBar(
        context,
        message: 'Settings updated for "${result.name}"',
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final useCupertino = context.useCupertino;

    return ChangeNotifierProvider.value(
      value: sl<CatalogsProvider>(),
      child: AdaptivePageScaffold(
        navigationBar: AdaptiveNavigationBar(
          title: 'Servers',
          trailing: [
            AdaptiveIconButton(
              icon: useCupertino ? CupertinoIcons.add : Icons.add,
              tooltip: 'Add Server',
              onPressed: _showAddCatalogDialog,
            ),
          ],
        ),
        child: Consumer<CatalogsProvider>(
          builder: (context, provider, child) {
            // Filter out RSS feeds (they are managed in FeedsScreen)
            final servers = provider.catalogs.where((c) => !c.isRss).toList();

            if (provider.isLoading && servers.isEmpty) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            if (provider.error != null && servers.isEmpty) {
              return _buildErrorState(provider);
            }

            if (servers.isEmpty) {
              return _buildEmptyState();
            }

            return _buildCatalogList(provider);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'No Servers Connected',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Connect to a Kavita or OPDS server to browse and download books.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _showAddCatalogDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Server'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(CatalogsProvider provider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacingXL),
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
              'Error Loading Servers',
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

  Widget _buildCatalogList(CatalogsProvider provider) {
    // Filter out RSS feeds (they are managed in FeedsScreen)
    final servers = provider.catalogs.where((c) => !c.isRss).toList();

    if (servers.isEmpty) {
      return _buildEmptyState();
    }

    // Use grid layout in phone landscape for better horizontal space usage
    final useGrid = context.isPhoneLandscape;
    final padding = context.spacingM;

    return RefreshIndicator.adaptive(
      onRefresh: () => provider.loadCatalogs(),
      child: useGrid
          ? GridView.builder(
              padding: EdgeInsets.all(padding),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: servers.length,
              itemBuilder: (context, index) {
                final catalog = servers[index];
                return CatalogCard(
                  catalog: catalog,
                  onTap: () => _openCatalog(catalog),
                  onDelete: () => _confirmDeleteCatalog(catalog),
                  onSettings: catalog.isNextcloud
                      ? () => _openSettings(catalog)
                      : null,
                );
              },
            )
          : ListView.builder(
              padding: EdgeInsets.all(padding),
              itemCount: servers.length,
              itemBuilder: (context, index) {
                final catalog = servers[index];
                return CatalogCard(
                  catalog: catalog,
                  onTap: () => _openCatalog(catalog),
                  onDelete: () => _confirmDeleteCatalog(catalog),
                  onSettings: catalog.isNextcloud
                      ? () => _openSettings(catalog)
                      : null,
                );
              },
            ),
    );
  }
}
