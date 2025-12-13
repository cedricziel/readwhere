import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:readwhere_nextcloud/readwhere_nextcloud.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../data/services/book_import_service.dart';
import '../../../../domain/repositories/book_repository.dart';
import '../../../providers/catalogs_provider.dart';
import '../../../providers/library_provider.dart';
import '../../../router/routes.dart';

/// Screen for browsing Nextcloud files via WebDAV
class NextcloudBrowserScreen extends StatefulWidget {
  final String catalogId;

  const NextcloudBrowserScreen({super.key, required this.catalogId});

  @override
  State<NextcloudBrowserScreen> createState() => _NextcloudBrowserScreenState();
}

class _NextcloudBrowserScreenState extends State<NextcloudBrowserScreen> {
  bool _isRefreshing = false;
  String? _catalogName;

  @override
  void initState() {
    super.initState();
    // Defer loading to avoid calling notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCatalog();
    });
  }

  Future<void> _loadCatalog() async {
    final catalogsProvider = sl<CatalogsProvider>();
    final nextcloudProvider = sl<NextcloudProvider>();

    final catalog = catalogsProvider.catalogs.firstWhere(
      (c) => c.id == widget.catalogId,
      orElse: () => throw Exception('Catalog not found'),
    );

    setState(() {
      _catalogName = catalog.name;
    });

    if (catalog.isNextcloud) {
      await nextcloudProvider.openBrowser(
        catalogId: catalog.id,
        serverUrl: catalog.url,
        userId: catalog.userId ?? catalog.username ?? '',
        username: catalog.username,
        booksFolder: catalog.effectiveBooksFolder,
      );

      // Update last accessed
      await catalogsProvider.updateLastAccessed(catalog.id);
    }
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    try {
      await sl<NextcloudProvider>().refresh();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _handleFileTap(NextcloudFile file) {
    final provider = sl<NextcloudProvider>();
    if (file.isDirectory) {
      provider.navigateTo(file.path);
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

    final provider = sl<NextcloudProvider>();

    try {
      // Get temp directory for download
      final tempDir = await getTemporaryDirectory();
      final localPath = p.join(tempDir.path, file.name);

      // Download the file
      final downloadedFile = await provider.downloadFile(file, localPath);

      if (downloadedFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Download failed'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _handleBreadcrumbTap(int index) {
    final provider = sl<NextcloudProvider>();
    final breadcrumbs = provider.breadcrumbs;

    // Only allow tapping non-last breadcrumbs
    if (index < breadcrumbs.length - 1) {
      // Build path from breadcrumb parts up to tapped index
      final pathParts = breadcrumbs.sublist(0, index + 1);
      provider.navigateTo('/${pathParts.join('/')}');
    }
    // If it's the last breadcrumb, do nothing (already there)
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: sl<NextcloudProvider>(),
      child: Consumer<NextcloudProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(_catalogName ?? 'Nextcloud'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (provider.error != null) {
                    // In error state: navigate back without reload
                    final canGoBack = provider.navigateBackWithoutLoad();
                    if (!canGoBack) {
                      provider.closeBrowser();
                      Navigator.of(context).pop();
                    }
                  } else if (provider.canNavigateBack) {
                    provider.navigateBack();
                  } else {
                    provider.closeBrowser();
                    Navigator.of(context).pop();
                  }
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
      ),
    );
  }

  Widget _buildBreadcrumbs(NextcloudProvider provider) {
    final breadcrumbs = provider.breadcrumbs;
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
            onPressed: isLast ? null : () => _handleBreadcrumbTap(index),
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

  Widget _buildContent(NextcloudProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return _buildErrorState(provider.error!);
    }

    final files = provider.files;
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
            downloadProgress: provider.getDownloadProgress(file.path),
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
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                sl<NextcloudProvider>().closeBrowser();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.list),
              label: const Text('Back to Catalogs'),
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
