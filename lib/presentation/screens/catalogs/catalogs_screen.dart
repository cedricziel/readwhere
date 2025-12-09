import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/service_locator.dart';
import '../../../domain/entities/catalog.dart';
import '../../providers/catalogs_provider.dart';
import '../../router/routes.dart';
import 'widgets/add_catalog_dialog.dart';
import 'widgets/catalog_card.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${result.name}"'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => _openCatalog(result),
          ),
        ),
      );
    }
  }

  void _openCatalog(Catalog catalog) {
    if (catalog.isNextcloud) {
      context.push(AppRoutes.nextcloudBrowsePath(catalog.id));
    } else {
      context.push(AppRoutes.catalogBrowsePath(catalog.id));
    }
  }

  Future<void> _confirmDeleteCatalog(Catalog catalog) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Server'),
        content: Text(
          'Remove "${catalog.name}" from your servers?\n\n'
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = sl<CatalogsProvider>();
      final success = await provider.removeCatalog(catalog.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Removed "${catalog.name}"'
                  : 'Failed to remove catalog',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: sl<CatalogsProvider>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Servers')),
        body: Consumer<CatalogsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.catalogs.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null && provider.catalogs.isEmpty) {
              return _buildErrorState(provider);
            }

            if (provider.catalogs.isEmpty) {
              return _buildEmptyState();
            }

            return _buildCatalogList(provider);
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddCatalogDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Server'),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
    return RefreshIndicator(
      onRefresh: () => provider.loadCatalogs(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.catalogs.length,
        itemBuilder: (context, index) {
          final catalog = provider.catalogs[index];
          return CatalogCard(
            catalog: catalog,
            onTap: () => _openCatalog(catalog),
            onDelete: () => _confirmDeleteCatalog(catalog),
          );
        },
      ),
    );
  }
}
