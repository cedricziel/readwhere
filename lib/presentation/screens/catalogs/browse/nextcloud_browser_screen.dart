import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';

import '../../../../core/di/service_locator.dart';
import '../../../providers/catalogs_provider.dart';
import '../../../providers/library_provider.dart';

/// Screen for browsing Nextcloud files via WebDAV
class NextcloudBrowserScreen extends StatefulWidget {
  final String catalogId;

  const NextcloudBrowserScreen({super.key, required this.catalogId});

  @override
  State<NextcloudBrowserScreen> createState() => _NextcloudBrowserScreenState();
}

class _NextcloudBrowserScreenState extends State<NextcloudBrowserScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Defer loading to avoid calling notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCatalog();
    });
  }

  Future<void> _loadCatalog() async {
    final provider = sl<CatalogsProvider>();
    final catalog = provider.catalogs.firstWhere(
      (c) => c.id == widget.catalogId,
      orElse: () => throw Exception('Catalog not found'),
    );

    if (catalog.isNextcloud) {
      await provider.openNextcloudBrowser(catalog);
    }
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await sl<CatalogsProvider>().refreshNextcloudDirectory();
    setState(() => _isRefreshing = false);
  }

  void _handleFileTap(NextcloudFile file) {
    final provider = sl<CatalogsProvider>();
    if (file.isDirectory) {
      provider.navigateNextcloudTo(file.path);
    } else if (file.isSupportedBook) {
      _showDownloadSheet(file);
    }
  }

  void _showDownloadSheet(NextcloudFile file) {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          _DownloadSheet(file: file, onDownload: () => _handleDownload(file)),
    );
  }

  Future<void> _handleDownload(NextcloudFile file) async {
    Navigator.of(context).pop(); // Close bottom sheet

    final provider = sl<CatalogsProvider>();
    final book = await provider.downloadNextcloudBook(file);

    if (book != null && mounted) {
      // Refresh library
      sl<LibraryProvider>().loadBooks();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded: ${book.title}'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              // Navigate to reader
              // context.push('/reader/${book.id}');
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CatalogsProvider>(
      builder: (context, provider, _) {
        final catalog = provider.selectedCatalog;

        return Scaffold(
          appBar: AppBar(
            title: Text(catalog?.name ?? 'Nextcloud'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                provider.closeNextcloudBrowser();
                Navigator.of(context).pop();
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _isRefreshing ? null : _refresh,
              ),
            ],
          ),
          body: Column(
            children: [
              // Breadcrumb navigation
              _buildBreadcrumbs(provider),
              // Content
              Expanded(child: _buildContent(provider)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBreadcrumbs(CatalogsProvider provider) {
    final breadcrumbs = provider.nextcloudBreadcrumbs;
    final theme = Theme.of(context);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: breadcrumbs.length,
        separatorBuilder: (context, index) =>
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        itemBuilder: (context, index) {
          final isLast = index == breadcrumbs.length - 1;
          return TextButton(
            onPressed: isLast
                ? null
                : () {
                    // Navigate to that path
                    final path = breadcrumbs.sublist(0, index + 1).join('/');
                    provider.navigateNextcloudTo(path == '/' ? '/' : path);
                  },
            child: Text(
              breadcrumbs[index],
              style: TextStyle(
                fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                color: isLast
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.primary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(CatalogsProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return _buildErrorState(provider.error!);
    }

    final files = provider.nextcloudFiles;
    if (files.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return NextcloudFileTile(
            file: file,
            onTap: () => _handleFileTap(file),
            downloadProgress: provider.getDownloadProgress(
              'nextcloud:${file.path}',
            ),
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
            Icons.folder_open,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'This folder is empty',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
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
              'Error loading files',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for download options
class _DownloadSheet extends StatelessWidget {
  final NextcloudFile file;
  final VoidCallback onDownload;

  const _DownloadSheet({required this.file, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              file.name,
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (file.size != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatFileSize(file.size!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download),
                label: const Text('Download to Library'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
